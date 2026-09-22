// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.54 (build 115).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Process-exec recorder: shared data model + defensive parser for the JSON
// stream of Apple's own `/usr/bin/eslogger`. Used by RoamSwitchHelper (root:
// runs eslogger, records, correlates), the app (status, notifications, viewer)
// and RoamSwitchMCPServer (read-only queries). Dependency-free on purpose.
//
// eslogger is NOT an entitlement of ours: it ships with macOS 13+, runs as
// root and needs Full Disk Access for the process that launches it (here the
// helper). It is notify-only telemetry; nothing here blocks an exec.

public enum ExecRecorderPaths {
    /// Same root-owned directory the helper already uses for its other state
    /// (`PortScanDetector`, gateway ARP lock, ...).
    public static let stateDir = "/Library/Application Support/RoamSwitch"
    public static let logDir = stateDir + "/exec_log"
    public static let statusFile = stateDir + "/exec_recorder_status.json"
    public static let configFile = stateDir + "/exec_recorder_config.json"
    public static let alertsFile = stateDir + "/exec_alerts.jsonl"
}

public enum ExecSignatureClass: String, Codable, Equatable {
    /// Apple platform binary (`is_platform_binary`).
    case platform
    /// Signed with a Team ID (Developer ID / App Store / Apple Development).
    case developer
    /// Has a code-signing identifier but no Team ID and is not a platform
    /// binary (linker-signed / `codesign -s -`).
    case adhoc
    /// No code-signing identifier at all.
    case unsigned
}

/// One recorded process event. `path` and the signing fields describe the
/// process image the event is about: the NEW image for `exec`, the child for
/// `fork`, the exiting process for `exit`.
public struct ExecEventRecord: Codable, Equatable {
    public var seq: UInt64
    /// Unix epoch seconds.
    public var time: Double
    /// "exec" | "fork" | "exit"
    public var kind: String
    public var pid: Int32
    /// exec: the parent pid; fork: the forking (parent) pid; exit: the parent pid.
    public var ppid: Int32
    public var uid: UInt32?
    public var path: String
    public var args: [String]?
    public var cwd: String?
    /// exec only: the image the process had BEFORE this exec (for fork+exec
    /// this is the parent's image — a fallback when the parent was never seen).
    public var priorPath: String?
    public var signingID: String?
    public var teamID: String?
    public var cdhash: String?
    public var isPlatform: Bool?
    public var csFlags: UInt32?
    public var exitStatus: Int32?

    public init(
        seq: UInt64 = 0, time: Double, kind: String, pid: Int32, ppid: Int32, uid: UInt32? = nil,
        path: String, args: [String]? = nil, cwd: String? = nil, priorPath: String? = nil,
        signingID: String? = nil, teamID: String? = nil, cdhash: String? = nil,
        isPlatform: Bool? = nil, csFlags: UInt32? = nil, exitStatus: Int32? = nil
    ) {
        self.seq = seq
        self.time = time
        self.kind = kind
        self.pid = pid
        self.ppid = ppid
        self.uid = uid
        self.path = path
        self.args = args
        self.cwd = cwd
        self.priorPath = priorPath
        self.signingID = signingID
        self.teamID = teamID
        self.cdhash = cdhash
        self.isPlatform = isPlatform
        self.csFlags = csFlags
        self.exitStatus = exitStatus
    }

    public var signatureClass: ExecSignatureClass {
        if isPlatform == true { return .platform }
        if let t = teamID, !t.isEmpty { return .developer }
        // CS_ADHOC (0x2) wins over a stray identifier.
        if let f = csFlags, f & 0x2 != 0 { return .adhoc }
        if let s = signingID, !s.isEmpty { return .adhoc }
        return .unsigned
    }

    /// Basename of `path`.
    public var executableName: String { (path as NSString).lastPathComponent }
}

/// One correlation-rule hit. `detail` is a neutral fact string (English, never
/// shown as-is in the UI except in the log); the UI localizes by `ruleID`.
public struct ExecAlert: Codable, Equatable {
    public var alertSeq: UInt64
    public var id: String
    public var time: Double
    public var ruleID: String
    /// MITRE ATT&CK technique id.
    public var technique: String
    /// "medium" | "high"
    public var severity: String
    public var eventSeq: UInt64
    public var pid: Int32
    public var ppid: Int32
    public var path: String
    public var args: [String]?
    public var parentPath: String?
    public var detail: String
    /// `exec.keychain_access` only: the Developer ID team of the ancestor that ran `security`
    /// (nil when it is not Developer ID signed) and the `-s` item it read. What "allow this
    /// program" needs; absent (nil) in alerts written by older builds.
    public var parentTeamID: String?
    public var keychainService: String?

    public init(
        alertSeq: UInt64 = 0, id: String = UUID().uuidString, time: Double, ruleID: String, technique: String,
        severity: String, eventSeq: UInt64, pid: Int32, ppid: Int32, path: String, args: [String]?,
        parentPath: String?, detail: String, parentTeamID: String? = nil, keychainService: String? = nil
    ) {
        self.alertSeq = alertSeq
        self.id = id
        self.time = time
        self.ruleID = ruleID
        self.technique = technique
        self.severity = severity
        self.eventSeq = eventSeq
        self.pid = pid
        self.ppid = ppid
        self.path = path
        self.args = args
        self.parentPath = parentPath
        self.detail = detail
        self.parentTeamID = parentTeamID
        self.keychainService = keychainService
    }
}

/// A keychain item that one specific program is expected to read on its own.
/// `service` is the `-s` value of `security find-generic-password`. The program is
/// named either by the Developer ID team of the process that runs it (`teamID`, for
/// signed tools) or by its executable name (`executableName`, for unsigned or ad-hoc
/// tools such as a Homebrew build, the same way the Linux edition allowlists the
/// opener of a credential file by name). The item must match too, so a program run
/// by such a tool cannot use the exemption to read some other item.
public struct TrustedKeychainReader: Codable, Equatable, Hashable {
    public var teamID: String?
    public var executableName: String?
    public var service: String
    public init(teamID: String? = nil, executableName: String? = nil, service: String) {
        self.teamID = teamID
        self.executableName = executableName
        self.service = service
    }

    /// The entry "allow this program" would add for a `keychain_access` alert: the ancestor's
    /// Developer ID team when it has one (a signature the program cannot fake by renaming),
    /// otherwise its executable name, together with the item that was read. nil when the alert
    /// does not say which item (nothing is allowed for "everything").
    public static func suggestion(for alert: ExecAlert) -> TrustedKeychainReader? {
        // The rule id is spelled out: `ExecRuleID` lives in `ExecCorrelationRules`, which the MCP
        // target does not compile (this file is in it).
        guard alert.ruleID == "exec.keychain_access",
              let service = alert.keychainService, !service.isEmpty else { return nil }
        if let team = alert.parentTeamID, !team.isEmpty {
            return TrustedKeychainReader(teamID: team, service: service)
        }
        guard let parent = alert.parentPath else { return nil }
        let name = (parent as NSString).lastPathComponent
        return name.isEmpty ? nil : TrustedKeychainReader(executableName: name, service: service)
    }
}

public struct ExecRecorderConfig: Codable, Equatable {
    public var enabled: Bool
    public var maxTotalMB: Int
    public var maxAgeDays: Int
    public var segmentMB: Int
    public var hashChain: Bool
    /// Persist `fork`/`exit` lines too (they always feed the in-memory process
    /// table). Off by default: exec lines alone carry pid/ppid for the tree.
    public var persistForkExit: Bool
    public var rulesEnabled: Bool
    /// Executable path prefixes exempt from every correlation rule.
    public var allowlistPrefixes: [String]
    /// A LaunchAgent/Daemon plist counts as "just written" within this window.
    public var launchPlistRecentSecs: Int
    /// Keychain reads that stay quiet in `exec.keychain_access`. `nil` (also what an
    /// older config file decodes to) means the built-in list.
    public var trustedKeychainReaders: [TrustedKeychainReader]?

    /// Claude Code reads its own login items from the keychain on every start
    /// (Developer ID: Anthropic PBC). Both names were seen on a real Mac, read by the
    /// `claude` binary itself: the current item, and the older one without a suffix.
    public static let defaultTrustedKeychainReaders: [TrustedKeychainReader] = [
        TrustedKeychainReader(teamID: "Q6L2SF6YDW", service: "Claude Code-credentials"),
        TrustedKeychainReader(teamID: "Q6L2SF6YDW", service: "Claude Code"),
        // GitHub CLI reads its own token (a Homebrew build is ad-hoc signed, so by name).
        TrustedKeychainReader(executableName: "gh", service: "gh:github.com"),
    ]

    public var effectiveTrustedKeychainReaders: [TrustedKeychainReader] {
        trustedKeychainReaders ?? Self.defaultTrustedKeychainReaders
    }

    public static let defaultMaxTotalMB = 200
    public static let defaultMaxAgeDays = 14

    public init(
        enabled: Bool = false, maxTotalMB: Int = ExecRecorderConfig.defaultMaxTotalMB,
        maxAgeDays: Int = ExecRecorderConfig.defaultMaxAgeDays, segmentMB: Int = 8, hashChain: Bool = true,
        persistForkExit: Bool = false, rulesEnabled: Bool = true, allowlistPrefixes: [String] = [],
        launchPlistRecentSecs: Int = 86_400, trustedKeychainReaders: [TrustedKeychainReader]? = nil
    ) {
        self.enabled = enabled
        self.maxTotalMB = maxTotalMB
        self.maxAgeDays = maxAgeDays
        self.segmentMB = segmentMB
        self.hashChain = hashChain
        self.persistForkExit = persistForkExit
        self.rulesEnabled = rulesEnabled
        self.allowlistPrefixes = allowlistPrefixes
        self.launchPlistRecentSecs = launchPlistRecentSecs
        self.trustedKeychainReaders = trustedKeychainReaders
    }

    /// Tolerant of missing keys (older/newer writers) — same `decodeIfPresent`
    /// convention as the other persisted structs.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ExecRecorderConfig()
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? d.enabled
        maxTotalMB = try c.decodeIfPresent(Int.self, forKey: .maxTotalMB) ?? d.maxTotalMB
        maxAgeDays = try c.decodeIfPresent(Int.self, forKey: .maxAgeDays) ?? d.maxAgeDays
        segmentMB = try c.decodeIfPresent(Int.self, forKey: .segmentMB) ?? d.segmentMB
        hashChain = try c.decodeIfPresent(Bool.self, forKey: .hashChain) ?? d.hashChain
        persistForkExit = try c.decodeIfPresent(Bool.self, forKey: .persistForkExit) ?? d.persistForkExit
        rulesEnabled = try c.decodeIfPresent(Bool.self, forKey: .rulesEnabled) ?? d.rulesEnabled
        allowlistPrefixes = try c.decodeIfPresent([String].self, forKey: .allowlistPrefixes) ?? d.allowlistPrefixes
        launchPlistRecentSecs = try c.decodeIfPresent(Int.self, forKey: .launchPlistRecentSecs) ?? d.launchPlistRecentSecs
        // Absent (an older writer) stays nil = the built-in list.
        trustedKeychainReaders = try c.decodeIfPresent([TrustedKeychainReader].self, forKey: .trustedKeychainReaders)
    }

    /// Bounds every numeric field so a corrupt or hostile config can neither
    /// fill the disk nor disable rotation.
    public func clamped() -> ExecRecorderConfig {
        var c = self
        c.maxTotalMB = min(max(c.maxTotalMB, 16), 4096)
        c.maxAgeDays = min(max(c.maxAgeDays, 1), 365)
        c.segmentMB = min(max(c.segmentMB, 1), 64)
        c.launchPlistRecentSecs = min(max(c.launchPlistRecentSecs, 60), 7 * 86_400)
        c.allowlistPrefixes = Array(c.allowlistPrefixes.prefix(64))
        return c
    }
}

/// Written by the helper (atomic, world-readable, contains no secrets), read by
/// the app UI and the MCP server.
public struct ExecRecorderStatus: Codable, Equatable {
    /// "stopped" | "starting" | "running" | "needsFullDiskAccess" |
    /// "esloggerMissing" | "backoff" | "failed"
    public var state: String
    public var updatedAt: Double
    public var startedAt: Double?
    public var eventsRecorded: UInt64
    /// Lines dropped because the bounded queue overflowed (drop-oldest).
    public var eventsDropped: UInt64
    /// Malformed / oversized eslogger lines skipped.
    public var malformedLines: UInt64
    public var alertsRaised: UInt64
    public var restartCount: Int
    public var nextRetryAt: Double?
    public var lastError: String?

    public init(
        state: String = "stopped", updatedAt: Double = Date().timeIntervalSince1970, startedAt: Double? = nil,
        eventsRecorded: UInt64 = 0, eventsDropped: UInt64 = 0, malformedLines: UInt64 = 0, alertsRaised: UInt64 = 0,
        restartCount: Int = 0, nextRetryAt: Double? = nil, lastError: String? = nil
    ) {
        self.state = state
        self.updatedAt = updatedAt
        self.startedAt = startedAt
        self.eventsRecorded = eventsRecorded
        self.eventsDropped = eventsDropped
        self.malformedLines = malformedLines
        self.alertsRaised = alertsRaised
        self.restartCount = restartCount
        self.nextRetryAt = nextRetryAt
        self.lastError = lastError
    }

    public static func read(path: String = ExecRecorderPaths.statusFile) -> ExecRecorderStatus? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(ExecRecorderStatus.self, from: data)
    }
}

// MARK: - Bounded FIFO with drop-oldest

/// Thread-safe bounded line queue. When full, the OLDEST entry is dropped and
/// counted — the recorder must never let a burst grow memory or stall eslogger.
public final class BoundedLineQueue {
    private let lock = NSLock()
    private var items: [Data] = []
    private var head = 0
    private var bytes = 0
    private let maxItems: Int
    private let maxBytes: Int
    private var droppedTotal: UInt64 = 0

    public init(maxItems: Int = 4000, maxBytes: Int = 32 * 1024 * 1024) {
        self.maxItems = max(1, maxItems)
        self.maxBytes = max(1, maxBytes)
    }

    public var count: Int { lock.lock(); defer { lock.unlock() }; return items.count - head }
    public var dropped: UInt64 { lock.lock(); defer { lock.unlock() }; return droppedTotal }

    public func push(_ line: Data) {
        lock.lock(); defer { lock.unlock() }
        items.append(line)
        bytes += line.count
        while (items.count - head) > maxItems || (bytes > maxBytes && (items.count - head) > 1) {
            bytes -= items[head].count
            items[head] = Data()
            head += 1
            droppedTotal += 1
        }
        compactIfNeeded()
    }

    public func drain(max n: Int) -> [Data] {
        lock.lock(); defer { lock.unlock() }
        let avail = items.count - head
        let take = min(max(n, 0), avail)
        guard take > 0 else { return [] }
        let out = Array(items[head..<(head + take)])
        for i in head..<(head + take) { items[i] = Data() }
        head += take
        for d in out { bytes -= d.count }
        compactIfNeeded()
        return out
    }

    private func compactIfNeeded() {
        if head > 1024 && head * 2 > items.count {
            items.removeFirst(head)
            head = 0
        }
    }
}

// MARK: - Line splitting (bounded)

/// Splits a byte stream into newline-terminated lines with a hard cap on line
/// length: an over-long line is discarded (counted), never buffered whole.
public struct ESLineSplitter {
    public static let defaultMaxLineBytes = 1_048_576

    private var buffer = Data()
    private var discarding = false
    private let maxLineBytes: Int
    public private(set) var oversizedLines: UInt64 = 0

    public init(maxLineBytes: Int = ESLineSplitter.defaultMaxLineBytes) {
        self.maxLineBytes = max(16, maxLineBytes)
    }

    public mutating func feed(_ chunk: Data) -> [Data] {
        var data = chunk
        if discarding {
            guard let nl = data.firstIndex(of: 0x0A) else { return [] }
            data = Data(data[(nl + 1)...])
            discarding = false
        }
        buffer.append(data)
        var out: [Data] = []
        var start = buffer.startIndex
        while let nl = buffer[start...].firstIndex(of: 0x0A) {
            let len = nl - start
            if len > 0 {
                if len <= maxLineBytes {
                    out.append(Data(buffer[start..<nl]))
                } else {
                    oversizedLines += 1
                }
            }
            start = nl + 1
        }
        buffer = start >= buffer.endIndex ? Data() : Data(buffer[start...])
        if buffer.count > maxLineBytes {
            buffer = Data()
            discarding = true
            oversizedLines += 1
        }
        return out
    }
}

// MARK: - eslogger JSON parser

/// Parses one line of `eslogger exec fork exit` output (one JSON object per
/// line, `schema_version` 1). Field paths used (from Apple's es_message_t JSON
/// serialization):
///
///   time                                   ISO-8601 string (fractional seconds)
///   process.audit_token.{pid,euid,ruid}    the acting process
///   process.ppid, process.executable.path, process.signing_id, process.team_id,
///   process.cdhash, process.is_platform_binary, process.cs_flags
///   event.exec.target                      the NEW process (same fields as above)
///   event.exec.args                        [String]
///   event.exec.cwd.path
///   event.fork.child                       the child process (same fields)
///   event.exit.stat                        Int
///
/// Unknown fields are ignored, `event.exec.env` is never read or kept
/// (secrets), malformed input yields `.malformed` — never a crash. NOTE: not
/// yet verified against real eslogger output on a Mac (see docs/EXEC_RECORDER.md).
public enum ESLoggerParser {
    public static let maxLineBytes = ESLineSplitter.defaultMaxLineBytes
    public static let maxArgs = 64
    public static let maxArgChars = 512
    public static let maxPathChars = 1024

    public enum ParseResult: Equatable {
        case record(ExecEventRecord)
        /// A valid message of a kind we do not record.
        case ignored
        case malformed
    }

    public static func parse(_ line: Data, seq: UInt64 = 0) -> ParseResult {
        guard !line.isEmpty, line.count <= maxLineBytes else { return .malformed }
        guard let obj = try? JSONSerialization.jsonObject(with: line, options: []),
              let root = obj as? [String: Any],
              let event = root["event"] as? [String: Any] else { return .malformed }
        let process = root["process"] as? [String: Any] ?? [:]
        let time = parseTime(root["time"]) ?? Date().timeIntervalSince1970
        let acting = info(process)

        if let exec = event["exec"] as? [String: Any] {
            guard let target = exec["target"] as? [String: Any] else { return .malformed }
            let t = info(target)
            guard let path = t.path else { return .malformed }
            guard let pid = t.pid ?? acting.pid else { return .malformed }
            var args: [String]?
            if let raw = exec["args"] as? [Any] {
                args = raw.prefix(maxArgs).compactMap { str($0, max: maxArgChars, allowEmpty: true) }
            }
            let cwd = (exec["cwd"] as? [String: Any]).flatMap { str($0["path"], max: maxPathChars) }
            return .record(ExecEventRecord(
                seq: seq, time: time, kind: "exec", pid: pid, ppid: t.ppid ?? acting.ppid ?? 0,
                uid: t.uid ?? acting.uid, path: path, args: args, cwd: cwd, priorPath: acting.path,
                signingID: t.signingID, teamID: t.teamID, cdhash: t.cdhash, isPlatform: t.isPlatform, csFlags: t.csFlags
            ))
        }
        if let fork = event["fork"] as? [String: Any] {
            guard let child = fork["child"] as? [String: Any] else { return .malformed }
            let c = info(child)
            guard let pid = c.pid, let path = c.path ?? acting.path else { return .malformed }
            return .record(ExecEventRecord(
                seq: seq, time: time, kind: "fork", pid: pid, ppid: acting.pid ?? c.ppid ?? 0,
                uid: c.uid ?? acting.uid, path: path, signingID: c.signingID ?? acting.signingID,
                teamID: c.teamID ?? acting.teamID, cdhash: c.cdhash ?? acting.cdhash,
                isPlatform: c.isPlatform ?? acting.isPlatform, csFlags: c.csFlags ?? acting.csFlags
            ))
        }
        if let exit = event["exit"] as? [String: Any] {
            guard let pid = acting.pid, let path = acting.path else { return .malformed }
            let stat = int(exit["stat"]).map { Int32(truncatingIfNeeded: $0) }
            return .record(ExecEventRecord(
                seq: seq, time: time, kind: "exit", pid: pid, ppid: acting.ppid ?? 0, uid: acting.uid, path: path,
                signingID: acting.signingID, teamID: acting.teamID, cdhash: acting.cdhash,
                isPlatform: acting.isPlatform, csFlags: acting.csFlags, exitStatus: stat
            ))
        }
        return .ignored
    }

    // MARK: helpers

    private struct ProcInfo {
        var pid: Int32?
        var ppid: Int32?
        var uid: UInt32?
        var path: String?
        var signingID: String?
        var teamID: String?
        var cdhash: String?
        var isPlatform: Bool?
        var csFlags: UInt32?
    }

    private static func info(_ p: [String: Any]) -> ProcInfo {
        var r = ProcInfo()
        if let tok = p["audit_token"] as? [String: Any] {
            r.pid = int(tok["pid"]).flatMap { Int32(exactly: $0) }
            r.uid = int(tok["euid"]).flatMap { UInt32(exactly: $0) } ?? int(tok["ruid"]).flatMap { UInt32(exactly: $0) }
        }
        r.ppid = int(p["ppid"]).flatMap { Int32(exactly: $0) }
        if let exe = p["executable"] as? [String: Any] { r.path = str(exe["path"], max: maxPathChars) }
        r.signingID = str(p["signing_id"], max: 256)
        r.teamID = str(p["team_id"], max: 32)
        r.cdhash = str(p["cdhash"], max: 64)
        r.isPlatform = p["is_platform_binary"] as? Bool
        r.csFlags = int(p["cs_flags"]).flatMap { UInt32(exactly: $0) }
        return r
    }

    private static func str(_ v: Any?, max: Int, allowEmpty: Bool = false) -> String? {
        guard let s = v as? String else { return nil }
        if s.isEmpty && !allowEmpty { return nil }
        return s.count > max ? String(s.prefix(max)) : s
    }

    private static func int(_ v: Any?) -> Int64? {
        if let n = v as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() { return n.int64Value }
        return nil
    }

    /// ISO-8601 with 0-9 fractional digits; unparsable -> nil (caller uses "now").
    static func parseTime(_ v: Any?) -> Double? {
        guard let s = v as? String, !s.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d.timeIntervalSince1970 }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: s) { return d.timeIntervalSince1970 }
        // More than 3 fractional digits are rejected by ISO8601DateFormatter: trim to ms.
        if let dot = s.firstIndex(of: "."), let z = s[dot...].firstIndex(where: { $0 == "Z" || $0 == "+" || $0 == "-" }) {
            let frac = s[s.index(after: dot)..<z]
            let ms = String(frac.prefix(3))
            let trimmed = String(s[..<dot]) + "." + ms + String(s[z...])
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: trimmed)?.timeIntervalSince1970
        }
        return nil
    }
}
