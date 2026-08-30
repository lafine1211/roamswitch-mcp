// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.0 (build 23).
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

    public init(category: String, title: String, isPassed: Bool, statusText: String, detail: String, recommendation: String, settingsURL: String?, isApplicable: Bool = true) {
        self.category = category
        self.title = title
        self.isPassed = isPassed
        self.statusText = statusText
        self.detail = detail
        self.recommendation = recommendation
        self.settingsURL = settingsURL
        self.isApplicable = isApplicable
    }
}

public struct SecurityHealthStatus: Equatable {
    public var isFileVaultEnabled: Bool
    public var isSIPEnabled: Bool
    public var isGatekeeperEnabled: Bool
    public var isAutoUpdateEnabled: Bool
    public var isXProtectActive: Bool

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

    func checkHealth() -> SecurityHealthStatus {
        let isFileVault = checkFileVault()
        let isSIP = checkSIP()
        let isGatekeeper = checkGatekeeper()
        let isAutoUpdate = checkAutoUpdate()
        let isXProtect = checkXProtect()

        return SecurityHealthStatus(
            isFileVaultEnabled: isFileVault,
            isSIPEnabled: isSIP,
            isGatekeeperEnabled: isGatekeeper,
            isAutoUpdateEnabled: isAutoUpdate,
            isXProtectActive: isXProtect
        )
    }

    func generateComprehensiveReport(
        wifiInfo: WiFiInfo,
        arpStatus: ARPMonitorStatus,
        listeningPorts: [ListeningPortInfo],
        activeSecurityLevel: SecurityLevel
    ) -> ComprehensiveSecurityReport {
        let health = checkHealth()
        var items: [SecurityAuditItem] = []

        // MARK: - 1. System Defense (システム堅牢性)
        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("FileVault (ディスク暗号化)"),
            isPassed: health.isFileVaultEnabled,
            statusText: health.isFileVaultEnabled ? loc("有効 (暗号化保護中)") : loc("無効 (未保護)"),
            detail: loc("MacのSSD/HDDストレージ全体をXTS-AES 128暗号で暗号化し、盗難や紛失時のデータ抜き取りを防ぎます。"),
            recommendation: health.isFileVaultEnabled ? loc("設定は万全です。") : loc("システム設定 > プライバシーとセキュリティからFileVaultをオンにしてください。"),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security?FileVault"
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("SIP (システム完全性保護)"),
            isPassed: health.isSIPEnabled,
            statusText: health.isSIPEnabled ? loc("有効 (システム保護中)") : loc("無効 (危険)"),
            detail: loc("root権限を持つプロセスであってもmacOSの重要システムファイルやカーネルの改ざんを禁止します。"),
            recommendation: health.isSIPEnabled ? loc("設定は万全です。") : loc("リカバリーモードで起動し、csrutil enable を実行してSIPを有効化してください。"),
            settingsURL: nil
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("Gatekeeper (アプリ検証)"),
            isPassed: health.isGatekeeperEnabled,
            statusText: health.isGatekeeperEnabled ? loc("有効 (悪質アプリ遮断)") : loc("無効 (危険)"),
            detail: loc("Apple公認の開発者署名がない未承認アプリや改ざんされたバイナリの起動を自動ブロックします。"),
            recommendation: health.isGatekeeperEnabled ? loc("設定は万全です。") : loc("システム設定 > プライバシーとセキュリティからアプリの実行許可を適切に設定してください。"),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security"
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("自動セキュリティアップデート"),
            isPassed: health.isAutoUpdateEnabled,
            statusText: health.isAutoUpdateEnabled ? loc("有効 (最新パッチ自動適用)") : loc("無効 (推奨設定外)"),
            detail: loc("緊急セキュリティ対応（RSR）やシステム脆弱性パッチを自動的にバックグラウンドでダウンロード・適用します。"),
            recommendation: health.isAutoUpdateEnabled ? loc("設定は万全です。") : loc("システム設定 > 一般 > ソフトウェアアップデートから自動更新を有効にしてください。"),
            settingsURL: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension"
        ))

        items.append(SecurityAuditItem(
            category: loc("システム堅牢性"),
            title: loc("Apple XProtect (マルウェア検知・自動駆除)"),
            isPassed: health.isXProtectActive,
            statusText: health.isXProtectActive ? loc("稼働中 (常時監視)") : loc("停止中"),
            detail: loc("Apple公式のシグネチャベースのマルウェア検知およびRemediator自動駆除エンジンが常時稼働しています。"),
            recommendation: loc("定期的に最新のmacOSアップデートを適用することで定義が最新に保たれます。"),
            settingsURL: nil
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
            detail: loc("外部からの未承認な着信TCP/UDPパケットをカーネルのパケットフィルタ層で自動破棄します。"),
            recommendation: isTrustedOpenNetwork ? loc("信頼ネットワークのため意図的に保護を解除しています。公衆Wi-Fi等、信頼できない場所では別の保護レベルを選んでください。") : (activeSecurityLevel.firewallBlockAll ? loc("外部接続は完全に遮断されています。") : loc("外出先では最大ロックダウンまたは標準保護への設定を推奨します。")),
            settingsURL: "x-apple.systempreferences:com.apple.preference.security?Firewall",
            isApplicable: !isTrustedOpenNetwork
        ))

        let isStealthPassed = activeSecurityLevel.firewallBlockAll
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("ステルスモード (外部Ping隠蔽)"),
            isPassed: isTrustedOpenNetwork ? true : isStealthPassed,
            statusText: isTrustedOpenNetwork ? loc("対象外 (信頼ネットワークのため意図的に無効)") : (isStealthPassed ? loc("有効 (隠蔽中)") : loc("無効 (Ping応答許可)")),
            detail: loc("ネットワークスキャンやPing（ICMP）に対して無応答にすることで、外部からMacの存在自体を隠蔽します。"),
            recommendation: isTrustedOpenNetwork ? loc("信頼ネットワークのため意図的に保護を解除しています。") : (isStealthPassed ? loc("外部スキャンから保護されています。") : loc("公衆Wi-Fi接続時はステルスモードの有効化を推奨します。")),
            settingsURL: nil,
            isApplicable: !isTrustedOpenNetwork
        ))

        let isWiFiPassed = wifiInfo.securityLevel.isSafe
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("Wi-Fi 暗号化強度"),
            isPassed: isWiFiPassed,
            statusText: wifiInfo.securityLevel.label,
            detail: loc("接続中のWi-Fiアクセスポイントが強力な暗号化（WPA2-AES / WPA3）で通信を保護しているかを検証します。"),
            recommendation: isWiFiPassed ? loc("通信は安全に暗号化されています。") : loc("暗号化のないOpen Wi-Fiや古いWEPは盗聴の危険があるため、VPNまたはロックダウンを使用してください。"),
            settingsURL: "x-apple.systempreferences:com.apple.wifi-settings-extension"
        ))

        let isARPPassed = !arpStatus.isSpoofingDetected
        items.append(SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("ARP スプーフィング監視 (中間者攻撃)"),
            isPassed: isARPPassed,
            statusText: isARPPassed ? loc("正常 (盗聴未検知)") : loc("⚠️ スプーフィング疑い検知"),
            detail: loc("同一LAN内の悪意ある端末がルーターになりすまして通信を盗聴・改ざんする中間者攻撃（MitM）を監視します。"),
            recommendation: isARPPassed ? loc("中間者攻撃の兆候はありません。") : loc("直ちにネットワークから切断し、信頼できる接続に変更してください。"),
            settingsURL: nil
        ))

        // MARK: - 3. Services & Ports (サービス・ポート露出)
        let exposedCount = listeningPorts.filter { $0.isGloballyExposed }.count
        let isPortPassed = exposedCount == 0 || activeSecurityLevel.firewallBlockAll
        let portStatusStr = activeSecurityLevel.firewallBlockAll ? loc("🛡️ ファイアウォール遮断中 (安全)") : (exposedCount == 0 ? loc("公開ポートなし (安全)") : String(format: loc("⚠️ %d個のポートが露出中"), exposedCount))
        items.append(SecurityAuditItem(
            category: loc("サービス・ポート露出"),
            title: loc("外部公開ポート"),
            isPassed: isPortPassed,
            statusText: portStatusStr,
            detail: loc("外部からの接続を待ち受けているTCP/UDPポートを検査します。ファイアウォール有効時は全ポートが保護されます。"),
            recommendation: isPortPassed ? loc("外部からの不正アクセスは遮断されています。") : loc("不要な開発サーバーを停止するか、ファイアウォールを有効にしてください。"),
            settingsURL: nil
        ))

        // MARK: - 4. Malware & Download Protection (マルウェア・ダウンロード保護)
        let isDownloadGuardEnabled = UserDefaults.standard.object(forKey: "RoamSwitch.WebMailDownloadGuardEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "RoamSwitch.WebMailDownloadGuardEnabled")
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
            settingsURL: nil
        ))

        let isDNSGuardEnabled = UserDefaults.standard.object(forKey: "RoamSwitch.DNSThreatGuardEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "RoamSwitch.DNSThreatGuardEnabled")
        let dnsProviderRaw = UserDefaults.standard.string(forKey: "RoamSwitch.DNSThreatGuardProvider") ?? "quad9"
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
            settingsURL: nil
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
            settingsURL: nil
        ))

        // Score & Grade Calculation — excludes not-applicable items (see
        // above) from both numerator and denominator entirely, rather than
        // counting them as passed, so they neither hurt nor artificially
        // inflate the score.
        let applicableItems = items.filter { $0.isApplicable }
        let passedCount = applicableItems.filter { $0.isPassed }.count
        let totalCount = applicableItems.count
        let score = Int((Double(passedCount) / Double(totalCount)) * 100.0)

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

    // MARK: - Sub-check Helpers

    private func checkFileVault() -> Bool {
        let output = runCommand(path: "/usr/bin/fdesetup", arguments: ["status"])
        return output.lowercased().contains("on")
    }

    private func checkSIP() -> Bool {
        let output = runCommand(path: "/usr/bin/csrutil", arguments: ["status"])
        return output.lowercased().contains("enabled")
    }

    private func checkGatekeeper() -> Bool {
        let output = runCommand(path: "/usr/sbin/spctl", arguments: ["--status"])
        return output.lowercased().contains("assessments enabled")
    }

    private func checkAutoUpdate() -> Bool {
        let output = runCommand(path: "/usr/sbin/softwareupdate", arguments: ["--schedule"])
        return output.lowercased().contains("on")
    }

    private func checkXProtect() -> Bool {
        let path = "/Library/Apple/System/Library/CoreServices/XProtect.bundle"
        return FileManager.default.fileExists(atPath: path)
    }

    private func runCommand(path: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
