// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.3 (build 60).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `RuntimeThreatContainmentManager`'s
/// on-disk state — used by `RoamSwitchMCPServer`, mirroring
/// `CanaryStatusReader`/`PortAnomalyStatusReader`. Unlike those, this only
/// ever tracks a single latest incident (not a history array) — deliberate
/// scope decision, since `isIsolated` toggles off before a second one could
/// occur.
enum RuntimeThreatStatusReader {
    private static let enabledKey = "RoamSwitch.RuntimeThreatContainmentEnabled"
    private static let isolatedKey = "RoamSwitch.RuntimeThreatContainment.IsIsolated"
    private static let lastContainmentDateKey = "RoamSwitch.RuntimeThreatContainment.LastContainmentDate"
    private static let lastIncidentKey = "RoamSwitch.RuntimeThreatContainment.LastIncidentV1"

    /// `defaults` must be the app's real shared preferences domain — see
    /// `CanaryStatusReader`'s doc comment for why `RoamSwitchMCPServer` must
    /// pass the shared-suite instance rather than `UserDefaults.standard`.
    static func currentStatus(defaults: UserDefaults = .standard) -> (isEnabled: Bool, isIsolated: Bool, lastContainmentDate: Date?, lastIncident: SecurityLogEvent?) {
        let isEnabled = defaults.bool(forKey: enabledKey)
        let isIsolated = defaults.bool(forKey: isolatedKey)
        let lastContainmentDate: Date?
        if defaults.object(forKey: lastContainmentDateKey) != nil {
            lastContainmentDate = Date(timeIntervalSince1970: defaults.double(forKey: lastContainmentDateKey))
        } else {
            lastContainmentDate = nil
        }
        let lastIncident: SecurityLogEvent?
        if let data = defaults.data(forKey: lastIncidentKey) {
            lastIncident = try? JSONDecoder().decode(SecurityLogEvent.self, from: data)
        } else {
            lastIncident = nil
        }
        return (isEnabled, isIsolated, lastContainmentDate, lastIncident)
    }
}
