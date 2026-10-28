// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.11 (build 190).
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
    /// The Mac is on a Wi-Fi network but macOS did not give the app its name. Since macOS 14 the name (and the
    /// access point's address) is withheld from an app that has no Location Services permission. Measured with a
    /// command-line program on a connected Mac: `ssid()` and `bssid()` were nil, `rssiValue()` was -59 and
    /// `security()` was WPA2, so "no name" does not mean "not connected".
    public var ssidWithheld: Bool = false

    /// The level above is a reading of the real network: the name was read, or the connection was seen and its
    /// encryption read without the name.
    public var levelIsMeasured: Bool {
        ssid != nil || (ssidWithheld && securityLevel != .notConnected)
    }

    /// Connected, but neither the name nor the encryption could be read: "not connected" would be a guess.
    public var readingUnreliable: Bool {
        ssidWithheld && securityLevel == .notConnected
    }
}

final class WiFiSecurityMonitor {
    static let shared = WiFiSecurityMonitor()

    func checkCurrentWiFi() -> WiFiInfo {
        guard let interface = CWWiFiClient.shared().interface() else {
            return WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected)
        }
        return Self.classify(powerOn: interface.powerOn(), ssid: interface.ssid(), bssid: interface.bssid(),
                             rssi: interface.rssiValue(), security: interface.security())
    }

    /// Pure: what the readings of the Wi-Fi interface mean. A name that is nil with a signal on the interface is a
    /// connected network whose name was withheld, not a missing connection.
    static func classify(powerOn: Bool, ssid: String?, bssid: String?, rssi: Int, security: CWSecurity) -> WiFiInfo {
        if let ssid {
            return WiFiInfo(ssid: ssid, bssid: bssid, securityLevel: parseSecurityLevel(security))
        }
        // Wi-Fi off, or no signal (not associated): nothing to read.
        guard powerOn, rssi != 0 else {
            return WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected)
        }
        // Associated, name withheld. The encryption is still readable; with it unknown, say nothing about it.
        let level: WiFiSecurityLevel = security == .unknown ? .notConnected : parseSecurityLevel(security)
        return WiFiInfo(ssid: nil, bssid: bssid, securityLevel: level, ssidWithheld: true)
    }

    private func parseSecurity(_ sec: CWSecurity) -> WiFiSecurityLevel {
        Self.parseSecurityLevel(sec)
    }

    static func parseSecurityLevel(_ sec: CWSecurity) -> WiFiSecurityLevel {
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
