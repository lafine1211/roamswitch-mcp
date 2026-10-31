// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.18 (build 197).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// A guard that reads a stream (`log stream`, tcpdump, eslogger) or a file can lose input without anyone
// noticing: the process ends and is started again, nothing is replayed, and the guard looks the same as
// before. This is the small counted record of that, kept per input source, plus how it is stored and how
// it turns into the one word `get_guard_status` and `get_detection_coverage` show as `liveState`.
//
// What is counted is only what the code can truly count:
// - `gaps`: how many times the input stopped while it should have been flowing. Each is an interval of
//   unknown length in which nothing was observed and nothing is replayed afterwards.
// - `restarts`: how many times the reader was started again after such a stop.
// - `linesDropped` / `oversizeDropped`: lines refused by a line budget or lost because the parser was
//   unavailable (counted per line), and the number of times an unterminated oversize buffer was thrown
//   away (counted per event, since the number of lines in it is unknown). Both are nil for a source
//   that has no such step.
// - `unreadable` with a `reason` code: the source cannot be read right now.
// A helper restart is itself a gap for every helper reader that was running (see `begin`).

public struct GuardReaderHealth: Codable, Equatable {
    /// The reader is meant to be running (set when it starts, cleared on an intentional stop).
    public var active = false
    public var restarts = 0
    /// Unix seconds.
    public var lastRestartAt: Double?
    public var gaps = 0
    public var lastGapAt: Double?
    /// A gap is open: the input stopped and has not been read again since.
    public var inGap = false
    /// The source cannot be read right now.
    public var unreadable = false
    /// `reader_not_running`, `start_refused`, `launch_failed`, `too_many_restarts`, `permission`, `tool_missing`,
    /// `restarting`, `not_running`, `unreadable_file`, `helper_unreachable`.
    public var reason: String?
    public var linesDropped: UInt64?
    public var oversizeDropped: UInt64?
    /// Files the last scan or batch could not open or read and so skipped (nil for a source that has no such step).
    public var filesUnreadable: Int?
    /// When a scan last skipped at least one file (unix seconds).
    public var filesUnreadableAt: Double?
    /// Folders the last scan could not list, so everything below them was not looked at (nil where the source has no folders).
    public var foldersUnreadable: Int?
    /// Files the last scan read only the beginning and the end of, because they are longer than the whole-read limit (nil where there is no limit).
    public var filesTruncated: Int?
    /// The last scan left part of what it should watch out because a limit was reached (more working copies than it
    /// keeps, a walk that stopped at its folder limit, more files than its list holds). nil where the source has no such
    /// limit. What was left out was not looked at, the same as an unreadable file.
    public var scopeLimited: Bool?
    public var updatedAt: Double = 0

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case active, restarts, lastRestartAt, gaps, lastGapAt, inGap, unreadable, reason, linesDropped, oversizeDropped
        case filesUnreadable, filesUnreadableAt, foldersUnreadable, filesTruncated, scopeLimited, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        active = try c.decodeIfPresent(Bool.self, forKey: .active) ?? false
        restarts = try c.decodeIfPresent(Int.self, forKey: .restarts) ?? 0
        lastRestartAt = try c.decodeIfPresent(Double.self, forKey: .lastRestartAt)
        gaps = try c.decodeIfPresent(Int.self, forKey: .gaps) ?? 0
        lastGapAt = try c.decodeIfPresent(Double.self, forKey: .lastGapAt)
        inGap = try c.decodeIfPresent(Bool.self, forKey: .inGap) ?? false
        unreadable = try c.decodeIfPresent(Bool.self, forKey: .unreadable) ?? false
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
        linesDropped = try c.decodeIfPresent(UInt64.self, forKey: .linesDropped)
        oversizeDropped = try c.decodeIfPresent(UInt64.self, forKey: .oversizeDropped)
        filesUnreadable = try c.decodeIfPresent(Int.self, forKey: .filesUnreadable)
        filesUnreadableAt = try c.decodeIfPresent(Double.self, forKey: .filesUnreadableAt)
        foldersUnreadable = try c.decodeIfPresent(Int.self, forKey: .foldersUnreadable)
        filesTruncated = try c.decodeIfPresent(Int.self, forKey: .filesTruncated)
        scopeLimited = try c.decodeIfPresent(Bool.self, forKey: .scopeLimited)
        updatedAt = try c.decodeIfPresent(Double.self, forKey: .updatedAt) ?? 0
    }

    // MARK: Transitions (pure)

    private mutating func openGap(at now: Double) {
        guard !inGap else { return }
        inGap = true
        gaps += 1
        lastGapAt = now
    }

    /// The reader began reading. Closes an open gap.
    public mutating func markStarted(now: Double) {
        active = true
        inGap = false
        unreadable = false
        reason = nil
        updatedAt = now
    }

    /// The reader ended on its own while it should have kept running: a gap opens.
    public mutating func markEnded(now: Double) {
        active = true
        openGap(at: now)
        updatedAt = now
    }

    /// The reader is being started again after a gap.
    public mutating func markRestarting(now: Double) {
        restarts += 1
        lastRestartAt = now
        updatedAt = now
    }

    /// The source cannot be read (the reader process is missing, refused, would not launch, keeps dying).
    public mutating func markUnreadable(reason: String, now: Double) {
        active = true
        unreadable = true
        self.reason = reason
        openGap(at: now)
        updatedAt = now
    }

    /// An intentional stop (guard switched off, nothing left to watch). Not a gap.
    public mutating func markStopped(now: Double) {
        active = false
        inGap = false
        unreadable = false
        reason = nil
        updatedAt = now
    }

    public mutating func addDropped(_ lines: Int, now: Double) {
        guard lines > 0 else { return }
        linesDropped = (linesDropped ?? 0) + UInt64(lines)
        updatedAt = now
    }

    public mutating func addOversize(now: Double) {
        oversizeDropped = (oversizeDropped ?? 0) + 1
        updatedAt = now
    }

    /// The result of one scan: how many files it had to skip because they could not be opened or read. Replaces the
    /// previous count (it is "the last scan", not a running total); the time moves only when something was skipped.
    public mutating func setFilesUnreadable(_ count: Int, now: Double) {
        filesUnreadable = count
        if count > 0 { filesUnreadableAt = now }
        updatedAt = now
    }

    /// The result of one folder scan: files it could not open, folders it could not list (everything below them
    /// unseen) and files it read only the start of. Each replaces the previous scan's count; the time moves only
    /// when the scan skipped a file or folder.
    public mutating func setScanResult(filesUnreadable files: Int, foldersUnreadable folders: Int, filesTruncated truncated: Int, now: Double) {
        filesUnreadable = files
        foldersUnreadable = folders
        filesTruncated = truncated
        if files > 0 || folders > 0 { filesUnreadableAt = now }
        updatedAt = now
    }

    /// Whether the last scan left part of its scope out because a limit was reached. Replaces the previous answer.
    public mutating func setScopeLimited(_ limited: Bool, now: Double) {
        scopeLimited = limited
        updatedAt = now
    }

    /// Makes the unreadable-files count exist (as 0) for a source whose scans skip files they cannot read.
    public mutating func enableFileCounter() {
        if filesUnreadable == nil { filesUnreadable = 0 }
    }

    /// Makes the counters exist (as 0) for a source that has the step they count.
    public mutating func enableDropCounters() {
        if linesDropped == nil { linesDropped = 0 }
        if oversizeDropped == nil { oversizeDropped = 0 }
    }

    /// The previous run of the process that owned this reader ended without a clean stop (the helper was
    /// killed, restarted for an update, or the Mac was shut down while the reader was running). The time in
    /// between is a gap that started when the record was last written.
    public mutating func markLostWhileProcessWasDown(now: Double) {
        guard active else { return }
        gaps += 1
        lastGapAt = updatedAt > 0 ? updatedAt : now
        restarts += 1
        lastRestartAt = now
        inGap = true
        updatedAt = now
    }
}

/// Persists the records. The helper writes one world-readable file (same folder and mode as the exec
/// recorder's status file); the app writes its own readers to the shared preferences. The MCP server
/// reads both.
public enum GuardReaderHealthStore {
    public static let stateDir = "/Library/Application Support/RoamSwitch"
    public static let helperFile = stateDir + "/reader_health.json"
    public static let appDefaultsKey = "RoamSwitch.GuardReaderHealthV1"

    private static let lock = NSLock()

    struct File: Codable { var sources: [String: GuardReaderHealth] = [:] }

    public static func readHelper(path: String = helperFile) -> [String: GuardReaderHealth] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [:] }
        return file.sources
    }

    public static func writeHelper(source: String, health: GuardReaderHealth, path: String = helperFile) {
        lock.lock(); defer { lock.unlock() }
        var file = File(sources: readHelper(path: path))
        file.sources[source] = health
        guard let data = try? JSONEncoder().encode(file) else { return }
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        chmod(path, 0o644)
    }

    public static func readApp(defaults: UserDefaults) -> [String: GuardReaderHealth] {
        guard let data = defaults.data(forKey: appDefaultsKey),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [:] }
        return file.sources
    }

    public static func writeApp(source: String, health: GuardReaderHealth, defaults: UserDefaults = .standard) {
        lock.lock(); defer { lock.unlock() }
        var file = File(sources: readApp(defaults: defaults))
        file.sources[source] = health
        if let data = try? JSONEncoder().encode(file) { defaults.set(data, forKey: appDefaultsKey) }
    }

    /// The exec recorder keeps its own status; its health is derived from that instead of written twice.
    public static func health(fromExecRecorder status: ExecRecorderStatus?) -> GuardReaderHealth? {
        guard let s = status else { return nil }
        var h = GuardReaderHealth()
        h.updatedAt = s.updatedAt
        h.restarts = s.restartCount
        h.gaps = s.restartCount
        h.linesDropped = s.eventsDropped
        h.oversizeDropped = nil
        h.active = s.state != "stopped"
        switch s.state {
        case "needsFullDiskAccess": h.unreadable = true; h.reason = "permission"
        case "esloggerMissing": h.unreadable = true; h.reason = "tool_missing"
        case "failed": h.unreadable = true; h.reason = "too_many_restarts"
        case "backoff": h.unreadable = true; h.reason = "restarting"
        default: break
        }
        h.inGap = h.unreadable
        if let at = s.lastRestartAt { h.lastRestartAt = at; h.lastGapAt = at }
        return h
    }

    /// Every record the app or the MCP server can see, by source id.
    public static func all(defaults: UserDefaults, helperPath: String = helperFile,
                           execStatusPath: String = ExecRecorderPaths.statusFile) -> [String: GuardReaderHealth] {
        var out = readHelper(path: helperPath)
        for (k, v) in readApp(defaults: defaults) { out[k] = v }
        if let exec = health(fromExecRecorder: ExecRecorderStatus.read(path: execStatusPath)) { out["execRecorder"] = exec }
        return out
    }

    // MARK: guard -> sources, and the one word

    public struct GuardSources {
        /// Without these the guard sees nothing.
        public let sources: [String]
        /// Narrower inputs: when one of these is down the guard still works with less (`partial`).
        public let auxiliary: [String]
        /// Nothing to read while the reader is idle is healthy (the SSH guard only reads while Remote Login is on).
        public let idleIsHealthy: Bool
    }

    /// The guards of `get_guard_status` that read a stream or a file, and which health records belong to them.
    public static let guardSources: [String: GuardSources] = [
        "sshGuard": GuardSources(sources: ["sshLogStream"], auxiliary: [], idleIsHealthy: true),
        // pflog0 is the input; the second capture only checks whether a source address is forged.
        "portScanGuard": GuardSources(sources: ["portScanTcpdump"], auxiliary: ["linkSource"], idleIsHealthy: false),
        "execRecorder": GuardSources(sources: ["execRecorder"], auxiliary: [], idleIsHealthy: false),
        "runtimeThreatContainment": GuardSources(sources: ["runtimeThreatLogStream"], auxiliary: [], idleIsHealthy: false),
        // The clipboard check is the narrower input: without macOS's permission to read it the guard still sees the history.
        "clickFixGuard": GuardSources(sources: ["clickFixHistory"], auxiliary: ["clickFixClipboard"], idleIsHealthy: false),
        // FSEvents is a trigger here and the timer is the backstop, so a watch that cannot start is `partial`, not `off`.
        "criticalPathFim": GuardSources(sources: ["criticalPathFimHelper"], auxiliary: ["criticalPathFimFSEvents"], idleIsHealthy: false),
        "lockfileTamperGuard": GuardSources(sources: ["lockfileTamperScan"], auxiliary: ["lockfileTamperFSEvents"], idleIsHealthy: false),
        // The automatic npm check: the scan is what runs (it says when no project folder is registered); FSEvents only brings
        // it forward, and the daily look is the backstop, so a stream that cannot start is `partial`.
        "npmSupplyWatch": GuardSources(sources: ["npmSupplyWatchScan"], auxiliary: ["npmSupplyWatchStream"], idleIsHealthy: false),
        // The automatic dependency vulnerability check: the same shape as the npm one (the scan says when no project folder is
        // registered; FSEvents only brings it forward and the daily look is the backstop).
        "dependencyWatch": GuardSources(sources: ["dependencyWatchScan"], auxiliary: ["dependencyWatchStream"], idleIsHealthy: false),
        // The notice for a setting that passed at the last diagnosis and fails now. It has no input of its own: it reads the
        // finding history the diagnosis already writes, so there is no reader to fail.
        "configRegressionNotice": GuardSources(sources: [], auxiliary: [], idleIsHealthy: true),
        // FSEvents is the only input of these: a watch that cannot start means the guard sees nothing.
        "ransomwareEntropyGuard": GuardSources(sources: ["ransomwareEntropyFSEvents"], auxiliary: [], idleIsHealthy: false),
        // The plist watch is FSEvents; the start-up script poll (shell rc, periodic, hooks) is a narrower input.
        "persistenceMonitor": GuardSources(sources: ["persistenceMonitorFSEvents"], auxiliary: ["startupScriptPoll"], idleIsHealthy: false),
        // The static signature pass runs per batch of downloads; what it could not examine in the last batch is the auxiliary record.
        "webMailDownloadGuard": GuardSources(sources: ["webMailDownloadFSEvents"], auxiliary: ["staticSignatureScan"], idleIsHealthy: false),
        "browserCredentialWatchGuard": GuardSources(sources: ["browserCredentialWatchFSEvents"], auxiliary: [], idleIsHealthy: false),
        // A poll of the process table (libproc) every few seconds; if the table cannot be read the guard sees nothing.
        "reverseShellWatch": GuardSources(sources: ["reverseShellScan"], auxiliary: [], idleIsHealthy: false),
        // A subscription to the system configuration store; if it cannot be set up the guard sees nothing.
        "networkSettingsWatch": GuardSources(sources: ["networkSettingsStore"], auxiliary: [], idleIsHealthy: false),
        "ransomwareCanaryGuard": GuardSources(sources: ["ransomwareCanaryFiles"], auxiliary: [], idleIsHealthy: false),
        // The decoy files themselves are the input: with none in place (every path holds a real file, or cannot be
        // written) the guard watches nothing, whatever its switch says.
        "credentialHoneytokenGuard": GuardSources(sources: ["honeytokenPlaced"], auxiliary: [], idleIsHealthy: false),
        // The comparison itself runs on a timer; FSEvents only brings it forward. A stream that cannot start leaves the
        // timer (five minutes), so the guard still works with less.
        "agentSetupWatch": GuardSources(sources: [], auxiliary: ["agentSetupWatchStream"], idleIsHealthy: true),
        // The guard drives `blueutil`; with the tool gone, the switch does nothing.
        "bluetoothGuard": GuardSources(sources: ["bluetoothBlueutil"], auxiliary: [], idleIsHealthy: false),
        // The error logs of nginx, Apache and PHP-FPM; with none to follow, a crashing worker is not seen.
        "webWorkerCrashWatch": GuardSources(sources: ["webWorkerCrashLogs"], auxiliary: [], idleIsHealthy: false),
        // `docker ps` is how the guard sees containers; without an answer it sees none.
        "dockerEventGuard": GuardSources(sources: ["dockerDaemon"], auxiliary: [], idleIsHealthy: false),
        // A batch scan (daily and on demand), so being idle between runs is healthy; what it can report is what the last
        // scan could not examine.
        "webRulesFolderScan": GuardSources(sources: ["webRuleFolderScan"], auxiliary: [], idleIsHealthy: true),
        // The Unified Log query (`log show`) of the scheduled and manual audit: a batch read, so idle is healthy; what it can
        // report is that the last query could not be read at all (`off`) or was cut short (`partial`).
        "scheduledLogAudit": GuardSources(sources: ["scheduledLogAudit"], auxiliary: [], idleIsHealthy: true),
    ]

    /// A gap this recent still marks the guard `partial`.
    public static let gapWindowSecs: Double = 86_400

    /// The records that belong to a guard, in `guardSources` order (required first, then auxiliary).
    public static func sourceIDs(forGuard guardKey: String) -> [String] {
        guard let def = guardSources[guardKey] else { return [] }
        return def.sources + def.auxiliary
    }

    /// `on`, `off`, `partial` or `unknown`.
    /// - toggle off -> `off`
    /// - a guard with no reader to check -> `on`
    /// - a required record missing -> `unknown` (never reported, so not shown as healthy)
    /// - a required reader that cannot read its source, or is not running when it should be -> `off`
    /// - input lost within the last day, or a narrower input down -> `partial`
    /// - otherwise `on`
    public static func guardLiveState(guardKey: String, enabledInSettings: Bool, records: [String: GuardReaderHealth], now: Double) -> String {
        guard enabledInSettings else { return "off" }
        guard let def = guardSources[guardKey] else { return "on" }
        let required = def.sources.map { records[$0] }
        if required.contains(where: { $0 == nil }) { return "unknown" }
        let healths = required.compactMap { $0 }
        if healths.contains(where: { $0.unreadable }) { return "off" }
        if !def.idleIsHealthy && healths.contains(where: { !$0.active }) { return "off" }
        // Input lost recently, or the last scan had to skip files it could not read.
        func lostRecently(_ h: GuardReaderHealth) -> Bool {
            h.inGap || (h.lastGapAt.map { now - $0 <= gapWindowSecs } ?? false)
                || (h.filesUnreadable ?? 0) > 0 || (h.foldersUnreadable ?? 0) > 0 || (h.filesTruncated ?? 0) > 0
                || h.scopeLimited == true
        }
        if healths.contains(where: lostRecently) { return "partial" }
        for id in def.auxiliary {
            // A missing auxiliary record is not held against the guard: it may simply not have started.
            guard let h = records[id] else { continue }
            if h.unreadable || lostRecently(h) { return "partial" }
        }
        return "on"
    }
}

/// Keeps one source's record: applies a change, stamps the time and hands the record to `persist`, at most
/// every five seconds unless `force`, with a trailing write so the last counter change is not left behind.
public final class GuardReaderHealthRecorder {
    public typealias Persist = (_ source: String, _ health: GuardReaderHealth) -> Void
    public static let minWriteInterval: Double = 5

    private let lock = NSLock()
    private var health: GuardReaderHealth
    private let source: String
    private let persist: Persist
    private var lastWriteAt: Double = 0
    private var flushScheduled = false
    private let flushQueue = DispatchQueue(label: "com.tetsuharu.RoamSwitch.readerHealthFlush")

    /// `prior` is the record the previous run of this process left. If it was meant to be running, its end
    /// was not clean and that interval is counted as a gap.
    public init(source: String, prior: GuardReaderHealth?, now: Double = Date().timeIntervalSince1970, persist: @escaping Persist) {
        self.source = source
        self.persist = persist
        var h = prior ?? GuardReaderHealth()
        h.markLostWhileProcessWasDown(now: now)
        health = h
        if prior != nil { persist(source, h); lastWriteAt = now }
    }

    /// A recorder for a reader that lives in the app; its record is kept in the shared preferences.
    public static func forApp(source: String, defaults: UserDefaults = .standard) -> GuardReaderHealthRecorder {
        GuardReaderHealthRecorder(source: source, prior: GuardReaderHealthStore.readApp(defaults: defaults)[source],
                                  persist: { GuardReaderHealthStore.writeApp(source: $0, health: $1, defaults: defaults) })
    }

    public var snapshot: GuardReaderHealth { lock.lock(); defer { lock.unlock() }; return health }

    public func update(now: Double = Date().timeIntervalSince1970, force: Bool = false, _ change: (inout GuardReaderHealth, Double) -> Void) {
        lock.lock()
        change(&health, now)
        health.updatedAt = now
        let snap = health
        let due = force || now - lastWriteAt >= Self.minWriteInterval
        if due { lastWriteAt = now }
        let needTrailing = !due && !flushScheduled
        if needTrailing { flushScheduled = true }
        lock.unlock()
        if due {
            persist(source, snap)
        } else if needTrailing {
            flushQueue.asyncAfter(deadline: .now() + Self.minWriteInterval) { [weak self] in self?.flush() }
        }
    }

    public func flush() {
        lock.lock()
        flushScheduled = false
        let snap = health
        lastWriteAt = max(lastWriteAt, health.updatedAt)
        lock.unlock()
        persist(source, snap)
    }
}

// MARK: - What a guard needs besides its toggle: Pro and the helper

/// What `get_guard_status` and `get_detection_coverage` know about the environment of the guards. The tool runs in
/// its own process, so it cannot ask the licence or the helper. It reads what the app saved: the Pro mirror
/// (`RoamSwitch.IsProCache`) and the helper-link record (`HelperLinkSnapshot`).
public struct GuardEnvironment: Equatable {
    public var isPro: Bool
    /// Whether the app has a working connection to the helper. `nil`: not known (the app has not written the record
    /// lately, so it may not be running).
    public var helperConnected: Bool?

    public init(isPro: Bool, helperConnected: Bool?) {
        self.isPro = isPro
        self.helperConnected = helperConnected
    }

    /// Nothing is checked: Pro and the helper are taken as present. For callers that only want the reader state.
    public static let unchecked = GuardEnvironment(isPro: true, helperConnected: true)

    public static let proCacheKey = "RoamSwitch.IsProCache"

    public static func read(defaults: UserDefaults, now: Date = Date()) -> GuardEnvironment {
        GuardEnvironment(isPro: defaults.bool(forKey: proCacheKey),
                         helperConnected: HelperLinkSnapshot.read(defaults: defaults, now: now.timeIntervalSince1970))
    }
}

/// Whether the app can reach the helper, written by the app (every minute and when its status changes) and read by
/// the MCP tool. A record that is older than `freshSecs` is not trusted: the app is probably not running.
public enum HelperLinkSnapshot {
    public static let defaultsKey = "RoamSwitch.HelperLinkV1"
    public static let freshSecs: Double = 180

    public static func write(connected: Bool?, now: Double, defaults: UserDefaults = .standard) {
        var record: [String: Any] = ["at": now]
        if let connected { record["connected"] = connected }
        defaults.set(record, forKey: defaultsKey)
    }

    /// `true` or `false` as the app last wrote it; `nil` when there is no record, it is stale, or the app did not know.
    public static func read(defaults: UserDefaults, now: Double) -> Bool? {
        guard let record = defaults.dictionary(forKey: defaultsKey),
              let at = record["at"] as? Double, now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return record["connected"] as? Bool
    }
}

extension GuardReaderHealthStore {

    public enum HelperNeed: Equatable {
        /// Works without the helper.
        case none
        /// Works without the helper, but with less (a response such as the Air-Gap, or the listeners of other users).
        case partial
        /// Sees nothing without the helper (the helper reads its input, or the guard is a setting the helper applies).
        case required
    }

    public struct Requirements: Equatable {
        public let pro: Bool
        public let helper: HelperNeed
    }

    /// What each guard of `get_guard_status` needs, read from the code of the guard (a `LicenseManager.shared.isPro` gate
    /// where it starts or runs; a call to the helper for its input or for its response). A guard that is not listed
    /// needs neither: `secretLeakClipboardAuditor`, `airGapAutoWiFiKill` (a setting, no gate of its own) and `activeVulnScan`.
    public static let guardRequirements: [String: Requirements] = [
        "portAnomalyGuard": Requirements(pro: true, helper: .partial),               // the listeners of other users come from the helper
        "portScanGuard": Requirements(pro: true, helper: .required),                 // pflog is captured by the helper
        "sshGuard": Requirements(pro: true, helper: .required),                      // the helper reads sshd's log
        "arpSpoofAutoContainment": Requirements(pro: true, helper: .partial),        // detection in the app; the Air-Gap is the helper's
        "usbKeyboardGuard": Requirements(pro: true, helper: .none),
        "usbStorageGuard": Requirements(pro: true, helper: .none),
        "bluetoothGuard": Requirements(pro: true, helper: .none),
        "webMailDownloadGuard": Requirements(pro: true, helper: .none),
        "dnsThreatGuard": Requirements(pro: true, helper: .required),                // the helper sets the DNS servers
        "runtimeThreatContainment": Requirements(pro: true, helper: .partial),       // the log is read in the app; the Air-Gap is the helper's
        "ransomwareCanaryGuard": Requirements(pro: true, helper: .partial),          // detection in the app; stopping the process and the Air-Gap are the helper's
        "ransomwareEntropyGuard": Requirements(pro: true, helper: .partial),
        "credentialHoneytokenGuard": Requirements(pro: true, helper: .none),
        "webWorkerCrashWatch": Requirements(pro: true, helper: .none),                   // the alert is Pro; there is no switch
        "agentSetupWatch": Requirements(pro: true, helper: .none),                       // the comparison and the notice are Pro; it needs an accepted state
        "browserCredentialWatchGuard": Requirements(pro: true, helper: .none),
        "reverseShellWatch": Requirements(pro: true, helper: .none),
        "networkSettingsWatch": Requirements(pro: true, helper: .none),
        "clickFixGuard": Requirements(pro: true, helper: .partial),
        "execRecorder": Requirements(pro: true, helper: .required),                  // the helper runs eslogger
        "dockerEventGuard": Requirements(pro: true, helper: .none),
        "criticalPathFim": Requirements(pro: true, helper: .required),               // the helper computes the hashes
        "lockfileTamperGuard": Requirements(pro: true, helper: .none),
        "npmSupplyWatch": Requirements(pro: true, helper: .none),                    // the comparison and the notice are Pro
        "dependencyWatch": Requirements(pro: true, helper: .none),                   // the comparison and the notice are Pro
        "configRegressionNotice": Requirements(pro: true, helper: .none),            // the notice is Pro (the history is recorded for everyone)
        "persistenceMonitor": Requirements(pro: true, helper: .none),
        "gatewayARPLock": Requirements(pro: true, helper: .required),                // the helper sets the static entry
        "scheduledLogAudit": Requirements(pro: true, helper: .none),
        "wireGuardVPN": Requirements(pro: true, helper: .required),                  // the helper brings the tunnel up
        "tailscaleKillSwitch": Requirements(pro: true, helper: .required),           // the helper applies the kill switch
        "linkGuard": Requirements(pro: true, helper: .none),
        "linkGuardFeedUpdates": Requirements(pro: true, helper: .none),
        "webRulesFolderScan": Requirements(pro: true, helper: .none),
    ]

    /// Folds Pro and the helper into the state the reader records gave (`guardLiveState`), and says why.
    /// - the toggle is off: `off`, no reason;
    /// - Pro is needed and the Pro mirror is not set: `off`, `pro_not_active` (whatever the readers say);
    /// - the helper is needed (`required`) and the app says it is not connected: `off`, `helper_not_connected`; when the
    ///   app has not said (no fresh record): `unknown`, `helper_status_unknown`;
    /// - the helper is needed for a part (`partial`) and the app says it is not connected: `on` becomes `partial`,
    ///   `helper_not_connected`. An unknown helper does not change a guard that only needs it for a response;
    /// - otherwise the state of the readers.
    public static func applyingEnvironment(guardKey: String, enabledInSettings: Bool, state: String,
                                           environment: GuardEnvironment) -> (state: String, reason: String?) {
        guard enabledInSettings, let need = guardRequirements[guardKey] else { return (state, nil) }
        if need.pro && !environment.isPro { return ("off", "pro_not_active") }
        switch need.helper {
        case .none:
            return (state, nil)
        case .required:
            if environment.helperConnected == false { return ("off", "helper_not_connected") }
            if environment.helperConnected == nil { return state == "off" ? (state, nil) : ("unknown", "helper_status_unknown") }
            return (state, nil)
        case .partial:
            if environment.helperConnected == false && state == "on" { return ("partial", "helper_not_connected") }
            return (state, nil)
        }
    }
}
