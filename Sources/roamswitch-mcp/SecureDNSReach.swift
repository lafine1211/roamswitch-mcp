// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Whether the network the Mac is on reaches the secure-DNS provider (`SecureDNSCoordinator`). The coordinator decides in the
/// app; `get_guard_status` (the MCP server is another process) and the protection status window read this record, so that a
/// guard that is switched on and has fallen back to the network's own DNS is not shown as working.
///
/// The app writes it when the coordinator's state changes and again every minute (`GuardReaderHealthMonitor.check`); a record
/// older than [`freshSecs`] is not believed (the app is probably not running), like `LinkGuardEnforcement`.
struct SecureDNSReach: Equatable {
    /// `SecureDNSProvider.rawValue`.
    var provider: String
    var unreachable: Bool

    static let defaultsKey = "RoamSwitch.SecureDNSReachV1"
    static let freshSecs: Double = 180
    /// The reason code of `liveStateReason`.
    static let reasonCode = "secure_dns_unreachable"

    static func write(_ value: SecureDNSReach, now: Double, defaults: UserDefaults = .standard) {
        defaults.set(["provider": value.provider, "unreachable": value.unreachable, "at": now] as [String: Any], forKey: defaultsKey)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: defaultsKey)
    }

    /// As the app last wrote it; nil when there is none or it is stale.
    static func read(defaults: UserDefaults, now: Double) -> SecureDNSReach? {
        guard let record = defaults.dictionary(forKey: defaultsKey), let provider = record["provider"] as? String,
              let unreachable = record["unreachable"] as? Bool, let at = record["at"] as? Double,
              now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return SecureDNSReach(provider: provider, unreachable: unreachable)
    }

    /// `Quad9 (9.9.9.9 / 149.112.112.112)`: what `get_guard_status` gives in `liveStateDetail` and the window shows.
    static func detail(provider: String) -> String {
        // Mirrors `SecureDNSProvider` (DNSThreatGuard.swift, AppKit-only: not compiled into the MCP server).
        switch provider {
        case "cloudflareSecurity": return "Cloudflare (1.1.1.2 / 1.0.0.2)"
        case "adguard": return "AdGuard (94.140.14.14 / 94.140.15.15)"
        case "cleanBrowsing": return "CleanBrowsing (185.228.168.9 / 185.228.169.9)"
        default: return "Quad9 (9.9.9.9 / 149.112.112.112)"
        }
    }
}
