// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.11.3 (build 150).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public struct SecurityAuditItem: Identifiable, Equatable {
    public var id: String { title }
    public let category: String
    public let title: String
    public let isPassed: Bool
    public let statusText: String
    public let detail: String
    public let recommendation: String
    public let settingsURL: String?
    /// False for a check that's intentionally not in effect given the
    /// user's own choice — e.g. firewall/stealth on a network explicitly
    /// set to "信頼 (オープン)" — rather than a genuine gap. Excluded from
    /// the score's numerator/denominator so choosing a trusted network on
    /// purpose doesn't read as a security regression.
    public let isApplicable: Bool
    /// Stable machine identifier for this specific check (e.g.
    /// `"luks_encryption"`), independent of the localized `title`, and
    /// shared with the Linux client's `SecurityAuditItem.check_id` where
    /// both platforms implement the same real-world control. Empty string
    /// means "no stable identifier assigned yet".
    public let checkId: String
    /// A CIS Controls v8 safeguard number this check corresponds to (e.g.
    /// `"3.11"`), when confident — same "confident mapping or omit" policy
    /// `ContainmentIncidentTimeline.attackTechnique(for:context:)` uses for
    /// MITRE ATT&CK tags. `nil` is not "not compliance-relevant", just "not
    /// confidently mappable to a single control number".
    public let cisControlID: String?
    /// NIST CSF 2.0 subcategory codes (e.g. `["PR.DS-01"]`) this check
    /// relates to. Same "confident or omit" policy; a check can map to more
    /// than one subcategory, so this is an array, unlike `cisControlID`.
    public let nistCsfCategories: [String]
    /// 非nilなら、この項目の合否は信頼できない(測定できなかった、または測定結果が当てにならない)。
    /// `isPassed` はスコア計算のために従来どおり入っているが、`SecurityCheckVerification.classify` は
    /// これを最優先して `inconclusive` を返す。値は言語に依存しない理由コード
    /// ("helper_unavailable" / "gateway_unknown" / "no_baseline" / "location_unavailable" / "not_verifiable" / "tool_failed")。
    public let inconclusiveReason: String?

    public init(category: String, title: String, isPassed: Bool, statusText: String, detail: String, recommendation: String, settingsURL: String?, isApplicable: Bool = true, checkId: String = "", cisControlID: String? = nil, nistCsfCategories: [String] = [], inconclusiveReason: String? = nil) {
        self.category = category
        self.title = title
        self.isPassed = isPassed
        self.statusText = statusText
        self.detail = detail
        self.recommendation = recommendation
        self.settingsURL = settingsURL
        self.isApplicable = isApplicable
        self.checkId = checkId
        self.cisControlID = cisControlID
        self.nistCsfCategories = nistCsfCategories
        self.inconclusiveReason = inconclusiveReason
    }
}

/// `verify_security_findings` の判定。Linux版と共通の3値(JSON上の文字列もこのrawValue)。
public enum SecurityCheckVerification: String, Codable, Equatable {
    case stillPresent
    case resolved
    case inconclusive

    /// 1項目の判定。純関数(項目に入っている情報だけで決まる)。
    /// 優先順位: 信頼できない(inconclusiveReason) > 設計上の対象外(isApplicable == false) > 合否。
    public static func classify(_ item: SecurityAuditItem) -> (verdict: SecurityCheckVerification, reason: String) {
        if let why = item.inconclusiveReason {
            return (.inconclusive, why)
        }
        if !item.isApplicable {
            return (.resolved, "not_applicable")
        }
        return item.isPassed ? (.resolved, "passing") : (.stillPresent, "failing")
    }

    /// `classify` が inconclusive と判定する項目の理由コード。それ以外は nil。
    /// `get_security_report` の項目に出す値と `verify_security_findings` の reason を同じ根拠にするための共通関数。
    public static func inconclusiveReason(of item: SecurityAuditItem) -> String? {
        let result = classify(item)
        return result.verdict == .inconclusive ? result.reason : nil
    }
}

extension SecurityAuditItem {
    /// 結果を確認できていない(`inconclusiveReason` あり)。表示は赤/警告でも緑でもなく、中立にする。
    public var isUnconfirmed: Bool { inconclusiveReason != nil }
    /// 対応が必要: 適用対象で、確認できていて、不合格。測定不能の項目は「失敗」ではない。
    public var needsAttention: Bool { isApplicable && inconclusiveReason == nil && !isPassed }
}

/// 1項目の状態(UI用): 有効 / 無効 / 測定不能 / 部分的に有効(SIP のカスタム設定)。
/// `Bool` だけでは「無効」と「測れなかった」が区別できないので、表示はこの三値(+部分)で行う。
public enum HealthCheckState: Equatable {
    case enabled
    case disabled
    /// コマンド失敗・想定外の出力などで、有効か無効かを判断していない。
    case unmeasured
    /// 有効だが一部の保護が外れている(`detail` は csrutil の出力)。
    case partial(detail: String)
}

public struct SecurityHealthStatus: Equatable {
    public var isFileVaultEnabled: Bool
    public var isSIPEnabled: Bool
    public var isGatekeeperEnabled: Bool
    public var isAutoUpdateEnabled: Bool
    public var isXProtectActive: Bool
    /// 外部コマンドが何も出力しなかった(起動失敗・権限不足など)ため、`false` が「無効」ではなく
    /// 「測れなかった」を意味するチェックの checkId。空なら全項目を実際に測定できている。
    public var unmeasuredCheckIds: Set<String> = []
    /// SIP が "enabled (Custom Configuration)" のとき、csrutil の出力(どの保護が外れているか)。通常は nil。
    public var sipPartialDetail: String?

    /// checkId(`luks_encryption` / `lsm_active` / `gatekeeper_app_verification` / `auto_security_updates`)ごとの状態。
    public func state(forCheckId checkId: String) -> HealthCheckState {
        if checkId == "lsm_active", let detail = sipPartialDetail { return .partial(detail: detail) }
        if unmeasuredCheckIds.contains(checkId) { return .unmeasured }
        let value: Bool
        switch checkId {
        case "luks_encryption": value = isFileVaultEnabled
        case "lsm_active": value = isSIPEnabled
        case "gatekeeper_app_verification": value = isGatekeeperEnabled
        case "auto_security_updates": value = isAutoUpdateEnabled
        default: return .unmeasured
        }
        return value ? .enabled : .disabled
    }

    public var allPassed: Bool {
        isFileVaultEnabled && isSIPEnabled && isGatekeeperEnabled && isAutoUpdateEnabled && isXProtectActive
    }

    public var passedCount: Int {
        var count = 0
        if isFileVaultEnabled { count += 1 }
        if isSIPEnabled { count += 1 }
        if isGatekeeperEnabled { count += 1 }
        if isAutoUpdateEnabled { count += 1 }
        if isXProtectActive { count += 1 }
        return count
    }
}

public struct ComprehensiveSecurityReport: Equatable {
    public let score: Int
    public let grade: String
    public let totalChecks: Int
    public let passedChecks: Int
    public let items: [SecurityAuditItem]
    public let timestamp: Date
}

final class SecurityHealthChecker {
    static let shared = SecurityHealthChecker()

    /// 外部コマンドの実行(テストでは偽の出力を返すものを差し込む)と、sshd_config の読み取り元。
    private let runner: CommandRunner
    private let sshConfigSource: SSHDConfigSource

    init(runner: @escaping CommandRunner = SystemCommand.run, sshConfigSource: SSHDConfigSource = FileSSHDConfigSource()) {
        self.runner = runner
        self.sshConfigSource = sshConfigSource
    }

    func checkHealth() -> SecurityHealthStatus {
        var unmeasured: Set<String> = []
        // 外部コマンドが空出力なら、起動失敗と「無効」を区別できない。無効と誤判定せず「測れなかった」として記録する。
        func measured(_ checkId: String, _ value: Bool?) -> Bool {
            if value == nil { unmeasured.insert(checkId) }
            return value ?? false
        }
        let isFileVault = measured("luks_encryption", checkFileVault())
        let sipOutput = runner("/usr/bin/csrutil", ["status"])
        let sipPartial = sipOutput.flatMap(HealthCommandParsing.sipCustomConfigurationDetail)
        let isSIP = measured("lsm_active", sipOutput.flatMap(HealthCommandParsing.sip))
        let isGatekeeper = measured("gatekeeper_app_verification", checkGatekeeper())
        let isAutoUpdate = measured("auto_security_updates", checkAutoUpdate())
        let isXProtect = checkXProtect()

        return SecurityHealthStatus(
            isFileVaultEnabled: isFileVault,
            isSIPEnabled: isSIP,
            isGatekeeperEnabled: isGatekeeper,
            isAutoUpdateEnabled: isAutoUpdate,
            isXProtectActive: isXProtect,
            unmeasuredCheckIds: unmeasured,
            sipPartialDetail: sipPartial
        )
    }

    func generateComprehensiveReport(
        wifiInfo: WiFiInfo,
        arpStatus: ARPMonitorStatus,
        /// `nil` = ポート一覧を取得できなかった(`lsof` の失敗)。`[]`(= 本当に待ち受けなし)とは別物で、
        /// 「公開ポートなし (安全)」とは決して表示せず、対象外+測定不能として扱う。
        listeningPorts: [ListeningPortInfo]?,
        activeSecurityLevel: SecurityLevel,
        /// `nil` = not yet checked (e.g. helper not connected yet) — kept out
        /// of the score rather than counted as a pass or a fail. See
        /// `HelperTool.auditSudoNopasswd` (root-only `/etc/sudoers`).
        sudoAuditIsHardened: Bool? = nil,
        sudoAuditDetail: String? = nil,
        /// `GatewayARPLockManager.shared.isEnabled` — passed in rather than
        /// read here so this stays a pure function of its inputs, matching
        /// the other pre-fetched parameters.
        gatewayARPLockEnabled: Bool = false,
        /// `DevServerIsolator.shared.isolatedPorts` — a port the user (or
        /// `PortAnomalyGuard`'s auto-isolation) already pf-blocked is not a
        /// real exposure, the same distinction Linux RoamSwitch's
        /// `PortScanner::scan_ports` already makes via `is_isolated`. Passed
        /// in rather than read here for the same pure-function reason as
        /// `gatewayARPLockEnabled` above — `DevServerIsolator` is `@MainActor`.
        isolatedDevPorts: Set<Int> = [],
        /// Wi-Fiインターフェースはあるが SSID を解決できなかった(位置情報の権限が無い CLI/MCP プロセスなど)。
        /// 「未接続」と「読めなかった」を区別できないので、Wi-Fi暗号化強度は `verify_security_findings` で inconclusive になる。
        wifiReadingUnreliable: Bool = false,
        /// ユーザー設定(ダウンロードガード・DNS保護・USBガード)を読む UserDefaults。
        /// アプリ本体は `.standard`、別プロセスの MCP サーバーは App Group 相当の `sharedDefaults` を渡す
        /// (MCP側の `.standard` はアプリの設定を見ていない)。
        defaults: UserDefaults = .standard,
        /// `listeningPorts == nil` のとき、「まだ一度も測っていない」(true)か「lsof が失敗した」(false)か。
        /// 前者の reason は `not_measured`、後者は `tool_failed`。
        portListNotMeasuredYet: Bool = false
    ) -> ComprehensiveSecurityReport {
        let health = checkHealth()
        func unmeasuredReason(_ id: String) -> String? {
            guard health.unmeasuredCheckIds.contains(id) else { return nil }
            // SIP のカスタム設定は「測れなかった」のではなく、有効と言い切れない状態。
            if id == "lsm_active", health.sipPartialDetail != nil { return "not_verifiable" }
            return "tool_failed"
        }
        // 測れなかった項目は合否を持たない(`false` は「無効」ではなく「不明」)。スコアと失敗件数から除外する。
        func measuredFlag(_ id: String) -> Bool { !health.unmeasuredCheckIds.contains(id) }
        let unmeasuredStatus = loc("状態を確認できませんでした")
        var items: [SecurityAuditItem] = []

        // MARK: - 1. System Defense (システム堅牢性)
        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("FileVault (ディスク暗号化)"),
            isPassed: health.isFileVaultEnabled,
            statusText: !measuredFlag("luks_encryption") ? unmeasuredStatus : (health.isFileVaultEnabled ? loc("有効 (暗号化保護中)") : loc("無効 (未保護)")),
            detail: loc("MacのSSD/HDDストレージ全体をXTS-AES 128暗号で暗号化し、盗難や紛失時のデータ抜き取りを防ぎます。"),
            recommendation: health.isFileVaultEnabled ? loc("設定は万全です。") : loc("システム設定 > プライバシーとセキュリティからFileVaultをオンにしてください。"),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security?FileVault",
            isApplicable: measuredFlag("luks_encryption"),
            checkId: "luks_encryption",
            cisControlID: "3.11",
            nistCsfCategories: ["PR.DS-01"],
            inconclusiveReason: unmeasuredReason("luks_encryption")
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("SIP (システム完全性保護)"),
            isPassed: health.isSIPEnabled,
            statusText: health.sipPartialDetail != nil ? loc("部分的に有効 (カスタム設定)") : !measuredFlag("lsm_active") ? unmeasuredStatus : (health.isSIPEnabled ? loc("有効 (システム保護中)") : loc("無効 (危険)")),
            detail: loc("root権限を持つプロセスであってもmacOSの重要システムファイルやカーネルの改ざんを禁止します。"),
            recommendation: health.isSIPEnabled ? loc("設定は万全です。") : loc("リカバリーモードで起動し、csrutil enable を実行してSIPを有効化してください。"),
            settingsURL: nil,
            isApplicable: measuredFlag("lsm_active"),
            checkId: "lsm_active",
            nistCsfCategories: ["PR.PS-01"],
            inconclusiveReason: unmeasuredReason("lsm_active")
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("Gatekeeper (アプリ検証)"),
            isPassed: health.isGatekeeperEnabled,
            statusText: !measuredFlag("gatekeeper_app_verification") ? unmeasuredStatus : (health.isGatekeeperEnabled ? loc("有効 (悪質アプリ遮断)") : loc("無効 (危険)")),
            detail: loc("Apple公認の開発者署名がない未承認アプリや改ざんされたバイナリの起動を自動ブロックします。"),
            recommendation: health.isGatekeeperEnabled ? loc("設定は万全です。") : loc("システム設定 > プライバシーとセキュリティからアプリの実行許可を適切に設定してください。"),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security",
            isApplicable: measuredFlag("gatekeeper_app_verification"),
            checkId: "gatekeeper_app_verification",
            cisControlID: "2.5",
            nistCsfCategories: ["PR.PS-05"],
            inconclusiveReason: unmeasuredReason("gatekeeper_app_verification")
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("自動セキュリティアップデート"),
            isPassed: health.isAutoUpdateEnabled,
            statusText: !measuredFlag("auto_security_updates") ? unmeasuredStatus : (health.isAutoUpdateEnabled ? loc("有効 (最新パッチ自動適用)") : loc("無効 (推奨設定外)")),
            detail: loc("緊急セキュリティ対応（RSR）やシステム脆弱性パッチを自動的にバックグラウンドでダウンロード・適用します。"),
            recommendation: health.isAutoUpdateEnabled ? loc("設定は万全です。") : loc("システム設定 > 一般 > ソフトウェアアップデートから自動更新を有効にしてください。"),
            settingsURL: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension",
            isApplicable: measuredFlag("auto_security_updates"),
            checkId: "auto_security_updates",
            cisControlID: "7.3",
            nistCsfCategories: ["PR.PS-02"],
            inconclusiveReason: unmeasuredReason("auto_security_updates")
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("Apple XProtect (マルウェア検知・自動駆除)"),
            isPassed: health.isXProtectActive,
            statusText: health.isXProtectActive ? loc("稼働中 (常時監視)") : loc("停止中"),
            detail: loc("Apple公式のシグネチャベースのマルウェア検知およびRemediator自動駆除エンジンが常時稼働しています。"),
            recommendation: loc("定期的に最新のmacOSアップデートを適用することで定義が最新に保たれます。"),
            settingsURL: nil,
            checkId: "os_builtin_malware_detection",
            cisControlID: "10.1",
            nistCsfCategories: ["DE.CM-09"]
        ))

        // MARK: - 2. Network Defense (ネットワーク防御)
        // A network explicitly set to "信頼 (オープン)" is *meant* to have
        // the firewall/stealth checks below fail — that's the whole point
        // of choosing that level for a network you trust. Flagging it as a
        // security regression would misrepresent a deliberate choice, so
        // these two checks are marked not-applicable instead of failed.
        let isTrustedOpenNetwork = activeSecurityLevel == .open

        let isFirewallPassed = activeSecurityLevel.firewallBlockAll || activeSecurityLevel == .balanced
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("macOS ファイアウォール"),
            isPassed: isTrustedOpenNetwork ? true : isFirewallPassed,
            statusText: isTrustedOpenNetwork ? loc("対象外 (信頼ネットワークのため意図的に無効)") : (activeSecurityLevel.firewallBlockAll ? loc("全受信ブロック中 (強固)") : (isFirewallPassed ? loc("標準保護 (有効)") : loc("解除中 (オープン)"))),
            detail: loc("外部からの未承認な着信TCP/UDPパケットをカーネルのパケットフィルタ層で自動破棄します。") + (isTrustedOpenNetwork ? "\n" + Self.trustedOpenNotApplicableNote : ""),
            recommendation: isTrustedOpenNetwork ? loc("信頼ネットワークのため意図的に保護を解除しています。公衆Wi-Fi等、信頼できない場所では別の保護レベルを選んでください。") : (activeSecurityLevel.firewallBlockAll ? loc("外部接続は完全に遮断されています。") : loc("外出先では最大ロックダウンまたは標準保護への設定を推奨します。")),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security?Firewall",
            isApplicable: !isTrustedOpenNetwork,
            checkId: "host_firewall",
            cisControlID: "4.4",
            nistCsfCategories: ["PR.IR-01"]
        ))

        let isStealthPassed = activeSecurityLevel.firewallBlockAll
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("ステルスモード (外部Ping隠蔽)"),
            isPassed: isTrustedOpenNetwork ? true : isStealthPassed,
            statusText: isTrustedOpenNetwork ? loc("対象外 (信頼ネットワークのため意図的に無効)") : (isStealthPassed ? loc("有効 (隠蔽中)") : loc("無効 (Ping応答許可)")),
            detail: loc("ネットワークスキャンやPing（ICMP）に対して無応答にすることで、外部からMacの存在自体を隠蔽します。") + (isTrustedOpenNetwork ? "\n" + Self.trustedOpenNotApplicableNote : ""),
            recommendation: isTrustedOpenNetwork ? loc("信頼ネットワークのため意図的に保護を解除しています。") : (isStealthPassed ? loc("外部スキャンから保護されています。") : loc("公衆Wi-Fi接続時はステルスモードの有効化を推奨します。")),
            settingsURL: nil,
            isApplicable: !isTrustedOpenNetwork,
            checkId: "network_stealth_mode",
            nistCsfCategories: ["PR.IR-01"]
        ))

        let isWiFiPassed = wifiInfo.securityLevel.isSafe
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("Wi-Fi 暗号化強度"),
            isPassed: isWiFiPassed,
            statusText: wifiInfo.securityLevel.label,
            detail: loc("接続中のWi-Fiアクセスポイントが強力な暗号化（WPA2-AES / WPA3）で通信を保護しているかを検証します。"),
            recommendation: isWiFiPassed ? loc("通信は安全に暗号化されています。") : loc("暗号化のないOpen Wi-Fiや古いWEPは盗聴の危険があるため、VPNまたはロックダウンを使用してください。"),
            settingsURL: "x-apple.systempreferences:com.apple.wifi-settings-extension",
            checkId: "wifi_encryption_strength",
            nistCsfCategories: ["PR.IR-01"],
            inconclusiveReason: wifiReadingUnreliable ? "location_unavailable" : nil
        ))

        let isARPPassed = !arpStatus.isSpoofingDetected
        // 疑いを検知していればそれが答え。検知していないときだけ「ゲートウェイ不明」「比較対象の履歴なし」が
        // 「正常」の根拠にならない(= 監視が何も比べていない)ことを明示する。
        let arpInconclusiveReason: String? = arpStatus.isSpoofingDetected ? nil
            : (!arpStatus.gatewayKnown ? "gateway_unknown" : (!arpStatus.hadBaseline ? "no_baseline" : nil))
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("ARP スプーフィング監視 (中間者攻撃)"),
            isPassed: isARPPassed,
            statusText: isARPPassed ? loc("正常 (盗聴未検知)") : loc("⚠️ スプーフィング疑い検知"),
            detail: loc("同一LAN内の悪意ある端末がルーターになりすまして通信を盗聴・改ざんする中間者攻撃（MitM）を監視します。"),
            recommendation: isARPPassed ? loc("中間者攻撃の兆候はありません。") : loc("直ちにネットワークから切断し、信頼できる接続に変更してください。"),
            settingsURL: nil,
            checkId: "arp_spoof_monitor",
            nistCsfCategories: ["DE.CM-01"],
            inconclusiveReason: arpInconclusiveReason
        ))

        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("ゲートウェイ ARP 固定 (予防的MITM対策)"),
            isPassed: gatewayARPLockEnabled,
            statusText: gatewayARPLockEnabled ? loc("有効 (ゲートウェイMACを固定中)") : loc("無効"),
            detail: loc("カフェ等の未信頼ネットワーク接続時、ルーターのMACアドレスをARPテーブルに静的固定し、ARPスプーフィングによる中間者攻撃を検知ではなく未然に防止します。"),
            recommendation: gatewayARPLockEnabled ? loc("予防的なMITM対策が有効です。") : loc("未信頼ネットワークを頻繁に使う場合は、メニューバーからゲートウェイARP固定を有効化してください。"),
            settingsURL: nil,
            checkId: "gateway_arp_lock",
            nistCsfCategories: ["PR.IR-01"]
        ))

        // MARK: - 2.5. Authentication & Access Control (認証・アクセス制御)
        let remoteLogin = checkRemoteLoginEnabled()           // nil = launchctl の結果を判別できない
        let isRemoteLoginEnabled = remoteLogin == true
        let sshHardened = isRemoteLoginEnabled ? sshConfigIsHardened() : nil
        let sshVerifiable = remoteLogin != nil && (!isRemoteLoginEnabled || sshHardened != nil)
        items.append(SecurityAuditItem(
            category: loc("認証・アクセス制御"),
            title: loc("SSH リモートログイン設定"),
            isPassed: remoteLogin == nil ? false : (!isRemoteLoginEnabled || (sshHardened ?? false)),
            statusText: !sshVerifiable
                ? unmeasuredStatus
                : (!isRemoteLoginEnabled
                    ? loc("リモートログイン無効 (対象外)")
                    : ((sshHardened ?? false) ? loc("有効・強化済み") : loc("⚠️ 有効・設定に改善余地あり"))),
            detail: loc("リモートログイン（SSH）が有効な場合、rootログイン禁止・鍵認証必須（パスワード認証拒否）になっているかを`/etc/ssh/sshd_config`から確認します。"),
            recommendation: !isRemoteLoginEnabled
                ? loc("リモートログインは無効です。")
                : ((sshHardened ?? false)
                    ? loc("設定は万全です。")
                    : loc("`/etc/ssh/sshd_config`で`PermitRootLogin no`・`PasswordAuthentication no`（鍵認証必須）を設定してください。")),
            settingsURL: "x-apple.systempreferences:com.apple.preferences.sharing",
            // 有効で、設定を判定できたときだけスコア対象。launchctl が判別できない・設定が読めないときは「不明」で除外する。
            isApplicable: isRemoteLoginEnabled && sshVerifiable,
            checkId: "ssh_hardening",
            cisControlID: "4.1",
            nistCsfCategories: ["PR.AA-01"],
            inconclusiveReason: remoteLogin == nil ? "tool_failed" : (isRemoteLoginEnabled && sshHardened == nil ? "not_verifiable" : nil)
        ))

        let sudoAudit = sudoAuditIsHardened
        items.append(SecurityAuditItem(
            category: loc("認証・アクセス制御"),
            title: loc("Sudo 権限昇格設定 (NOPASSWD監査)"),
            isPassed: sudoAudit ?? true,
            statusText: sudoAudit == nil
                ? loc("未確認 (ヘルパー接続待ち)")
                : (sudoAudit == true ? loc("安全 (NOPASSWD設定なし)") : loc("⚠️ NOPASSWD設定を検出")),
            detail: (sudoAuditDetail.map { loc("パスワード無しでsudo実行を許可する`NOPASSWD`設定が見つかりました:\n") + $0 })
                ?? loc("`/etc/sudoers`・`/etc/sudoers.d/`にパスワード無しでroot権限昇格を許可する`NOPASSWD`設定が無いかを監査します。悪意あるインストーラーやマルウェアがこの設定を悪用すると、パスワード入力なしに任意のroot操作が可能になります。"),
            recommendation: sudoAudit == false
                ? loc("心当たりのない`NOPASSWD`設定があれば、`sudo visudo`で削除してください。")
                : loc("設定は万全です。"),
            settingsURL: nil,
            isApplicable: sudoAudit != nil,
            checkId: "sudo_hygiene",
            cisControlID: "5.4",
            nistCsfCategories: ["PR.AA-05"],
            inconclusiveReason: sudoAudit == nil ? "helper_unavailable" : nil
        ))

        // MARK: - 3. Services & Ports (サービス・ポート露出)
        // A port `DevServerIsolator`(またはその自動検知の`PortAnomalyGuard`)が
        // 既にpfでブロック済みの場合、外部到達不能なので露出として数えない —
        // Linux版`PortScanner::scan_ports`の`is_isolated`除外と同じ扱い。
        let exposedCount = (listeningPorts ?? []).filter { $0.isGloballyExposed && !isolatedDevPorts.contains($0.port) }.count
        let portsMeasured = listeningPorts != nil
        let isPortPassed = exposedCount == 0 || activeSecurityLevel.firewallBlockAll
        let portStatusStr: String
        if !portsMeasured {
            // 測れなかったものを「公開ポートなし (安全)」と言わない。ファイアウォールが全遮断中でも、一覧が無い以上
            // この項目は判定できない(遮断中の文言は一覧の有無と無関係に正しいが、合否の根拠にはならない)。
            portStatusStr = portListNotMeasuredYet ? loc("まだ測定していません") : loc("測定できませんでした (lsof の実行に失敗)")
        } else {
            portStatusStr = activeSecurityLevel.firewallBlockAll ? loc("🛡️ ファイアウォール遮断中 (安全)") : (exposedCount == 0 ? loc("公開ポートなし (安全)") : String(format: loc("⚠️ %d個のポートが露出中"), exposedCount))
        }
        items.append(SecurityAuditItem(
            category: loc("サービス・ポート露出"),
            title: loc("外部公開ポート"),
            isPassed: portsMeasured && isPortPassed,
            statusText: portStatusStr,
            detail: loc("外部からの接続を待ち受けているTCP/UDPポートを検査します。ファイアウォール有効時は全ポートが保護されます。"),
            recommendation: !portsMeasured ? (portListNotMeasuredYet ? loc("診断の完了後にもう一度確認してください。") : loc("lsof を実行できる状態で、もう一度確認してください。")) : (isPortPassed ? loc("外部からの不正アクセスは遮断されています。") : loc("不要な開発サーバーを停止するか、Dev Server Isolatorでそのポートを個別に遮断するか、ファイアウォールを有効にしてください。")),
            settingsURL: nil,
            isApplicable: portsMeasured,
            checkId: "exposed_ports",
            cisControlID: "4.4",
            nistCsfCategories: ["DE.CM-01"],
            inconclusiveReason: portsMeasured ? nil : (portListNotMeasuredYet ? "not_measured" : "tool_failed")
        ))

        // MARK: - 4. Malware & Download Protection (マルウェア・ダウンロード保護)
        let isDownloadGuardEnabled = defaults.object(forKey: "RoamSwitch.WebMailDownloadGuardEnabled") == nil ? true : defaults.bool(forKey: "RoamSwitch.WebMailDownloadGuardEnabled")
        let clamCandidates = [
            "/opt/homebrew/bin/clamscan",
            "/usr/local/bin/clamscan",
            "/usr/bin/clamscan"
        ]
        let isClamInstalled = clamCandidates.contains { FileManager.default.isExecutableFile(atPath: $0) }
        let isDownloadGuardPassed = isDownloadGuardEnabled && isClamInstalled
        let downloadStatusStr: String = {
            if !isClamInstalled {
                return loc("要ClamAV (未導入)")
            }
            return isDownloadGuardEnabled ? loc("常時監視中 (安全)") : loc("停止中 (手動無効化)")
        }()
        items.append(SecurityAuditItem(
            category: loc("マルウェア・ダウンロード保護"),
            title: loc("Web・メール保護 (ダウンロード自動スキャン)"),
            isPassed: isDownloadGuardPassed,
            statusText: downloadStatusStr,
            detail: loc("Webブラウザやメール、メッセージングアプリから保存されたファイルをFSEventsでリアルタイム検知し、ClamAVで自動スキャン・隔離します。"),
            recommendation: isDownloadGuardPassed ? loc("ダウンロードファイルはリアルタイムに保護されています。") : (isClamInstalled ? loc("メニューバーよりWeb・メール保護を有効にしてください。") : loc("ClamAVをインストールしてダウンロード自動保護を有効化してください。")),
            settingsURL: nil,
            checkId: "malware_scanning",
            cisControlID: "10.1",
            nistCsfCategories: ["DE.CM-09"]
        ))

        let isDNSGuardEnabled = defaults.object(forKey: "RoamSwitch.DNSThreatGuardEnabled") == nil ? true : defaults.bool(forKey: "RoamSwitch.DNSThreatGuardEnabled")
        let dnsProviderRaw = defaults.string(forKey: "RoamSwitch.DNSThreatGuardProvider") ?? "quad9"
        let dnsProviderName: String = {
            switch dnsProviderRaw {
            case "cloudflareSecurity": return "Cloudflare 1.1.1.2"
            case "adguard": return "AdGuard DNS"
            case "cleanBrowsing": return "CleanBrowsing"
            default: return "Quad9"
            }
        }()
        let dnsStatusStr = isDNSGuardEnabled ? String(format: loc("保護中 (%@)"), dnsProviderName) : loc("停止中 (手動無効化)")
        items.append(SecurityAuditItem(
            category: loc("マルウェア・ダウンロード保護"),
            title: loc("DNS脅威保護 (悪質サイト・C2遮断)"),
            isPassed: isDNSGuardEnabled,
            statusText: dnsStatusStr,
            detail: loc("マルウェアのC2サーバー、ランサムウェア配布ドメイン、フィッシング詐欺サイトへの名前解決をDNSレイヤーで未然に遮断します。"),
            recommendation: isDNSGuardEnabled ? loc("DNS脅威保護は正常に構成されています。") : loc("公衆Wi-Fi接続時はメニューバーよりDNS脅威保護を有効にしてください。"),
            settingsURL: nil,
            checkId: "dns_threat_guard",
            cisControlID: "9.2",
            nistCsfCategories: ["DE.CM-01"]
        ))

        // Check Safari Fraud Warning via CFPreferences
        let safariDomain = "com.apple.Safari" as CFString
        let safariKey = "WarnAboutFraudulentWebsites" as CFString
        let isSafariFraudActive = (CFPreferencesCopyAppValue(safariKey, safariDomain) as? Bool) ?? true
        items.append(SecurityAuditItem(
            category: loc("マルウェア・ダウンロード保護"),
            title: loc("フィッシング・悪質リンク保護 (Safari & LinkAuditor)"),
            isPassed: isSafariFraudActive,
            statusText: isSafariFraudActive ? loc("有効 (詐欺サイト警告・リンク診断)") : loc("警告無効"),
            detail: loc("Safariの詐欺Webサイト警告機能およびRoamSwitchリンク安全性診断により、巧妙なフィッシングURLやUnicode偽装ドメインを遮断・解析します。"),
            recommendation: isSafariFraudActive ? loc("ブラウザおよびリンク保護は万全です。") : loc("Safari > 設定 > セキュリティから「詐欺Webサイト警告」をオンにしてください。"),
            settingsURL: nil,
            checkId: "browser_phishing_protection",
            nistCsfCategories: ["PR.IR-01"]
        ))

        // MARK: - 5. Physical Port & Device Defense (物理ポート・デバイス防御)
        let isUSBKeyboardEnabled = defaults.bool(forKey: "RoamSwitch.USBKeyboardGuardEnabled")
        let isUSBStorageEnabled = defaults.bool(forKey: "RoamSwitch.USBStorageGuardEnabled")
        let isBadUSBGuardActive = isUSBKeyboardEnabled || isUSBStorageEnabled
        let badUSBStatusStr: String = {
            if isUSBKeyboardEnabled && isUSBStorageEnabled {
                return loc("全保護有効 (キーボード & ストレージ)")
            } else if isUSBKeyboardEnabled {
                return loc("BadUSBキーボード保護有効")
            } else if isUSBStorageEnabled {
                return loc("USBストレージ保護有効")
            } else {
                return loc("停止中 (手動無効化)")
            }
        }()

        items.append(SecurityAuditItem(
            category: loc("物理ポート・デバイス防御"),
            title: loc("不正USB / BadUSB 物理ポートガード"),
            isPassed: isBadUSBGuardActive,
            statusText: badUSBStatusStr,
            detail: loc("未承認のキーボード・改造USBケーブル（O.MG / Rubber Ducky）からの自動キーストローク注入や、不正な外部ストレージのデータ持ち出しを水際で遮断します。"),
            recommendation: isBadUSBGuardActive ? loc("物理ポートの防御は万全です。") : loc("メニューバーのUSB設定より、不正USB / BadUSB物理ポートガードを有効化してください。"),
            settingsURL: nil,
            checkId: "usb_zero_trust",
            nistCsfCategories: ["PR.PS-01"]
        ))

        // macOS Accessory Connection Protection. RoamSwitch is Apple Silicon
        // only (see README's "Apple Silicon 専用"), so there is no Intel Mac
        // left to gate this on — it just runs.
        let accessoryPolicy = readAccessoryConnectionPolicy()
        items.append(SecurityAuditItem(
            category: loc("物理ポート・デバイス防御"),
            title: loc("macOS アクセサリ接続保護"),
            isPassed: accessoryPolicy?.isPassed ?? false,
            statusText: accessoryPolicy?.statusText ?? loc("状態を確認できませんでした"),
            detail: loc("新しいUSB/Thunderboltアクセサリが接続された際、Macがロックされている場合はデータ通信をOSハードウェア層で未然に遮断します。"),
            recommendation: loc("システム設定 > プライバシーとセキュリティ > アクセサリの接続を許可 が適切に設定されていることを推奨します。"),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security",
            isApplicable: accessoryPolicy != nil,
            checkId: "accessory_connection_protection",
            nistCsfCategories: ["PR.PS-01"],
            inconclusiveReason: accessoryPolicy == nil ? "not_verifiable" : nil
        ))

        // Score & Grade Calculation — excludes not-applicable items (see
        // above) from both numerator and denominator entirely, rather than
        // counting them as passed, so they neither hurt nor artificially
        // inflate the score.
        let applicableItems = items.filter { $0.isApplicable }
        let passedCount = applicableItems.filter { $0.isPassed }.count
        let totalCount = applicableItems.count
        // 全項目が測定不能・対象外のときも 0 除算にしない(その場合は 0 点=評価不能として最低ランクに落ちる)。
        let score = totalCount == 0 ? 0 : Int((Double(passedCount) / Double(totalCount)) * 100.0)

        let grade: String
        switch score {
        case 100: grade = loc("S (極めて安全)")
        case 85...99: grade = loc("A (良好)")
        case 70...84: grade = loc("B (注意)")
        default: grade = loc("C (要対策)")
        }

        return ComprehensiveSecurityReport(
            score: score,
            grade: grade,
            totalChecks: totalCount,
            passedChecks: passedCount,
            items: items,
            timestamp: Date()
        )
    }

    /// 保護レベルが信頼(open)の間、ファイアウォール/ステルスは「対象外」になる。macOS 側の設定が変わったわけではない。
    static var trustedOpenNotApplicableNote: String {
        loc("保護レベルが信頼(open)のため対象外です。macOSファイアウォール自体の状態は変更されていません。")
    }

    // MARK: - Sub-check Helpers

    /// 各コマンドは「終了コード0 かつ 期待した出力に厳密一致」したときだけ判定する。エラー文・権限エラー・空・
    /// 起動失敗は nil(= 測れなかった。「無効」とは別物)。パターンは `HealthCommandParsing`(純関数)。
    private func checkFileVault() -> Bool? {
        guard let out = runner("/usr/bin/fdesetup", ["status"]) else { return nil }
        return HealthCommandParsing.fileVault(out)
    }

    private func checkGatekeeper() -> Bool? {
        guard let out = runner("/usr/sbin/spctl", ["--status"]) else { return nil }
        return HealthCommandParsing.gatekeeper(out)
    }

    private func checkAutoUpdate() -> Bool? {
        guard let out = runner("/usr/sbin/softwareupdate", ["--schedule"]) else { return nil }
        return HealthCommandParsing.autoUpdate(out)
    }

    private func checkXProtect() -> Bool {
        let path = "/Library/Apple/System/Library/CoreServices/XProtect.bundle"
        return FileManager.default.fileExists(atPath: path)
    }

    /// Whether Remote Login (sshd) is currently registered with launchd. nil = 判別できない(権限エラー等)。
    private func checkRemoteLoginEnabled() -> Bool? {
        guard let out = runner("/bin/launchctl", ["print", "system/com.openssh.sshd"]) else { return nil }
        return HealthCommandParsing.remoteLogin(out)
    }

    /// `/etc/ssh/sshd_config`(と Include 先)は一般ユーザーが読める。`nil` = 読めない/判定できない。
    private func sshConfigIsHardened() -> Bool? {
        SSHDConfigPolicy.isHardened(SSHDConfigPolicy.read(from: sshConfigSource))
    }

    /// Reads the live value of System Settings > Privacy & Security >
    /// "Allow accessories to connect" via IOKit — previously this item
    /// hardcoded `isPassed: true` unconditionally, never actually checking
    /// the setting at all.
    ///
    /// No documented `defaults`/API exists for this (the `allowUSBRestrictedMode`
    /// key some references mention is a separate MDM policy *gate*, not the
    /// user's chosen value, and is absent entirely on an unmanaged Mac).
    /// Verified live 2026-09-11 by toggling the setting and diffing
    /// `ioreg -c IOPortTransportStateUSB3 -r -l` output: each connected
    /// port's `IOPortTransportStateUSB3` child node carries `TRM_Profile` /
    /// `TRM_ProfileDescription` ("Trust Restriction Manager"), which changed
    /// from `"Ask Every Time"` to `"Always Allow"` exactly matching the
    /// System Settings toggle — no root required to read it. Matched by
    /// description string (not the numeric `TRM_Profile`) since only the
    /// "Ask Every Time" (1) and "Always Allow" (4) values were confirmed
    /// live; the other two options' numeric encoding wasn't tested.
    private func readAccessoryConnectionPolicy() -> (isPassed: Bool, statusText: String)? {
        guard let out = runner("/usr/sbin/ioreg", ["-c", "IOPortTransportStateUSB3", "-r", "-l"]), out.status == 0,
              let profile = Self.accessoryProfile(fromIoreg: out.stdout) else { return nil }
        let isPassed = profile != "Always Allow"
        let statusText = isPassed
            ? String(format: loc("有効 (%@)"), profile)
            : String(format: loc("弱い設定 (%@)。システム設定で見直しを推奨"), profile)
        return (isPassed, statusText)
    }

    /// `    "TRM_ProfileDescription" = "Always Allow"` 形式の行から値を取り出す純関数。無ければ nil。
    static func accessoryProfile(fromIoreg output: String) -> String? {
        guard let line = output.split(separator: "\n").first(where: { $0.contains("TRM_ProfileDescription") }),
              let firstQuote = line.range(of: "\" = \""),
              let end = line[firstQuote.upperBound...].range(of: "\"") else { return nil }
        let value = String(line[firstQuote.upperBound..<end.lowerBound])
        return value.isEmpty ? nil : value
    }
}

// MARK: - 外部コマンド実行

/// 外部コマンドの結果。`status` はシグナルで終了したとき -1。
public struct CommandOutput: Equatable {
    public let status: Int32
    public let stdout: String
    public let stderr: String
    public init(status: Int32, stdout: String, stderr: String = "") {
        self.status = status
        self.stdout = stdout
        self.stderr = stderr
    }
}

/// `nil` = コマンドを起動できなかった。
typealias CommandRunner = (_ path: String, _ arguments: [String]) -> CommandOutput?

enum SystemCommand {
    /// stdout と stderr を別々に、同時に読む(片方が詰まって子プロセスが止まらないように)。
    static func run(_ path: String, _ arguments: [String]) -> CommandOutput? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        do {
            try process.run()
        } catch {
            return nil
        }
        var outData = Data()
        var errData = Data()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        DispatchQueue.global().async {
            errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.wait()
        process.waitUntilExit()
        let status: Int32 = process.terminationReason == .uncaughtSignal ? -1 : process.terminationStatus
        return CommandOutput(status: status, stdout: String(decoding: outData, as: UTF8.self), stderr: String(decoding: errData, as: UTF8.self))
    }
}

/// 各コマンドの出力を、期待したパターンに「厳密一致」したときだけ真偽にする純関数群。
/// 一致しない(エラー文・権限エラー・空・想定外の文言)は nil = 測れなかった。
enum HealthCommandParsing {
    /// 先頭の非空行(前後の空白を除く)。
    private static func firstLine(_ text: String) -> String? {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
    }

    /// `expected` はそのコマンドが出す文言(小文字化して完全一致)。`positive` に一致 = true、`negative` = false。
    /// 終了コードが 0 でないのに「有効」と言っている出力は信用しない(false は出力の主張どおりに採る)。
    private static func decide(_ out: CommandOutput, positive: [String], negative: [String]) -> Bool? {
        guard let line = firstLine(out.stdout)?.lowercased() else { return nil }
        if positive.contains(line) { return out.status == 0 ? true : nil }
        if negative.contains(line) { return false }
        return nil
    }

    /// `fdesetup status`: "FileVault is On." / "FileVault is Off."
    static func fileVault(_ out: CommandOutput) -> Bool? {
        decide(out, positive: ["filevault is on.", "filevault is on"], negative: ["filevault is off.", "filevault is off"])
    }

    /// `csrutil status`: "System Integrity Protection status: enabled." / "...: disabled."
    /// ("enabled (Custom Configuration)." のような部分的な状態は「有効」と言い切れないので nil。)
    static func sip(_ out: CommandOutput) -> Bool? {
        decide(out,
               positive: ["system integrity protection status: enabled."],
               negative: ["system integrity protection status: disabled."])
    }

    /// "enabled (Custom Configuration)." のとき、csrutil の出力全体(外れている保護の一覧を含む)。それ以外は nil。
    static func sipCustomConfigurationDetail(_ out: CommandOutput) -> String? {
        guard out.status == 0, let line = firstLine(out.stdout)?.lowercased(),
              line.hasPrefix("system integrity protection status: enabled (custom configuration)") else { return nil }
        return String(out.stdout.trimmingCharacters(in: .whitespacesAndNewlines).prefix(600))
    }

    /// `spctl --status`: "assessments enabled" / "assessments disabled"
    static func gatekeeper(_ out: CommandOutput) -> Bool? {
        decide(out, positive: ["assessments enabled"], negative: ["assessments disabled"])
    }

    /// `softwareupdate --schedule`: "Automatic checking for updates is turned on" / "...turned off"
    static func autoUpdate(_ out: CommandOutput) -> Bool? {
        decide(out,
               positive: ["automatic checking for updates is turned on"],
               negative: ["automatic checking for updates is turned off"])
    }

    /// `launchctl print system/com.openssh.sshd`:
    /// - 終了コード0 かつ先頭行が "system/com.openssh.sshd = {" → 登録済み(Remote Login オン)
    /// - 終了コード113 かつ出力に `Could not find service` → 未登録(オフ)
    /// - それ以外(権限エラー・空・想定外)は nil。
    static func remoteLogin(_ out: CommandOutput) -> Bool? {
        if out.status == 0, firstLine(out.stdout) == "system/com.openssh.sshd = {" { return true }
        if out.status == 113, (out.stdout + out.stderr).contains("Could not find service") { return false }
        return nil
    }
}

// MARK: - sshd_config

/// ファイル読み取りの差し込み口(テスト用)。`expand` は Include の1パターンが指すファイル(sshd が読む順)。
protocol SSHDConfigSource {
    func read(_ path: String) -> String?
    /// nil = ディレクトリを読めない/ディレクトリ部分にワイルドカードがある(推測しない)。
    func expand(_ pattern: String) -> [String]?
}

struct FileSSHDConfigSource: SSHDConfigSource {
    func read(_ path: String) -> String? { try? String(contentsOfFile: path, encoding: .utf8) }

    func expand(_ pattern: String) -> [String]? {
        let abs = pattern.hasPrefix("/") ? pattern : "/etc/ssh/" + pattern
        guard let slash = abs.lastIndex(of: "/") else { return nil }
        let dir = slash == abs.startIndex ? "/" : String(abs[..<slash])
        let filePattern = String(abs[abs.index(after: slash)...])
        if dir.contains("*") || dir.contains("?") { return nil }
        if !filePattern.contains("*") && !filePattern.contains("?") { return [abs] }
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return nil }
        return names.filter { SSHDConfigPolicy.globMatch(filePattern, $0) }.sorted().map { (dir as NSString).appendingPathComponent($0) }
    }
}

/// `PermitRootLogin` / `PasswordAuthentication` の実効値を、sshd 自身の規則で読む(Linux 版 sshd_config.rs と同じ観点)。
///  - キーワードは大文字小文字を区別せず、`Key value` / `Key=value` / 引用符つきの値を受け付ける。
///  - 先頭が `#` の行はコメント。
///  - 各キーワードは最初に得られた値が勝つ(後の行・後のファイルは上書きしない)。
///  - `Include` はその場で展開(相対パスは /etc/ssh 基準、ファイル名部分のワイルドカード可、深さ制限あり)。
///  - `Match` 以降は条件付きでグローバルではない(以降の Include も条件付き)。ファイルごとに独立。
///  - 読めないファイルは最初の値を隠しうるので、その時点で未設定のキーワードは「不明」(既定値とは扱わない)。
enum SSHDConfigPolicy {
    static let mainConfig = "/etc/ssh/sshd_config"
    static let maxIncludeDepth = 8

    enum Directive: Equatable {
        case set(String)   // 小文字化した値
        case `default`     // どこにも書かれておらず、全ファイルを読めた: 既定値が効く
        case unknown       // 書かれておらず、読めないファイルがあった
    }

    struct Policy: Equatable {
        var permitRootLogin: Directive
        var passwordAuthentication: Directive
    }

    private struct State {
        var root: String?
        var rootUnknown = false
        var password: String?
        var passwordUnknown = false
        mutating func readFailed() {
            if root == nil { rootUnknown = true }
            if password == nil { passwordUnknown = true }
        }
    }

    static func read(from source: SSHDConfigSource) -> Policy {
        guard let main = source.read(mainConfig) else {
            return Policy(permitRootLogin: .unknown, passwordAuthentication: .unknown)
        }
        return parse(main, source: source)
    }

    static func parse(_ mainText: String, source: SSHDConfigSource) -> Policy {
        var st = State()
        parseText(mainText, depth: 0, source: source, state: &st)
        func directive(_ v: String?, _ unknown: Bool) -> Directive { v.map(Directive.set) ?? (unknown ? .unknown : .default) }
        return Policy(permitRootLogin: directive(st.root, st.rootUnknown), passwordAuthentication: directive(st.password, st.passwordUnknown))
    }

    private static func parseText(_ text: String, depth: Int, source: SSHDConfigSource, state st: inout State) {
        var inMatch = false
        for line in text.components(separatedBy: .newlines) {
            guard let (keyword, rest) = splitLine(line) else { continue }
            if keyword == "match" { inMatch = true; continue }
            if inMatch { continue }
            switch keyword {
            case "include":
                if depth >= maxIncludeDepth { st.readFailed(); continue }
                for pattern in splitArgs(rest) {
                    guard let files = source.expand(pattern) else { st.readFailed(); continue }
                    for file in files {
                        if let t = source.read(file) { parseText(t, depth: depth + 1, source: source, state: &st) } else { st.readFailed() }
                    }
                }
            case "permitrootlogin" where st.root == nil && !st.rootUnknown:
                st.root = splitArgs(rest).first?.lowercased()
            case "passwordauthentication" where st.password == nil && !st.passwordUnknown:
                st.password = splitArgs(rest).first?.lowercased()
            default:
                break
            }
        }
    }

    /// `(小文字のキーワード, 引数テキスト)`。空行・コメント行は nil。
    static func splitLine(_ line: String) -> (String, String)? {
        let l = line.trimmingCharacters(in: .whitespaces)
        if l.isEmpty || l.hasPrefix("#") { return nil }
        let end = l.firstIndex(where: { $0.isWhitespace || $0 == "=" }) ?? l.endIndex
        let keyword = String(l[..<end]).lowercased()
        var rest = String(l[end...]).trimmingCharacters(in: .whitespaces)
        if rest.hasPrefix("=") { rest = String(rest.dropFirst()).trimmingCharacters(in: .whitespaces) }
        return (keyword, rest)
    }

    /// 空白区切りの語に分け、`"..."` の引用符を解釈する。
    static func splitArgs(_ rest: String) -> [String] {
        var out: [String] = []
        var cur = ""
        var inQuote = false
        var has = false
        for c in rest {
            if c == "\"" { inQuote.toggle(); has = true }
            else if c.isWhitespace && !inQuote { if has { out.append(cur); cur = ""; has = false } }
            else { cur.append(c); has = true }
        }
        if has { out.append(cur) }
        return out
    }

    /// `*`(任意の列)と `?`(任意の1文字)だけのマッチ。
    static func globMatch(_ pattern: String, _ name: String) -> Bool {
        func go(_ p: ArraySlice<Character>, _ n: ArraySlice<Character>) -> Bool {
            guard let first = p.first else { return n.isEmpty }
            switch first {
            case "*":
                var i = n.startIndex
                while true {
                    if go(p.dropFirst(), n[i...]) { return true }
                    if i == n.endIndex { return false }
                    i = n.index(after: i)
                }
            case "?":
                return !n.isEmpty && go(p.dropFirst(), n.dropFirst())
            default:
                return n.first == first && go(p.dropFirst(), n.dropFirst())
            }
        }
        return go(Array(pattern)[...], Array(name)[...])
    }

    /// 鍵認証のみ(rootログインを拒否し、パスワード認証も拒否)なら true、そうでなければ false。判定できなければ nil。
    /// 直接の root ログインが許されているなら、パスワード側が不明でも false。
    static func isHardened(_ p: Policy) -> Bool? {
        let rootBlocked: Bool?
        switch p.permitRootLogin {
        case .unknown: rootBlocked = nil
        case .default: rootBlocked = true   // 既定は prohibit-password
        case .set(let v): rootBlocked = ["no", "prohibit-password", "without-password", "forced-commands-only"].contains(v)
        }
        let passwordOff: Bool?
        switch p.passwordAuthentication {
        case .unknown: passwordOff = nil
        case .default: passwordOff = false  // 既定は yes
        case .set(let v): passwordOff = v == "no"
        }
        if rootBlocked == false { return false }
        guard let rb = rootBlocked, let po = passwordOff else { return nil }
        return rb && po
    }
}
