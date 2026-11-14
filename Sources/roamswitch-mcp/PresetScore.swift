// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.1 (build 217).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// 診断の点数に入れる、設定のプリセットで切り替わる保護。
///
/// これまでの点数は OS の項目(FileVault や SIP など)だけで決まり、プリセットで変わるのは「ゲートウェイ ARP 固定」と
/// 「USB ガード」の 2 項目だけだった。そのため、軽量・バランス・標準は同じ点数になった。オーナーの決定(2026-11-14):
/// 各プリセットと理想のセキュリティ項目との差が分かるように、理想を「最大セキュリティ」とし、プリセットで切り替わる
/// 保護(最大セキュリティでオンになるもの)も点数に入れる。軽量や標準の点数が低いのは、公正な結果である。
///
/// 数えないもの:
///  - すでに同じ保護を見ている診断の項目がある設定(二重に数えない): `foldedIntoExistingItem`
///  - Pro でない Mac で動かない保護(`worksWithoutPro` が false)
///  - アプリが自分で許可できない前提(アクセシビリティの許可、blueutil)が無いもの
///  - 数値や文字列の設定(間隔など)。保護のオン・オフではない
/// 数えない分は、点数の分母にも分子にも入れない(診断の項目の「対象外」と同じ扱い)。
enum PresetScore {

    /// 点数に入る 1 行。
    struct Row: Equatable {
        let id: String
        let titleKey: String
        let isOn: Bool
    }

    struct Result: Equatable {
        var counted: [Row] = []
        /// 前提が無い・Pro でないために、点数に入れなかった保護の id。
        var notApplicable: [String] = []
        /// 既存の診断項目が見ているため、ここでは数えなかった保護の id。
        var folded: [String] = []

        var total: Int { counted.count }
        var passed: Int { counted.filter(\.isOn).count }
        var off: [Row] { counted.filter { !$0.isOn } }
    }

    /// 点数の計算に要る入力(Pro か、アプリが得られない許可はどれか)。テストでは値を直接渡す。
    struct Inputs {
        var defaults: UserDefaults
        var isPro: Bool
        var unmet: Set<PresetPrerequisite>

        /// いまのアプリの状態。この別プロセスの MCP サーバーでも同じ値になるよう、Pro は共有の保存値から読む。
        static func current(defaults: UserDefaults) -> Inputs {
            let shared = UserDefaults(suiteName: "com.tetsuharu.RoamSwitch") ?? .standard
            var unmet: Set<PresetPrerequisite> = []
            // アクセシビリティの許可は、ここでは見ない。それを要るのは USB キーボードガードだけで、診断の既存の項目が見ている
            // ため数えない(`foldedIntoExistingItem`)。しかも MCP サーバーは別のプロセスで、アプリの許可を知らない。
            let blueutil = ["/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"]
            if !blueutil.contains(where: { FileManager.default.fileExists(atPath: $0) }) { unmet.insert(.blueutil) }
            return Inputs(defaults: defaults, isPro: shared.bool(forKey: "RoamSwitch.IsProCache"), unmet: unmet)
        }
    }

    /// 同じ保護を、診断の既存の項目(`checkId`)がすでに見ている設定(プリセットの設定 id → 診断の項目)。
    static let foldedIntoExistingItem: [String: String] = [
        "gatewayARPLock": "gateway_arp_lock",
        "usbKeyboardGuard": "usb_zero_trust",
        "usbStorageGuard": "usb_zero_trust",
        "webMailDownloadGuard": "malware_scanning",
        "dnsThreatGuard": "dns_threat_guard",
    ]

    static let summaryCheckId = "preset_gap"

    static func evaluate(_ inputs: Inputs) -> Result {
        var result = Result()
        for setting in ProtectionPresetTable.settings {
            // 理想は最大セキュリティ。そこでオンになる、オン・オフの保護だけを数える。
            guard setting.value(for: .maximum) == .bool(true) else { continue }
            if foldedIntoExistingItem[setting.id] != nil { result.folded.append(setting.id); continue }
            if !setting.worksWithoutPro && !inputs.isPro { result.notApplicable.append(setting.id); continue }
            if let need = setting.prerequisite, inputs.unmet.contains(need) { result.notApplicable.append(setting.id); continue }
            let now = ProtectionPresetTable.effectiveValue(of: setting, defaults: inputs.defaults)
            result.counted.append(Row(id: setting.id, titleKey: setting.titleKey, isOn: now == .bool(true)))
        }
        return result
    }

    /// 診断の一覧に足す、1 行のまとめ。点数には入れない(`isApplicable == false`)。
    static func summaryItem(_ result: Result, defaults: UserDefaults) -> SecurityAuditItem {
        let state = ProtectionPresetTable.state(defaults: defaults)
        let name = ProtectionPresetText.stateLabel(state)
        let remaining = result.off.count
        let status = remaining == 0
            ? String(format: loc("%@: 最大セキュリティと同じ保護がオンです"), name)
            : String(format: loc("%@: 最大セキュリティまであと %d 個"), name, remaining)
        let detail = remaining == 0
            ? loc("点数には、設定のプリセットで切り替わる保護も入っています。理想は最大セキュリティです。")
            : loc("点数には、設定のプリセットで切り替わる保護も入っています。理想は最大セキュリティです。オフの保護は次のとおりです。")
                + "\n" + result.off.map { "- " + loc($0.titleKey) }.joined(separator: "\n")
        return SecurityAuditItem(
            category: loc("設定のプリセット"),
            title: loc("プリセットと最大セキュリティの差"),
            isPassed: remaining == 0,
            statusText: status,
            detail: detail,
            recommendation: loc("メニューの「設定のプリセット」から、プリセットを選べます。選ぶ前に、変わる項目の一覧が出ます。"),
            settingsURL: nil,
            isApplicable: false,
            checkId: summaryCheckId
        )
    }
}
