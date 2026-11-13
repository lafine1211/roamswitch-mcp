// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.33 (build 212).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The protection presets of the Mac app: one choice that sets the guards' switches and a few numbers together.
///
/// This file is the table and the rules around it, kept free of any singleton, AppKit and licence so it can be tested
/// against a throwaway `UserDefaults` suite and compiled into the MCP server (which reads the current preset). What
/// turns a changed row into a started or stopped guard is `ProtectionPresetApplier`.
///
/// The four presets (the owner's definition, 2026-11-13):
///  - light: the smallest resident cost. The core detections stay; what costs CPU, disk reads or wake-ups goes.
///  - balanced: resource use against security. The shipped defaults, except where a heavy job gives little for its
///    cost (the home-folder walk of the start-up watch: 21 percent of one core in the 30-second sample of 2026-11-13).
///  - standard: the ordinary security setting that does not weigh resources. Everything that costs only resources
///    is on (process-execution record, file-open record, short intervals). What would raise false positives, stop
///    the person's work or send something out stays a separate choice, listed when the preset is applied.
///  - maximum: standard plus everything that can raise false positives or stop work, for every setting the app can
///    write itself. OS permissions the app cannot grant (Full Disk Access and the like) are never written; they are
///    listed as "needs a permission".
///
/// A preset never touches: the network trust model (`awaySecurityLevel`, registered networks, the manual override),
/// allow-lists and watched folders, thresholds (SSH counts), the VPN, the Sensor pairing and the event forwarding
/// (each needs an address or a server only the person has), the helper-side limits that need an administrator.
public enum ProtectionPreset: String, CaseIterable, Codable, Sendable {
    case light, balanced, standard, maximum

    /// Japanese (the catalog key) of the name shown to the person.
    public var nameKey: String {
        switch self {
        case .light: return "軽量"
        case .balanced: return "バランス"
        case .standard: return "標準セキュリティ"
        case .maximum: return "最大セキュリティ"
        }
    }
}

public enum PresetValue: Equatable, Sendable, Codable {
    case bool(Bool)
    case int(Int)
    case string(String)

    public var boolValue: Bool? { if case .bool(let b) = self { return b }; return nil }
}

/// Why a setting is not simply "on" for everyone: shown, one line per setting, before the maximum preset is applied.
public enum PresetRisk: String, Equatable, Sendable {
    /// More notifications or blocks that are not attacks.
    case falsePositive
    /// The person's work stops or changes (a file is quarantined, a USB device waits, a name does not resolve).
    case stopsWork
    /// Something is sent to the outside (a feed fetch, a registry call, DNS queries).
    case sendsOut
    /// Quarantines the network (Air-Gap) on a heuristic.
    case isolates
}

/// A thing that must be present for a setting to do anything. The app never grants it; when it is missing the setting
/// is not written (and is listed as needing it).
public enum PresetPrerequisite: String, Equatable, Sendable {
    case accessibility
    case blueutil
}

public struct PresetSetting: Sendable {
    /// Stable short id (the `get_guard_status` key for a guard).
    public let id: String
    public let key: String
    /// Japanese (catalog key) of the setting's name.
    public let titleKey: String
    /// The value in force while the key has never been written.
    public let unset: PresetValue
    /// The value the shipped defaults aim for; differs from `unset` only for the Pro default-on guards (Pro writes the
    /// key once at activation, so an unwritten key means "off" until then).
    public let shipDefault: PresetValue
    public let values: [ProtectionPreset: PresetValue]
    /// Whether the setting does something on a Free Mac too (those are reset when the licence is removed).
    public let worksWithoutPro: Bool
    public let risks: Set<PresetRisk>
    /// Japanese (catalog key) of the one-line warning, and the presets in whose confirmation it appears.
    public let warningKey: String?
    public let warnIn: Set<ProtectionPreset>
    public let prerequisite: PresetPrerequisite?
    /// The values the setting can have, when it is a fixed list (nil: any).
    public let allowed: [PresetValue]?

    public func value(for preset: ProtectionPreset) -> PresetValue { values[preset] ?? unset }
}

public enum ProtectionPresetTable {

    public static let selectedKey = "RoamSwitch.Preset.Selected"
    public static let appliedAtKey = "RoamSwitch.Preset.AppliedAt"
    /// What the last application replaced (JSON `UndoRecord`), for "undo the last application". One level only.
    public static let undoKey = "RoamSwitch.Preset.Undo"
    /// Set once, on the first Pro activation of this Mac; cleared when the offer of the standard preset is shown.
    public static let activationOfferPendingKey = "RoamSwitch.Preset.ActivationOfferPending"

    // MARK: - The table

    private static func b(_ v: Bool) -> PresetValue { .bool(v) }

    /// A row. `v` is [light, balanced, standard, maximum].
    private static func row(_ id: String, _ key: String, _ title: String, unset: PresetValue, ship: PresetValue? = nil,
                            _ v: [PresetValue], free: Bool = false, risks: Set<PresetRisk> = [], warning: String? = nil,
                            warnIn: Set<ProtectionPreset> = [.maximum], needs: PresetPrerequisite? = nil,
                            allowed: [PresetValue]? = nil) -> PresetSetting {
        precondition(v.count == 4, id)
        return PresetSetting(id: id, key: "RoamSwitch." + key, titleKey: title, unset: unset, shipDefault: ship ?? unset,
                             values: [.light: v[0], .balanced: v[1], .standard: v[2], .maximum: v[3]],
                             worksWithoutPro: free, risks: risks, warningKey: warning, warnIn: warnIn, prerequisite: needs,
                             allowed: allowed)
    }

    /// A guard that Pro switches on at activation: unwritten is off, the shipped default is on.
    private static func proDefault(_ id: String, _ key: String, _ title: String, _ v: [Bool]) -> PresetSetting {
        row(id, key, title, unset: b(false), ship: b(true), v.map(b))
    }

    /// A switch that is on unless the person turned it off.
    private static func onUnlessOff(_ id: String, _ key: String, _ title: String, _ v: [Bool], free: Bool = false) -> PresetSetting {
        row(id, key, title, unset: b(true), v.map(b), free: free)
    }

    /// A switch that stays off until chosen.
    private static func optIn(_ id: String, _ key: String, _ title: String, _ v: [Bool], risks: Set<PresetRisk> = [],
                              warning: String? = nil, warnIn: Set<ProtectionPreset> = [.maximum], needs: PresetPrerequisite? = nil,
                              free: Bool = false) -> PresetSetting {
        row(id, key, title, unset: b(false), v.map(b), free: free, risks: risks, warning: warning, warnIn: warnIn, needs: needs)
    }

    private static func ints(_ xs: [Int]) -> [PresetValue] { xs.map { .int($0) } }
    private static func strs(_ xs: [String]) -> [PresetValue] { xs.map { .string($0) } }

    /// Light, balanced, standard, maximum.
    public static let settings: [PresetSetting] = [
        // ---- Detection that runs in the app (Pro) ----
        proDefault("portAnomalyGuard", "PortAnomalyGuardEnabled", "未知のリスニングポートの自動遮断", [true, true, true, true]),
        proDefault("portScanGuard", "PortScanGuardEnabled", "着信ポートスキャンの検知", [false, true, true, true]),
        proDefault("sshGuard", "SSHGuardEnabled", "SSH総当たり検知", [true, true, true, true]),
        proDefault("ransomwareCanaryGuard", "RansomwareCanaryGuardEnabled", "ランサムウェアおとりファイル検知", [true, true, true, true]),
        proDefault("ransomwareEntropyGuard", "RansomwareEntropyGuardEnabled", "汎用ランサムウェア検知(エントロピー解析)", [false, true, true, true]),
        proDefault("credentialHoneytokenGuard", "CredentialHoneytokenGuardEnabled", "認証情報ハニートークン", [true, true, true, true]),
        optIn("browserCredentialWatchGuard", "BrowserCredentialWatchGuardEnabled", "ブラウザ認証情報アクセス監視", [false, false, false, true],
              risks: [.falsePositive], warning: "バックアップ、同期、パスワード管理ツールのインポートでも通知が出ます。"),
        proDefault("scheduledLogAudit", "ScheduledLogAuditEnabled", "定期ログ監査", [false, true, true, true]),
        proDefault("criticalPathFim", "CriticalPathFimEnabled", "重要システムファイルの改ざん監視", [true, true, true, true]),
        proDefault("lockfileTamperGuard", "LockfileTamperGuardEnabled", "依存関係ロックファイルの改ざん監視", [true, true, true, true]),
        proDefault("reverseShellWatch", "ReverseShellWatchEnabled", "リバースシェルの常時監視", [true, true, true, true]),
        optIn("reverseShellIncludePrivate", "ReverseShellWatch.IncludePrivateV1", "リバースシェル検知: ローカルネットワーク内の接続先も対象にする",
              [false, false, false, true], risks: [.falsePositive],
              warning: "ssh の ProxyCommand、リモート開発、コンテナの通信でも通知が出ます。"),
        proDefault("networkSettingsWatch", "NetworkSettingsWatchEnabled", "ネットワーク設定の変化の監視", [true, true, true, true]),
        proDefault("arpSpoofAutoContainment", "ARPSpoofAutoContainmentEnabled", "ARPスプーフィング検知時の自動遮断", [true, true, true, true]),
        proDefault("runtimeThreatContainment", "RuntimeThreatContainmentEnabled", "XProtectが検知したときの自動遮断", [true, true, true, true]),
        optIn("clickFixGuard", "ClickFixGuardEnabled", "ClickFixガード（不審なコマンド検知）", [false, false, true, true],
              risks: [.isolates, .falsePositive], warning: "コマンドの履歴にClickFixの形が見つかると、ネットワークが自動で隔離される(Air-Gap)ので、誤検知でも通信が止まります。",
              warnIn: [.standard, .maximum]),
        optIn("dockerEventGuard", "DockerEventGuardEnabled", "Dockerリスク検知", [false, false, false, true], risks: [.falsePositive],
              warning: "開発では日常的な docker.sock のマウントや特権コンテナでも通知が出ます。"),
        // ---- Records (Pro; the process record needs Full Disk Access) ----
        optIn("execRecorder", "ExecRecorder.Enabled", "プロセス実行の記録", [false, false, true, true], warning: "フルディスクアクセスの許可が要ります。コマンドの引数に機密が含まれることがあります。ヘルパーの解析プロセスが、2GB前後のメモリを使うことがあります。",
              warnIn: [.standard, .maximum]),
        optIn("fileActors", "ExecRecorder.FileActorsV1", "ファイルを開いたプロセスの記録", [false, false, true, true],
              warning: "1コアの約5%を使い続けます(上限を超えると自動で止まります)。", warnIn: [.standard, .maximum]),
        row("execMaxTotalMB", "ExecRecorder.MaxTotalMB", "プロセス実行の記録の保存量(MB)", unset: .int(200), ints([100, 200, 500, 500]),
            allowed: ints([50, 100, 200, 500, 1000])),
        row("execMaxAgeDays", "ExecRecorder.MaxAgeDays", "プロセス実行の記録の保存日数", unset: .int(14), ints([7, 14, 30, 30]),
            allowed: ints([3, 7, 14, 30, 60])),
        // ---- File guards (Pro; on unless turned off) ----
        onUnlessOff("webMailDownloadGuard", "WebMailDownloadGuardEnabled", "ダウンロードの自動スキャン", [true, true, true, true]),
        onUnlessOff("persistenceMonitor", "PersistenceMonitorEnabled", "自動起動登録(LaunchAgent/Daemon)の監視", [true, true, true, true]),
        // ---- Network ----
        onUnlessOff("dnsThreatGuard", "DNSThreatGuardEnabled", "DNS脅威保護", [true, true, true, true]),
        row("dnsThreatGuardScope", "DNSThreatGuardScope", "DNS脅威保護の適用範囲", unset: .string("awayOnly"),
            strs(["awayOnly", "awayOnly", "awayOnly", "always"]), risks: [.stopsWork, .sendsOut],
            warning: "自宅でも常にDNSをプロバイダ経由にします。ルーター名や社内の名前が引けなくなることがあり、問い合わせが常に外へ出ます。",
            allowed: strs(["awayOnly", "always"])),
        row("linkGuardMode", "LinkGuardMode", "リンク保護のモード", unset: .string("block"), strs(["block", "block", "block", "block"]),
            allowed: strs(["off", "warn", "block"])),
        onUnlessOff("linkGuardFeedUpdates", "LinkGuardUpdatesEnabled", "リンク保護の一覧の自動更新", [true, true, true, true]),
        // ---- Notices that run in the app ----
        onUnlessOff("secretLeakClipboardAuditor", "SecretLeakAuditorEnabled", "クリップボードの確認", [false, true, true, true], free: true),
        onUnlessOff("agentSetupWatch", "AgentSetupWatchEnabled", "AIエージェント設定の変更の通知", [true, true, true, true]),
        onUnlessOff("npmSupplyWatch", "NpmSupplyWatchEnabled", "npm の依存関係の自動確認", [true, true, true, true]),
        onUnlessOff("dependencyWatch", "DependencyWatchEnabled", "依存パッケージの脆弱性の自動確認", [true, true, true, true]),
        onUnlessOff("configRegressionNotice", "ConfigRegressionNoticeEnabled", "設定が弱くなったときの通知", [true, true, true, true]),
        onUnlessOff("devicePostureTrust", "DevicePosture.Enabled", "侵害の兆候での標準保護への切り替え", [true, true, true, true]),
        row("devicePostureWindowHours", "DevicePosture.WindowHours", "侵害の兆候を数える期間(時間)", unset: .int(6), ints([6, 6, 6, 24]), risks: [.stopsWork],
            warning: "侵害の兆候のあと、信頼ネットワークが標準保護に下がる時間が、最大24時間に延びます。"),
        // ---- Choices that send something out ----
        optIn("activeVulnScan", "ActiveVulnScanEnabled", "実証型脆弱性診断", [false, false, false, true], risks: [.sendsOut],
              warning: "脆弱性の一覧(CVEマップ)を毎日取得する通信が始まります。診断そのものは、このMacの127.0.0.1にだけ送ります。"),
        optIn("npmAuditSignatures", "NpmAuditSignaturesEnabled", "npm署名/provenance検証", [false, false, false, true], risks: [.sendsOut],
              warning: "実行のたびに npmjs.com へ接続します。"),
        // ---- Choices that stop the person's work ----
        optIn("usbKeyboardGuard", "USBKeyboardGuardEnabled", "BadUSB / 物理キーボード承認ガード", [false, false, false, true], risks: [.stopsWork],
              warning: "承認するまで、新しいUSBキーボードは使えません。アクセシビリティの許可が要ります。", needs: .accessibility),
        optIn("usbStorageGuard", "USBStorageGuardEnabled", "USBストレージの自動遮断", [false, false, false, true], risks: [.stopsWork],
              warning: "許可リストにないUSBメモリは読み取り専用になり、確認が毎回出ます。"),
        optIn("bluetoothGuard", "BluetoothGuardEnabled", "Bluetoothの自動オフ", [false, false, false, true], risks: [.stopsWork],
              warning: "未登録のネットワークでBluetoothが切れ、AirPodsなども止まります。blueutil(Homebrew)が要ります。", needs: .blueutil),
        optIn("gatewayARPLock", "GatewayARPLockEnabled", "ゲートウェイARP/NDPの固定", [false, false, false, true], risks: [.stopsWork],
              warning: "ルーターを交換したあとなど、古い固定のせいで接続できなくなることがあります。"),
        row("webRulesQuarantineLevel", "WebRules.QuarantineLevel", "Webシェル検知の自動隔離の範囲", unset: .string("critical"),
            strs(["critical", "critical", "critical", "high"]), risks: [.falsePositive, .stopsWork],
            warning: "重大度が高いだけの検知も自動で隔離します。作業中のファイルが動くことがあります。", allowed: strs(["off", "critical", "high"])),
        // ---- Recovery ----
        row("ransomwareSnapshotIntervalHours", "RansomwareSnapshots.IntervalHours", "事前スナップショットの間隔", unset: .int(6), ints([12, 6, 6, 6]),
            free: true, allowed: ints([0, 1, 3, 6, 12, 24])),
        // ---- Heavy jobs that had no switch (new keys; the defaults are today's behaviour) ----
        onUnlessOff("webMailClamAVStage", "WebMailGuard.ClamAVStageEnabled", "ダウンロードのClamAVスキャン", [false, true, true, true]),
        onUnlessOff("sentinelDailyClamAVScan", "Sentinel.DailyClamAVScanEnabled", "定期ClamAVスキャン(1日1回)", [false, true, true, true]),
        row("sentinelDiagnosisHours", "Sentinel.DiagnosisIntervalHours", "総合診断の間隔(時間)", unset: .int(4), ints([8, 4, 1, 1]), free: true,
            allowed: ints([1, 2, 4, 8, 24])),
        onUnlessOff("webRulesDailyFolderScan", "WebRules.DailyFolderScanEnabled", "Web開発フォルダの日次スキャン", [false, true, true, true]),
        row("startupScriptWalkSecs", "StartupScriptWatch.WalkIntervalSecs", "自動起動ファイルの走査間隔(秒)", unset: .int(60), ints([600, 300, 30, 30]),
            allowed: ints([30, 60, 300, 600])),
        row("dependencyWatchBackstopHours", "DependencyWatch.BackstopHours", "依存関係の定期確認の間隔(時間)", unset: .int(24), ints([72, 24, 6, 6]),
            allowed: ints([6, 12, 24, 72])),
        row("agentSetupFallbackSecs", "AgentSetupWatch.FallbackSecs", "AIエージェント設定の定期確認の間隔(秒)", unset: .int(300), ints([900, 300, 60, 60]),
            allowed: ints([60, 300, 900])),
        row("reverseShellScanSecs", "ReverseShellWatch.ScanIntervalSecs", "リバースシェル監視の間隔(秒)", unset: .int(4), ints([15, 4, 4, 4]),
            allowed: ints([2, 4, 8, 15])),
    ]

    /// Every key the table writes.
    public static var keys: [String] { settings.map(\.key) }

    public static func setting(id: String) -> PresetSetting? { settings.first { $0.id == id } }

    // MARK: - Things a preset never writes

    /// Keys a preset leaves alone, with the reason. The tests check that none of them is in the table.
    public static let untouchedKeys: [String] = [
        "RoamSwitch.awaySecurityLevel", "RoamSwitch.trustedNetworks", "RoamSwitch.manualOverrideLevel", // the trust model
        "RoamSwitch.SSHGuard.MaxFailures", "RoamSwitch.SSHGuard.WindowSecs", "RoamSwitch.SSHGuard.ExemptList", // thresholds, user data
        "RoamSwitch.PortScanGuard.BlockEnabled", "RoamSwitch.SSHGuard.BlockEnabled",
        "RoamSwitch.WireGuardVPNEnabled", "RoamSwitch.VPNBackend", "RoamSwitch.SensorPairingEnabled",     // need a server or an address
        "RoamSwitch.EventForward.enabled", "RoamSwitch.WebRules.AccountAction",                            // a destination, an administrator
        "RoamSwitch.ReverseShellWatch.AllowedV1", "RoamSwitch.WebMailGuardCustomWatchedPaths",             // the person's own lists
        "RoamSwitch.DNSThreatGuardProvider", "RoamSwitch.PackageCveWatchedFolders",
        "RoamSwitch.AirGapAutoWiFiKillEnabled", "RoamSwitch.ProSecurityDefaultsApplied",
    ]

    // MARK: - Reading and comparing

    public static func storedValue(of setting: PresetSetting, defaults: UserDefaults) -> PresetValue? {
        guard let object = defaults.object(forKey: setting.key) else { return nil }
        switch setting.unset {
        case .bool: return (object as? Bool).map { .bool($0) } ?? (object as? NSNumber).map { .bool($0.boolValue) }
        case .int: return (object as? NSNumber).map { .int($0.intValue) }
        case .string: return (object as? String).map { .string($0) }
        }
    }

    /// What the app does now for `setting`: the stored value, or the value of an unwritten key.
    public static func effectiveValue(of setting: PresetSetting, defaults: UserDefaults) -> PresetValue {
        storedValue(of: setting, defaults: defaults) ?? setting.unset
    }

    public static func matches(_ preset: ProtectionPreset, defaults: UserDefaults) -> Bool {
        settings.allSatisfy { effectiveValue(of: $0, defaults: defaults) == $0.value(for: preset) }
    }

    /// True when nothing has been moved off the shipped defaults: each key is unwritten or holds the shipped value.
    public static func isDefaultState(defaults: UserDefaults) -> Bool {
        settings.allSatisfy { setting in
            guard let stored = storedValue(of: setting, defaults: defaults) else { return true }
            return stored == setting.shipDefault
        }
    }

    public enum State: Equatable, Sendable {
        case preset(ProtectionPreset)
        /// Never chosen and nothing moved off the shipped defaults.
        case defaultSettings
        /// Something was changed one by one (or a preset was applied and then changed).
        case custom
    }

    public static func state(defaults: UserDefaults) -> State {
        // The chosen preset first (two presets can never match at once, but the chosen one is the one to confirm).
        if let chosen = selected(defaults: defaults), matches(chosen, defaults: defaults) { return .preset(chosen) }
        if let found = ProtectionPreset.allCases.first(where: { matches($0, defaults: defaults) }) { return .preset(found) }
        if defaults.string(forKey: selectedKey) == nil, isDefaultState(defaults: defaults) { return .defaultSettings }
        return .custom
    }

    public static func selected(defaults: UserDefaults) -> ProtectionPreset? {
        defaults.string(forKey: selectedKey).flatMap(ProtectionPreset.init(rawValue:))
    }

    // MARK: - Planning and writing

    public struct Change: Equatable, Sendable {
        public let id: String
        public let key: String
        public let from: PresetValue
        public let to: PresetValue
    }

    /// The settings whose effective value differs from `preset`'s, minus those whose prerequisite is missing
    /// (`unmet`). The missing ones are returned separately: they are not written, and they are listed.
    public static func plan(for preset: ProtectionPreset, defaults: UserDefaults,
                            unmet: Set<PresetPrerequisite> = []) -> (changes: [Change], notWritten: [PresetSetting]) {
        var changes: [Change] = []
        var notWritten: [PresetSetting] = []
        for setting in settings {
            let target = setting.value(for: preset)
            let now = effectiveValue(of: setting, defaults: defaults)
            guard now != target else { continue }
            if let need = setting.prerequisite, unmet.contains(need), target == .bool(true) {
                notWritten.append(setting)
                continue
            }
            changes.append(Change(id: setting.id, key: setting.key, from: now, to: target))
        }
        return (changes, notWritten)
    }

    /// Writes the changes and the chosen preset. Only keys of the table are written. Unless `recordUndo` is false, what
    /// the changes replace is kept first (`UndoRecord`), so the last application can be undone.
    public static func write(_ changes: [Change], preset: ProtectionPreset, defaults: UserDefaults, now: Date = Date(),
                             recordUndo: Bool = true) {
        if recordUndo { saveUndo(UndoRecord.capture(changes, applying: preset, defaults: defaults, now: now), defaults: defaults) }
        for change in changes { set(change.to, forKey: change.key, defaults: defaults) }
        defaults.set(preset.rawValue, forKey: selectedKey)
        defaults.set(now.timeIntervalSince1970, forKey: appliedAtKey)
    }

    private static func set(_ value: PresetValue, forKey key: String, defaults: UserDefaults) {
        switch value {
        case .bool(let v): defaults.set(v, forKey: key)
        case .int(let v): defaults.set(v, forKey: key)
        case .string(let v): defaults.set(v, forKey: key)
        }
    }

    // MARK: - New Pro activation: the default is "balanced"

    /// The first Pro activation of a Mac. The shipped defaults are what the guards write for themselves; the balanced
    /// preset differs from them in a few settings that are read where they are used (today the home-folder walk of
    /// the start-up watch: 300 seconds instead of 60). A key that already holds a value is the person's choice and is
    /// never touched. When the settings then match the balanced preset, it is recorded as the chosen one, so the menu
    /// says "バランス". No undo record: the person did not apply anything.
    /// Returns the keys written.
    @discardableResult
    public static func adoptBalancedOnFirstActivation(defaults: UserDefaults, now: Date = Date()) -> [Change] {
        var changes: [Change] = []
        for setting in settings {
            let target = setting.value(for: .balanced)
            guard target != setting.shipDefault, storedValue(of: setting, defaults: defaults) == nil else { continue }
            changes.append(Change(id: setting.id, key: setting.key, from: setting.unset, to: target))
        }
        for change in changes { set(change.to, forKey: change.key, defaults: defaults) }
        if matches(.balanced, defaults: defaults) {
            defaults.set(ProtectionPreset.balanced.rawValue, forKey: selectedKey)
            defaults.set(now.timeIntervalSince1970, forKey: appliedAtKey)
        }
        return changes
    }

    /// The offer of the standard preset is waiting for the person (set on the first activation, cleared when shown).
    public static func isActivationOfferPending(defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: activationOfferPendingKey)
    }

    // MARK: - Undo (the last application only)

    /// What one application replaced: for each key it wrote, the value stored before (nil: the key was not written),
    /// and the choice that was in force.
    public struct UndoRecord: Codable, Equatable, Sendable {
        public struct Entry: Codable, Equatable, Sendable {
            public let id: String
            public let key: String
            public let previous: PresetValue?
        }
        /// The preset that was applied.
        public let applied: ProtectionPreset
        public let previousSelected: ProtectionPreset?
        public let previousAppliedAt: Double?
        public let entries: [Entry]
        public let at: Double

        static func capture(_ changes: [Change], applying preset: ProtectionPreset, defaults: UserDefaults, now: Date) -> UndoRecord {
            UndoRecord(applied: preset,
                       previousSelected: ProtectionPresetTable.selected(defaults: defaults),
                       previousAppliedAt: defaults.object(forKey: ProtectionPresetTable.appliedAtKey) as? Double,
                       entries: changes.map { change in
                           Entry(id: change.id, key: change.key,
                                 previous: ProtectionPresetTable.setting(id: change.id)
                                     .flatMap { ProtectionPresetTable.storedValue(of: $0, defaults: defaults) })
                       },
                       at: now.timeIntervalSince1970)
        }
    }

    static func saveUndo(_ record: UndoRecord, defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: undoKey) }
    }

    public static func undoRecord(defaults: UserDefaults) -> UndoRecord? {
        guard let data = defaults.data(forKey: undoKey) else { return nil }
        return try? JSONDecoder().decode(UndoRecord.self, from: data)
    }

    /// What "undo" would change now: for each key of the record, the value in force now and the value before the
    /// application. A row that already holds its earlier value is left out. nil when there is nothing to undo.
    public static func undoPlan(defaults: UserDefaults) -> (record: UndoRecord, changes: [Change])? {
        guard let record = undoRecord(defaults: defaults) else { return nil }
        var changes: [Change] = []
        for entry in record.entries {
            // A row that is no longer in the table (an older record) is skipped: nothing is written for a key we do not know.
            guard let setting = setting(id: entry.id), setting.key == entry.key else { continue }
            let now = effectiveValue(of: setting, defaults: defaults)
            let before = entry.previous ?? setting.unset
            if now != before { changes.append(Change(id: entry.id, key: entry.key, from: now, to: before)) }
        }
        return changes.isEmpty ? nil : (record, changes)
    }

    /// Puts every key of the record back (a key that was not written is removed), restores the earlier choice and
    /// forgets the record. Call `undoPlan` first for the changes to start or stop.
    public static func applyUndo(_ record: UndoRecord, defaults: UserDefaults) {
        for entry in record.entries {
            guard let setting = setting(id: entry.id), setting.key == entry.key else { continue }
            if let previous = entry.previous { set(previous, forKey: entry.key, defaults: defaults) } else { defaults.removeObject(forKey: entry.key) }
        }
        if let selected = record.previousSelected { defaults.set(selected.rawValue, forKey: selectedKey) } else { defaults.removeObject(forKey: selectedKey) }
        if let at = record.previousAppliedAt { defaults.set(at, forKey: appliedAtKey) } else { defaults.removeObject(forKey: appliedAtKey) }
        defaults.removeObject(forKey: undoKey)
    }

    /// When the licence is removed: forgets the choice and puts the settings that work on a Free Mac back to the
    /// shipped defaults, so a preset does not leave a free feature switched off or slowed. The other settings follow
    /// the guards' own licence-loss handling.
    public static func resetAfterLicenseRemoval(defaults: UserDefaults) {
        defaults.removeObject(forKey: selectedKey)
        defaults.removeObject(forKey: appliedAtKey)
        defaults.removeObject(forKey: undoKey)
        defaults.removeObject(forKey: activationOfferPendingKey)
        for setting in settings where setting.worksWithoutPro {
            defaults.removeObject(forKey: setting.key)
        }
    }

    // MARK: - What a preset cannot do by itself

    /// A permission or an install the app cannot give itself. Listed after a preset is applied, never written.
    public enum Guidance: String, CaseIterable, Sendable {
        case fullDiskAccess, accessibility, systemExtension, helperApproval, notificationPermission, blueutil, clamav, vpn, sensor, eventForward, sshAllow

        public var titleKey: String {
            switch self {
            case .fullDiskAccess: return "フルディスクアクセスの許可(プロセス実行の記録、ファイルを開いたプロセスの記録)"
            case .accessibility: return "アクセシビリティの許可(USBキーボードの承認ガード)"
            case .systemExtension: return "システム拡張の承認(リンク保護の完全な働き)"
            case .helperApproval: return "ヘルパーの承認(ポートスキャン、SSH、重要ファイルの改ざん監視など)"
            case .notificationPermission: return "通知の許可(すべての通知)"
            case .blueutil: return "blueutilのインストール(Bluetoothの自動オフ)"
            case .clamav: return "ClamAVのインストール(ダウンロードと定期のウイルススキャン)"
            case .vpn: return "VPN(サーバーの情報が要るので、自分で設定します)"
            case .sensor: return "Sensorのペアリング(Sensorのアドレスが要るので、自分で設定します)"
            case .eventForward: return "イベント転送(転送先が要るので、自分で設定します)"
            case .sshAllow: return "SSH接続元の限定(管理者のパスワードが要るので、自分で設定します)"
            }
        }
    }

    /// The guidance that applies to a preset.
    public static func guidance(for preset: ProtectionPreset) -> [Guidance] {
        switch preset {
        case .light:
            return [.helperApproval, .notificationPermission]
        case .balanced:
            return [.helperApproval, .notificationPermission, .systemExtension, .clamav]
        case .standard:
            return [.helperApproval, .notificationPermission, .systemExtension, .clamav, .fullDiskAccess, .vpn, .sensor, .eventForward, .sshAllow]
        case .maximum:
            return [.helperApproval, .notificationPermission, .systemExtension, .clamav, .fullDiskAccess, .accessibility, .blueutil,
                    .vpn, .sensor, .eventForward, .sshAllow]
        }
    }

    /// Settings a preset leaves to a separate choice because the maximum preset's value would add false positives,
    /// stop work or send something out. Listed in the confirmation of the lighter presets.
    public static func leftToIndividualChoice(for preset: ProtectionPreset) -> [PresetSetting] {
        guard preset != .maximum else { return [] }
        return settings.filter { !$0.risks.isEmpty && $0.value(for: preset) != $0.value(for: .maximum) }
    }
}
