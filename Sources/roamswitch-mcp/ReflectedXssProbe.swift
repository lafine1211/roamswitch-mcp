// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.1 (build 180).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Reflected cross-site scripting check for local dev servers (`webvuln-xss`), the fourth
/// generic dev-server check next to CORS, path traversal and open redirect in
/// `ActiveVulnScan`. The macOS counterpart of the Linux client's `reflected_xss.rs`; both
/// follow the same rules so a finding means the same thing on either platform.
///
/// Safety invariants (the same as the other generic checks, plus the bounds this one needs):
/// - `127.0.0.1` only, and only on the dev-server ports `ActiveVulnScan.runScan` already
///   restricts the generic checks to.
/// - GET only, never POST: a form is read for its field names but never submitted, so
///   nothing is created or changed on the server.
/// - The value sent is a harmless marker: random letters and digits around `<`, `>`, `"` and
///   `'`. It contains no script, no event handler and no URL, so even a page that reflects it
///   unescaped runs nothing in a browser.
/// - Bounded: one request for `/`, then at most `maxCandidates` parameter requests, each with
///   the caller's short timeout and at most `maxBody` bytes read. No retries.
///
/// What it decides. A page can reflect a value in many places, and only some are exploitable
/// with the characters in the marker, so the response is read with a small HTML tokenizer that
/// knows where the marker landed:
/// - in element text, a raw `<marker>` becomes an element: exploitable;
/// - inside a double- or single-quoted attribute value, the raw quote of that kind ends the
///   value: exploitable;
/// - inside a comment, `<script>`, `<style>`, `<textarea>`, `<title>` and the other raw-text
///   elements, `<` and quotes do nothing without a matching closing tag, so it is not counted
///   (those contexts, and JavaScript strings, are not covered).
///
/// Three outcomes, like every other check: exploitable (`true`), reflected but every
/// reflection was neutralized (`false`, "confirmed safe"), and nothing reflected the marker at
/// all (`nil`, "inconclusive": no parameter was found that this check could test, which is not
/// the same as the server being safe).
enum ReflectedXssProbe {
    static let maxCandidates = 12
    static let maxBody = 64 * 1024

    /// Names tried on `/` when the page itself offers none (a search box built by script has
    /// no `<form>` to read).
    static let fallbackParams = ["q", "s", "search", "query", "keyword", "name", "message"]

    /// Where in the document a byte offset falls.
    enum Ctx: Equatable {
        case text            // <p>HERE</p>
        case comment         // <!-- HERE -->
        case rawText         // inside <script>, <style>, <textarea>, <title>, ...
        case tag             // inside a start tag, outside a quoted attribute value
        case attr(UInt8)     // inside a quoted attribute value; the byte is the quote
    }

    private static let rawTextElements: Set<String> = ["script", "style", "textarea", "title", "xmp", "iframe", "noembed", "noframes"]

    // MARK: - byte helpers

    private static func find(_ hay: [UInt8], from: Int, _ needle: [UInt8], caseInsensitive: Bool = false) -> Int? {
        guard !needle.isEmpty, from >= 0, from + needle.count <= hay.count else { return nil }
        var i = from
        while i + needle.count <= hay.count {
            var ok = true
            for k in 0..<needle.count {
                var a = hay[i + k], b = needle[k]
                if caseInsensitive {
                    if a >= 65 && a <= 90 { a += 32 }
                    if b >= 65 && b <= 90 { b += 32 }
                }
                if a != b { ok = false; break }
            }
            if ok { return i }
            i += 1
        }
        return nil
    }

    private static func isSpace(_ c: UInt8) -> Bool { c == 32 || (c >= 9 && c <= 13) }
    private static func isAlpha(_ c: UInt8) -> Bool { (c >= 65 && c <= 90) || (c >= 97 && c <= 122) }
    private static func isAlnum(_ c: UInt8) -> Bool { isAlpha(c) || (c >= 48 && c <= 57) }

    private enum TagEnd { case closed(Int), inside(Ctx) }

    /// Reads attributes from `start` (just after the tag name) until the closing `>`, or until `end`.
    private static func scanTag(_ b: [UInt8], from start: Int, end: Int) -> TagEnd {
        let n = b.count
        var pos = start
        while true {
            while pos < n && (isSpace(b[pos]) || b[pos] == UInt8(ascii: "/")) { pos += 1 }
            if pos >= end || pos >= n { return .inside(.tag) }
            if b[pos] == UInt8(ascii: ">") { return .closed(pos) }
            // attribute name
            while pos < n && !isSpace(b[pos]) && b[pos] != UInt8(ascii: "=") && b[pos] != UInt8(ascii: ">") && b[pos] != UInt8(ascii: "/") { pos += 1 }
            if pos >= end { return .inside(.tag) }
            while pos < n && isSpace(b[pos]) { pos += 1 }
            if pos < n && b[pos] == UInt8(ascii: "=") {
                pos += 1
                while pos < n && isSpace(b[pos]) { pos += 1 }
                if pos >= end { return .inside(.tag) }
                if pos < n && (b[pos] == UInt8(ascii: "\"") || b[pos] == UInt8(ascii: "'")) {
                    let q = b[pos]
                    let valueStart = pos + 1
                    var close: Int?
                    var k = valueStart
                    while k < n { if b[k] == q { close = k; break }; k += 1 }
                    if let close = close {
                        if end >= valueStart && end < close { return .inside(.attr(q)) }
                        if end < valueStart { return .inside(.tag) }
                        pos = close + 1
                    } else {
                        // the quote never closes: everything after it is the value
                        return .inside(end >= valueStart ? .attr(q) : .tag)
                    }
                } else {
                    while pos < n && !isSpace(b[pos]) && b[pos] != UInt8(ascii: ">") { pos += 1 }
                    if pos >= end { return .inside(.tag) }
                }
            }
        }
    }

    /// The context of byte `offset` in `html`.
    static func context(in html: [UInt8], at offset: Int) -> Ctx {
        let end = min(offset, html.count)
        var i = 0
        let lt = UInt8(ascii: "<")
        while i < end {
            if html[i] != lt { i += 1; continue }
            if find(html, from: i, Array("<!--".utf8)) == i {
                if let j = find(html, from: i + 4, Array("-->".utf8)), j + 3 <= end { i = j + 3; continue }
                return .comment
            }
            let next: UInt8 = i + 1 < html.count ? html[i + 1] : 0
            if next == UInt8(ascii: "/") || next == UInt8(ascii: "!") || next == UInt8(ascii: "?") {
                var k = i
                var gt: Int?
                while k < html.count { if html[k] == UInt8(ascii: ">") { gt = k; break }; k += 1 }
                if let gt = gt, gt < end { i = gt + 1; continue }
                return .tag
            }
            if !isAlpha(next) { i += 1; continue }
            let nameStart = i + 1
            var j = nameStart
            while j < html.count && (isAlnum(html[j]) || html[j] == UInt8(ascii: "-") || html[j] == UInt8(ascii: ":")) { j += 1 }
            if j >= end { return .tag }
            let name = String(decoding: html[nameStart..<j], as: UTF8.self).lowercased()
            switch scanTag(html, from: j, end: end) {
            case .inside(let c):
                return c
            case .closed(let gt):
                i = gt + 1
                if rawTextElements.contains(name) {
                    if let c = find(html, from: i, Array("</\(name)".utf8), caseInsensitive: true), c < end { i = c } else { return .rawText }
                }
            }
        }
        return .text
    }

    // MARK: - analysis

    struct Analysis: Equatable {
        /// The marker appears in the body at all (escaped or not).
        var reflected = false
        /// How an exploitable reflection breaks out, if one does.
        var exploitable: String?
    }

    /// The marker value for one scan. `token` is letters and digits only.
    static func markerValue(token: String) -> String {
        "\(token)a<\(token)b>\(token)c\"\(token)d'\(token)e"
    }

    static func percentEncode(_ s: String) -> String {
        var out = ""
        for c in s.utf8 {
            if isAlnum(c) { out.append(Character(UnicodeScalar(c))) } else { out += String(format: "%%%02X", c) }
        }
        return out
    }

    /// Reads `body` for the marker built from `token`.
    static func analyze(body: String, token: String) -> Analysis {
        let b = Array(body.utf8)
        var result = Analysis()
        result.reflected = find(b, from: 0, Array("\(token)a".utf8)) != nil
        guard result.reflected else { return result }
        let tag = Array("<\(token)b>".utf8)
        var from = 0
        while let i = find(b, from: from, tag) {
            if context(in: b, at: i) == .text { result.exploitable = "html"; return result }
            from = i + 1
        }
        let probes: [(String, UInt8)] = [("\(token)c\"", UInt8(ascii: "\"")), ("\(token)d'", UInt8(ascii: "'"))]
        for (needle, quote) in probes {
            var from = 0
            let n = Array(needle.utf8)
            while let i = find(b, from: from, n) {
                if context(in: b, at: i) == .attr(quote) { result.exploitable = "attribute"; return result }
                from = i + 1
            }
        }
        return result
    }

    // MARK: - candidates

    /// The value of attribute `name` inside the text of a tag (after the tag name), if present.
    private static func attrValue(_ inner: String, _ name: String) -> String? {
        let b = Array(inner.utf8)
        let n = b.count
        var pos = 0
        while pos < n {
            while pos < n && (isSpace(b[pos]) || b[pos] == UInt8(ascii: "/")) { pos += 1 }
            let start = pos
            while pos < n && !isSpace(b[pos]) && b[pos] != UInt8(ascii: "=") && b[pos] != UInt8(ascii: "/") { pos += 1 }
            let key = String(decoding: b[start..<pos], as: UTF8.self).lowercased()
            while pos < n && isSpace(b[pos]) { pos += 1 }
            var value = ""
            if pos < n && b[pos] == UInt8(ascii: "=") {
                pos += 1
                while pos < n && isSpace(b[pos]) { pos += 1 }
                if pos < n && (b[pos] == UInt8(ascii: "\"") || b[pos] == UInt8(ascii: "'")) {
                    let q = b[pos]
                    let vs = pos + 1
                    var ve = vs
                    while ve < n && b[ve] != q { ve += 1 }
                    value = String(decoding: b[vs..<ve], as: UTF8.self)
                    pos = min(ve + 1, n)
                } else {
                    let vs = pos
                    while pos < n && !isSpace(b[pos]) { pos += 1 }
                    value = String(decoding: b[vs..<pos], as: UTF8.self)
                }
            }
            if key == name { return value }
            if pos == start { pos += 1 }
        }
        return nil
    }

    /// `(path, query)` of a same-server link, or `nil` for anything that leaves this server.
    private static func localTarget(_ href: String, port: Int) -> (path: String, query: String)? {
        var h = href.trimmingCharacters(in: .whitespaces)
        for prefix in ["http://127.0.0.1:\(port)", "http://localhost:\(port)"] where h.hasPrefix(prefix) {
            h = String(h.dropFirst(prefix.count))
            if h.isEmpty { h = "/" }
        }
        let lower = h.lowercased()
        if h.hasPrefix("#") || h.hasPrefix("//") || h.contains("://") || lower.hasPrefix("javascript:") || lower.hasPrefix("mailto:") { return nil }
        h = String(h.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
        let parts = h.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        var path = String(parts.first ?? "")
        let query = parts.count > 1 ? String(parts[1]) : ""
        if path.isEmpty { path = "/" }
        else if !path.hasPrefix("/") {
            var rest = path
            while rest.hasPrefix("./") { rest.removeFirst(2) }
            path = "/" + rest
        }
        return (path, query)
    }

    private static func safeName(_ name: String) -> Bool {
        !name.isEmpty && name.utf8.count <= 40 && name.utf8.allSatisfy { isAlnum($0) || $0 == UInt8(ascii: "_") || $0 == UInt8(ascii: "-") || $0 == UInt8(ascii: "[") || $0 == UInt8(ascii: "]") || $0 == UInt8(ascii: ".") }
    }

    /// `(path, parameter)` pairs worth testing, read from the links and GET forms of `html`, then
    /// the fixed fallback names on `/`. At most `maxCandidates`, no duplicates.
    static func candidates(html: String, port: Int) -> [(path: String, name: String)] {
        var out: [(path: String, name: String)] = []
        func push(_ path: String, _ name: String) {
            if out.count < maxCandidates, safeName(name), !out.contains(where: { $0.path == path && $0.name == name }) {
                out.append((path, name))
            }
        }
        let b = Array(html.utf8)
        var i = 0
        var form: String?   // path of the GET form being read
        while i < b.count {
            guard let lt = b[i...].firstIndex(of: UInt8(ascii: "<")), let gt = b[lt...].firstIndex(of: UInt8(ascii: ">")) else { break }
            let inner = String(decoding: b[(lt + 1)..<gt], as: UTF8.self)
            i = gt + 1
            let nameEnd = inner.firstIndex(where: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" || $0 == "/" }) ?? inner.endIndex
            let tag = inner[..<nameEnd].lowercased()
            let attrs = String(inner[nameEnd...])
            switch tag {
            case "a":
                if let href = attrValue(attrs, "href"), let t = localTarget(href, port: port) {
                    for pair in t.query.split(separator: "&") {
                        if let eq = pair.firstIndex(of: "=") { push(t.path, String(pair[..<eq])) }
                    }
                }
            case "form":
                let method = (attrValue(attrs, "method") ?? "").lowercased()
                if method.isEmpty || method == "get" {
                    let action = attrValue(attrs, "action") ?? ""
                    if let t = localTarget(action, port: port) { form = t.path }
                    else { form = action.trimmingCharacters(in: .whitespaces).isEmpty ? "/" : nil }
                } else {
                    form = nil
                }
            case "/form":
                form = nil
            case "input", "textarea", "select":
                if let path = form {
                    let kind = (attrValue(attrs, "type") ?? "").lowercased()
                    let skip: Set<String> = ["submit", "button", "image", "reset", "hidden", "file", "password", "checkbox", "radio"]
                    if !skip.contains(kind), let n = attrValue(attrs, "name") { push(path, n) }
                }
            default:
                break
            }
        }
        for name in fallbackParams { push("/", name) }
        return out
    }

    // MARK: - HTTP and the probe

    private struct Page {
        var contentType: String
        var body: String
    }

    private static func isHTML(_ contentType: String) -> Bool {
        contentType.contains("text/html") || contentType.contains("application/xhtml+xml")
    }

    /// One GET on an ephemeral, cookie-less, cache-less session (like the other generic checks).
    private static func get(port: Int, pathAndQuery: String, timeout: TimeInterval) -> Page? {
        guard let url = URL(string: "http://127.0.0.1:\(port)\(pathAndQuery)") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let semaphore = DispatchSemaphore(value: 0)
        var page: Page?
        let task = session.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                let ct = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
                page = Page(contentType: ct, body: String(decoding: (data ?? Data()).prefix(maxBody), as: UTF8.self))
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return page
    }

    /// A token that differs on every scan, so a cached or replayed page cannot look like a reflection.
    static func freshToken() -> String {
        "rsxss" + String(format: "%08x", UInt32.random(in: 0...UInt32.max))
    }

    struct Result: Equatable {
        /// `true` exploitable, `false` reflected but neutralized, `nil` inconclusive.
        var vulnerable: Bool?
        /// Where it was found, e.g. `GET /search?q (html)`, when `vulnerable == true`.
        var detail: String?
    }

    /// Runs the check against `127.0.0.1:{port}`.
    static func probe(port: Int, timeout: TimeInterval = 2.0, token: String = freshToken()) -> Result {
        guard let root = get(port: port, pathAndQuery: "/", timeout: timeout) else { return Result(vulnerable: nil, detail: nil) }
        let html = isHTML(root.contentType) ? root.body : ""
        let encoded = percentEncode(markerValue(token: token))
        var reflectedSomewhere = false
        var answered = 0
        for c in candidates(html: html, port: port) {
            guard let r = get(port: port, pathAndQuery: "\(c.path)?\(c.name)=\(encoded)", timeout: timeout) else { continue }
            answered += 1
            guard isHTML(r.contentType) else { continue }
            let a = analyze(body: r.body, token: token)
            reflectedSomewhere = reflectedSomewhere || a.reflected
            if let kind = a.exploitable {
                return Result(vulnerable: true, detail: "GET \(c.path)?\(c.name) (\(kind))")
            }
        }
        // Nothing reflected, or the server stopped answering: not "safe", just not verified.
        _ = answered
        return Result(vulnerable: reflectedSomewhere ? false : nil, detail: nil)
    }
}
