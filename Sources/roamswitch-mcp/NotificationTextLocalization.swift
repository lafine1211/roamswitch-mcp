// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.27 (build 206).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The app's side of `NotificationText`: rendering a stored text in a language, and finding the catalog keys
/// behind a title and body that were rendered in the current language.
///
/// The notifications are built from `loc()` strings in a hundred places. Rather than pass a second, key-based copy
/// through each of them, the history reads the rendered text back against the catalog of the language it was
/// rendered in: a line that is a catalog value, or a catalog format with its values filled in, becomes that key
/// with those values (which are read the same way, so a translated fragment inside a sentence is translated too).
/// What no entry matches stays a literal. The result is kept only when it renders back to exactly the text that was
/// shown, so in its own language an entry is never different from the notification.
enum NotificationTextLocalization {
    /// The format of `key` in the language `code`, or `nil` when the catalog does not have the key.
    static func format(_ key: String, table: NotificationText.Table, localeCode code: String) -> String? {
        switch table {
        case .app:
            guard AppLanguage.catalogHasKey(key) else { return nil }
            return loc(key, localeCode: code)
        case .watchdog:
            guard let k = WatchdogMessages.Key(rawValue: key) else { return nil }
            return WatchdogMessages.text(k, language: WatchdogMessages.languageCode(selected: code, preferred: []))
        }
    }

    static func render(_ text: NotificationText, localeCode code: String) -> String? {
        text.render { format($0, table: $1, localeCode: code) }
    }

    /// The title and body in the language `code`, or `nil` when they cannot be read back (the caller keeps them as
    /// rendered) or hold no catalog key.
    static func texts(title: String, body: String, localeCode code: String) -> NotificationTexts? {
        let parser = NotificationTextParser.shared(localeCode: code)
        let t = parser.parse(title)
        let b = parser.parse(body)
        guard t.hasKey || b.hasKey,
              render(t, localeCode: code) == title,
              render(b, localeCode: code) == body else { return nil }
        return NotificationTexts(title: t, body: b)
    }

    /// Installs the reader into the history: from now on every recorded notification also keeps its text without a language.
    static func install() {
        NotificationHistory.textResolver = { title, body in
            texts(title: title, body: body, localeCode: AppLanguage.activeLocaleCode)
        }
        // The parser is built on first use (the whole catalog); build it now, off the main thread.
        DispatchQueue.global(qos: .utility).async {
            _ = NotificationTextParser.shared(localeCode: AppLanguage.activeLocaleCode)
        }
    }
}

extension NotificationHistoryEntry {
    /// This entry as a reader in the language `code` sees it: title and body rendered from `text`. An entry without
    /// `text` (older ones), or whose text cannot be rendered, is unchanged. `text` is left out, so what a reader of
    /// the JSON gets has the same keys as before (`timestamp`, `title`, `body`).
    func inLanguage(_ code: String) -> NotificationHistoryEntry {
        var e = NotificationHistoryEntry(timestamp: timestamp, title: title, body: body)
        if let text,
           let title = NotificationTextLocalization.render(text.title, localeCode: code),
           let body = NotificationTextLocalization.render(text.body, localeCode: code) {
            e.title = title
            e.body = body
        }
        return e
    }

    /// `inLanguage` in the language the app uses now.
    var inCurrentLanguage: NotificationHistoryEntry { inLanguage(AppLanguage.activeLocaleCode) }
}

/// Reads a text rendered in one language back into catalog keys and values (see `NotificationTextLocalization`).
final class NotificationTextParser {
    private struct Format {
        let key: String
        let regex: NSRegularExpression
        /// For each capture group in order, the argument it is.
        let arguments: [Int]
        let argumentCount: Int
        /// Characters of fixed text: the match with the most is the most specific.
        let weight: Int
        /// The longest piece of fixed text; a format is tried only on a text that contains it.
        let anchor: String
    }

    private let exact: [String: String]
    private let formats: [Format]

    /// `entries` are the catalog's keys with their values in one language.
    init(entries: [(key: String, value: String)]) {
        var exact: [String: String] = [:]
        var formats: [Format] = []
        for (key, value) in entries {
            let specs = NotificationText.specifiers(in: value)
            if specs.isEmpty {
                let plain = value.replacingOccurrences(of: "%%", with: "%")
                guard !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                // Two keys with one value render the same here; keep one, the same one every time.
                if let other = exact[plain], other < key { continue }
                exact[plain] = key
                continue
            }
            var pattern = "^"
            var chunks: [String] = []
            var cursor = value.startIndex
            var arguments: [Int] = []
            for spec in specs {
                let chunk = value[cursor..<spec.range.lowerBound].replacingOccurrences(of: "%%", with: "%")
                chunks.append(chunk)
                pattern += NSRegularExpression.escapedPattern(for: chunk) + "(.*?)"
                arguments.append(spec.argument)
                cursor = spec.range.upperBound
            }
            let tail = value[cursor...].replacingOccurrences(of: "%%", with: "%")
            chunks.append(tail)
            pattern += NSRegularExpression.escapedPattern(for: tail) + "$"
            let weight = chunks.joined().filter { !$0.isWhitespace }.count
            // A format that is nearly all values ("%@: %@") would match almost anything.
            guard weight >= 2,
                  let anchor = chunks.max(by: { $0.count < $1.count }), !anchor.isEmpty,
                  let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { continue }
            formats.append(Format(key: key, regex: regex, arguments: arguments,
                                  argumentCount: (arguments.max() ?? -1) + 1, weight: weight, anchor: anchor))
        }
        self.exact = exact
        self.formats = formats.sorted { $0.key < $1.key }
    }

    private static let cacheLock = NSLock()
    private static var cache: [String: NotificationTextParser] = [:]

    /// The parser for the catalog in the language `code` (built once per language).
    static func shared(localeCode code: String) -> NotificationTextParser {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cache[code] { return cached }
        let parser = NotificationTextParser(entries: AppLanguage.catalogKeys.map { ($0, loc($0, localeCode: code)) })
        cache[code] = parser
        return parser
    }

    // MARK: - Reading

    /// Arguments are read again this many levels down (a translated reason inside a sentence inside a body).
    private static let maxDepth = 2

    func parse(_ text: String) -> NotificationText {
        let candidates = formats.filter { text.contains($0.anchor) }
        return block(text, candidates)
    }

    /// A text of one or more lines: the whole, or else the longest run of lines from the top that matches, then the rest.
    private func block(_ text: String, _ candidates: [Format]) -> NotificationText {
        if let whole = match(text, candidates, depth: 0) { return whole }
        let lines = text.components(separatedBy: "\n")
        guard lines.count > 1 else { return line(text, candidates) }
        var parts: [NotificationText] = []
        var i = 0
        while i < lines.count {
            if i > 0 { parts.append(.literal("\n")) }
            var matched: (NotificationText, Int)?
            var j = lines.count
            while j > i + 1 {
                if let t = match(lines[i..<j].joined(separator: "\n"), candidates, depth: 0) { matched = (t, j); break }
                j -= 1
            }
            if let (t, end) = matched {
                parts.append(t)
                i = end
            } else {
                parts.append(line(lines[i], candidates))
                i += 1
            }
        }
        return Self.merged(parts)
    }

    /// One line: the whole line, or a marker in front of it ("🚨 ", "⚠️ ", "• ") and the rest.
    private func line(_ text: String, _ candidates: [Format]) -> NotificationText {
        if text.isEmpty { return .literal(text) }
        if let whole = match(text, candidates, depth: 0) { return whole }
        if let space = text.firstIndex(of: " "), space > text.startIndex {
            let marker = text[..<space]
            let rest = String(text[text.index(after: space)...])
            if !marker.contains(where: { $0.isLetter || $0.isNumber }), !rest.isEmpty,
               let t = match(rest, candidates, depth: 0) {
                return .parts([.literal(String(marker) + " "), t])
            }
        }
        return .literal(text)
    }

    private func match(_ text: String, _ candidates: [Format], depth: Int) -> NotificationText? {
        if let key = exact[text] { return .key(key) }
        var best: (format: Format, match: NSTextCheckingResult)?
        let range = NSRange(text.startIndex..., in: text)
        for f in candidates where f.weight > (best?.format.weight ?? 0) && text.contains(f.anchor) {
            if let m = f.regex.firstMatch(in: text, options: [], range: range) { best = (f, m) }
        }
        guard let (format, m) = best else { return nil }
        var args = [NotificationText](repeating: .literal(""), count: format.argumentCount)
        var filled = Set<Int>()
        for (group, argument) in format.arguments.enumerated() {
            guard filled.insert(argument).inserted,
                  let r = Range(m.range(at: group + 1), in: text) else { continue }
            let value = String(text[r])
            if depth < Self.maxDepth, !value.isEmpty {
                let inner = formats.filter { value.contains($0.anchor) }
                args[argument] = match(value, inner, depth: depth + 1) ?? .literal(value)
            } else {
                args[argument] = .literal(value)
            }
        }
        return .key(format.key, args: args, table: .app)
    }

    /// Neighbouring literals as one.
    private static func merged(_ parts: [NotificationText]) -> NotificationText {
        var out: [NotificationText] = []
        for part in parts {
            if case .literal(let s) = part, case .literal(let prev)? = out.last {
                out[out.count - 1] = .literal(prev + s)
            } else {
                out.append(part)
            }
        }
        if out.count == 1 { return out[0] }
        return .parts(out)
    }
}
