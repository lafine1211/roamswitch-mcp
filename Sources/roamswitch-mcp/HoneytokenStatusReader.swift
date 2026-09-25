// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.4 (build 122).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `CredentialHoneytokenGuard`'s
/// on-disk state — same rationale as `CanaryStatusReader`/
/// `RansomwareEntropyStatusReader`: the bare MCP server process can't
/// reuse the full `@MainActor`-isolated guard class (it depends on
/// `LicenseManager`, itself requiring app-level context this process
/// lacks).
enum HoneytokenStatusReader {
    private static let enabledKey = "RoamSwitch.CredentialHoneytokenGuardEnabled"
    private static let persistedEventsKey = "RoamSwitch.HoneytokenAccessEventsV1"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    static func persistedEvents(defaults: UserDefaults = .standard) -> [PersistedHoneytokenEvent] {
        guard let data = defaults.data(forKey: persistedEventsKey),
              let decoded = try? JSONDecoder().decode([PersistedHoneytokenEvent].self, from: data) else {
            return []
        }
        return decoded
    }
}

/// Field-for-field mirror of `HoneytokenAccessEvent`'s `Codable` shape —
/// duplicated per this codebase's established convention (see
/// `PersistedCanaryIncident`).
struct PersistedHoneytokenEvent: Codable {
    let timestamp: Date
    let path: String
    let kind: String
    let suspectedProcess: String
}
