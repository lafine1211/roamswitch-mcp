// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// User-facing texts of `RoamSwitchWatchdog` (its restart / give-up
/// notifications) in all ten app languages.
///
/// The watchdog is a separate tool process without the app's `.lproj` /
/// `Localizable.xcstrings` resources, so `loc()` is unavailable there; the texts
/// live in this self-contained table instead (unit-tested for placeholder parity
/// in `WatchdogMessagesTests`). Language selection mirrors `AppLanguage`: the
/// user's in-app choice (`RoamSwitch.appLanguage` in the app's preferences
/// domain), else the first supported system language, else English.
enum WatchdogMessages {
    static let languages = ["ja", "en", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es", "it", "pt-PT"]

    /// The raw values name the texts in the notification history (`NotificationText`, table `watchdog`): keep them.
    enum Key: String, CaseIterable {
        /// (no placeholders)
        case restartTitle
        /// %lld = seconds, %lld = attempt, %lld = max attempts
        case restartBody
        /// (no placeholders)
        case limitTitle
        /// %lld = max attempts
        case limitBody
        /// (no placeholders)
        case hangTitle
        /// %lld = seconds without an answer, %lld = seconds until the restart, %lld = attempt, %lld = max attempts
        case hangBody
    }

    static func text(_ key: Key, language: String) -> String {
        let table = table(for: key)
        return table[language] ?? table["en"] ?? ""
    }

    static func table(for key: Key) -> [String: String] {
        switch key {
        case .restartTitle:
            return [
                "ja": "RoamSwitch 自動再起動",
                "en": "RoamSwitch automatic restart",
                "zh-Hans": "RoamSwitch 自动重启",
                "zh-Hant": "RoamSwitch 自動重新啟動",
                "ko": "RoamSwitch 자동 재시작",
                "de": "RoamSwitch: automatischer Neustart",
                "fr": "RoamSwitch : redémarrage automatique",
                "es": "RoamSwitch: reinicio automático",
                "it": "RoamSwitch: riavvio automatico",
                "pt-PT": "RoamSwitch: reinício automático",
            ]
        case .restartBody:
            return [
                "ja": "RoamSwitch が予期せず終了したため、%lld秒後に自動再起動します (試行 %lld/%lld 回)",
                "en": "RoamSwitch quit unexpectedly and will restart automatically in %lld s (attempt %lld of %lld)",
                "zh-Hans": "RoamSwitch 意外退出，将在 %lld 秒后自动重启（第 %lld/%lld 次尝试）",
                "zh-Hant": "RoamSwitch 意外結束，將在 %lld 秒後自動重新啟動（第 %lld/%lld 次嘗試）",
                "ko": "RoamSwitch가 예기치 않게 종료되어 %lld초 후 자동으로 다시 시작합니다 (시도 %lld/%lld회)",
                "de": "RoamSwitch wurde unerwartet beendet und startet in %lld s automatisch neu (Versuch %lld von %lld)",
                "fr": "RoamSwitch s’est arrêté de façon inattendue et redémarrera automatiquement dans %lld s (tentative %lld sur %lld)",
                "es": "RoamSwitch se cerró inesperadamente y se reiniciará automáticamente en %lld s (intento %lld de %lld)",
                "it": "RoamSwitch si è chiuso in modo imprevisto e verrà riavviato automaticamente tra %lld s (tentativo %lld di %lld)",
                "pt-PT": "O RoamSwitch terminou inesperadamente e será reiniciado automaticamente dentro de %lld s (tentativa %lld de %lld)",
            ]
        case .limitTitle:
            return [
                "ja": "⚠️ RoamSwitch 自動再起動停止",
                "en": "⚠️ RoamSwitch automatic restart stopped",
                "zh-Hans": "⚠️ RoamSwitch 已停止自动重启",
                "zh-Hant": "⚠️ RoamSwitch 已停止自動重新啟動",
                "ko": "⚠️ RoamSwitch 자동 재시작 중지",
                "de": "⚠️ RoamSwitch: automatischer Neustart gestoppt",
                "fr": "⚠️ RoamSwitch : redémarrage automatique arrêté",
                "es": "⚠️ RoamSwitch: reinicio automático detenido",
                "it": "⚠️ RoamSwitch: riavvio automatico interrotto",
                "pt-PT": "⚠️ RoamSwitch: reinício automático interrompido",
            ]
        case .hangTitle:
            return [
                "ja": "RoamSwitch の応答がなくなったので再起動しました",
                "en": "RoamSwitch stopped responding and was restarted",
                "zh-Hans": "RoamSwitch 无响应，已重新启动",
                "zh-Hant": "RoamSwitch 沒有回應，已重新啟動",
                "ko": "RoamSwitch가 응답하지 않아 다시 시작했습니다",
                "de": "RoamSwitch reagierte nicht mehr und wurde neu gestartet",
                "fr": "RoamSwitch ne répondait plus et a été redémarré",
                "es": "RoamSwitch dejó de responder y se ha reiniciado",
                "it": "RoamSwitch non rispondeva più ed è stato riavviato",
                "pt-PT": "O RoamSwitch deixou de responder e foi reiniciado",
            ]
        case .hangBody:
            return [
                "ja": "RoamSwitch が%lld秒以上応答しなかったため終了させ、%lld秒後に起動し直します (試行 %lld/%lld 回)",
                "en": "RoamSwitch did not respond for over %lld s, so it was ended and will start again in %lld s (attempt %lld of %lld)",
                "zh-Hans": "RoamSwitch 超过 %lld 秒没有响应，已将其结束，并将在 %lld 秒后重新启动（第 %lld/%lld 次尝试）",
                "zh-Hant": "RoamSwitch 超過 %lld 秒沒有回應，已將其結束，並將在 %lld 秒後重新啟動（第 %lld/%lld 次嘗試）",
                "ko": "RoamSwitch가 %lld초 이상 응답하지 않아 종료했으며, %lld초 후 다시 시작합니다 (시도 %lld/%lld회)",
                "de": "RoamSwitch hat über %lld s nicht reagiert, wurde beendet und startet in %lld s neu (Versuch %lld von %lld)",
                "fr": "RoamSwitch n’a pas répondu pendant plus de %lld s ; il a été arrêté et redémarrera dans %lld s (tentative %lld sur %lld)",
                "es": "RoamSwitch no respondió durante más de %lld s; se cerró y se reiniciará en %lld s (intento %lld de %lld)",
                "it": "RoamSwitch non ha risposto per oltre %lld s; è stato chiuso e verrà riavviato tra %lld s (tentativo %lld di %lld)",
                "pt-PT": "O RoamSwitch não respondeu durante mais de %lld s; foi terminado e será reiniciado dentro de %lld s (tentativa %lld de %lld)",
            ]
        case .limitBody:
            return [
                "ja": "連続クラッシュ回数が上限 (%lld 回) に達したため、自動再起動を停止しました。",
                "en": "Automatic restart was stopped because the number of consecutive crashes reached the limit (%lld).",
                "zh-Hans": "连续崩溃次数已达上限（%lld 次），已停止自动重启。",
                "zh-Hant": "連續當機次數已達上限（%lld 次），已停止自動重新啟動。",
                "ko": "연속 충돌 횟수가 상한(%lld회)에 도달하여 자동 재시작을 중지했습니다.",
                "de": "Der automatische Neustart wurde gestoppt, weil die Zahl aufeinanderfolgender Abstürze das Limit (%lld) erreicht hat.",
                "fr": "Le redémarrage automatique a été arrêté car le nombre de plantages consécutifs a atteint la limite (%lld).",
                "es": "Se detuvo el reinicio automático porque el número de bloqueos consecutivos alcanzó el límite (%lld).",
                "it": "Il riavvio automatico è stato interrotto perché il numero di arresti anomali consecutivi ha raggiunto il limite (%lld).",
                "pt-PT": "O reinício automático foi interrompido porque o número de falhas consecutivas atingiu o limite (%lld).",
            ]
        }
    }

    /// Maps the user's in-app choice / system preferences to one of `languages`.
    static func languageCode(selected: String?, preferred: [String]) -> String {
        if let selected, languages.contains(selected) { return selected }
        for pref in preferred {
            let p = pref.lowercased()
            if p.hasPrefix("ja") { return "ja" }
            if p.hasPrefix("zh") {
                let traditional = p.contains("hant") || p.hasSuffix("-tw") || p.hasSuffix("-hk") || p.hasSuffix("-mo")
                return traditional ? "zh-Hant" : "zh-Hans"
            }
            if p.hasPrefix("ko") { return "ko" }
            if p.hasPrefix("de") { return "de" }
            if p.hasPrefix("fr") { return "fr" }
            if p.hasPrefix("es") { return "es" }
            if p.hasPrefix("it") { return "it" }
            if p.hasPrefix("pt") { return "pt-PT" }
            if p.hasPrefix("en") { return "en" }
        }
        return "en"
    }

    /// The language to use right now (reads the app's shared preferences domain).
    static func currentLanguage() -> String {
        let selected = UserDefaults(suiteName: "com.tetsuharu.RoamSwitch")?.string(forKey: "RoamSwitch.appLanguage")
        return languageCode(selected: selected, preferred: Locale.preferredLanguages)
    }

    static func restartTitle() -> String { text(.restartTitle, language: currentLanguage()) }
    static func restartBody(delay: Int, current: Int, max: Int) -> String {
        String(format: text(.restartBody, language: currentLanguage()), Int64(delay), Int64(current), Int64(max))
    }
    static func limitTitle() -> String { text(.limitTitle, language: currentLanguage()) }
    static func limitBody(max: Int) -> String {
        String(format: text(.limitBody, language: currentLanguage()), Int64(max))
    }

    static func hangTitle() -> String { text(.hangTitle, language: currentLanguage()) }
    static func hangBody(silent: Int, delay: Int, current: Int, max: Int) -> String {
        String(format: text(.hangBody, language: currentLanguage()), Int64(silent), Int64(delay), Int64(current), Int64(max))
    }

    static func hangTexts(silent: Int, delay: Int, current: Int, max: Int) -> NotificationTexts {
        NotificationTexts(title: .key(Key.hangTitle.rawValue, args: [], table: .watchdog),
                          body: .key(Key.hangBody.rawValue, args: [silent, delay, current, max].map { .literal(String($0)) }, table: .watchdog))
    }

    /// The same texts without a language, for the notification history (drawn in the reader's language there).
    static func restartTexts(delay: Int, current: Int, max: Int) -> NotificationTexts {
        NotificationTexts(title: .key(Key.restartTitle.rawValue, args: [], table: .watchdog),
                          body: .key(Key.restartBody.rawValue, args: [delay, current, max].map { .literal(String($0)) }, table: .watchdog))
    }

    static func limitTexts(max: Int) -> NotificationTexts {
        NotificationTexts(title: .key(Key.limitTitle.rawValue, args: [], table: .watchdog),
                          body: .key(Key.limitBody.rawValue, args: [.literal(String(max))], table: .watchdog))
    }
}
