// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.2 (build 120).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `RansomwareEntropyGuard`'s on-disk
/// state — used by `RoamSwitchMCPServer`, which can't reuse the full
/// `@MainActor`-isolated `RansomwareEntropyGuard` class directly (same
/// reason as `CanaryStatusReader`: it depends on `LicenseManager`, itself
/// `@MainActor` and requiring app-level Keychain/NSAlert context the bare
/// MCP server process doesn't have).
enum RansomwareEntropyStatusReader {
    private static let enabledKey = "RoamSwitch.RansomwareEntropyGuardEnabled"
    /// Mirrors `RansomwareEntropyGuard.persistedAlertsKey` — duplicated
    /// rather than shared, same convention as `CanaryStatusReader`, to keep
    /// this reader dependency-free.
    private static let persistedAlertsKey = "RoamSwitch.EntropyGuardRecentAlertsV1"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    static func persistedAlerts(defaults: UserDefaults = .standard) -> [PersistedEntropyAlert] {
        guard let data = defaults.data(forKey: persistedAlertsKey),
              let decoded = try? JSONDecoder().decode([PersistedEntropyAlert].self, from: data) else {
            return []
        }
        return decoded
    }
}

/// Field-for-field mirror of `RansomwareEntropyAlert`'s `Codable` shape —
/// duplicated rather than shared, same convention as
/// `PersistedCanaryIncident`, so this reader stays dependency-free.
struct PersistedEntropyAlert: Codable {
    let timestamp: Date
    let processLabel: String
    let affectedFilePaths: [String]
    let averageEntropy: Double
}
