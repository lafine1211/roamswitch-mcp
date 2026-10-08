// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.11.1 (build 148).
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
    /// ゲートウェイのIP/MACを取得できたか。`false` なら何とも比べていないので「正常」は何も保証しない。
    public var gatewayKnown: Bool = true
    /// 信頼できる基準と照合できたか: 現在のゲートウェイMACが、ユーザーが登録した信頼ネットワークのMACと一致した。
    /// `false` なら「疑いなし」は何とも照合していない。このプロセス自身の前回観測は基準にしない
    /// (最初の観測の時点で既に偽造されていれば、2回目以降も「一致」してしまうため)。
    public var hadBaseline: Bool = true
}

final class ARPSpoofMonitor {
    static let shared = ARPSpoofMonitor()

    /// Guards the baseline: the gateway ARP lock reads it from a background queue.
    private let baselineLock = NSLock()
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
    func inspectGateway(currentIP: String?, currentMAC: String?, currentSSID: String?, matchesTrustedBaseline: Bool = false) -> ARPMonitorStatus {
        guard let ip = currentIP, let mac = currentMAC else {
            return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（監視中）"), previousMAC: nil, currentMAC: nil, gatewayKnown: false, hadBaseline: false)
        }

        // 「照合済み」と言えるのは、永続する信頼できる基準(登録済みの信頼ネットワークのゲートウェイMAC)と一致したときだけ。
        // 検知ロジック自体(プロセス内の前回観測との比較)は従来どおりだが、それは基準の信頼性を保証しない。
        let hadBaseline = matchesTrustedBaseline

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

        baselineLock.lock()
        lastObservedGatewayIP = ip
        lastObservedGatewayMAC = mac
        lastObservedSSID = currentSSID
        baselineLock.unlock()
        return ARPMonitorStatus(isSpoofingDetected: false, message: loc("正常（スプーフィング未検知）"), previousMAC: nil, currentMAC: nil, gatewayKnown: true, hadBaseline: hadBaseline)
    }

    /// Keeps the trusted gateway as the baseline (instead of adopting whatever is there now), for a release
    /// or a recovery that could not verify the cause is gone. A gateway that differs keeps being reported.
    func keepBaseline(trustedMAC: String, gatewayIP: String?, ssid: String?) {
        baselineLock.lock()
        lastObservedGatewayMAC = trustedMAC
        lastObservedGatewayIP = gatewayIP
        lastObservedSSID = ssid
        baselineLock.unlock()
    }

    /// True when the baseline for this gateway address is a different hardware address than `mac`: what is
    /// answering for the gateway now is not what was accepted before. Anything that would copy the current
    /// ARP entry into something durable (the gateway ARP lock) must not do so while this is true.
    func differsFromBaseline(gatewayIP ip: String, mac: String) -> Bool {
        baselineLock.lock()
        defer { baselineLock.unlock() }
        guard lastObservedGatewayIP == ip, let baseline = lastObservedGatewayMAC else { return false }
        return baseline.caseInsensitiveCompare(mac) != .orderedSame
    }

    func reset() {
        baselineLock.lock()
        lastObservedGatewayIP = nil
        lastObservedGatewayMAC = nil
        lastObservedSSID = nil
        baselineLock.unlock()
    }
}
