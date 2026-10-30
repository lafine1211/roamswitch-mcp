// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.15 (build 194).
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
public enum ActiveVulnScan {

    static let enabledDefaultsKey = "RoamSwitch.ActiveVulnScanEnabled"

    /// The app's own preferences domain, which the MCP server reads by suite name too.
    static var isEnabled: Bool {
        AppLanguage.sharedDefaults.bool(forKey: enabledDefaultsKey)
    }

    struct Finding {
        let port: Int
        let processName: String
        let title: String
        let description: String
        let recommendation: String
        /// The probe (a `ProbeCatalog` id) that produced this finding, and how strong the evidence is.
        /// A known-CVE finding added after a confirmed one is `versionRangeMatch`; nmap's is `externalToolReport`.
        var probeName: String? = nil
        var evidenceKind: EvidenceKind = .confirmed
        /// ISO 8601 time the same probe on the same port last reached a verdict earlier and that verdict was
        /// `safe`. Set only when the latest earlier verdict is `safe`; a probe that was never run, or whose
        /// earlier runs were all inconclusive, leaves it `nil`. It says what the log holds, not that a fix was undone:
        /// the listener may be a different program, or the probe may have changed since.
        var previouslySafeAt: String? = nil
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
        /// Ids of the probes this run actually executed (`ProbeCatalog` keys), each once, in the order first run.
        var probesRun: [String] = []
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

    /// The newest row before this run for `probeName` on `port` that reached a verdict (`safe` or `vulnerable`).
    /// `inconclusive` rows are skipped: a run that could not connect says nothing about the state.
    static func previousVerdict(probeName: String, port: Int, in entries: [ProbeRunRecord]) -> ProbeRunRecord? {
        entries
            .filter { $0.probeName == probeName && $0.port == port && $0.outcome != "inconclusive" }
            .max { $0.lastFinishedAt < $1.lastFinishedAt }
    }

    /// Marks each finding whose probe and port were last judged `safe` before this run.
    static func markingPreviouslySafe(_ findings: [Finding], history: [ProbeRunRecord]) -> [Finding] {
        findings.map { finding in
            guard let name = finding.probeName,
                  let previous = previousVerdict(probeName: name, port: finding.port, in: history),
                  previous.outcome == "safe" else { return finding }
            var marked = finding
            marked.previouslySafeAt = previous.lastFinishedAt
            return marked
        }
    }

    // MARK: - SLA / staleness surfacing (`passAge`)
    //
    // The reservation above is now implemented — mirrors Linux RoamSwitch's
    // `active_vuln_scan.rs::probe_status_summary` exactly (same grouping,
    // same "no scheduler, so this is bounded by however irregularly the
    // scan has actually been run" caveat).

    public struct ProbeStatus: Codable, Equatable {
        public let probeName: String
        public let port: Int?
        public let lastOutcome: String
        public let lastFinishedAt: String
        /// Whole days since `lastFinishedAt`, floored (0 for anything
        /// within the last 24h). `nil` only if `lastFinishedAt` fails to
        /// parse (should not happen for a row this file wrote itself).
        public let passAgeDays: Int?
        /// From `ProbeCatalog`: the side effects this probe declares and what a positive result means
        /// (`ProbeSideEffect` / `EvidenceKind` raw values). `nil` for a probe name this version does not know.
        public var sideEffects: [String]? = nil
        public var evidenceKind: String? = nil
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
            let declared = ProbeCatalog.declaration(forProbeName: r.probeName)
            return ProbeStatus(probeName: r.probeName, port: r.port, lastOutcome: r.outcome, lastFinishedAt: r.lastFinishedAt, passAgeDays: passAgeDays,
                               sideEffects: declared?.sideEffects.map(\.rawValue), evidenceKind: declared?.evidenceKind.rawValue)
        }
        // Most-stale first, matching the Linux edition's sort order. Sorting on `passAgeDays` alone
        // (floored to whole days) ties every probe checked the same calendar day, and `latest` is a
        // Dictionary, whose iteration order is unspecified — those ties fell back to that unspecified
        // order, a different, meaningless order on every run rather than anything a viewer could make
        // sense of. Comparing the actual timestamp first fixes that: same-day entries still land
        // oldest-first, and probeName/port only matter for the now-vanishingly rare case of two rows
        // with the identical instant. Mirrors the same fix in the Linux edition's
        // `probe_status_summary_at`.
        out.sort { a, b in
            switch (probeLogFormatter.date(from: a.lastFinishedAt), probeLogFormatter.date(from: b.lastFinishedAt)) {
            case let (.some(ta), .some(tb)) where ta != tb:
                return ta < tb
            case (.none, .some):
                // Unparsable (shouldn't happen — this file wrote it) sorts as if it just finished,
                // same as `passAgeDays`' `?? 0` treated it before.
                return false
            case (.some, .none):
                return true
            default:
                break
            }
            if a.probeName != b.probeName { return a.probeName < b.probeName }
            return (a.port ?? Int.min) < (b.port ?? Int.min)
        }
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
        guard let response = httpGet(port: port, path: path, timeout: timeout) else { return nil }
        guard let status = response.status else { return false }
        return verdict(status, response.body)
    }

    /// The single read-only request shared by every HTTP probe and version lookup: one `GET`,
    /// one connection, at most 16 KiB of the answer. Reads until the answer is complete (its
    /// `Content-Length` is reached or the chunked body ends) or the peer closes, so a body that
    /// arrives in a second TCP segment is not lost. A chunked body is decoded, so a version
    /// number is never cut up by chunk framing. `nil` = no response at all; `status == nil` =
    /// the peer answered something that is not HTTP.
    static func httpGet(port: Int, path: String, timeout: TimeInterval) -> (status: Int?, body: String)? {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let request = "GET \(path) HTTP/1.1\r\nHost: 127.0.0.1:\(port)\r\nAccept: application/json\r\nConnection: close\r\n\r\n"
        let connection = NWConnection(host: "127.0.0.1", port: nwPort, using: .tcp)
        let semaphore = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var received = Data()
        var finished = false

        func finish() {
            lock.lock(); defer { lock.unlock() }
            if !finished { finished = true; semaphore.signal() }
        }
        func receiveMore() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
                lock.lock()
                if let data = data { received.append(data) }
                let snapshot = received
                lock.unlock()
                if error != nil || isComplete || snapshot.count >= 16 * 1024 || httpResponseIsComplete(snapshot) {
                    finish()
                } else {
                    receiveMore()
                }
            }
        }
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: Data(request.utf8), completion: .contentProcessed { _ in receiveMore() })
            case .failed, .cancelled:
                finish()
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue.global(qos: .utility))
        _ = semaphore.wait(timeout: .now() + timeout)
        connection.cancel()

        lock.lock(); let raw = received; lock.unlock()
        guard !raw.isEmpty else { return nil }
        return parseHTTPResponse(raw)
    }

    /// Splits a raw HTTP/1.1 response into its status code and (decoded) body.
    static func parseHTTPResponse(_ raw: Data) -> (status: Int?, body: String) {
        let text = String(decoding: raw, as: UTF8.self)
        guard let statusLine = text.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: false).first,
              let code = statusLine.split(separator: " ").dropFirst().first.flatMap({ Int($0) }) else {
            return (nil, "")
        }
        let parts = text.components(separatedBy: "\r\n\r\n")
        let head = parts.first ?? ""
        let body = parts.dropFirst().joined(separator: "\r\n\r\n")
        let chunked = head.split(separator: "\r\n").contains {
            let line = $0.lowercased()
            return line.hasPrefix("transfer-encoding:") && line.contains("chunked")
        }
        return (code, chunked ? dechunk(body) : body)
    }

    /// Decodes an HTTP/1.1 chunked body. A truncated tail (the 16 KiB read limit) just ends the text.
    /// Works on bytes: chunk sizes are byte counts, and Swift treats "\r\n" as a single Character.
    static func dechunk(_ body: String) -> String {
        let bytes = Array(body.utf8)
        var out: [UInt8] = []
        var i = 0
        while i < bytes.count {
            guard let lineEnd = (i..<max(i, bytes.count - 1)).first(where: { bytes[$0] == 13 && bytes[$0 + 1] == 10 }) else { break }
            let sizeText = String(decoding: bytes[i..<lineEnd], as: UTF8.self).split(separator: ";").first.map(String.init) ?? ""
            guard let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16), size > 0 else { break }
            let start = lineEnd + 2
            let end = min(start + size, bytes.count)
            out.append(contentsOf: bytes[start..<end])
            i = end
            if i + 1 < bytes.count, bytes[i] == 13, bytes[i + 1] == 10 { i += 2 }
        }
        return String(decoding: out, as: UTF8.self)
    }

    /// True once the headers are in and the body is complete: its `Content-Length` is reached, or
    /// the chunked body has its terminating zero-length chunk. Without either, only the peer's
    /// close (or the timeout) ends the read.
    private static func httpResponseIsComplete(_ data: Data) -> Bool {
        let text = String(decoding: data, as: UTF8.self)
        guard let split = text.range(of: "\r\n\r\n") else { return false }
        let head = text[text.startIndex..<split.lowerBound].lowercased()
        let body = text[split.upperBound...]
        for line in head.split(separator: "\r\n") {
            if line.hasPrefix("content-length:"),
               let n = Int(line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) {
                return body.utf8.count >= n
            }
            if line.hasPrefix("transfer-encoding:") && line.contains("chunked") {
                return body.hasSuffix("0\r\n\r\n")
            }
        }
        return false
    }

    /// HexStrike AI's API server has no authentication, so a positive answer means every
    /// client that can reach this port can run commands. The probe asks for
    /// `/api/processes/list`, which returns `{"active_processes":{},"success":true,"total_count":0}`
    /// instantly and has no side effect. NOT `/health`, the obvious fingerprint: measured
    /// against the real server it takes ~3.5 s (over this probe's timeout) and it runs ~127
    /// `which` commands, which would trip RoamSwitch's own `exec.offensive_tool_inventory` rule.
    static func probeHexStrikeNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/api/processes/list", timeout: timeout) {
            $0 == 200 && $1.contains("\"active_processes\"") && $1.contains("\"total_count\"")
        }
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

    // Local AI / ML services. Each is one read-only GET whose answer proves both identity and
    // "no login in front of it"; the response shapes were measured on real servers (Ollama 0.40.4,
    // Jupyter Server 2.21.1, MLflow 3.17.1, Gradio 6.30.0). A login-protected instance answers
    // differently (Jupyter with a token: 403 on /api/status; Gradio with auth: 401 on /config),
    // which is what makes each probe return `false` there. Mirrors `active_vuln_scan.rs`.

    static func probeOllamaExposed(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/", timeout: timeout) {
            $0 == 200 && $1.trimmingCharacters(in: .whitespacesAndNewlines) == "Ollama is running"
        }
    }

    static func probeJupyterNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/api/status", timeout: timeout) {
            $0 == 200 && $1.contains("\"kernels\"") && $1.contains("\"connections\"")
        }
    }

    static func probeMLflowNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/api/2.0/mlflow/experiments/search?max_results=1", timeout: timeout) {
            $0 == 200 && $1.contains("\"experiments\"")
        }
    }

    static func probeGradioNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        probeHTTPBody(port: port, path: "/config", timeout: timeout) { $0 == 200 && isGradioConfig($1) }
    }

    /// `GET /config` of a Gradio app starts `{"version":"6.30.0","api_prefix":...` and carries the
    /// `components` list (measured against Gradio 6.30.0; the FastAPI JSON writer used by every
    /// Gradio 3-6 puts `version` first).
    static func isGradioConfig(_ body: String) -> Bool {
        let head = body.drop(while: { $0.isWhitespace }).prefix(16)
        return jsonStringField(body, key: "version") != nil
            && head.contains("\"version\"")
            && body.contains("\"components\"")
    }

    /// The string value of a `"key": "value"` pair, found by text search so a body that was cut at the
    /// 16 KiB read limit still yields its leading fields. `nil` when absent or implausible.
    static func jsonStringField(_ body: String, key: String) -> String? {
        guard let keyRange = body.range(of: "\"\(key)\"") else { return nil }
        var rest = body[keyRange.upperBound...].drop(while: { $0.isWhitespace })
        guard rest.first == ":" else { return nil }
        rest = rest.dropFirst().drop(while: { $0.isWhitespace })
        guard rest.first == "\"" else { return nil }
        rest = rest.dropFirst()
        guard let end = rest.firstIndex(of: "\"") else { return nil }
        let value = String(rest[rest.startIndex..<end])
        return value.isEmpty || value.count > 40 ? nil : value
    }

    /// Where each local AI / ML service reports its own version, and how to read it. Ollama
    /// `GET /api/version` -> `{"version":"0.40.4"}`; Jupyter Server `GET /api` -> `{"version": "2.21.1"}`;
    /// MLflow `GET /version` -> `3.17.1`; Gradio `GET /config` -> `{"version":"6.30.0",...}`.
    static func aiServiceVersion(signatureID: String, port: Int, timeout: TimeInterval = 2.0) -> String? {
        let path: String
        switch signatureID {
        case "ollama-exposed": path = "/api/version"
        case "jupyter-noauth": path = "/api"
        case "mlflow-noauth": path = "/version"
        case "gradio-noauth": path = "/config"
        default: return nil
        }
        guard let response = httpGet(port: port, path: path, timeout: timeout), response.status == 200 else { return nil }
        if signatureID == "mlflow-noauth" {
            let v = response.body.trimmingCharacters(in: .whitespacesAndNewlines)
            let plausible = v.count <= 20 && (v.first?.isNumber ?? false)
                && v.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "-") }
            return plausible ? v : nil
        }
        return jsonStringField(response.body, key: "version")
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
        default: return aiServiceVersion(signatureID: signatureID, port: port, timeout: timeout)
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

    // MARK: - Unauthenticated admin surface

    /// The paths asked for, with no cookie and no `Authorization` header. A fixed, short list: nothing is guessed,
    /// nothing is fuzzed and no login is tried. Same list as the Linux build.
    static let unauthAdminPaths = ["/admin", "/api/admin", "/api/users", "/api/v1/users", "/api/v1/user", "/actuator/env", "/swagger-ui/index.html"]

    /// What an answer must look like to count: 200, and either structured data (a JSON object or array that is more
    /// than an error message), a table of users, or the Swagger UI. A login page, a redirect, a single-page-app shell
    /// and `{"error":"unauthorized"}` do not count.
    static func isOpenAdminResponse(path: String, status: Int, body: String) -> Bool {
        guard status == 200 else { return false }
        let trimmed = body.drop(while: { $0.isWhitespace })
        let lower = trimmed.lowercased()
        let shells = ["<div id=\"app\"", "<div id=\"root\"", "<div id=\"__next\"", "<app-root", "<div id=app", "<noscript>you need to enable javascript"]
        if shells.contains(where: { lower.contains($0) }) { return false }
        if path.hasSuffix("swagger-ui/index.html") { return lower.contains("swagger-ui") }
        if lower.hasPrefix("{") || lower.hasPrefix("[") {
            guard let data = String(trimmed).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else { return false }
            if let array = json as? [Any] { return !array.isEmpty }
            if let object = json as? [String: Any] {
                // A short object of status words is an error or a notice, not data.
                let notice: Set<String> = ["error", "message", "status", "detail", "code", "success", "msg"]
                return !(object.isEmpty || (object.count <= 3 && object.keys.allSatisfy { notice.contains($0.lowercased()) }))
            }
            return false
        }
        return lower.contains("<table") && (lower.contains("user") || lower.contains("e-mail") || lower.contains("email")) && !lower.contains("type=\"password\"")
    }

    /// Asks each of `unauthAdminPaths` once. `path` is the first one that answered like an open admin surface;
    /// `answered` is false when no request got any answer (the check is then inconclusive, not "safe").
    static func unauthAdminPath(port: Int, timeout: TimeInterval = 2.0) -> (path: String?, answered: Bool) {
        var answered = false
        for path in unauthAdminPaths {
            guard let response = httpGet(port: port, path: path, timeout: timeout) else { continue }
            answered = true
            if let status = response.status, isOpenAdminResponse(path: path, status: status, body: response.body) {
                return (path, true)
            }
        }
        return (nil, answered)
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

    // MARK: - SSRF (server fetches a URL it is given)

    /// Parameter names tried at the root path, then `url` at a few conventional "fetch this
    /// URL for me" paths. Like `redirectParamNames`, a server taking its URL under another
    /// name is simply not flagged: this check is biased toward false negatives.
    private static let ssrfRootParams = ["url", "uri", "link", "src", "image", "target", "dest", "callback"]
    private static let ssrfPaths = ["/proxy", "/fetch", "/image", "/preview"]
    /// How long to keep watching our own listener after a candidate request was answered: a
    /// server that fetches the URL does so while handling the request or right after it.
    private static let ssrfSettle: TimeInterval = 0.15

    /// A throw-away listener bound to `127.0.0.1` only. It counts the requests it receives and
    /// answers each with `reply`. Plain BSD sockets, so it needs no entitlement and cannot be
    /// reached from another machine.
    private final class HopListener {
        let port: Int
        private let fd: Int32
        private let reply: Data
        private let lock = NSLock()
        private var count = 0
        private var stopped = false
        private let finished = DispatchSemaphore(value: 0)

        init?(reply: String) {
            self.reply = Data(reply.utf8)
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            guard fd >= 0 else { return nil }
            var addr = sockaddr_in()
            addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = 0
            addr.sin_addr.s_addr = UInt32(0x7F000001).bigEndian
            let bound = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
            }
            guard bound == 0, listen(fd, 8) == 0 else { close(fd); return nil }
            var out = sockaddr_in()
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            let named = withUnsafeMutablePointer(to: &out) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &len) }
            }
            guard named == 0 else { close(fd); return nil }
            self.fd = fd
            self.port = Int(UInt16(bigEndian: out.sin_port))
            DispatchQueue.global(qos: .utility).async { [self] in acceptLoop() }
        }

        private var isStopped: Bool { lock.lock(); defer { lock.unlock() }; return stopped }

        private func acceptLoop() {
            defer { finished.signal() }
            while !isStopped {
                var pfd = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
                guard poll(&pfd, 1, 50) > 0 else { continue }
                let client = accept(fd, nil, nil)
                if client < 0 { continue }
                var tv = timeval(tv_sec: 0, tv_usec: 500_000)
                setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
                var buf = [UInt8](repeating: 0, count: 1024)
                _ = read(client, &buf, buf.count)
                lock.lock(); count += 1; lock.unlock()
                _ = reply.withUnsafeBytes { write(client, $0.baseAddress, reply.count) }
                close(client)
            }
        }

        var hits: Int { lock.lock(); defer { lock.unlock() }; return count }

        func stop() {
            lock.lock(); stopped = true; lock.unlock()
            _ = finished.wait(timeout: .now() + 2)
            close(fd)
        }
    }

    /// Server-side request forgery: hands the target a URL that points at a listener of ours
    /// on `127.0.0.1`, in the parameters a "fetch this URL" feature usually takes, and reports
    /// whether the target actually connected to it. Our listener answers with a 302 to a second
    /// listener of ours, so a target that also follows redirects is seen too, which is how an
    /// attacker's own redirect server (a `/r302?u=<target>` page, found on attack servers by
    /// JPCERT/CC in 2026-10) gets past a check that only looks at the first URL.
    ///
    /// Both listeners are loopback-only and answer a plain GET; nothing outside this machine
    /// is contacted and nothing is written. A hit proves the target fetches URLs it is given
    /// and does not refuse an address on this machine. No hit is not proof of safety (see the
    /// name lists above), so only a hit is flagged. Same contract as `probeOpenRedirect`:
    /// `nil` when the target never answered.
    static func probeSSRFFetch(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let second = HopListener(reply: "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok") else { return nil }
        guard let first = HopListener(reply: "HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:\(second.port)/ssrf-redirect-hop\r\nContent-Length: 0\r\nConnection: close\r\n\r\n") else {
            second.stop()
            return nil
        }
        defer { first.stop(); second.stop() }
        let probeURL = "http://127.0.0.1:\(first.port)/ssrf-probe"

        var candidates: [(path: String, param: String)] = ssrfRootParams.map { ("/", $0) }
        candidates += ssrfPaths.map { ($0, "url") }
        var sawAnyResponse = false
        for candidate in candidates {
            var components = URLComponents(string: "http://127.0.0.1:\(port)\(candidate.path)")!
            components.queryItems = [URLQueryItem(name: candidate.param, value: probeURL)]
            guard let url = components.url else { continue }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            if syncHTTPRequestNoRedirect(request, timeout: timeout) != nil { sawAnyResponse = true }
            let deadline = Date().addingTimeInterval(ssrfSettle)
            while first.hits == 0 && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
            if first.hits > 0 { return true }
        }
        return sawAnyResponse ? false : nil
    }

    // MARK: - Orchestration

    /// Which `ServiceSignatures` ids Phase 2 has an actual probe implemented for.
    /// Signatures without a matching prober here are Phase-1-only (flagged passively).
    private static let probeableSignatureIDs: Set<String> = [
        "redis-default-noauth", "memcached-noauth", "mongod-default-noauth",
        "elasticsearch-noauth", "couchdb-noauth", "jenkins-noauth", "vnc-noauth",
        "smb1-enabled", "smb-signing-not-required", "hexstrike-noauth",
        "ollama-exposed", "jupyter-noauth", "mlflow-noauth", "gradio-noauth",
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

    /// The side effects a run against this one port declares (`ProbeCatalog`): its signature probes plus, for a
    /// known dev-server port, the web checks. Shown before the first run so the person can see what will be sent.
    /// The nmap layer is left out: it runs only when nmap is installed and covers every port at once.
    static func plannedSideEffects(for port: ListeningPortInfo) -> [ProbeSideEffect] {
        var names = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            .map(\.id).filter { probeableSignatureIDs.contains($0) }
        if PortSecurityAuditor.isKnownDevServerPort(port.port) {
            names += ["webvuln-cors", "webvuln-traversal", "webvuln-redirect", "webvuln-ssrf", "webvuln-unauth-admin"]
        }
        let effects = Set(names.flatMap { ProbeCatalog.declaration(forProbeName: $0)?.sideEffects ?? [] })
        return ProbeSideEffect.allCases.filter(effects.contains)
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
    /// Signatures whose finding is about being reachable from the network: probed only for a
    /// listener bound beyond loopback (`ListeningPortInfo.isGloballyExposed`).
    static let networkExposureOnlyIDs: Set<String> = ["ollama-exposed", "jupyter-noauth", "mlflow-noauth", "gradio-noauth"]

    static func runScan(ports: [ListeningPortInfo], probeLogURL: URL = probeLogURL, includeNmapNSE: Bool = true) -> ScanRunResult {
        var result = ScanRunResult()
        var logEntries: [ProbeRunRecord] = []
        // Read before this run appends its own rows, so "earlier" never includes the run itself.
        let history = loadProbeLog(at: probeLogURL)

        for port in ports {
            let signatures = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            for signature in signatures where probeableSignatureIDs.contains(signature.id) {
                // The AI services' findings say "usable from the network", which is only true when
                // the listener is bound beyond loopback. A copy on 127.0.0.1 is not reported.
                if networkExposureOnlyIDs.contains(signature.id) && !port.isGloballyExposed { continue }
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
                case "hexstrike-noauth": confirmed = probeHexStrikeNoAuth(port: port.port)
                case "ollama-exposed": confirmed = probeOllamaExposed(port: port.port)
                case "jupyter-noauth": confirmed = probeJupyterNoAuth(port: port.port)
                case "mlflow-noauth": confirmed = probeMLflowNoAuth(port: port.port)
                case "gradio-noauth": confirmed = probeGradioNoAuth(port: port.port)
                case "smb1-enabled": confirmed = probeSMBNegotiate(port: port.port).map { $0 == .smb1 }
                case "smb-signing-not-required": confirmed = probeSMBNegotiate(port: port.port).map { $0 == .smb2SigningNotRequired }
                default: confirmed = nil
                }
                let finishedAt = Date()
                if !result.probesRun.contains(signature.id) { result.probesRun.append(signature.id) }
                logEntries.append(ProbeRunRecord(
                    probeName: signature.id,
                    port: port.port,
                    lastStartedAt: probeLogFormatter.string(from: startedAt),
                    lastFinishedAt: probeLogFormatter.string(from: finishedAt),
                    outcome: confirmed == true ? "vulnerable" : (confirmed == false ? "safe" : "inconclusive")
                ))
                let outcome = CheckOutcome(port: port.port, processName: port.processName, check: signature.title)
                if confirmed == true {
                    result.findings.append(Finding(
                        port: port.port,
                        processName: port.processName,
                        title: signature.title,
                        description: signature.description,
                        recommendation: signature.recommendation,
                        probeName: signature.id,
                        evidenceKind: .confirmed
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
                                recommendation: resolveLang(cve.recommendation),
                                probeName: signature.id,
                                evidenceKind: .versionRangeMatch
                            ))
                        }
                    }
                } else if confirmed == false {
                    result.confirmedSafe.append(outcome)
                } else {
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
            if !result.probesRun.contains(probeName) { result.probesRun.append(probeName) }
            logEntries.append(ProbeRunRecord(
                probeName: probeName,
                port: outcome.port,
                lastStartedAt: probeLogFormatter.string(from: startedAt),
                lastFinishedAt: probeLogFormatter.string(from: finishedAt),
                outcome: confirmed == true ? "vulnerable" : (confirmed == false ? "safe" : "inconclusive")
            ))
            if confirmed == true {
                var finding = makeFinding()
                finding.probeName = probeName
                result.findings.append(finding)
            } else if confirmed == false {
                result.confirmedSafe.append(outcome)
            } else {
                result.inconclusive.append(outcome)
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

            runOne(
                probeName: "webvuln-ssrf",
                probe: { probeSSRFFetch(port: port.port) },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("SSRF（サーバーが指定されたURLを取りに行く）"),
                        description: loc("URLを受け取りやすいパラメータ（url/uri/src/image/target など）に、このマシン上の待ち受けを指すURLを渡したところ、サーバーがそこへ実際に接続しました。サーバーが渡されたURLを、このマシン内のアドレスかどうかを確かめずに取りに行くため、攻撃者は内部のサービスやクラウドのメタデータ（169.254.169.254）へ到達させ、認証情報を読み出せます。攻撃者が自分のサーバーのURLを渡し、そこから内部アドレスへのリダイレクト（302）を返させて、最初のURLだけを調べる対策をすり抜ける手口も確認されています。"),
                        recommendation: loc("取得してよい宛先を、必要なものだけの許可リストにしてください。ホスト名は自分で名前解決し、解決後のアドレスがループバック・プライベート・リンクローカル（169.254.169.254を含む）なら拒否します。リダイレクトは追わないか、追うたびに同じ検査をかけてください。クラウド上のサーバーでは、メタデータをIMDSv2（トークン必須）に切り替えることも有効です。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("SSRF（サーバーが指定されたURLを取りに行く）"))
            )

            // No login, no guessing: a short fixed list of paths asked without any credential.
            let open = unauthAdminPath(port: port.port)
            runOne(
                probeName: "webvuln-unauth-admin",
                probe: { open.answered ? (open.path != nil) : nil },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("認証なしで、管理用らしいパスがデータを返す"),
                        description: String(format: loc("ログインの情報を一切付けずに %@ へ GET したところ、エラーや画面の枠ではなく、データ(JSON の一覧や設定、ユーザーの表、API の文書)が返りました。表示の側で隠しているだけで、サーバー側で認可を確認していない可能性があります。ログインはしておらず、ほかのパスも試していません。"), open.path ?? ""),
                        recommendation: loc("サーバー側(アプリケーション)で、すべての管理用・API のルートに認証と、利用者ごとの認可の確認を入れてください。画面のメニューを隠すだけでは足りません。/actuator や /swagger-ui のような運用用の画面は、本番では閉じるか、内部ネットワークだけに限ってください。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("認証なしで、管理用らしいパスがデータを返す"))
            )

            // Reflected XSS (see `ReflectedXssProbe`). `xssDetail` carries where it was found from the probe to the finding text.
            var xssDetail: String?
            runOne(
                probeName: "webvuln-xss",
                probe: {
                    let r = ReflectedXssProbe.probe(port: port.port)
                    xssDetail = r.detail
                    return r.vulnerable
                },
                makeFinding: {
                    Finding(
                        port: port.port,
                        processName: port.processName,
                        title: loc("反射型XSS（入力値が無害化されずにHTMLへ出力される）"),
                        description: loc("検証用の無害な文字列（< > と引用符を含み、スクリプトは含みません）をGETパラメータに入れて送ったところ、エスケープされないままHTMLに出力されました。悪意あるリンクを開いた利用者のブラウザで、攻撃者のスクリプトが実行される危険があります。") + (xssDetail.map { " [\($0)]" } ?? ""),
                        recommendation: loc("出力時にHTMLエスケープしてください（テンプレートエンジンの自動エスケープを有効にし、innerHTML や dangerouslySetInnerHTML などで生の文字列を挿入しない）。あわせて Content-Security-Policy を設定すると、万一の被害を抑えられます。")
                    )
                },
                outcome: CheckOutcome(port: port.port, processName: port.processName, check: loc("反射型XSS（入力値が無害化されずにHTMLへ出力される）"))
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
            if NmapNSE.nmapAvailable() { result.probesRun.append(ProbeCatalog.nmapNSEProbeName) }
            for finding in nseFindings {
                let processName = ports.first { $0.port == finding.port }?.processName ?? ""
                result.findings.append(Finding(
                    port: finding.port,
                    processName: processName,
                    title: "\(loc("nmap NSE所見")): \(finding.script)",
                    description: finding.output,
                    recommendation: loc("これはnmap自身の検知結果です（RoamSwitch独自の検証は行っていません）。内容を確認し、該当する場合は対応してください。"),
                    probeName: ProbeCatalog.nmapNSEProbeName,
                    evidenceKind: .externalToolReport
                ))
            }
        }

        result.findings = markingPreviouslySafe(result.findings, history: history)
        appendProbeLog(logEntries, to: probeLogURL)
        return result
    }
}
