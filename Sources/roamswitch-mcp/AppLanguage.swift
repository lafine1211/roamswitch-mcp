// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.22 (build 79).
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

    /// `suiteName` equal to the main app's own bundle ID (`com.tetsuharu.RoamSwitch`)
    /// resolves to the exact same preferences domain as `UserDefaults.standard` when
    /// read from the main app itself, but — unlike `.standard` — is also readable from
    /// `RoamSwitchMCPServer`, a separate process under its own bundle ID
    /// (`com.tetsuharu.RoamSwitch.MCPServer`). Without this, the MCP server could never
    /// see the language the user picked in the app's own settings and every `loc(_:)`
    /// call there (including this file's own `activeBundle`) silently fell back to the
    /// OS system locale instead — same cross-process pitfall already fixed for
    /// `ActiveVulnScan.isEnabled` (see `MCPServer.swift`'s `sharedDefaults`). No data
    /// migration needed: existing values written via `.standard` from the main app are
    /// already sitting in this exact same domain.
    private static let sharedDefaults = UserDefaults(suiteName: "com.tetsuharu.RoamSwitch") ?? .standard

    static var current: AppLanguage {
        get {
            guard let raw = sharedDefaults.string(forKey: selectedLangKey),
                  let lang = AppLanguage(rawValue: raw) else {
                return .system
            }
            return lang
        }
        set {
            if newValue == .system {
                sharedDefaults.removeObject(forKey: selectedLangKey)
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                sharedDefaults.set(newValue.rawValue, forKey: selectedLangKey)
                // AppKit's own locale-selection key — only meaningful for (and only
                // read by) the process that sets it, so this one stays process-local
                // on `.standard` rather than moving to the shared suite.
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

    /// `RoamSwitchMCPServer` is a bare Mach-O executable embedded at
    /// `RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer` — it has no `.app` bundle
    /// of its own, so `Bundle.main` there carries none of the compiled
    /// `Localizable.xcstrings` `.lproj` resources (they live in the *enclosing* app's
    /// `Contents/Resources`), and every `loc(_:)` call from that process silently fell
    /// back to the raw (Japanese) key regardless of the user's language setting. This
    /// climbs from the running executable's own path to the nearest ancestor
    /// directory ending in `.app` and returns a `Bundle` for that instead, which does
    /// have the real resources. For the main app itself, `Bundle.main` already has
    /// them directly, so this is a no-op there (the loop below never runs).
    private static var resourceBundle: Bundle {
        if Bundle.main.path(forResource: "ja", ofType: "lproj") != nil {
            return Bundle.main
        }
        var dir = Bundle.main.executableURL?.deletingLastPathComponent()
        for _ in 0..<8 {
            guard let candidate = dir else { break }
            if candidate.pathExtension == "app", let appBundle = Bundle(url: candidate) {
                return appBundle
            }
            dir = candidate.pathComponents.count > 1 ? candidate.deletingLastPathComponent() : nil
        }
        return Bundle.main
    }

    // `Bundle(path:)` re-parses Info.plist and rescans resources on every call —
    // cheap once, but `loc(_:)` (below) is called per-row in views like
    // SecurityLogAuditView's event list, where thousands of rows each call it
    // several times; without this cache that reconstruction cost multiplies
    // into a multi-second-to-frozen UI hang. Keyed by locale code, not
    // invalidated: a given code always resolves to the same on-disk bundle for
    // the life of the process, so stale entries aren't possible.
    //
    // `loc(_:)` is called from background queues too (e.g. `PortSecurityAuditor`'s
    // completion handler) as well as the main thread, so this cache must be
    // synchronized: a plain, unguarded `[String: Bundle]` mutated from two
    // threads at once corrupts Swift's Dictionary storage — observed in
    // practice as a crash inside the Dictionary setter with an unrelated
    // "-[__NSCFNumber count]: unrecognized selector" exception (classic
    // symptom of concurrent-mutation heap corruption, not an actual NSNumber
    // bug). The lock is held only around the dictionary access itself, not
    // the `Bundle(path:)` construction, so a rare concurrent cache-miss on
    // the same locale just redoes that (idempotent, harmless) work once.
    private static let activeBundleCacheLock = NSLock()
    private static var activeBundleCache: [String: Bundle] = [:]

    static var activeBundle: Bundle {
        let code = activeLocaleCode

        activeBundleCacheLock.lock()
        let cached = activeBundleCache[code]
        activeBundleCacheLock.unlock()
        if let cached { return cached }

        let resolved: Bundle
        if let path = resourceBundle.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            resolved = bundle
        } else {
            resolved = resourceBundle
        }

        activeBundleCacheLock.lock()
        activeBundleCache[code] = resolved
        activeBundleCacheLock.unlock()
        return resolved
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("RoamSwitch.languageDidChange")
}

@inline(__always)
func loc(_ key: String) -> String {
    AppLanguage.activeBundle.localizedString(forKey: key, value: nil, table: nil)
}
