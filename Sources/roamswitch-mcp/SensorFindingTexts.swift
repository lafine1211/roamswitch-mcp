// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// A Sensor finding's texts in a display language, from its `text_keys` (`SensorFindingTextKeys`).
///
/// The Sensor writes the texts of an audit this Mac requested in English, and an older Sensor sends no keys. The
/// texts here are roamswitch-core's own (`SensorFindingTextsData`, generated), so for a keyed finding they are the
/// same sentences the Sensor writes, in each of the 10 languages.
enum SensorFindingTexts {
    struct Rendered: Equatable {
        let title: String
        let description: String
        let recommendation: String
    }

    private static let table: [String: [String: [String]]] = {
        guard let data = SensorFindingTextsData.embeddedJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [String: [String]]].self, from: data) else { return [:] }
        return decoded
    }()

    /// The checks this build has texts for (`<source>:<check>`).
    static var knownChecks: [String] { table.keys.sorted() }

    /// The languages a check's texts are in (the 10 of `AppLanguage`).
    static func languages(of check: String) -> [String] { table[check].map { $0.keys.sorted() } ?? [] }

    /// `keys`' texts in `lang` (one of `AppLanguage`'s raw values), or `nil` when there are no keys, this build does
    /// not know the check (a newer Sensor's), or not in that language: the caller then shows the texts as stored.
    /// A signature or web key takes no arguments; a `cve` key takes exactly `signature` (roamswitch-core's
    /// `finding_text_keys::render`), and its texts are the table's entry of that signature and CVE.
    static func render(_ keys: SensorFindingTextKeys?, lang: String) -> Rendered? {
        guard let keys, keys.check.count <= SensorFindingTextKeys.maxChars, let entry = tableKey(keys),
              let texts = table[entry]?[lang], texts.count == 3,
              texts.allSatisfy({ !$0.isEmpty }) else { return nil }
        return Rendered(title: texts[0], description: texts[1], recommendation: texts[2])
    }

    /// The key of `keys`' texts in the table, or nil when the arguments are not the ones its source takes.
    static func tableKey(_ keys: SensorFindingTextKeys) -> String? {
        switch keys.source {
        case "cve":
            guard keys.args.count == 1, let signature = keys.args["signature"], !signature.contains(":") else { return nil }
            return "cve:\(signature):\(keys.check)"
        default:
            guard keys.args.isEmpty, !keys.check.contains(":") else { return nil }
            return "\(keys.source):\(keys.check)"
        }
    }

    /// `(title, description, recommendation)` to show: the keyed texts in `lang` when they can be rendered, else
    /// the stored ones.
    static func display(
        title: String, description: String, recommendation: String, keys: SensorFindingTextKeys?,
        lang: String = AppLanguage.activeLocaleCode
    ) -> Rendered {
        render(keys, lang: lang) ?? Rendered(title: title, description: description, recommendation: recommendation)
    }
}
