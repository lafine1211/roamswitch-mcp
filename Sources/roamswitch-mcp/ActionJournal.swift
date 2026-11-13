// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.35 (build 214).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// The automatic and manual containment actions the journal records (adoption plan 2026-11-12, #11). The raw values
/// are the names in the file and are shared with the Linux build (`docs/p1_design_mac.md`).
public enum JournalAction: String, Codable, CaseIterable, Sendable {
    /// An SSH brute-force source banned in pf (`SSHGuardDetector`).
    case sshBan = "ssh_ban"
    /// A port-scan source blocked in pf (`PortScanDetector`).
    case portScanBlock = "port_scan_block"
    /// The emergency air-gap (pf `block drop all`).
    case airGap = "airgap"
    /// A process paused with SIGSTOP.
    case freeze = "freeze"
    /// A web server account whose login shell was taken away (`WebAccountLockService`).
    case webAccountLock = "web_account_lock"
    /// A file moved into the quarantine folder (`QuarantineManager`). Written by the app, in its own journal.
    case quarantine = "quarantine"

    /// The actions network recovery takes back in reverse order. Freezes, account locks and quarantined files are
    /// not network changes: they are released by a person from their own screens.
    public static let networkActions: Set<JournalAction> = [.sshBan, .portScanBlock, .airGap]
}

public enum JournalPhase: String, Codable, Sendable {
    case begin
    /// Carried out, and the state read back afterwards shows it.
    case done
    /// Tried, and not in effect.
    case failed
    /// Not tried: a safety rule (the gateway, this Mac) or the automatic action budget said no.
    case refused
    /// Taken back by network recovery.
    case undone
    /// Network recovery tried to take it back and could not.
    case undoFailed = "undo_failed"

    public var isTerminal: Bool { self != .begin }
}

public enum JournalOrigin: String, Codable, Sendable {
    /// Decided by a guard on its own.
    case auto
    /// Asked for by a person.
    case manual
}

/// One line of the journal. Every line repeats the action, the target and the origin, so a line read alone says what
/// it is about.
public struct JournalRecord: Codable, Equatable, Sendable {
    public var id: String
    public var at: Date
    public var phase: JournalPhase
    public var action: JournalAction
    public var target: String
    public var origin: JournalOrigin
    /// What set it off (`AirGapTrigger` raw value, a detector name); nil when not known.
    public var trigger: String?
    /// Why it ended this way, in English (a log line, never shown as it is).
    public var detail: String?

    public init(id: String, at: Date, phase: JournalPhase, action: JournalAction, target: String,
                origin: JournalOrigin, trigger: String? = nil, detail: String? = nil) {
        self.id = id
        self.at = at
        self.phase = phase
        self.action = action
        self.target = target
        self.origin = origin
        self.trigger = trigger
        self.detail = detail
    }
}

/// The append-only journal of containment actions: `begin` before an action, then `done`, `failed` or `refused`.
/// One JSON object per line. An action whose last line is still `begin` (the process ended in between) is `pending`;
/// `reverifyPending` settles it from the state read at start.
///
/// The helper's file is in its root-owned state folder (0600) and is trusted only when it is a regular file owned by
/// `expectedOwner` that no other account can write; an untrusted file is neither read nor appended to.
public final class ActionJournal {
    public static let helperPath = "/Library/Application Support/RoamSwitch/action_journal.jsonl"
    /// Past this size the file is rewritten with the newest actions (and every pending one).
    static let compactAboveBytes = 512 * 1024
    static let keepActionsWhenCompacting = 500
    static let maxReadBytes = 4 * 1024 * 1024

    private let path: String
    private let expectedOwner: uid_t
    private let now: () -> Date
    private let lock = NSLock()

    public init(path: String = ActionJournal.helperPath, expectedOwner: uid_t = 0, now: @escaping () -> Date = Date.init) {
        self.path = path
        self.expectedOwner = expectedOwner
        self.now = now
    }

    // MARK: - Writing

    /// Writes `begin` and returns the id the later line uses.
    @discardableResult
    public func begin(_ action: JournalAction, target: String, origin: JournalOrigin, trigger: String? = nil) -> String {
        let id = UUID().uuidString
        append(JournalRecord(id: id, at: now(), phase: .begin, action: action, target: target, origin: origin, trigger: trigger))
        return id
    }

    /// Writes the outcome of the action `id` began.
    public func finish(_ id: String, _ phase: JournalPhase, detail: String? = nil) {
        lock.lock()
        let first = readLocked().first { $0.id == id }
        lock.unlock()
        guard let first else { return }
        var record = first
        record.at = now()
        record.phase = phase
        record.detail = detail
        append(record)
    }

    /// `begin` and `refused` at once, for an action that is not tried at all.
    @discardableResult
    public func refuse(_ action: JournalAction, target: String, origin: JournalOrigin, trigger: String?, detail: String) -> String {
        let id = begin(action, target: target, origin: origin, trigger: trigger)
        finish(id, .refused, detail: detail)
        return id
    }

    private func append(_ record: JournalRecord) {
        lock.lock(); defer { lock.unlock() }
        guard var line = try? Self.encoder.encode(record) else { return }
        line.append(0x0A)
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let fd = open(path, O_WRONLY | O_APPEND | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { return }
        defer { close(fd) }
        var st = stat()
        guard fstat(fd, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG, st.st_uid == expectedOwner, (st.st_mode & 0o022) == 0 else { return }
        _ = line.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        _ = fsync(fd)
        if Int(st.st_size) + line.count > Self.compactAboveBytes { compactLocked() }
    }

    /// Rewrites the file with the newest actions (at most `keepActionsWhenCompacting`, in half the size limit) and every
    /// pending one (temporary file, then rename). Must hold `lock`.
    private func compactLocked() {
        let records = readLocked()
        let byID = Dictionary(grouping: records, by: \.id)
        let pendingIDs = Set(byID.filter { $0.value.last?.phase == .begin }.keys)
        // Newest actions first, while they fit in half the limit (so the file does not fill up again at once).
        var keep = pendingIDs
        var bytes = 0
        var seen = Set<String>()
        for record in records.reversed() where seen.insert(record.id).inserted {
            let size = (byID[record.id] ?? []).reduce(0) { $0 + ((try? Self.encoder.encode($1).count) ?? 0) + 1 }
            guard seen.count <= Self.keepActionsWhenCompacting, bytes + size <= Self.compactAboveBytes / 2 else { break }
            bytes += size
            keep.insert(record.id)
        }
        var data = Data()
        for record in records where keep.contains(record.id) {
            guard let line = try? Self.encoder.encode(record) else { continue }
            data.append(line)
            data.append(0x0A)
        }
        let temp = path + ".tmp-\(getpid())"
        unlink(temp)
        let fd = open(temp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { return }
        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        _ = fsync(fd)
        close(fd)
        guard written == data.count, rename(temp, path) == 0 else { unlink(temp); return }
    }

    // MARK: - Reading

    /// Every line in order. Lines that do not decode are skipped (a line cut short by a crash is the last one).
    public func read() -> [JournalRecord] {
        lock.lock(); defer { lock.unlock() }
        return readLocked()
    }

    private func readLocked() -> [JournalRecord] {
        let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { return [] }
        defer { close(fd) }
        var st = stat()
        guard fstat(fd, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG, st.st_uid == expectedOwner, (st.st_mode & 0o022) == 0,
              st.st_size <= off_t(Self.maxReadBytes) else { return [] }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let n = Darwin.read(fd, &buffer, buffer.count)
            if n <= 0 { break }
            data.append(buffer, count: n)
        }
        return data.split(separator: 0x0A).compactMap { try? Self.decoder.decode(JournalRecord.self, from: Data($0)) }
    }

    /// The latest line of every action, oldest action first.
    public func latest() -> [JournalRecord] {
        Self.latest(of: read())
    }

    public static func latest(of records: [JournalRecord]) -> [JournalRecord] {
        var order: [String] = []
        var last: [String: JournalRecord] = [:]
        for record in records {
            if last[record.id] == nil { order.append(record.id) }
            last[record.id] = record
        }
        return order.compactMap { last[$0] }
    }

    /// Actions whose last line is `begin`.
    public func pending() -> [JournalRecord] {
        latest().filter { $0.phase == .begin }
    }

    /// Settles every pending action from the state read now: in effect -> `done`, not in effect -> `failed`, cannot
    /// tell (nil) -> `failed` with that said. Run once when the helper starts. Returns what was settled.
    @discardableResult
    public func reverifyPending(inEffect: (JournalRecord) -> Bool?) -> [JournalRecord] {
        var settled: [JournalRecord] = []
        for record in pending() {
            switch inEffect(record) {
            case true?: finish(record.id, .done, detail: "reverified at start: in effect")
            case false?: finish(record.id, .failed, detail: "reverified at start: not in effect")
            case nil: finish(record.id, .failed, detail: "reverified at start: state could not be read")
            }
            settled.append(record)
        }
        return settled
    }

    /// What network recovery takes back: actions in `actions` whose last line is `done` and that are still in effect,
    /// newest first (the reverse of the order they were carried out).
    public func undoPlan(actions: Set<JournalAction>, inEffect: (JournalRecord) -> Bool) -> [JournalRecord] {
        latest().filter { $0.phase == .done && actions.contains($0.action) && inEffect($0) }.reversed()
    }

    /// How many automatic actions in `actions` were carried out (or are still under way) since `since`. Failed and
    /// refused attempts do not count: they changed nothing.
    public func automaticCount(of actions: Set<JournalAction>, since: Date) -> Int {
        Self.automaticCount(in: read(), of: actions, since: since)
    }

    /// The detail of a `done` line for an action asked for again while it already held (the air-gap applied again).
    /// It is not counted against the automatic action budget.
    public static let reappliedDetail = "reapplied while already in effect"

    public static func automaticCount(in records: [JournalRecord], of actions: Set<JournalAction>, since: Date) -> Int {
        let begins = Dictionary(records.filter { $0.phase == .begin }.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return latest(of: records).filter { record in
            guard let begin = begins[record.id] else { return false }
            return begin.origin == .auto && actions.contains(begin.action) && begin.at >= since
                && record.detail != reappliedDetail
                && [.begin, .done, .undone, .undoFailed].contains(record.phase)
        }.count
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
