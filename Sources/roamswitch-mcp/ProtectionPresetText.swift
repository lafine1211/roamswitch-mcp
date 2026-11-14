// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.0 (build 216).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The words of the protection presets: names, the confirmation before a preset is applied, the line in the menu and
/// the notice after. Pure text (no AppKit), so the tests can read what the person is told. The catalog
/// (`Localizable.xcstrings`) has every string in all ten languages; the keys are the Japanese source strings
/// (`scripts/add_preset_strings.py` adds them).
enum ProtectionPresetText {

    static func name(_ preset: ProtectionPreset) -> String {
        switch preset {
        case .light: return loc("軽量")
        case .balanced: return loc("バランス")
        case .standard: return loc("標準セキュリティ")
        case .maximum: return loc("最大セキュリティ")
        }
    }

    static func summary(_ preset: ProtectionPreset) -> String {
        switch preset {
        case .light: return loc("常駐のリソース消費を最小にします。基本の検知は残します。")
        case .balanced: return loc("リソース消費とセキュリティのバランスを取る設定です。")
        case .standard: return loc("リソース消費を考えない、標準的なセキュリティ設定です。")
        case .maximum: return loc("誤検知が増える、作業が止まる、外へ通信する項目も含めて、設定できる保護をすべてオンにします。")
        }
    }

    static func stateLabel(_ state: ProtectionPresetTable.State) -> String {
        switch state {
        case .preset(let p): return name(p)
        case .defaultSettings: return loc("既定の設定")
        case .custom: return loc("カスタム(個別に変更済み)")
        }
    }

    // MARK: - Menu

    /// A Free Mac: the item is always shown, and opens the licence window.
    static var freeMenuTitle: String { loc("設定のプリセット (Pro)…") }
    static var freeMenuTooltip: String { loc("プリセットは、Proのライセンスで選べます。選ぶと、ライセンスの画面を開きます。") }

    static func menuTitle(state: ProtectionPresetTable.State) -> String {
        String(format: loc("設定のプリセット: %@"), stateLabel(state))
    }

    /// The licence lapsed: the keys still hold the choice, but the guards are stopped.
    static func lapsedMenuTitle(state: ProtectionPresetTable.State) -> String {
        String(format: loc("設定のプリセット: %@(Pro無効のため停止中)"), stateLabel(state))
    }

    static var viewContentsTitle: String { loc("内容を見る…") }

    /// The text of "内容を見る…": the four presets, one line each, and the current state.
    static func overview(state: ProtectionPresetTable.State) -> String {
        var lines = ProtectionPreset.allCases.map { locBullet(name($0) + ": " + summary($0)) }
        lines.append("")
        lines.append(String(format: loc("設定のプリセットの状態: %@"), stateLabel(state)))
        lines.append(loc("ネットワークの信頼の設定(登録したネットワーク、外出先のネットワークの保護レベル、手動の指定)は、設定のプリセットでは変わりません。"))
        return lines.joined(separator: "\n")
    }

    // MARK: - Values

    static func valueLabel(_ value: PresetValue) -> String {
        switch value {
        case .bool(let on): return on ? loc("オン") : loc("オフ")
        case .int(let n): return String(n)
        case .string(let s):
            switch s {
            case "awayOnly": return loc("信頼以外のネットワークのみ")
            case "always": return loc("常に")
            case "critical": return loc("重大のみ")
            case "high": return loc("重大と高")
            case "block": return loc("ブロック")
            case "warn": return loc("警告")
            case "off": return loc("オフ")
            default: return s
            }
        }
    }

    static func tags(_ risks: Set<PresetRisk>) -> String {
        var out: [String] = []
        if risks.contains(.falsePositive) { out.append(loc("誤検知")) }
        if risks.contains(.stopsWork) { out.append(loc("作業停止")) }
        if risks.contains(.sendsOut) { out.append(loc("外へ通信")) }
        if risks.contains(.isolates) { out.append(loc("隔離")) }
        return locList(out)
    }

    // MARK: - The confirmation

    struct Confirmation: Equatable {
        let title: String
        let lines: [String]
        /// The lines as one text, for the alert.
        var body: String { lines.joined(separator: "\n") }
    }

    /// Everything the person is told before the preset is applied, once, for the whole preset.
    /// - Parameters:
    ///   - changes: what the preset writes.
    ///   - notWritten: settings whose prerequisite is missing now (listed, not written).
    static func confirmation(preset: ProtectionPreset, changes: [ProtectionPresetTable.Change], notWritten: [PresetSetting]) -> Confirmation {
        var lines: [String] = [summary(preset)]
        if preset == .maximum {
            lines.append("")
            lines.append(loc("最大セキュリティは、誤検知が増える、作業が止まる、外へ通信する項目も含めて、設定できる保護をすべてオンにします。下の項目を1つずつ読んで、理解してから適用してください。"))
        }

        let rows = changes.compactMap { change in ProtectionPresetTable.setting(id: change.id).map { ($0, change) } }
        let flagged = rows.filter { $0.0.warningKey != nil && $0.0.warnIn.contains(preset) }
        let plain = rows.filter { !($0.0.warningKey != nil && $0.0.warnIn.contains(preset)) }

        if !flagged.isEmpty {
            lines.append("")
            lines.append(String(format: loc("注意が要る項目(%d)"), flagged.count))
            for (setting, change) in flagged {
                let tag = tags(setting.risks)
                let head = tag.isEmpty ? loc(setting.titleKey) : loc(setting.titleKey) + "[" + tag + "]"
                lines.append(locBullet(head + " (" + valueLabel(change.from) + " → " + valueLabel(change.to) + "): " + loc(setting.warningKey ?? "")))
            }
        }
        if !plain.isEmpty {
            lines.append("")
            lines.append(String(format: loc("変わる項目(%d)"), plain.count))
            for (setting, change) in plain {
                lines.append(locBullet(loc(setting.titleKey) + ": " + valueLabel(change.from) + " → " + valueLabel(change.to)))
            }
        }
        if rows.isEmpty {
            lines.append("")
            lines.append(loc("変わる項目はありません。"))
        }

        lines.append(contentsOf: consequenceLines(changes))

        if !notWritten.isEmpty {
            lines.append("")
            lines.append(loc("いまは条件が足りないため、オンにしない項目"))
            for setting in notWritten {
                lines.append(locBullet(loc(setting.titleKey) + ": " + loc(setting.warningKey ?? "")))
            }
        }

        // What the preset leaves to a separate choice (the ordinary security preset), and what needs a permission.
        if preset == .standard {
            let left = ProtectionPresetTable.leftToIndividualChoice(for: preset)
            if !left.isEmpty {
                lines.append("")
                lines.append(loc("個別に選ぶ項目(この設定では変えません)"))
                for setting in left {
                    lines.append(locBullet(loc(setting.titleKey) + "[" + tags(setting.risks) + "]"))
                }
            }
        }
        let guidance = ProtectionPresetTable.guidance(for: preset)
        if !guidance.isEmpty {
            lines.append("")
            lines.append(loc("権限やインストール、自分での設定が要る項目(この設定では書きません)"))
            for item in guidance { lines.append(locBullet(loc(item.titleKey))) }
        }

        return Confirmation(title: String(format: loc("設定のプリセット「%@」を適用しますか？"), name(preset)), lines: lines)
    }

    /// What follows from a set of changes, said once (not per row).
    static func consequenceLines(_ changes: [ProtectionPresetTable.Change]) -> [String] {
        var lines: [String] = []
        let turnsOn = Set(changes.filter { $0.to == .bool(true) }.map(\.id))
        let turnsOff = Set(changes.filter { $0.to == .bool(false) }.map(\.id))
        let isolating: Set<String> = ["ransomwareCanaryGuard", "ransomwareEntropyGuard", "arpSpoofAutoContainment", "runtimeThreatContainment", "clickFixGuard"]
        if !turnsOn.isDisjoint(with: isolating) {
            lines.append("")
            lines.append(loc("ネットワークを自動で隔離(Air-Gap)する保護が増えます。誤検知のときは、メニューの「Air-Gap隔離を解除する」から解除できます。"))
        }
        if turnsOff.contains("portAnomalyGuard") {
            lines.append("")
            lines.append(loc("未知のリスニングポートの自動遮断をオフにすると、この保護が自動で入れたポート遮断を解除します。"))
        }
        return lines
    }

    static var applyButton: String { loc("適用する") }
    static var cancelButton: String { loc("キャンセル") }

    // MARK: - The offer right after Pro is activated

    /// Shown once, after the first Pro activation of a Mac. The settings are the balanced preset then; this offers
    /// the standard one, with the same list of changes as the confirmation of the preset. The maximum preset is never
    /// offered here: only a person who chooses it in the menu gets it.
    static func activationOffer(state: ProtectionPresetTable.State, changes: [ProtectionPresetTable.Change],
                                notWritten: [PresetSetting]) -> Confirmation {
        let standard = confirmation(preset: .standard, changes: changes, notWritten: notWritten)
        var lines = standard.lines
        lines[0] = summary(.standard)
        lines.insert(contentsOf: [String(format: loc("設定のプリセットの状態: %@"), stateLabel(state)),
                                  loc("このままでよければ、「バランスのまま」を選んでください。あとから、メニュー上部の「設定のプリセット」でいつでも選べます。")], at: 1)
        return Confirmation(title: String(format: loc("Proを有効にしました。設定のプリセット「%@」にしますか？"), name(.standard)), lines: lines)
    }

    /// The lines of the offer that go above the scrolling list (the summary, the state, how to decline).
    static let offerIntroLineCount = 3

    static var offerApplyButton: String { loc("標準セキュリティを適用") }
    static var offerKeepButton: String { loc("バランスのまま") }

    // MARK: - Undo

    static func undoMenuTitle(_ preset: ProtectionPreset) -> String { String(format: loc("設定のプリセット「%@」の適用を元に戻す…"), name(preset)) }
    static var undoButton: String { loc("元に戻す") }

    static func undoConfirmation(_ record: ProtectionPresetTable.UndoRecord, changes: [ProtectionPresetTable.Change]) -> Confirmation {
        var lines: [String] = [loc("適用の前の値に戻します。そのあとに個別に変えた値も、適用の前の値に戻ります。")]
        let rows = changes.compactMap { change in ProtectionPresetTable.setting(id: change.id).map { ($0, change) } }
        lines.append("")
        lines.append(String(format: loc("戻す項目(%d)"), rows.count))
        for (setting, change) in rows {
            lines.append(locBullet(loc(setting.titleKey) + ": " + valueLabel(change.from) + " → " + valueLabel(change.to)))
        }
        lines.append(contentsOf: consequenceLines(changes))
        return Confirmation(title: String(format: loc("設定のプリセット「%@」の適用を元に戻しますか？"), name(record.applied)), lines: lines)
    }

    static func undoneTitle(_ preset: ProtectionPreset) -> String { String(format: loc("設定のプリセット「%@」の適用を元に戻しました"), name(preset)) }
    static func undoneBody(changed: Int) -> String { String(format: loc("%d 項目を、適用の前の値に戻しました。"), changed) }

    // MARK: - Results

    static func deferredTitle() -> String { loc("隔離(Air-Gap)中は、設定のプリセットを適用しません") }
    static func deferredBody() -> String {
        loc("ネットワークを隔離している間は、保護の設定を変えません。メニューの「Air-Gap隔離を解除する」で解除してから、もう一度選んでください。")
    }

    static func alreadyTitle(_ preset: ProtectionPreset) -> String { String(format: loc("設定のプリセットはすでに「%@」です"), name(preset)) }
    static func alreadyBody() -> String { loc("変える項目はありません。") }

    static func appliedTitle(_ preset: ProtectionPreset) -> String { String(format: loc("設定のプリセット「%@」を適用しました"), name(preset)) }

    static func appliedBody(changed: Int, notWritten: [PresetSetting], guidance: [ProtectionPresetTable.Guidance]) -> String {
        var parts = [String(format: loc("%d 項目を変えました。"), changed)]
        if !notWritten.isEmpty {
            parts.append(String(format: loc("条件が足りないため、オンにしなかった項目: %@。"),
                                locList(notWritten.map { loc($0.titleKey) })))
        }
        let needs = guidance.filter { [.fullDiskAccess, .accessibility, .systemExtension, .helperApproval, .blueutil, .clamav].contains($0) }
        if !needs.isEmpty {
            parts.append(String(format: loc("権限やインストールが要る項目: %@。"), locList(needs.map { loc($0.titleKey) })))
        }
        return parts.joined(separator: "\n")
    }
}
