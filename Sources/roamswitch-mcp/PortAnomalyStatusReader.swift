// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.22 (build 79).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `PortAnomalyGuard`'s on-disk state —
/// used by `RoamSwitchMCPServer`, which can't reuse the full
/// `@MainActor`-isolated `PortAnomalyGuard` class directly. Keys are
/// duplicated from that type rather than shared, same convention as
/// `CanaryStatusReader`, to keep this reader dependency-free.
enum PortAnomalyStatusReader {
    private static let enabledKey = "RoamSwitch.PortAnomalyGuardEnabled"
    private static let baselineCapturedKey = "RoamSwitch.PortAnomalyGuard.BaselineCapturedV2"
    private static let autoIsolatedPortsKey = "RoamSwitch.PortAnomalyGuard.AutoIsolatedPorts"
    private static let persistedIncidentsKey = "RoamSwitch.PortAnomalyGuard.RecentIncidentsV1"

    /// `defaults` must be the app's real shared preferences domain — see
    /// `CanaryStatusReader`'s doc comment for why `RoamSwitchMCPServer` must
    /// pass the shared-suite instance rather than `UserDefaults.standard`.
    static func currentStatus(defaults: UserDefaults = .standard) -> (isEnabled: Bool, baselineCaptured: Bool, autoIsolatedPorts: [Int]) {
        let isEnabled = defaults.bool(forKey: enabledKey)
        let baselineCaptured = defaults.bool(forKey: baselineCapturedKey)
        let ports = defaults.array(forKey: autoIsolatedPortsKey) as? [Int] ?? []
        return (isEnabled, baselineCaptured, ports.sorted())
    }

    static func persistedIncidents(defaults: UserDefaults = .standard) -> [PersistedPortAnomalyIncident] {
        guard let data = defaults.data(forKey: persistedIncidentsKey),
              let decoded = try? JSONDecoder().decode([PersistedPortAnomalyIncident].self, from: data) else {
            return []
        }
        return decoded
    }
}

/// Field-for-field mirror of `PortAnomalyIncident`'s `Codable` shape,
/// duplicated rather than shared to keep this reader dependency-free — see
/// `CanaryStatusReader.PersistedCanaryIncident` for the same convention.
struct PersistedPortAnomalyIncident: Codable {
    let timestamp: Date
    let port: Int
    let processName: String
    let pid: Int
    let executablePath: String?
}
