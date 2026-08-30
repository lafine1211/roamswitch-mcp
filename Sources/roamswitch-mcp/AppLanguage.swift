// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.0 (build 23).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import AppKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese = "ja"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case korean = "ko"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt-PT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return loc("システム設定に従う")
        case .japanese: return "日本語"
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .korean: return "한국어"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        }
    }

    private static let selectedLangKey = "RoamSwitch.appLanguage"

    static var current: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: selectedLangKey),
                  let lang = AppLanguage(rawValue: raw) else {
                return .system
            }
            return lang
        }
        set {
            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: selectedLangKey)
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: selectedLangKey)
                UserDefaults.standard.set([newValue.rawValue], forKey: "AppleLanguages")
            }
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    static var activeLocaleCode: String {
        let cur = AppLanguage.current
        if cur != .system {
            return cur.rawValue
        }
        let preferred = Locale.preferredLanguages
        for pref in preferred {
            for candidate in AppLanguage.allCases where candidate != .system {
                if pref.hasPrefix(candidate.rawValue) {
                    return candidate.rawValue
                }
            }
        }
        return "ja"
    }

    static var activeBundle: Bundle {
        let code = activeLocaleCode
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("RoamSwitch.languageDidChange")
}

@inline(__always)
func loc(_ key: String) -> String {
    AppLanguage.activeBundle.localizedString(forKey: key, value: nil, table: nil)
}
