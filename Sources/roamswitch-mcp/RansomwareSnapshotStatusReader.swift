// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.6 (build 230).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// `tmutil` for local APFS snapshots. Creating, listing and deleting them work
/// without root and without Time Machine being set up (checked on a real Mac,
/// macOS 27). Dependency-free so `RoamSwitchMCPServer` can use it too.
enum TmutilRunner {
    /// Creating or deleting a local snapshot flushes the volume: 120 s. Listing them reads the snapshot list: 30 s. A call that
    /// does not finish is ended with what it started (TimedProcess) and is a failure (status -1) with a text that says so, never
    /// a success. stdout and stderr are one text, as before.
    static func timeout(for arguments: [String]) -> TimeInterval {
        switch arguments.first {
        case "localsnapshot", "deletelocalsnapshots": return 120
        default: return 30
        }
    }

    static func run(_ arguments: [String]) -> (status: Int32, output: String) {
        let limit = timeout(for: arguments)
        guard let r = TimedProcess.run("/usr/bin/tmutil", arguments, mergeStderr: true, timeout: limit, outputLimit: 1 << 20) else {
            return (-1, "could not start /usr/bin/tmutil")
        }
        if r.timedOut { return (-1, r.stdoutText + "\ntmutil did not finish in \(Int(limit)) s and was ended") }
        return (r.status, r.stdoutText)
    }

    /// Ids of the local snapshots that exist right now, or nil if `tmutil` failed.
    static func presentSnapshotIDs() -> Set<String>? {
        let (status, out) = run(["listlocalsnapshotdates", "/"])
        return status == 0 ? RansomwareSnapshotPolicy.ids(fromListOutput: out) : nil
    }
}

/// The last failure to take a snapshot (`tmutil localsnapshot`), kept in the preferences so the recovery window, the
/// notice and the MCP tool (a separate process) all say the same thing. Cleared by the next success.
struct RansomwareSnapshotFailure: Equatable {
    let message: String
    let at: Date
    /// Failures in a row, including this one.
    let consecutive: Int
}

enum RansomwareSnapshotFailureStore {
    static let key = "RoamSwitch.RansomwareSnapshots.LastFailureV1"
    static let maxMessageLength = 300

    /// One line, no control characters, capped: the text comes from a tool's output.
    static func cleaned(_ raw: String) -> String {
        let flat = raw.unicodeScalars.map { $0.value < 0x20 || $0.value == 0x7F ? " " : String($0) }.joined()
        let collapsed = flat.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        return String(collapsed.prefix(maxMessageLength))
    }

    @discardableResult
    static func record(message: String, at: Date, defaults: UserDefaults) -> RansomwareSnapshotFailure {
        let previous = read(defaults: defaults)?.consecutive ?? 0
        let cleanedMessage = cleaned(message)
        let failure = RansomwareSnapshotFailure(message: cleanedMessage.isEmpty ? "tmutil" : cleanedMessage, at: at, consecutive: previous + 1)
        defaults.set(["message": failure.message, "at": at.timeIntervalSince1970, "consecutive": failure.consecutive] as [String: Any], forKey: key)
        return failure
    }

    static func clear(defaults: UserDefaults) { defaults.removeObject(forKey: key) }

    static func read(defaults: UserDefaults) -> RansomwareSnapshotFailure? {
        guard let d = defaults.dictionary(forKey: key), let message = d["message"] as? String, let at = d["at"] as? Double else { return nil }
        return RansomwareSnapshotFailure(message: message, at: Date(timeIntervalSince1970: at), consecutive: (d["consecutive"] as? Int) ?? 1)
    }
}

/// Minimal, dependency-free reader of `RansomwareSnapshotManager`'s state for
/// `RoamSwitchMCPServer` (same convention as `CanaryStatusReader`: the keys are
/// duplicated rather than shared). Read-only: it never creates, deletes or
/// mounts anything.
enum RansomwareSnapshotStatusReader {
    private static let recordsKey = "RoamSwitch.RansomwareSnapshots.RecordsV1"
    private static let intervalKey = "RoamSwitch.RansomwareSnapshots.IntervalHours"

    struct Status {
        let snapshots: [RansomwareSnapshot]          // newest first, `exists` re-checked against the disk
        let recommendedID: String?
        let intervalHours: Int
        let retentionMode: Bool
        /// The last attempt to take a snapshot failed (nil after a success, or if none failed).
        let lastFailure: RansomwareSnapshotFailure?
        /// The stored records could not be read: `snapshots` is empty because nothing was read.
        var recordsUnreadable = false
    }

    /// `presentIDs` is injectable so tests never touch the real snapshots.
    static func currentStatus(defaults: UserDefaults = .standard, now: Date = Date(), presentIDs: Set<String>? = TmutilRunner.presentSnapshotIDs()) -> Status {
        let read = StoredRecordDefaults.peek([RansomwareSnapshot].self, key: recordsKey, defaults: defaults)
        let records = read.value(or: [])
        // If `tmutil` could not be run, keep the stored flags rather than guess.
        let checked = presentIDs.map { RansomwareSnapshotPolicy.merge(records, presentIDs: $0, now: now) }
            ?? records.sorted { $0.createdAt > $1.createdAt }
        let stored = defaults.object(forKey: intervalKey) as? Int
        let hours = stored.flatMap { RansomwareSnapshotPolicy.intervalHourChoices.contains($0) ? $0 : nil } ?? RansomwareSnapshotPolicy.defaultIntervalHours
        return Status(
            snapshots: checked,
            recommendedID: RansomwareSnapshotPolicy.recommended(from: checked)?.id,
            intervalHours: hours,
            retentionMode: RansomwareSnapshotPolicy.isRetentionMode(checked, now: now),
            lastFailure: RansomwareSnapshotFailureStore.read(defaults: defaults),
            recordsUnreadable: read.isUnreadable
        )
    }
}
