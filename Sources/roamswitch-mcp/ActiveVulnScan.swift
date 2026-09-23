// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.54 (build 115).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────

import Foundation
import Network

/// Phase 2 & 3 of the active-vulnerability-verification roadmap (see
/// `roamswitch-linux/docs/ACTIVE_VULN_SCAN_SPEC.ja.md`) — the macOS counterpart of the
/// Linux client's `active_vuln_scan.rs` (Phase 2) and `web_vuln_scan.rs` (Phase 3).
///
/// Unlike `ServiceSignatures.swift` (Phase 1, zero network I/O), this file actually
/// connects to a listening service on `127.0.0.1` and sends a minimal, read-only probe
/// to confirm whether it is really reachable without authentication — not just "the
/// port is open."
///
/// Safety invariants (same as the Linux implementation):
/// - Every target is `127.0.0.1` only. Targets are derived exclusively from this
///   machine's own `ListeningPortMonitor` output.
/// - Every probe is a single connection attempt with a short timeout and no retries.
/// - Every probe is read-only: it asks "are you there, unauthenticated?" and nothing
///   else. No write/delete/config-changing command is ever sent.
/// - Disabled unless `UserDefaults.standard.bool(forKey: "RoamSwitch.ActiveVulnScanEnabled")`
///   is true (opt-in, off by default) — callers must check this before invoking anything
///   here; this file performs no work on its own.
enum ActiveVulnScan {

    static let enabledDefaultsKey = "RoamSwitch.ActiveVulnScanEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledDefaultsKey)
    }

    struct Finding {
        let port: Int
        let processName: String
        let title: String
        let description: String
        let recommendation: String
    }

    /// One probe that did NOT produce a `Finding` — either the target was
    /// actually confirmed safe, or the probe itself couldn't complete
    /// (connection refused, timeout, DNS/socket error). Reported separately
    /// so a caller can't mistake "checked, and it's fine" for "never
    /// actually got to check" — both used to collapse into the same empty
    /// findings list (see the 2026-09 discussion of `wait-for-it.sh`
    /// reporting success for a port that never opened —
    /// https://dev.to/raknaos/my-wait-for-it-wrapper-reported-success-for-a-port-that-never-opened-ga3).
    /// `check` is the same title a `Finding` for this exact probe would carry.
    struct CheckOutcome {
        let port: Int
        let processName: String
        let check: String
    }

    /// Everything `runScan` learned: confirmed findings, checks that ran to
    /// completion and found nothing, and checks that could not complete at all.
    struct ScanRunResult {
        var findings: [Finding] = []
        var confirmedSafe: [CheckOutcome] = []
        var inconclusive: [CheckOutcome] = []
    }

    // MARK: - Lightweight per-run persistence (heartbeat log)
    //
    // `runScan` always executes synchronously, right now, at the caller's
    // request (MCP tool call / manual "Run Active Verification" button) —
    // there is no scheduled/background runner yet. But the answer to "did
    // we look, and was it clean" is worth persisting the moment it exists,
    // independent of whether a timer ever gets added: it's the first
    // artifact that outlives the calling process. This appends one row per
    // probe attempted (oldest dropped first past `maxProbeLogEntries`) to a
    // small JSON file under Application Support — same location convention
    // as `ContainmentIncidentTimeline`/`NetworkHistoryGuard`, so it's
    // readable/writable identically from the main app and the separate,
    // read-only `RoamSwitchMCPServer` process.
    //
    // Deliberately NOT wired into any reporting/API/UI yet, and deliberately
    // NOT computing any notion of staleness — storage only. Recording per
    // probe at storage time is cheap right now; promising per-probe
    // precision in a public field before a scheduled runner actually exists
    // is what creates real design debt (a consumer builds an expectation
    // around several independent timestamps, and retracting that false
    // precision later becomes a breaking change). When "how long since we
    // last actually checked" is surfaced, that field must be named
    // `passAge` (Linux mirror: `pass_age`) — reserved here so a future
    // implementation doesn't have to guess or rename later, and so it can
    // report one number even while these rows stay per-probe underneath.
    struct ProbeRunRecord: Codable {
        /// Stable machine identifier for the check, not the localized
        /// title — a `ServiceSignatures.Signature.id` (`"redis-default-noauth"`)
        /// or a Phase 3 check name (`"webvuln-cors"`, `"webvuln-traversal"`,
        /// `"webvuln-redirect"`).
        let probeName: String
        /// `nil` only for rows persisted before this field existed — every
        /// row written from here on always has one. Without it, several
        /// ports matching the same signature (e.g. two Redis instances)
        /// produced identical-looking rows in the CSV export with no way
        /// to tell them apart, which is exactly what made the exported log
        /// unreadable on first real use.
        let port: Int?
        /// ISO 8601, matching `NotificationHistory`'s timestamp convention.
        let lastStartedAt: String
        let lastFinishedAt: String
        /// `"vulnerable"` | `"safe"` | `"inconclusive"` — the same
        /// three-state distinction `ScanRunResult` already makes (see
        /// `CheckOutcome`), just named on the row instead of being implied
        /// by which list it landed in.
        let outcome: String
        /// Groups the rows written by one scan run (assigned by `appendProbeLog`);
        /// `nil` for rows saved before this existed. Lets a reader tell two runs
        /// that hit the same probe in the same minute apart.
        var scanId: String? = nil
    }

    private static let maxProbeLogEntries = 500
    private static let probeLogFormatter = ISO8601DateFormatter()

    /// Pure path computation — no side effects, matching
    /// `ContainmentIncidentTimeline.storeURL`'s convention.
    private static var probeLogURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
            .appendingPathComponent("active_vuln_scan_log.json")
    }

    /// Not private: `NativeMenuBarManager`'s CSV-export menu action reads the
    /// persisted log directly from outside this file. Was `private` while
    /// this store had no consumer at all — see this file's own doc comment
    /// above `ProbeRunRecord` ("deliberately NOT wired into any
    /// reporting/API/UI yet"), now no longer true.
    static func loadProbeLog(at url: URL = probeLogURL) -> [ProbeRunRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ProbeRunRecord].self, from: data)) ?? []
    }

    private static func saveProbeLog(_ entries: [ProbeRunRecord], to url: URL) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    /// Appends `records` (oldest-first within this run), capped at
    /// `maxProbeLogEntries` overall (oldest dropped first). Best-effort: a
    /// write failure here must never fail or slow down the scan itself,
    /// and an empty `records` list writes nothing (a run with zero
    /// applicable targets shouldn't touch the file at all).
    static func appendProbeLog(_ records: [ProbeRunRecord], to url: URL = probeLogURL) {
        guard !records.isEmpty else { return }
        // The app and roamswitch-mcp share this file across processes; hold an exclusive
        // advisory lock on a sidecar file for the whole read-modify-write, or two appends
        // racing lose or duplicate rows. Best effort: without the lock the append still runs.
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let lockFD = open(url.appendingPathExtension("lock").path, O_CREAT | O_WRONLY, 0o600)
        if lockFD >= 0 { flock(lockFD, LOCK_EX) }
        defer { if lockFD >= 0 { flock(lockFD, LOCK_UN); close(lockFD) } }
        let scanId = String(Int(Date().timeIntervalSince1970 * 1000), radix: 16) + "-" + String(ProcessInfo.processInfo.processIdentifier, radix: 16)
        var records = records
        for i in records.indices where records[i].scanId == nil { records[i].scanId = scanId }
        var entries = loadProbeLog(at: url)
        entries.append(contentsOf: records)
        if entries.count > maxProbeLogEntries {
            entries.removeFirst(entries.count - maxProbeLogEntries)
        }
        saveProbeLog(entries, to: url)
    }

    // MARK: - SLA / staleness surfacing (`passAge`)
    //
    // The reservation above is now implemented — mirrors Linux RoamSwitch's
    // `active_vuln_scan.rs::probe_status_summary` exactly (same grouping,
    // same "no scheduler, so this is bounded by however irregularly the
    // scan has actually been run" caveat).

    struct ProbeStatus: Codable, Equatable {
        let probeName: String
        let port: Int?
        let lastOutcome: String
        let lastFinishedAt: String
        /// Whole days since `lastFinishedAt`, floored (0 for anything
        /// within the last 24h). `nil` only if `lastFinishedAt` fails to
        /// parse (should not happen for a row this file wrote itself).
        let passAgeDays: Int?
    }

    /// Groups every persisted row by `(probeName, port)` and keeps the most
    /// recent (`lastFinishedAt`) row per group, with `passAgeDays` computed
    /// against `now`. Exposed as `_at` so the aging computation itself can
    /// be unit-tested without depending on the real clock or the real log
    /// file — mirrors the Linux edition's `probe_status_summary_at`.
    static func probeStatusSummary(from entries: [ProbeRunRecord], now: Date = Date()) -> [ProbeStatus] {
        var latest: [String: ProbeRunRecord] = [:]
        for r in entries {
            let key = "\(r.probeName)|\(r.port.map(String.init) ?? "-")"
            if let existing = latest[key], existing.lastFinishedAt >= r.lastFinishedAt { continue }
            latest[key] = r
        }
        var out = latest.values.map { r -> ProbeStatus in
            let passAgeDays: Int?
            if let finished = probeLogFormatter.date(from: r.lastFinishedAt) {
                let days = Calendar.current.dateComponents([.day], from: finished, to: now).day ?? 0
                passAgeDays = max(0, days)
            } else {
                passAgeDays = nil
            }
            return ProbeStatus(probeName: r.probeName, port: r.port, lastOutcome: r.outcome, lastFinishedAt: r.lastFinishedAt, passAgeDays: passAgeDays)
        }
        // Most-stale first, matching the Linux edition's sort order.
        out.sort { ($0.passAgeDays ?? 0, $0.probeName) > ($1.passAgeDays ?? 0, $1.probeName) }
        return out
    }

    /// Current status of every probe this Mac has ever recorded a result
    /// for. Safe to call from `RoamSwitchMCPServer` — reads only local
    /// disk state, no dependency on `LicenseManager`/AppKit.
    static func probeStatusSummary(at url: URL = probeLogURL) -> [ProbeStatus] {
        probeStatusSummary(from: loadProbeLog(at: url))
    }

    // MARK: - Phase 2: known-service raw-TCP probes

    /// Sends a single non-destructive `PING` to a Redis-protocol port and checks whether
    /// it answers without requiring `AUTH`. `nil` means inconclusive (connection failed,
    /// timed out, or closed) — never treated as a finding either way.
    static func probeRedisNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: Data("PING\r\n".utf8), timeout: timeout) else {
            return nil
        }
        return String(decoding: response, as: UTF8.self).hasPrefix("+PONG")
    }

    /// Sends a single non-destructive `stats` command (read-only server statistics, not a
    /// data key) to a Memcached port and checks for the standard `STAT ...` response.
    static func probeMemcachedNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: Data("stats\r\n".utf8), timeout: timeout) else {
            return nil
        }
        return String(decoding: response, as: UTF8.self).hasPrefix("STAT ")
    }

    /// Sends a single non-destructive `listDatabases` command (`OP_MSG`) and checks
    /// whether the server actually answers it, rather than rejecting it as requiring
    /// authentication.
    ///
    /// This deliberately does **not** use the `isMaster`/`hello` handshake command:
    /// MongoDB allows that one before authentication *by design* (drivers need it to
    /// negotiate wire-protocol capabilities before they can even attempt to log in) —
    /// confirmed empirically while building the Linux counterpart against a real
    /// `mongo:6` container, which answered `isMaster` successfully regardless of whether
    /// `--auth` was enabled. `listDatabases` has no such pre-auth exemption: an
    /// auth-enabled server replies with `errmsg: "command listDatabases requires
    /// authentication"`, while an open one replies with a `databases` array — verified
    /// against the same container. See `active_vuln_scan.rs::probe_mongod_noauth` for
    /// the identical Linux implementation this mirrors byte-for-byte.
    static func probeMongoDBNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: buildMongoListDatabasesOpMsg(), timeout: timeout) else {
            return nil
        }
        // The success response's BSON contains the field name "databases" (lowercase).
        // The auth-required error only ever echoes the command name "listDatabases"
        // (mixed case) inside its error message — the two never collide.
        return String(decoding: response, as: UTF8.self).contains("databases")
    }

    /// BSON `{ listDatabases: 1, $db: "admin" }` wrapped in an `OP_MSG` (opcode 2013)
    /// wire-protocol message. The query is fixed, so its bytes are constructed
    /// explicitly here rather than via a general-purpose BSON encoder.
    private static func buildMongoListDatabasesOpMsg() -> Data {
        var docBody = Data()
        docBody.append(0x10) // type: int32
        docBody.append(Data("listDatabases\0".utf8))
        docBody.append(contentsOf: withUnsafeBytes(of: Int32(1).littleEndian) { Data($0) })
        docBody.append(0x02) // type: string
        docBody.append(Data("$db\0".utf8))
        docBody.append(contentsOf: withUnsafeBytes(of: Int32(6).littleEndian) { Data($0) }) // "admin" + null
        docBody.append(Data("admin\0".utf8))

        var document = Data()
        let docLen = Int32(4 + docBody.count + 1)
        document.append(contentsOf: withUnsafeBytes(of: docLen.littleEndian) { Data($0) })
        document.append(docBody)
        document.append(0x00)

        var body = Data()
        body.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Data($0) }) // flagBits
        body.append(0x00) // section kind 0
        body.append(document)

        var message = Data()
        let messageLength = Int32(16 + body.count)
        message.append(contentsOf: withUnsafeBytes(of: messageLength.littleEndian) { Data($0) })
        message.append(contentsOf: withUnsafeBytes(of: Int32(1).littleEndian) { Data($0) }) // requestID
        message.append(contentsOf: withUnsafeBytes(of: Int32(0).littleEndian) { Data($0) }) // responseTo
        message.append(contentsOf: withUnsafeBytes(of: Int32(2013).littleEndian) { Data($0) }) // opCode: OP_MSG
        message.append(body)
        return message
    }

    /// Opens a single TCP connection to `127.0.0.1:port`, writes `payload`, reads
    /// whatever comes back within `timeout`, and closes. Returns `nil` on any
    /// connection/timeout failure — never a `Bool`, since an inconclusive probe must
    /// never be treated as evidence either way.
    private static func sendRawTCP(port: Int, payload: Data, timeout: TimeInterval) -> Data? {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let connection = NWConnection(host: "127.0.0.1", port: nwPort, using: .tcp)
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data?

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: payload, completion: .contentProcessed { _ in
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, _ in
                        result = data
                        semaphore.signal()
                    }
                })
            case .failed, .cancelled:
                semaphore.signal()
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue.global(qos: .utility))
        _ = semaphore.wait(timeout: .now() + timeout)
        connection.cancel()
        return result
    }

    // MARK: - Extended probes (HTTP / VNC / SMB)
    //
    // Mirrors the Linux client's extended probers in `active_vuln_scan.rs` (ported from
    // the standalone `vulnsweep` scanner): single connection, read-only, no credentials.

    /// One `GET {path}` and a verdict on the status line + start of the body. `nil` means
    /// inconclusive (no response at all).
    private static func probeHTTPBody(port: Int, path: String, timeout: TimeInterval,
                                      verdict: (Int, String) -> Bool) -> Bool? {
        let request = "GET \(path) HTTP/1.1\r\nHost: 127.0.0.1:\(port)\r\nAccept: application/json\r\nConnection: close\r\n\r\n"
        guard let response = sendRawTCP(port: port, payload: Data(request.utf8), timeout: timeout), !response.isEmpty else {
            return nil
        }
        let text = String(decoding: response, as: UTF8.self)
        guard let statusLine = text.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: false).first,
              let code = statusLine.split(separator: " ").dropFirst().first.flatMap({ Int($0) }) else {
            return false
        }
        let body = text.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
        return verdict(code, body)
    }

    static func probeElasticsearchNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/", timeout: timeout) { $0 == 200 && $1.contains("\"cluster_name\"") }
    }

    static func probeCouchDBNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/_all_dbs", timeout: timeout) {
            $0 == 200 && $1.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[")
        }
    }

    static func probeJenkinsNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/api/json", timeout: timeout) { $0 == 200 && $1.contains("\"_class\"") }
    }

    /// RFB handshake up to the security-type list only; never selects a type, so no
    /// session is established. `true` when security type 1 ("None") is offered.
    static func probeVNCNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let connection = NWConnection(host: "127.0.0.1", port: nwPort, using: .tcp)
        let queue = DispatchQueue.global(qos: .utility)
        let done = DispatchSemaphore(value: 0)
        var result: Bool?

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.receive(minimumIncompleteLength: 12, maximumLength: 12) { data, _, _, _ in
                    guard let ver = data, ver.count == 12, ver.prefix(4) == Data("RFB ".utf8) else {
                        result = data == nil ? nil : false
                        done.signal()
                        return
                    }
                    let minor = Int(String(decoding: ver[8..<11], as: UTF8.self)) ?? 0
                    let reply = minor < 7 ? "RFB 003.003\n" : "RFB 003.008\n"
                    connection.send(content: Data(reply.utf8), completion: .contentProcessed { _ in
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 300) { types, _, _, _ in
                            defer { done.signal() }
                            guard let types = types, !types.isEmpty else { return }
                            if minor < 7 {
                                result = types.count >= 4 && types.prefix(4) == Data([0, 0, 0, 1])
                            } else {
                                let count = Int(types[0])
                                result = count > 0 && types.dropFirst().prefix(count).contains(1)
                            }
                        }
                    })
                }
            case .failed, .cancelled:
                done.signal()
            default:
                break
            }
        }
        connection.start(queue: queue)
        _ = done.wait(timeout: .now() + timeout)
        connection.cancel()
        return result
    }

    enum SMBNegotiate { case smb1, smb2SigningRequired, smb2SigningNotRequired, notSMB }

    /// One SMB protocol-negotiate exchange offering SMB1 and SMB2 dialects. Never
    /// authenticates and never opens a share.
    static func probeSMBNegotiate(port: Int, timeout: TimeInterval = 2.0) -> SMBNegotiate? {
        let dialects = ["PC NETWORK PROGRAM 1.0", "LANMAN1.0", "Windows for Workgroups 3.1a", "LM1.2X002", "LANMAN2.1", "NT LM 0.12", "SMB 2.002", "SMB 2.???"]
        var dialectBytes = Data()
        for d in dialects {
            dialectBytes.append(0x02)
            dialectBytes.append(Data(d.utf8))
            dialectBytes.append(0x00)
        }
        var smb = Data([0xFF, 0x53, 0x4D, 0x42, 0x72, 0, 0, 0, 0, 0x18, 0x00, 0x00, 0, 0])
        smb.append(Data(count: 8))
        smb.append(Data([0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0x00]))
        smb.append(contentsOf: withUnsafeBytes(of: UInt16(dialectBytes.count).littleEndian) { Data($0) })
        smb.append(dialectBytes)
        var packet = Data([0x00, UInt8((smb.count >> 16) & 0xFF), UInt8((smb.count >> 8) & 0xFF), UInt8(smb.count & 0xFF)])
        packet.append(smb)

        guard let response = sendRawTCP(port: port, payload: packet, timeout: timeout), response.count >= 8 else {
            return nil
        }
        let body = response.dropFirst(4)
        let magic = Array(body.prefix(4))
        if magic == [0xFF, 0x53, 0x4D, 0x42] { return .smb1 }
        if magic == [0xFE, 0x53, 0x4D, 0x42], body.count >= 70 {
            let bytes = Array(body)
            let mode = UInt16(bytes[66]) | (UInt16(bytes[67]) << 8)
            return mode & 0x02 != 0 ? .smb2SigningRequired : .smb2SigningNotRequired
        }
        return .notSMB
    }

    // MARK: - Known-CVE version matching

    /// One version range known to be affected by a specific CVE. Matching is by
    /// semver-range only — never sends an actual exploit or DoS payload, only a
    /// harmless version-reporting command. `title`/`description`/`recommendation`
    /// are full per-language dictionaries (keyed by the same 10 language codes as
    /// `Localizable.xcstrings`'s `pt-PT`-style codes) rather than a single Japanese
    /// string routed through `loc(_:)` — this map can add genuinely new CVEs via the
    /// daily updater alone, without waiting for an app release to ship new
    /// translated strings, so the translations must travel with the data itself.
    /// Mirrors `roamswitch-core`'s `ActiveVulnCveEntry`/`ActiveVulnCveMap` exactly.
    struct KnownCVE: Decodable {
        let cveId: String
        let signatureID: String
        let minVersion: [Int]
        let fixedVersion: [Int]
        let title: [String: String]
        let description: [String: String]
        let recommendation: [String: String]

        enum CodingKeys: String, CodingKey {
            case cveId, signatureID = "signatureId", minVersion, fixedVersion
            case title, description, recommendation
        }
    }

    struct CVEMap: Decodable {
        let mapVersion: String
        let entries: [KnownCVE]
    }

    private static func versionLess(_ a: [Int], _ b: [Int]) -> Bool {
        for i in 0..<3 {
            if a[i] != b[i] { return a[i] < b[i] }
        }
        return false
    }

    private static func versionGreaterOrEqual(_ a: [Int], _ b: [Int]) -> Bool {
        !versionLess(a, b)
    }

    /// Where `ActiveVulnCveMapUpdater` installs a fresher signed copy (desktop client
    /// only). Preferred over the bundled baseline when present and its `mapVersion` is
    /// newer — mirrors `roamswitch-core::active_vuln_scan::load_cve_map` exactly.
    static let updatedCVEMapURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("active_vuln_cve_map.json")
    }()

    private static func loadCVEMap() -> CVEMap {
        let decoder = JSONDecoder()
        // Compiled in via `ActiveVulnCveMapData.swift` rather than loaded as a bundle
        // resource: `RoamSwitchMCPServer` is a bare `tool` target with no `.app`
        // bundle (`Bundle.main.url(forResource:)` always returns nil there), so a real
        // resource file would silently leave the MCP server with zero baseline data.
        // A compiled-in string works identically in both the app and the tool target.
        let bundled: CVEMap = (try? decoder.decode(CVEMap.self, from: Data(ActiveVulnCveMapData.embeddedJSON.utf8)))
            ?? CVEMap(mapVersion: "", entries: [])
        if let data = try? Data(contentsOf: updatedCVEMapURL),
           let updated = try? decoder.decode(CVEMap.self, from: data),
           updated.mapVersion >= bundled.mapVersion {
            return updated
        }
        return bundled
    }

    /// Resolves one entry's text for the active app language, falling back to English
    /// then Japanese then whatever the map happens to have, so a partially-translated
    /// feed update (e.g. a brand-new CVE added upstream before every language catches
    /// up) never surfaces an empty string. Mirrors the Linux implementation's
    /// `resolve_lang`.
    private static func resolveLang(_ dict: [String: String]) -> String {
        let lang = AppLanguage.activeLocaleCode
        return dict[lang] ?? dict["en"] ?? dict["ja"] ?? dict.values.first ?? ""
    }

    /// Parses a `"6.0.19"`-style version string into `[major, minor, patch]`, tolerating
    /// a trailing non-numeric suffix on the patch component (e.g. `"6.2.13-beta1"`).
    private static func parseSemver(_ s: String) -> [Int]? {
        let parts = s.trimmingCharacters(in: .whitespaces).split(separator: ".")
        guard !parts.isEmpty, let major = Int(parts[0]) else { return nil }
        let minor = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        let patchDigits = parts.count > 2 ? parts[2].prefix(while: { $0.isNumber }) : ""
        let patch = patchDigits.isEmpty ? 0 : (Int(patchDigits) ?? 0)
        return [major, minor, patch]
    }

    /// Returns every map entry the version matches, not just the first — several of
    /// these CVEs have genuinely overlapping affected ranges (distinct bugs that happen
    /// to affect the same versions), so a single instance can legitimately be vulnerable
    /// to more than one at once. Mirrors the Linux implementation's `find_known_cves`.
    private static func findKnownCVEs(signatureID: String, version: [Int]) -> [KnownCVE] {
        loadCVEMap().entries.filter {
            $0.signatureID == signatureID
                && versionGreaterOrEqual(version, $0.minVersion)
                && versionLess(version, $0.fixedVersion)
        }
    }

    /// Sends a single non-destructive `INFO server` command and extracts
    /// `redis_version:X.Y.Z` from the plain-text response.
    static func probeRedisVersion(port: Int, timeout: TimeInterval = 2.0) -> String? {
        guard let response = sendRawTCP(port: port, payload: Data("INFO server\r\n".utf8), timeout: timeout) else {
            return nil
        }
        let text = String(decoding: response, as: UTF8.self)
        for line in text.split(separator: "\r\n") where line.hasPrefix("redis_version:") {
            return String(line.dropFirst("redis_version:".count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    /// Reuses the same `stats` response `probeMemcachedNoAuth` already sends and extracts
    /// the `STAT version X.Y.Z` line from it.
    static func probeMemcachedVersion(port: Int, timeout: TimeInterval = 2.0) -> String? {
        guard let response = sendRawTCP(port: port, payload: Data("stats\r\n".utf8), timeout: timeout) else {
            return nil
        }
        let text = String(decoding: response, as: UTF8.self)
        for line in text.split(separator: "\r\n") where line.hasPrefix("STAT version ") {
            return String(line.dropFirst("STAT version ".count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func probeVersion(signatureID: String, port: Int, timeout: TimeInterval) -> String? {
        switch signatureID {
        case "redis-default-noauth": return probeRedisVersion(port: port, timeout: timeout)
        case "memcached-noauth": return probeMemcachedVersion(port: port, timeout: timeout)
        default: return nil
        }
    }

    // MARK: - Phase 3: generic dev-server HTTP checks (endpoint-agnostic)

    private static let corsTestOrigin = "http://roamswitch-cors-probe.invalid"

    /// Sends one GET to `/` with an arbitrary, never-allow-listed `Origin` header and
    /// checks whether the response reflects it (or sends a wildcard) *together with*
    /// `Access-Control-Allow-Credentials: true` — the actually exploitable combination.
    /// A bare wildcard without credentials is deliberately not flagged, to keep the
    /// false-positive rate low (many public/no-auth dev APIs use `*` safely).
    static func probeCorsMisconfiguration(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue(corsTestOrigin, forHTTPHeaderField: "Origin")

        guard let response = syncHTTPRequest(request, timeout: timeout) as? HTTPURLResponse else { return nil }
        let acao = response.value(forHTTPHeaderField: "Access-Control-Allow-Origin") ?? ""
        let acac = response.value(forHTTPHeaderField: "Access-Control-Allow-Credentials") ?? ""

        let reflectsOrWildcard = acao == "*" || acao == corsTestOrigin
        let credentialsAllowed = acac.caseInsensitiveCompare("true") == .orderedSame
        return reflectsOrWildcard && credentialsAllowed
    }

    /// A handful of common path-traversal encodings against the root path, targeting
    /// `/etc/passwd` — world-readable on macOS, so this stays a pure reachability proof
    /// and never needs to touch anything sensitive.
    private static let traversalPayloads = [
        "/../../../../../../../../etc/passwd",
        "/..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc%2fpasswd",
        "/static/../../../../../../etc/passwd",
    ]

    /// macOS's `/etc/passwd` uses `root:*:0:0:` (an asterisk in the password field —
    /// this file is a legacy stub next to Open Directory, not shadow-password-backed).
    /// This is deliberately **not** the same marker as the Linux implementation's
    /// `root:x:0:0:` — each targets the real format of the OS it actually runs on.
    private static let passwdMarker = "root:*:0:0:"

    /// Tries each payload in turn and stops at the first one that gets a reachable
    /// response containing the passwd marker.
    static func probePathTraversal(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        var sawAnyResponse = false
        for payload in traversalPayloads {
            guard let url = URL(string: "http://127.0.0.1:\(port)\(payload)") else { continue }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            guard let data = syncHTTPBody(request, timeout: timeout) else { continue }
            sawAnyResponse = true
            if String(decoding: data, as: UTF8.self).contains(passwdMarker) {
                return true
            }
        }
        return sawAnyResponse ? false : nil
    }

    /// Ephemeral-session, no-cache GET matching `PortSecurityAuditor.probeHTTPService`'s
    /// isolation settings — this is a security-audit probe, not a normal browse request.
    private static func syncHTTPRequest(_ request: URLRequest, timeout: TimeInterval) -> URLResponse? {
        var result: URLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { _, response, _ in
            result = response
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    private static func syncHTTPBody(_ request: URLRequest, timeout: TimeInterval) -> Data? {
        var result: Data?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { data, response, _ in
            if response is HTTPURLResponse {
                result = data ?? Data()
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    /// `URLSession` follows redirects transparently by default, which would hide the
    /// very `3xx` + `Location` response this probe needs to see. This delegate refuses
    /// every redirect (`completionHandler(nil)`) so the initial response is what
    /// `syncHTTPRequestNoRedirect` receives instead.
    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
    }

    private static func syncHTTPRequestNoRedirect(_ request: URLRequest, timeout: TimeInterval) -> HTTPURLResponse? {
        var result: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let delegate = NoRedirectDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { _, response, _ in
            result = response as? HTTPURLResponse
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    // MARK: - Open redirect

    private static let redirectTestTarget = "roamswitch-redirect-probe.invalid"
    private static let redirectTestTargetURL = "http://roamswitch-redirect-probe.invalid/"

    /// Common redirect-parameter names, tried one at a time against the root path.
    /// Unlike CORS/traversal, this doesn't need every dev server to use one of these —
    /// a server using a different parameter name is simply not flagged (biasing this
    /// check toward false negatives, never false positives).
    private static let redirectParamNames = ["redirect", "url", "next", "return_to", "returnUrl", "redirect_uri", "continue", "dest"]

    /// Tries each candidate parameter name in turn and stops at the first one that gets
    /// a `3xx` response whose `Location` header points at our (unregistered,
    /// unreachable) test domain — proof the server redirects to an attacker-controlled
    /// URL without validating it, rather than just accepting the parameter unused.
    static func probeOpenRedirect(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        var sawAnyResponse = false
        for param in redirectParamNames {
            var components = URLComponents(string: "http://127.0.0.1:\(port)/")!
            components.queryItems = [URLQueryItem(name: param, value: redirectTestTargetURL)]
            guard let url = components.url else { continue }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            guard let response = syncHTTPRequestNoRedirect(request, timeout: timeout) else { continue }
            sawAnyResponse = true
            let location = response.value(forHTTPHeaderField: "Location") ?? ""
            if (300...399).contains(response.statusCode), location.contains(redirectTestTarget) {
                return true
            }
        }
        return sawAnyResponse ? false : nil
    }

    // MARK: - Orchestration

    /// Which `ServiceSignatures` ids Phase 2 has an actual probe implemented for.
    /// Signatures without a matching prober here are Phase-1-only (flagged passively).
    private static let probeableSignatureIDs: Set<String> = [
        "redis-default-noauth", "memcached-noauth", "mongod-default-noauth",
        "elasticsearch-noauth", "couchdb-noauth", "jenkins-noauth", "vnc-noauth",
        "smb1-enabled", "smb-signing-not-required",
    ]

    /// Whether `runScan` would attempt anything at all for this port — i.e. it either
    /// matches a Phase 2 probeable signature or is a Phase 3 dev-server candidate. Lets
    /// UI code decide whether to offer the "Run Active Verification" action at all,
    /// without duplicating the matching logic.
    static func hasApplicableTargets(for port: ListeningPortInfo) -> Bool {
        let hasSignatureProbe = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            .contains { probeableSignatureIDs.contains($0.id) }
        return hasSignatureProbe || PortSecurityAuditor.isKnownDevServerPort(port.port)
    }

    /// Runs Phase 2 (known-service reachability) and Phase 3 (generic CORS/traversal
    /// checks, only for ports flagged as dev servers) against the given ports.
    /// Sequential — no concurrency, matching the Linux implementation's safety
    /// invariants. Confirmed-safe and inconclusive checks are tracked
    /// separately from findings — see `CheckOutcome`.
    /// `includeNmapNSE` exists only so unit tests can exercise Phases 2/3 deterministically:
    /// with it on, any machine that happens to have `nmap` installed appends several
    /// "nmap NSE所見" findings for the test's stub-server port (and adds ~15s per scan),
    /// making count-based assertions depend on the developer's environment. Production
    /// callers always take the default (on).
    static func runScan(ports: [ListeningPortInfo], probeLogURL: URL = probeLogURL, includeNmapNSE: Bool = true) -> ScanRunResult {
        var result = ScanRunResult()
        var logEntries: [ProbeRunRecord] = []

        for port in ports {
            let signatures = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            for signature in signatures where probeableSignatureIDs.contains(signature.id) {
                let startedAt = Date()
                let confirmed: Bool?
                switch signature.id {
                case "redis-default-noauth": confirmed = probeRedisNoAuth(port: port.port)
                case "memcached-noauth": confirmed = probeMemcachedNoAuth(port: port.port)
                case "mongod-default-noauth": confirmed = probeMongoDBNoAuth(port: port.port)
                case "elasticsearch-noauth": confirmed = probeElasticsearchNoAuth(port: port.port)
                case "couchdb-noauth": confirmed = probeCouchDBNoAuth(port: port.port)
                case "jenkins-noauth": confirmed = probeJenkinsNoAuth(port: port.port)
                case "vnc-noauth": confirmed = probeVNCNoAuth(port: port.port)
                case "smb1-enabled": confirmed = probeSMBNegotiate(port: port.port).map { $0 == .smb1 }
                case "smb-signing-not-required": confirmed = probeSMBNegotiate(port: port.port).map { $0 == .smb2SigningNotRequired }
                default: confirmed = nil
                }
                let finishedAt = Date()
                logEntries.append(ProbeRunRecord(
                    probeName: signature.id,
                    port: port.port,
                    lastStartedAt: probeLogFormatter.string(from: startedAt),
                    lastFinishedAt: probeLogFormatter.string(from: finishedAt),
                    outcome: confirmed == true ? "vulnerable" : (confirmed == false ? "safe" : "inconclusive")
                ))
                let outcome = CheckOutcome(port: port.port, processName: port.processName, check: signature.title)
                switch confirmed {
                case true:
                    result.findings.append(Finding(
                        port: port.port,
                        processName: port.processName,
                        title: signature.title,
                        description: signature.description,
                        recommendation: signature.recommendation
                    ))
                    // Known-CVE version matching piggybacks on the same confirmed-reachable
                    // target — a bonus lookup on an already-reported finding, not a separate
                    // pass/fail check of its own, so its own outcome isn't tracked here.
                    if let versionString = probeVersion(signatureID: signature.id, port: port.port, timeout: 2.0),
                       let version = parseSemver(versionString) {
                        for cve in findKnownCVEs(signatureID: signature.id, version: version) {
                            result.findings.append(Finding(
                                port: port.port,
                                processName: port.processName,
                                title: resolveLang(cve.title),
                                description: resolveLang(cve.description),
                                recommendation: resolveLang(cve.recommendation)
                            ))
                        }
                    }
                case false:
                    result.confirmedSafe.append(outcome)
                case nil:
                    result.inconclusive.append(outcome)
                }
            }
        }

        // Runs one Phase 3 probe, records its timing/outcome for the
        // heartbeat log, and routes the result the same way the Phase 2
        // loop above does.
        func runOne(
            probeName: String,
            probe: () -> Bool?,
            makeFinding: () -> Finding,
            outcome: CheckOutcome
        ) {
            let startedAt = Date()
            let confirmed = probe()
            let finishedAt = Date()
            logEntries.append(ProbeRunRecord(
                probeName: probeName,
                port: outcome.port,
                lastStartedAt: probeLogFormatter.string(from: startedAt),
                lastFinishedAt: probeLogFormatter.string(from: finishedAt),
                outcome: confirmed == true ? "vulnerable" : (confirmed == false ? "safe" : "inconclusive")
            ))
            switch confirmed {
            case true: result.findings.append(makeFinding())
            case false: result.confirmedSafe.append(outcome)
            case nil: result.inconclusive.append(outcome)
            }
        }

        for port in ports where PortSecurityAuditor.isKnownDevServerPort(port.port) {
            runOne(
                probeName: "webvuln-cors",
                probe: { probeCorsMisconfiguration(port: port.port) },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("CORS 設定ミス（認証情報付きクロスオリジン許可）"),
                        description: loc("任意のOriginヘッダを送信したところ、そのOriginがAccess-Control-Allow-Originに反映（または*が返却）され、かつAccess-Control-Allow-Credentials: trueが同時に返されました。この組み合わせは、悪意あるWebサイトが被害者のブラウザ経由でこのサーバーへ認証済みリクエストを送信し、レスポンスを読み取れることを意味します。"),
                        recommendation: loc("Access-Control-Allow-Origin を信頼できる特定のオリジンのみに限定し、Access-Control-Allow-Credentials は本当に必要な場合のみ有効にしてください。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("CORS 設定ミス（認証情報付きクロスオリジン許可）"))
            )

            runOne(
                probeName: "webvuln-traversal",
                probe: { probePathTraversal(port: port.port) },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("パストラバーサル（ディレクトリトラバーサル）"),
                        description: loc("静的ファイル配信のパスに ../ を含むリクエストを送信したところ、Webルート外の /etc/passwd の内容が取得できました。ファイルパスの正規化・検証が不十分なため、Webルート外の任意のファイルを読み取られる危険があります。"),
                        recommendation: loc("静的ファイル配信ライブラリを最新版に更新し、配信元パスを正規化したうえでWebルート内に限定してください。可能であればサンドボックスでファイルシステムへのアクセス範囲自体を制限することも推奨します。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("パストラバーサル（ディレクトリトラバーサル）"))
            )

            runOne(
                probeName: "webvuln-redirect",
                probe: { probeOpenRedirect(port: port.port) },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("オープンリダイレクト（未検証の外部リダイレクト）"),
                        description: loc("既知のリダイレクトパラメータ（redirect/url/next 等）に外部ドメインを指定したところ、検証なしにそのドメインへリダイレクトされました。フィッシング詐欺で正規サイトのURLを装いつつ悪意あるサイトへ誘導する手口に悪用される危険があります。"),
                        recommendation: loc("リダイレクト先URLを許可リスト（同一オリジンまたは信頼済みドメインのみ）で検証してください。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("オープンリダイレクト（未検証の外部リダイレクト）"))
            )
        }

        // Phase 4: nmap NSE supplementary layer — always runs alongside this
        // function's own `isEnabled` gate, no separate opt-in of its own.
        // Targets *every* port passed in, not just the ones a Phase 2/3
        // signature matched: NSE's whole value is covering services this
        // product's hand-rolled probes above don't — nmap picks which of
        // its scripts apply per port from its own service detection (see
        // `NmapNSE`'s doc comment). A no-op (empty result, never an error)
        // if `nmap` isn't installed. Single shared call site — both the
        // manual "Run Active Verification" button and `MCPServer`'s
        // `run_active_vuln_scan` tool call through `runScan`, so neither
        // needs its own wiring.
        if includeNmapNSE {
            let allPorts = ports.map(\.port)
            // A fixed 120s budget silently loses *every* finding, not just
            // the unfinished tail, on an ordinary dev Mac: nmap's normal-
            // format stdout is fully buffered until the whole invocation
            // finishes (confirmed empirically — `Process.terminate()` at
            // the deadline left only ~70 bytes captured, nowhere near a
            // parseable per-port result, even though the same single port
            // alone reliably produces real findings well within 120s).
            // 13 real listening ports on this machine (nothing exotic, just
            // the background services any active dev Mac accumulates) blew
            // straight through a fixed 120s and returned zero findings with
            // no indication anything was cut short — the exact "looks like
            // 'checked, nothing found' but was actually 'never finished
            // checking'" failure mode this product's own probes elsewhere
            // (see `runScan`'s `inconclusive` tracking, prompted by
            // https://dev.to/raknaos/my-wait-for-it-wrapper-reported-success-for-a-port-that-never-opened-ga3)
            // exist specifically to avoid. Scaling with port count keeps a
            // single/few-port run fast while giving a many-port run enough
            // wall-clock time to actually finish; capped so a pathological
            // port list still can't block the audit indefinitely.
            let nseTimeout = min(300, 30 + 15 * Double(allPorts.count))
            let nseFindings = NmapNSE.runNSESafeScripts(host: "127.0.0.1", ports: allPorts, timeoutSeconds: nseTimeout)
            for finding in nseFindings {
                let processName = ports.first { $0.port == finding.port }?.processName ?? ""
                result.findings.append(Finding(
                    port: finding.port,
                    processName: processName,
                    title: "\(loc("nmap NSE所見")): \(finding.script)",
                    description: finding.output,
                    recommendation: loc("これはnmap自身の検知結果です（RoamSwitch独自の検証は行っていません）。内容を確認し、該当する場合は対応してください。")
                ))
            }
        }

        appendProbeLog(logEntries, to: probeLogURL)
        return result
    }
}
