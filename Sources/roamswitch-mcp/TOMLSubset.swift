// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.18 (build 197).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// A small, defensive TOML reader for the agent config files that carry TOML (`~/.codex/config.toml`).
///
/// It reads comments, bare and quoted keys, dotted keys and table headers, `[[arrays.of.tables]]`, basic and literal
/// strings (also the multi-line forms), numbers, booleans, date-times (kept as text), arrays and inline tables. The
/// result uses the types `JSONSerialization` gives (`[String: Any]`, `[Any]`, `String`, `Bool`, `Int`, `Double`), so the
/// audits read both formats the same way.
///
/// Text from a config file is untrusted: this only parses. It never evaluates anything, opens nothing, and gives up
/// (returns nil) on a syntax it does not know or on nesting deeper than `maxDepth`, so a hostile file cannot crash it.
enum TOMLSubset {

    static let maxBytes = 2 * 1024 * 1024
    static let maxDepth = 32

    /// nil when the text is not TOML this reader understands.
    static func parse(_ data: Data) -> [String: Any]? {
        guard data.count <= maxBytes, !data.prefix(8192).contains(0), let text = String(data: data, encoding: .utf8) else { return nil }
        return parse(text)
    }

    static func parse(_ text: String) -> [String: Any]? {
        var reader = Reader(Array(text.unicodeScalars))
        return try? reader.document()
    }

    private struct SyntaxError: Error {}

    private struct Reader {
        let s: [Unicode.Scalar]
        var i = 0

        init(_ scalars: [Unicode.Scalar]) { s = scalars }

        var atEnd: Bool { i >= s.count }
        func peek(_ offset: Int = 0) -> Unicode.Scalar? { i + offset < s.count ? s[i + offset] : nil }

        // MARK: Document

        mutating func document() throws -> [String: Any] {
            var root: [String: Any] = [:]
            var current: [String] = []
            while true {
                skipBlank()
                guard let c = peek() else { break }
                if c == "[" {
                    let isArray = peek(1) == "["
                    i += isArray ? 2 : 1
                    skipInlineSpace()
                    let path = try keyPath()
                    skipInlineSpace()
                    guard peek() == "]" else { throw SyntaxError() }
                    i += 1
                    if isArray {
                        guard peek() == "]" else { throw SyntaxError() }
                        i += 1
                    }
                    try endOfLine()
                    guard !path.isEmpty else { throw SyntaxError() }
                    if isArray {
                        let parent = Array(path.dropLast())
                        let last = path[path.count - 1]
                        guard Self.mutate(&root, parent[...], { node in
                            if node[last] == nil { node[last] = [Any]() }
                            guard var list = node[last] as? [Any] else { return false }
                            node[last] = nil
                            list.append([String: Any]())
                            node[last] = list
                            return true
                        }) else { throw SyntaxError() }
                    } else {
                        guard Self.mutate(&root, path[...], { _ in true }) else { throw SyntaxError() }
                    }
                    current = path
                } else {
                    let path = try keyPath()
                    skipInlineSpace()
                    guard peek() == "=" else { throw SyntaxError() }
                    i += 1
                    skipInlineSpace()
                    let value = try parseValue(depth: 0)
                    try endOfLine()
                    guard let key = path.last else { throw SyntaxError() }
                    let table = current + path.dropLast()
                    guard Self.mutate(&root, table[...], { node in
                        node[key] = value
                        return true
                    }) else { throw SyntaxError() }
                }
            }
            return root
        }

        /// Runs `body` on the table at `path`, creating missing tables. For an array of tables the last element is used.
        /// false: a scalar is in the way.
        static func mutate(_ node: inout [String: Any], _ path: ArraySlice<String>, _ body: (inout [String: Any]) -> Bool) -> Bool {
            guard let key = path.first else { return body(&node) }
            let rest = path.dropFirst()
            switch node[key] {
            case nil:
                var child: [String: Any] = [:]
                guard mutate(&child, rest, body) else { return false }
                node[key] = child
                return true
            case var child as [String: Any]:
                node[key] = nil
                let ok = mutate(&child, rest, body)
                node[key] = child
                return ok
            case var list as [Any]:
                guard var last = list.last as? [String: Any] else { return false }
                node[key] = nil
                list.removeLast()
                let ok = mutate(&last, rest, body)
                list.append(last)
                node[key] = list
                return ok
            default:
                return false
            }
        }

        // MARK: Whitespace

        mutating func skipInlineSpace() {
            while let c = peek(), c == " " || c == "\t" { i += 1 }
        }

        /// Blanks, newlines and comments between statements.
        mutating func skipBlank() {
            while let c = peek() {
                if c == " " || c == "\t" || c == "\n" || c == "\r" { i += 1 }
                else if c == "#" { skipComment() }
                else { break }
            }
        }

        mutating func skipComment() {
            while let c = peek(), c != "\n" { i += 1 }
        }

        /// After a statement only blanks and a comment may follow on the same line.
        mutating func endOfLine() throws {
            skipInlineSpace()
            if peek() == "#" { skipComment() }
            if let c = peek() {
                if c == "\r" { i += 1; if peek() == "\n" { i += 1 } }
                else if c == "\n" { i += 1 }
                else { throw SyntaxError() }
            }
        }

        // MARK: Keys

        mutating func keyPath() throws -> [String] {
            var path = [try key()]
            while true {
                skipInlineSpace()
                guard peek() == "." else { break }
                i += 1
                skipInlineSpace()
                path.append(try key())
            }
            return path
        }

        mutating func key() throws -> String {
            guard let c = peek() else { throw SyntaxError() }
            if c == "\"" { return try basicString() }
            if c == "'" { return try literalString() }
            var out = String.UnicodeScalarView()
            while let d = peek(), Self.isBare(d) { out.append(d); i += 1 }
            guard !out.isEmpty else { throw SyntaxError() }
            return String(out)
        }

        static func isBare(_ c: Unicode.Scalar) -> Bool {
            (c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || (c >= "0" && c <= "9") || c == "_" || c == "-"
        }

        // MARK: Values

        mutating func parseValue(depth: Int) throws -> Any {
            guard depth <= TOMLSubset.maxDepth, let c = peek() else { throw SyntaxError() }
            switch c {
            case "\"":
                return peek(1) == "\"" && peek(2) == "\"" ? try multilineBasic() : try basicString()
            case "'":
                return peek(1) == "'" && peek(2) == "'" ? try multilineLiteral() : try literalString()
            case "[":
                i += 1
                var list: [Any] = []
                while true {
                    skipBlank()
                    if peek() == "]" { i += 1; return list }
                    list.append(try parseValue(depth: depth + 1))
                    skipBlank()
                    if peek() == "," { i += 1; continue }
                    guard peek() == "]" else { throw SyntaxError() }
                }
            case "{":
                i += 1
                var table: [String: Any] = [:]
                while true {
                    skipBlank()
                    if peek() == "}" { i += 1; return table }
                    let path = try keyPath()
                    skipInlineSpace()
                    guard peek() == "=" else { throw SyntaxError() }
                    i += 1
                    skipInlineSpace()
                    let value = try parseValue(depth: depth + 1)
                    guard let key = path.last,
                          Self.mutate(&table, path.dropLast()[...], { node in node[key] = value; return true }) else { throw SyntaxError() }
                    skipBlank()
                    if peek() == "," { i += 1; continue }
                    guard peek() == "}" else { throw SyntaxError() }
                }
            default:
                return try scalar()
            }
        }

        /// A number, a boolean or a date-time.
        mutating func scalar() throws -> Any {
            var token = String.UnicodeScalarView()
            while let c = peek(), !(c == "," || c == "]" || c == "}" || c == "#" || c == " " || c == "\t" || c == "\n" || c == "\r") {
                token.append(c); i += 1
            }
            var text = String(token)
            // `1979-05-27 07:32:00`: a date and a time separated by a blank.
            if text.count == 10, text.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
               peek() == " ", let d = peek(1), d >= "0" && d <= "9" {
                i += 1
                while let c = peek(), !(c == "," || c == "]" || c == "}" || c == "#" || c == " " || c == "\t" || c == "\n" || c == "\r") {
                    text.unicodeScalars.append(c); i += 1
                }
                return text
            }
            if text == "true" { return true }
            if text == "false" { return false }
            let digits = text.replacingOccurrences(of: "_", with: "")
            if digits.range(of: #"^[+-]?(0|[1-9][0-9]*)$"#, options: .regularExpression) != nil, let n = Int(digits) { return n }
            if digits.range(of: #"^0x[0-9A-Fa-f]+$"#, options: .regularExpression) != nil, let n = Int(digits.dropFirst(2), radix: 16) { return n }
            if digits.range(of: #"^0o[0-7]+$"#, options: .regularExpression) != nil, let n = Int(digits.dropFirst(2), radix: 8) { return n }
            if digits.range(of: #"^0b[01]+$"#, options: .regularExpression) != nil, let n = Int(digits.dropFirst(2), radix: 2) { return n }
            if digits.range(of: #"^[+-]?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$"#, options: .regularExpression) != nil, let x = Double(digits) { return x.isFinite ? x : text }
            if ["inf", "+inf", "-inf", "nan", "+nan", "-nan"].contains(text) { return text }
            if text.range(of: #"^\d{4}-\d{2}-\d{2}([Tt ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?([Zz]|[+-]\d{2}:\d{2})?)?$"#, options: .regularExpression) != nil { return text }
            if text.range(of: #"^\d{2}:\d{2}(:\d{2}(\.\d+)?)?$"#, options: .regularExpression) != nil { return text }
            throw SyntaxError()
        }

        // MARK: Strings

        /// A `"…"` string on one line.
        mutating func basicString() throws -> String {
            i += 1
            var out = String.UnicodeScalarView()
            while let c = peek() {
                if c == "\"" { i += 1; return String(out) }
                if c == "\n" || c == "\r" { throw SyntaxError() }
                if c == "\\" {
                    i += 1
                    try escape(into: &out)
                } else {
                    out.append(c); i += 1
                }
            }
            throw SyntaxError()
        }

        /// A `'…'` string on one line, no escapes.
        mutating func literalString() throws -> String {
            i += 1
            var out = String.UnicodeScalarView()
            while let c = peek() {
                if c == "'" { i += 1; return String(out) }
                if c == "\n" || c == "\r" { throw SyntaxError() }
                out.append(c); i += 1
            }
            throw SyntaxError()
        }

        mutating func multilineBasic() throws -> String {
            i += 3
            if peek() == "\r" { i += 1 }
            if peek() == "\n" { i += 1 }
            var out = String.UnicodeScalarView()
            while let c = peek() {
                if c == "\"", peek(1) == "\"", peek(2) == "\"" {
                    i += 3
                    // Up to two more quotes belong to the text.
                    var extra = 0
                    while extra < 2, peek() == "\"" { out.append("\""); i += 1; extra += 1 }
                    return String(out)
                }
                if c == "\\" {
                    i += 1
                    // A backslash at the end of a line removes the line break and the blanks that follow.
                    var j = i
                    while j < s.count, s[j] == " " || s[j] == "\t" || s[j] == "\r" { j += 1 }
                    if j < s.count, s[j] == "\n" {
                        i = j + 1
                        while let d = peek(), d == " " || d == "\t" || d == "\n" || d == "\r" { i += 1 }
                        continue
                    }
                    try escape(into: &out)
                } else {
                    out.append(c); i += 1
                }
            }
            throw SyntaxError()
        }

        mutating func multilineLiteral() throws -> String {
            i += 3
            if peek() == "\r" { i += 1 }
            if peek() == "\n" { i += 1 }
            var out = String.UnicodeScalarView()
            while let c = peek() {
                if c == "'", peek(1) == "'", peek(2) == "'" {
                    i += 3
                    var extra = 0
                    while extra < 2, peek() == "'" { out.append("'"); i += 1; extra += 1 }
                    return String(out)
                }
                out.append(c); i += 1
            }
            throw SyntaxError()
        }

        mutating func escape(into out: inout String.UnicodeScalarView) throws {
            guard let e = peek() else { throw SyntaxError() }
            i += 1
            switch e {
            case "n": out.append("\n")
            case "t": out.append("\t")
            case "r": out.append("\r")
            case "b": out.append("\u{08}")
            case "f": out.append("\u{0C}")
            case "e": out.append("\u{1B}")
            case "\"": out.append("\"")
            case "\\": out.append("\\")
            case "u", "U":
                let length = e == "u" ? 4 : 8
                guard i + length <= s.count else { throw SyntaxError() }
                let hex = String(String.UnicodeScalarView(s[i..<(i + length)]))
                guard let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) else { throw SyntaxError() }
                out.append(scalar)
                i += length
            default: throw SyntaxError()
            }
        }
    }
}
