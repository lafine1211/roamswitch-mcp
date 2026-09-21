// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.50 (build 107).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Pure logic of the ransomware recovery snapshots (no I/O), shared by the app,
// the privileged helper and the tests.
//
// Design (same decisions as the Linux edition's `roamswitch-ransomware-rollback`):
// - A snapshot taken when a detection fires already contains files encrypted
//   *before* the detection, so it is not a way back. Pre-damage snapshots are
//   therefore taken on a schedule, independent of any detection.
// - Recovery is always manual, and file-level: files are copied out to another
//   place, never restored over the current state.
// - While a detection snapshot is newer than the last pre-damage one, new
//   pre-damage snapshots and pruning stop (retention mode), so the encrypted
//   state cannot push out the last pre-encryption generation.
//
// macOS specifics (checked on a real Mac, macOS 27): `tmutil localsnapshot`
// creates `com.apple.TimeMachine.<yyyy-MM-dd-HHmmss>.local` on the data
// volume without root and without Time Machine configured, and macOS may purge
// local snapshots on its own (about 24 hours, sooner when space is low), so a
// record can outlive its snapshot: `exists` says whether it is still there.

enum RansomwareSnapshotKind: String, Codable, CaseIterable {
    /// Taken on a schedule, independent of any detection.
    case preDamage = "pre_damage"
    /// Taken when the canary guard fired. Contains anything encrypted before
    /// the detection, so it is NOT a source to recover from.
    case detection = "detection"
    /// Taken by hand.
    case manual = "manual"
}

struct RansomwareSnapshot: Codable, Equatable, Identifiable {
    /// The `tmutil` date, e.g. "2026-09-21-083213".
    let id: String
    var kind: RansomwareSnapshotKind
    let createdAt: Date
    /// False once macOS (or anyone) removed the snapshot.
    var exists: Bool

    /// Name as `mount_apfs -s` and `diskutil apfs listSnapshots` show it.
    var snapshotName: String { RansomwareSnapshotPolicy.snapshotName(forID: id) }
}

enum RansomwareSnapshotPolicy {
    /// Interval choices in hours; 0 turns scheduled snapshots off.
    static let intervalHourChoices: [Int] = [0, 1, 3, 6, 12, 24]
    static let defaultIntervalHours = 6
    /// Shortest interval that is accepted, in seconds.
    static let minimumIntervalSeconds: TimeInterval = 300
    /// How many pre-damage snapshots are kept (the OS may keep fewer).
    static let defaultKeepPreDamage = 4
    /// Retention mode lasts this long after a detection snapshot.
    static let retentionDays = 7
    /// Minimum gap between detection snapshots (not shared with pre-damage).
    static let detectionCooldownSeconds: TimeInterval = 300

    // MARK: - Names and dates

    static func snapshotName(forID id: String) -> String { "com.apple.TimeMachine.\(id).local" }

    /// `com.apple.TimeMachine.2026-09-21-083213.local` -> `2026-09-21-083213`.
    static func id(fromSnapshotName name: String) -> String? {
        let prefix = "com.apple.TimeMachine."
        let suffix = ".local"
        guard name.hasPrefix(prefix), name.hasSuffix(suffix), name.count > prefix.count + suffix.count else { return nil }
        let id = String(name.dropFirst(prefix.count).dropLast(suffix.count))
        return date(fromID: id) == nil ? nil : id
    }

    /// `tmutil` writes the local time of the snapshot.
    static func date(fromID id: String, timeZone: TimeZone = .current) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.date(from: id)
    }

    // MARK: - `tmutil` output

    /// `Created local snapshot with date: 2026-09-21-083213` -> the id.
    static func id(fromCreateOutput output: String) -> String? {
        for line in output.split(whereSeparator: \.isNewline) {
            guard let range = line.range(of: "Created local snapshot with date:") else { continue }
            let id = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if date(fromID: id) != nil { return id }
        }
        return nil
    }

    /// Ids listed by `tmutil listlocalsnapshotdates /` (a header line, then one
    /// date per line). Anything that is not a valid date is ignored.
    static func ids(fromListOutput output: String) -> Set<String> {
        Set(output.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { date(fromID: $0) != nil })
    }

    // MARK: - Keeping the records in step with what is on disk

    /// How long a record is kept after its snapshot is gone (macOS purges local
    /// snapshots on its own), so that retention mode and the history still know
    /// about it.
    static let recordKeepDays = 30

    /// Marks each record as existing or not according to `presentIDs`, and drops
    /// records older than `recordKeepDays`. Snapshots that are on disk but were
    /// not made by RoamSwitch (Time Machine's own, for example) are not adopted.
    static func merge(_ records: [RansomwareSnapshot], presentIDs: Set<String>, now: Date) -> [RansomwareSnapshot] {
        let cutoff = now.addingTimeInterval(-TimeInterval(recordKeepDays) * 86_400)
        return records
            .filter { $0.createdAt >= cutoff }
            .map { var r = $0; r.exists = presentIDs.contains($0.id); return r }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Interval setting

    /// Seconds for a chosen number of hours, or nil when scheduled snapshots are
    /// off (0) or the value is not accepted (not a choice, or under 300 s).
    static func intervalSeconds(hours: Int) -> TimeInterval? {
        guard hours > 0, intervalHourChoices.contains(hours) else { return nil }
        let seconds = TimeInterval(hours) * 3600
        return seconds >= minimumIntervalSeconds ? seconds : nil
    }

    // MARK: - Choosing the snapshot to recover from

    /// The newest pre-damage snapshot that still exists. Detection snapshots are
    /// never recommended: they may already hold encrypted files.
    static func recommended(from snapshots: [RansomwareSnapshot]) -> RansomwareSnapshot? {
        snapshots
            .filter { $0.kind == .preDamage && $0.exists }
            .max(by: { $0.createdAt < $1.createdAt })
    }

    // MARK: - Retention mode

    /// True while a detection snapshot is newer than the newest pre-damage one
    /// (whether or not that one still exists) and not older than `retentionDays`.
    static func isRetentionMode(_ snapshots: [RansomwareSnapshot], now: Date, retentionDays: Int = retentionDays) -> Bool {
        guard let detection = snapshots.filter({ $0.kind == .detection }).max(by: { $0.createdAt < $1.createdAt }) else { return false }
        if let lastPre = snapshots.filter({ $0.kind == .preDamage }).map(\.createdAt).max(), lastPre >= detection.createdAt {
            return false
        }
        return now.timeIntervalSince(detection.createdAt) < TimeInterval(retentionDays) * 86_400
    }

    // MARK: - Scheduling

    /// Whether a pre-damage snapshot is due now. After a restart or wake this
    /// is simply "the newest one is older than the interval (or none exists)",
    /// so a missed slot is taken up at once.
    static func shouldTakePreDamage(_ snapshots: [RansomwareSnapshot], now: Date, intervalHours: Int) -> Bool {
        guard let interval = intervalSeconds(hours: intervalHours) else { return false }
        if isRetentionMode(snapshots, now: now) { return false }
        guard let newest = snapshots.filter({ $0.kind == .preDamage && $0.exists }).map(\.createdAt).max() else { return true }
        return now.timeIntervalSince(newest) >= interval
    }

    /// Detection snapshots have their own cooldown so that a pre-damage
    /// snapshot never suppresses one taken because of a detection.
    static func shouldTakeDetection(lastDetectionAt: Date?, now: Date) -> Bool {
        guard let last = lastDetectionAt else { return true }
        return now.timeIntervalSince(last) >= detectionCooldownSeconds
    }

    // MARK: - Pruning

    /// Pre-damage snapshots to delete so that `keep` remain, oldest first. Only
    /// pre-damage ones are ever chosen (manual and detection snapshots are
    /// kept), and nothing is chosen in retention mode.
    static func pruneCandidates(_ snapshots: [RansomwareSnapshot], now: Date, keep: Int = defaultKeepPreDamage) -> [RansomwareSnapshot] {
        if isRetentionMode(snapshots, now: now) { return [] }
        let pre = snapshots.filter { $0.kind == .preDamage && $0.exists }.sorted { $0.createdAt > $1.createdAt }
        guard pre.count > keep else { return [] }
        return Array(pre.dropFirst(max(keep, 0)).reversed())
    }
}

// MARK: - Extraction result (helper -> app)

struct RansomwareSnapshotExtractItem: Codable, Equatable {
    let source: String
    /// Where the copy went (nil when it failed or was skipped).
    let destination: String?
    /// Why nothing was copied (nil on success).
    let error: String?
}

// MARK: - Extraction paths

enum RansomwareSnapshotPath {
    /// Turns an absolute path of a file on the data volume into the path inside
    /// the mounted snapshot (`/Users/a/x.txt` -> `Users/a/x.txt`). Rejects
    /// anything that could leave the snapshot: relative paths, `..`, NUL, empty.
    static func relativeInsideSnapshot(_ absolutePath: String) -> String? {
        guard absolutePath.hasPrefix("/"), !absolutePath.contains("\0") else { return nil }
        let parts = absolutePath.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard !parts.isEmpty, !parts.contains(".."), !parts.contains(".") else { return nil }
        return parts.joined(separator: "/")
    }

    /// True when `resolved` (the real path after following symlinks) is `root`
    /// itself or inside it. A symlink that points out of the snapshot resolves
    /// to a path that is not.
    static func isInside(resolved: String, root: String) -> Bool {
        let r = root.hasSuffix("/") ? String(root.dropLast()) : root
        return resolved == r || resolved.hasPrefix(r + "/")
    }

    /// First free name for `baseName` inside `directory`: `name`, `name (1)`,
    /// `name (2)` ... (before the extension). Never returns an existing path, so
    /// nothing is ever overwritten.
    static func uniqueName(baseName: String, exists: (String) -> Bool) -> String {
        if !exists(baseName) { return baseName }
        let ns = baseName as NSString
        let ext = ns.pathExtension
        let stem = ext.isEmpty ? baseName : ns.deletingPathExtension
        var i = 1
        while true {
            let candidate = ext.isEmpty ? "\(stem) (\(i))" : "\(stem) (\(i)).\(ext)"
            if !exists(candidate) { return candidate }
            i += 1
        }
    }
}
