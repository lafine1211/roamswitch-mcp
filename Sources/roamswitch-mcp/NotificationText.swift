// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// A notification's text kept apart from any language, so the notification history shows it in the language the
/// reader uses now rather than the one in effect when it was sent (2026-11-05: an entry stayed in the language of the
/// moment it was recorded). The Mac counterpart of the Linux edition's `NoticeText`.
///
/// In JSON: a string is a literal (a path, a host, a number, a line no catalog has), an array is the parts in order,
/// and an object `{"key": ..., "args": [...]}` is a catalog key whose format specifiers (`%@`, `%d`, `%1$@` ...) are
/// filled with the rendered args in order. `"table": "watchdog"` names `WatchdogMessages` instead of
/// `Localizable.xcstrings`.
public indirect enum NotificationText: Equatable {
    case literal(String)
    case parts([NotificationText])
    case key(String, args: [NotificationText], table: Table)

    public enum Table: String, Codable {
        case app
        case watchdog
    }

    public static func key(_ key: String, _ args: [NotificationText] = []) -> NotificationText {
        .key(key, args: args, table: .app)
    }

    /// Whether any part is a catalog key (a text of literals only is no different from the stored string).
    public var hasKey: Bool {
        switch self {
        case .literal: return false
        case .parts(let parts): return parts.contains { $0.hasKey }
        case .key: return true
        }
    }

    /// The text, with `lookup` giving a key's format in the reader's language. `nil` when `lookup` does not know a
    /// key (written by a newer version, or removed since): the caller then shows what was stored.
    public func render(_ lookup: (String, Table) -> String?) -> String? {
        switch self {
        case .literal(let s):
            return s
        case .parts(let parts):
            var out = ""
            for part in parts {
                guard let s = part.render(lookup) else { return nil }
                out += s
            }
            return out
        case .key(let key, let args, let table):
            guard let format = lookup(key, table) else { return nil }
            var values: [String] = []
            for arg in args {
                guard let s = arg.render(lookup) else { return nil }
                values.append(s)
            }
            return Self.fill(format, values)
        }
    }

    // MARK: - Format specifiers

    /// One conversion in a format: where it is, and which argument it takes (0-based).
    struct Specifier {
        let range: Range<String.Index>
        let argument: Int
        /// The conversion character (`@`, `d`, `f` ...).
        var conversion: Character = "@"
        /// A count whose words vary with it (`%1$#@n1@`, a plural substitution of the catalog): only Foundation can
        /// write it, with the number (`NotificationTextLocalization.render`).
        var isPlural = false
    }

    /// The conversions of `format` (`%%` is not one). An argument is taken in order unless it is numbered (`%2$@`).
    static func specifiers(in format: String) -> [Specifier] {
        var out: [Specifier] = []
        var next = 0
        var i = format.startIndex
        while i < format.endIndex {
            guard format[i] == "%" else { i = format.index(after: i); continue }
            let start = i
            var j = format.index(after: i)
            guard j < format.endIndex else { break }
            if format[j] == "%" { i = format.index(after: j); continue }
            // %[n$][flags][width][.precision][length]conversion
            var digits = ""
            var k = j
            while k < format.endIndex, format[k].isASCII, format[k].isNumber { digits.append(format[k]); k = format.index(after: k) }
            var position: Int?
            if k < format.endIndex, format[k] == "$", let n = Int(digits), n > 0 {
                position = n - 1
                j = format.index(after: k)
            }
            while j < format.endIndex, "-+ #0'".contains(format[j]) { j = format.index(after: j) }
            while j < format.endIndex, format[j].isASCII, format[j].isNumber || format[j] == "." || format[j] == "*" { j = format.index(after: j) }
            while j < format.endIndex, "hlqLztj".contains(format[j]) { j = format.index(after: j) }
            guard j < format.endIndex, "@dDiuUxXoOfFeEgGaAcCsSp".contains(format[j]) else {
                i = format.index(after: start)
                continue
            }
            var end = format.index(after: j)
            let argument: Int
            if let position { argument = position } else { argument = next; next += 1 }
            // `%#@name@` / `%1$#@name@`: a plural substitution, whose name runs to the next `@`.
            var isPlural = false
            if format[j] == "@", format[format.index(after: start)..<j].contains("#"),
               let close = format[end...].firstIndex(of: "@"), close > end,
               format[end..<close].allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) {
                end = format.index(after: close)
                isPlural = true
            }
            out.append(Specifier(range: start..<end, argument: argument, conversion: format[j], isPlural: isPlural))
            i = end
        }
        return out
    }

    /// `format` with each conversion replaced by its argument as text, and `%%` by `%`. Unlike `String(format:)`
    /// this never reads an argument of the wrong type: a number was already written out when it was recorded.
    static func fill(_ format: String, _ args: [String]) -> String {
        var out = ""
        var cursor = format.startIndex
        for spec in specifiers(in: format) {
            out += format[cursor..<spec.range.lowerBound].replacingOccurrences(of: "%%", with: "%")
            out += spec.argument < args.count ? args[spec.argument] : ""
            cursor = spec.range.upperBound
        }
        out += format[cursor...].replacingOccurrences(of: "%%", with: "%")
        return out
    }
}

extension NotificationText: Codable {
    private enum CodingKeys: String, CodingKey { case key, args, table }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer() {
            if let s = try? single.decode(String.self) { self = .literal(s); return }
            if let parts = try? single.decode([NotificationText].self) { self = .parts(parts); return }
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let key = try c.decode(String.self, forKey: .key)
        let args = try c.decodeIfPresent([NotificationText].self, forKey: .args) ?? []
        let table = try c.decodeIfPresent(Table.self, forKey: .table) ?? .app
        self = .key(key, args: args, table: table)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .literal(let s):
            var c = encoder.singleValueContainer()
            try c.encode(s)
        case .parts(let parts):
            var c = encoder.singleValueContainer()
            try c.encode(parts)
        case .key(let key, let args, let table):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(key, forKey: .key)
            if !args.isEmpty { try c.encode(args, forKey: .args) }
            if table != .app { try c.encode(table, forKey: .table) }
        }
    }
}

/// A notification's title and body as `NotificationText`.
public struct NotificationTexts: Codable, Equatable {
    public var title: NotificationText
    public var body: NotificationText

    public init(title: NotificationText, body: NotificationText) {
        self.title = title
        self.body = body
    }
}
