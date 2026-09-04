// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.8.1 (build 48).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CoreWLAN

public enum WiFiSecurityLevel: Equatable {
    case secure(String)
    case weak(String)
    case open
    case notConnected

    public var isSafe: Bool {
        switch self {
        case .secure: return true
        case .weak, .open: return false
        case .notConnected: return true
        }
    }

    public var label: String {
        switch self {
        case .secure(let type): return String(format: loc("暗号化保護済み (%@)"), type)
        case .weak(let type): return String(format: loc("⚠️ 脆弱な暗号化 (%@)"), type)
        case .open: return loc("⚠️ 暗号化なし (Open Wi-Fi)")
        case .notConnected: return loc("Wi-Fi未接続 (有線/その他)")
        }
    }
}

public struct WiFiInfo: Equatable {
    public var ssid: String?
    public var bssid: String?
    public var securityLevel: WiFiSecurityLevel
}

final class WiFiSecurityMonitor {
    static let shared = WiFiSecurityMonitor()

    func checkCurrentWiFi() -> WiFiInfo {
        guard let interface = CWWiFiClient.shared().interface(),
              let ssid = interface.ssid() else {
            return WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected)
        }

        let bssid = interface.bssid()
        let secType = interface.security()
        let level = parseSecurity(secType)

        return WiFiInfo(ssid: ssid, bssid: bssid, securityLevel: level)
    }

    private func parseSecurity(_ sec: CWSecurity) -> WiFiSecurityLevel {
        switch sec {
        case .none:
            return .open
        case .dynamicWEP:
            return .weak("WEP")
        case .wpaPersonal, .wpaPersonalMixed:
            return .secure("WPA Personal")
        case .wpa2Personal:
            return .secure("WPA2 Personal")
        case .personal:
            return .secure("WPA2/WPA3 Personal")
        case .wpaEnterprise, .wpaEnterpriseMixed, .wpa2Enterprise, .enterprise:
            return .secure("Enterprise")
        case .wpa3Personal:
            return .secure("WPA3 Personal")
        case .wpa3Enterprise:
            return .secure("WPA3 Enterprise")
        case .wpa3Transition:
            return .secure("WPA2/WPA3 Transition")
        case .unknown:
            return .open
        @unknown default:
            return .secure("Wi-Fi")
        }
    }
}
