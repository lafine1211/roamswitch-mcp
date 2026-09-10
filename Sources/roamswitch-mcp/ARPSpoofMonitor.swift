// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.17 (build 74).
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
    /// SSID observed alongside the last accepted (gatewayIP, gatewayMAC)
    /// baseline — the corroborating signal used to tell a genuine roam from
    /// an in-place spoof (see `inspectGateway`).
    private var lastObservedSSID: String?

    /// `currentSSID` is the corroborating signal that separates a genuine
    /// network move from an on-path spoof: many routers share the same
    /// default private gateway IP (192.168.1.1, 192.168.0.1, ...), so
    /// "gateway IP unchanged, MAC changed" alone also fires when walking
    /// into a *different* building whose router happens to reuse that IP.
    /// If the SSID changed too, that's an independent confirmation of a
    /// real move, so the new gateway is accepted as the fresh baseline
    /// instead of being flagged. A `nil` SSID (wired, or the Wi-Fi read
    /// failed) deliberately does *not* count as corroboration — unlike the
    /// Linux daemon's `confirmed_roam`, which trusts a `nil` SSID as "wired,
    /// trust the move": Linux has a second, independent full-ARP-cache diff
    /// layer (`ArpMonitor`) as a backstop, so it can afford to relax this
    /// one check for wired links. This is Mac's *only* gateway-spoof check,
    /// so staying conservative when the SSID can't corroborate anything
    /// avoids silently losing wired detection. If the SSID is unchanged (or
    /// unreadable on both sides), the far more likely explanation is that
    /// someone on the *same* network is now answering ARP requests for the
    /// gateway's IP with a different MAC — i.e. spoofing.
    func inspectGateway(currentIP: String?, currentMAC: String?, currentSSID: String?) -> ARPMonitorStatus {
        guard let ip = currentIP, let mac = currentMAC else {
            return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（監視中）"), previousMAC: nil, currentMAC: nil)
        }

        if let lastIP = lastObservedGatewayIP, let lastMAC = lastObservedGatewayMAC {
            if lastIP == ip && lastMAC.caseInsensitiveCompare(mac) != .orderedSame {
                let corroboratedRoam = currentSSID != nil && currentSSID != lastObservedSSID
                if !corroboratedRoam {
                    return ARPMonitorStatus(
                        isSpoofingDetected: true,
                        message: loc("⚠️ ARPスプーフィング疑い: ゲートウェイMACアドレスが急変しました"),
                        previousMAC: lastMAC,
                        currentMAC: mac
                    )
                }
                // SSID changed alongside the MAC — a genuine move to a
                // different network, not spoofing. Fall through to accept
                // the new gateway as the baseline.
            }
        }

        lastObservedGatewayIP = ip
        lastObservedGatewayMAC = mac
        lastObservedSSID = currentSSID
        return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（スプーフィング未検知）"), previousMAC: nil, currentMAC: nil)
    }

    func reset() {
        lastObservedGatewayIP = nil
        lastObservedGatewayMAC = nil
        lastObservedSSID = nil
    }
}
