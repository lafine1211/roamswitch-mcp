// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.34 (build 213).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The app's own action journal (`ActionJournal`, same format as the helper's): the quarantine moves, which the app
/// carries out itself. In the user's Application Support folder, owned by the user.
enum AppActionJournal {
    static let path: String = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("RoamSwitch/action_journal.jsonl").path
    }()

    static let shared = ActionJournal(path: path, expectedOwner: getuid())

    /// Settles the moves a quit or crash left pending: done when the original file is gone and the vault holds a
    /// record of it, failed otherwise.
    static func reverifyAtStart(quarantine: QuarantineManager = .shared) {
        let held = Set(quarantine.listQuarantinedFiles().map(\.originalPath))
        shared.reverifyPending { record in
            guard record.action == .quarantine else { return nil }
            return held.contains(record.target) && !FileManager.default.fileExists(atPath: record.target)
        }
    }
}
