// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.1 (build 180).
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
            retentionMode: RansomwareSnapshotPolicy.isRetentionMode(checked, now: now),
            lastFailure: RansomwareSnapshotFailureStore.read(defaults: defaults)
        )
    }
}
