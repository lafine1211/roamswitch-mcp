// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.0 (build 23).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public struct ARPMonitorStatus: Equatable {
    public var isSpoofingDetected: Bool
    public var message: String
    /// The gateway MAC observed immediately before this check, and the new
    /// one that replaced it — populated only when `isSpoofingDetected` is
    /// true. Kept for display purposes (e.g. an emergency containment modal
    /// explaining exactly what changed).
    public var previousMAC: String?
    public var currentMAC: String?
}

final class ARPSpoofMonitor {
    static let shared = ARPSpoofMonitor()

    private var lastObservedGatewayIP: String?
    private var lastObservedGatewayMAC: String?

    func inspectGateway(currentIP: String?, currentMAC: String?) -> ARPMonitorStatus {
        guard let ip = currentIP, let mac = currentMAC else {
            return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（監視中）"), previousMAC: nil, currentMAC: nil)
        }

        if let lastIP = lastObservedGatewayIP, let lastMAC = lastObservedGatewayMAC {
            // If the gateway IP stayed the same, but the MAC address suddenly changed, suspect ARP spoofing
            if lastIP == ip && lastMAC.caseInsensitiveCompare(mac) != .orderedSame {
                return ARPMonitorStatus(
                    isSpoofingDetected: true,
                    message: loc("⚠️ ARPスプーフィング疑い: ゲートウェイMACアドレスが急変しました"),
                    previousMAC: lastMAC,
                    currentMAC: mac
                )
            }
        }

        lastObservedGatewayIP = ip
        lastObservedGatewayMAC = mac
        return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（スプーフィング未検知）"), previousMAC: nil, currentMAC: nil)
    }

    func reset() {
        lastObservedGatewayIP = nil
        lastObservedGatewayMAC = nil
    }
}
