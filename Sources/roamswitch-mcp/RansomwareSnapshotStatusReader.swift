// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.51 (build 108).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// `tmutil` for local APFS snapshots. Creating, listing and deleting them work
/// without root and without Time Machine being set up (checked on a real Mac,
/// macOS 27). Dependency-free so `RoamSwitchMCPServer` can use it too.
enum TmutilRunner {
    static func run(_ arguments: [String]) -> (status: Int32, output: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        p.arguments = arguments
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (-1, "\(error)") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    /// Ids of the local snapshots that exist right now, or nil if `tmutil` failed.
    static func presentSnapshotIDs() -> Set<String>? {
        let (status, out) = run(["listlocalsnapshotdates", "/"])
        return status == 0 ? RansomwareSnapshotPolicy.ids(fromListOutput: out) : nil
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
    }

    /// `presentIDs` is injectable so tests never touch the real snapshots.
    static func currentStatus(defaults: UserDefaults = .standard, now: Date = Date(), presentIDs: Set<String>? = TmutilRunner.presentSnapshotIDs()) -> Status {
        var records: [RansomwareSnapshot] = []
        if let data = defaults.data(forKey: recordsKey), let decoded = try? JSONDecoder().decode([RansomwareSnapshot].self, from: data) {
            records = decoded
        }
        // If `tmutil` could not be run, keep the stored flags rather than guess.
        let checked = presentIDs.map { RansomwareSnapshotPolicy.merge(records, presentIDs: $0, now: now) }
            ?? records.sorted { $0.createdAt > $1.createdAt }
        let stored = defaults.object(forKey: intervalKey) as? Int
        let hours = stored.flatMap { RansomwareSnapshotPolicy.intervalHourChoices.contains($0) ? $0 : nil } ?? RansomwareSnapshotPolicy.defaultIntervalHours
        return Status(
            snapshots: checked,
            recommendedID: RansomwareSnapshotPolicy.recommended(from: checked)?.id,
            intervalHours: hours,
            retentionMode: RansomwareSnapshotPolicy.isRetentionMode(checked, now: now)
        )
    }
}
