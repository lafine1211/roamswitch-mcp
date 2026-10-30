// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.16 (build 195).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import SystemConfiguration

/// Audit check `proxy_autodiscovery`: is the Mac set to ask the network where its proxy is?
///
/// Two settings let whoever controls a network's DHCP or DNS choose the proxy a browser and other apps use:
/// "Auto Proxy Discovery" (WPAD: the Mac looks for a PAC file named by DHCP option 252 or at `wpad.<domain>`) and a
/// PAC URL that the network, not the person, supplied. A hostile network (a rogue DHCP server, an evil-twin access
/// point) that answers either can route web traffic through itself. Auto Proxy Discovery is off in a default macOS
/// setup, so an enabled one was switched on by a person, a profile or a tool.
///
/// This reads the proxy settings macOS is using now (`SCDynamicStoreCopyProxies`, the merge of the network
/// settings and what the network provided) and the saved settings of every network service, to tell a PAC URL that
/// somebody configured from one the network supplied. It changes nothing and sends nothing.
///
/// What it cannot see: a PAC file's contents, and a proxy a single application sets for itself (a browser extension,
/// a per-app VPN). A PAC URL that was configured on purpose (an organisation's profile) is reported as information,
/// not as a failure. A new PAC address is reported as it appears by the network-settings watch, not by this check.
struct ProxyExposure: Equatable {
    /// Auto Proxy Discovery (WPAD) is in effect.
    var wpadEnabled: Bool
    var pacEnabled: Bool
    var pacURL: String?
    /// The PAC URL is also in the saved settings of a service (set by a person or a profile). False means the
    /// network supplied it.
    var pacIsConfigured: Bool
}

enum ProxyAutoDiscoveryCheck {

    /// The reader the audit uses; the tests replace it.
    static var readExposure: () -> ProxyExposure? = liveExposure

    // MARK: Reading

    static func liveExposure() -> ProxyExposure? {
        guard let store = SCDynamicStoreCreate(nil, "RoamSwitch.ProxyAutoDiscoveryCheck" as CFString, nil, nil),
              let effective = SCDynamicStoreCopyProxies(store) as? [String: Any] else { return nil }
        let pattern = "Setup:/Network/Service/[^/]+/Proxies" as CFString
        let saved = SCDynamicStoreCopyMultiple(store, nil, [pattern] as CFArray) as? [String: [String: Any]] ?? [:]
        return exposure(effective: effective, saved: Array(saved.values))
    }

    /// Pure: `effective` is what is in force, `saved` the proxy settings of each network service.
    static func exposure(effective: [String: Any], saved: [[String: Any]]) -> ProxyExposure {
        func flag(_ dict: [String: Any], _ key: String) -> Bool { (dict[key] as? NSNumber)?.intValue == 1 }
        let pacEnabled = flag(effective, "ProxyAutoConfigEnable")
        let url = (effective["ProxyAutoConfigURLString"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let configured = pacEnabled && url != nil && saved.contains { flag($0, "ProxyAutoConfigEnable") && ($0["ProxyAutoConfigURLString"] as? String) == url }
        return ProxyExposure(wpadEnabled: flag(effective, "ProxyAutoDiscoveryEnable"), pacEnabled: pacEnabled,
                             pacURL: pacEnabled ? url : nil, pacIsConfigured: configured)
    }

    /// The host of a PAC URL, for display and for the set of hosts already seen.
    static func host(ofPACURL url: String) -> String? {
        URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines))?.host?.lowercased()
    }

    // MARK: Audit item

    static func item(_ exposure: ProxyExposure?) -> SecurityAuditItem {
        var isPassed = false
        var inconclusiveReason: String?
        var statusText: String
        var recommendation = loc("システム設定 > ネットワーク > 使用中の接続 > 詳細 > プロキシ で、「プロキシを自動検出」と、心当たりのない「自動プロキシ構成」をオフにしてください。")
        let detail = loc("接続先のネットワークが、Webアクセスの経由先(プロキシ)を指定できる設定がオンになっていないかを確認します。悪意のあるネットワークがこれに答えると、Web通信を自分経由にできます。「プロキシを自動検出」(WPAD)は、標準ではオフです。PACファイルの中身や、アプリ単体のプロキシ設定は確認しません。")
        switch exposure {
        case .none:
            statusText = loc("状態を確認できませんでした")
            inconclusiveReason = "not_verifiable"
        case .some(let e):
            if e.wpadEnabled {
                statusText = loc("⚠️ 「プロキシを自動検出」(WPAD)がオンです")
            } else if e.pacEnabled, let url = e.pacURL, !e.pacIsConfigured {
                statusText = String(format: loc("⚠️ ネットワークが指定したプロキシ設定(PAC)を使っています: %@"), MCPUntrustedText.sanitize(host(ofPACURL: url) ?? "?", maxLength: 80))
            } else if e.pacEnabled, let url = e.pacURL {
                isPassed = true
                statusText = String(format: loc("自動プロキシ構成(PAC)が設定されています: %@(設定した覚えがあれば問題ありません)"), MCPUntrustedText.sanitize(host(ofPACURL: url) ?? "?", maxLength: 80))
                recommendation = loc("設定した覚えがない場合は、システム設定 > ネットワーク > 詳細 > プロキシ で確認してください。")
            } else {
                isPassed = true
                statusText = loc("自動検出は無効です")
                recommendation = loc("設定は万全です。")
            }
        }
        return SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("プロキシ自動検出 (WPAD / PAC)"),
            isPassed: isPassed,
            statusText: statusText,
            detail: detail,
            recommendation: recommendation,
            settingsURL: "x-apple.systempreferences:com.apple.Network-Settings.extension",
            checkId: "proxy_autodiscovery",
            inconclusiveReason: inconclusiveReason
        )
    }
}
