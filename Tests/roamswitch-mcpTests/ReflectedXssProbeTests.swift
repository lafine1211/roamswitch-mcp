// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.1 (build 180). Do not edit here; see SYNC.md.

import XCTest
import Network
@testable import roamswitch_mcp

/// The macOS counterpart of the Linux client's `reflected_xss.rs` tests: the same HTML-context rules, the same
/// three outcomes, run against a real local `NWListener` that serves several requests.
final class ReflectedXssProbeTests: XCTestCase {
    private let token = "rsxss00000001"

    // MARK: - context and analysis (pure)

    private func ctx(_ html: String) -> ReflectedXssProbe.Ctx {
        let bytes = Array(html.utf8)
        let here = Array("HERE".utf8)
        var at = 0
        for i in 0...(bytes.count - here.count) where Array(bytes[i..<(i + here.count)]) == here { at = i; break }
        return ReflectedXssProbe.context(in: bytes, at: at)
    }

    func testContextDistinguishesTextAttributesCommentsAndRawText() {
        XCTAssertEqual(ctx("<p>HERE</p>"), .text)
        XCTAssertEqual(ctx("<div><p class=a>x</p><p>HERE"), .text)
        XCTAssertEqual(ctx(#"<input value="HERE">"#), .attr(UInt8(ascii: "\"")))
        XCTAssertEqual(ctx("<input value='HERE'>"), .attr(UInt8(ascii: "'")))
        XCTAssertEqual(ctx("<input value=HERE>"), .tag)
        XCTAssertEqual(ctx("<input HERE>"), .tag)
        XCTAssertEqual(ctx("<!-- HERE -->"), .comment)
        XCTAssertEqual(ctx("<!-- a --><p>HERE"), .text)
        XCTAssertEqual(ctx("<script>var a = 'HERE';</script>"), .rawText)
        XCTAssertEqual(ctx("<style>p{content:'HERE'}</style>"), .rawText)
        XCTAssertEqual(ctx("<TITLE>HERE</TITLE>"), .rawText)
        XCTAssertEqual(ctx("<textarea>HERE</textarea>"), .rawText)
        XCTAssertEqual(ctx("<script>x</script><p>HERE"), .text)
        XCTAssertEqual(ctx(#"<a href="/x?a=1&b=2" title="t">HERE</a>"#), .text)
        // a `>` inside a quoted value does not end the tag
        XCTAssertEqual(ctx(#"<a title="a > b" href="HERE">"#), .attr(UInt8(ascii: "\"")))
        // a lone `<` in text is not a tag
        XCTAssertEqual(ctx("1 < 2 and <p>HERE"), .text)
        XCTAssertEqual(ctx("1 < 2 HERE"), .text)
    }

    func testAnalyzeFlagsOnlyReflectionsTheMarkerCanExploit() {
        let m = ReflectedXssProbe.markerValue(token: token)
        XCTAssertEqual(ReflectedXssProbe.analyze(body: "<p>Results for \(m)</p>", token: token).exploitable, "html")
        let escaped = "<p>Results for \(token)a&lt;\(token)b&gt;\(token)c&quot;\(token)d&#39;\(token)e</p>"
        XCTAssertEqual(ReflectedXssProbe.analyze(body: escaped, token: token), ReflectedXssProbe.Analysis(reflected: true, exploitable: nil))
        XCTAssertEqual(ReflectedXssProbe.analyze(body: #"<input value="\#(m)">"#, token: token).exploitable, "attribute")
        // the attribute is single-quoted: a raw `"` does not break out
        XCTAssertNil(ReflectedXssProbe.analyze(body: "<input value='\(token)a&lt;\(token)b&gt;\(token)c\"\(token)d&#39;\(token)e'>", token: token).exploitable)
        XCTAssertEqual(ReflectedXssProbe.analyze(body: "<input value='\(token)a\(token)d'\(token)e'>", token: token).exploitable, "attribute")
        for wrap in ["<!-- {} -->", "<script>var q = '{}';</script>", "<title>{}</title>", "<textarea>{}</textarea>"] {
            let a = ReflectedXssProbe.analyze(body: wrap.replacingOccurrences(of: "{}", with: m), token: token)
            XCTAssertTrue(a.reflected, wrap)
            XCTAssertNil(a.exploitable, wrap)
        }
        XCTAssertEqual(ReflectedXssProbe.analyze(body: "<p>hello</p>", token: token), ReflectedXssProbe.Analysis())
    }

    func testCandidatesComeFromLinksAndGetFormsAndSkipTheRest() {
        let html = """
        <html><body>
        <a href="/search?q=1&page=2">s</a>
        <a href="http://127.0.0.1:3000/items?id=5">i</a>
        <a href="https://example.com/x?evil=1">external</a>
        <a href="javascript:void(0)">js</a>
        <form action="/find" method="get"><input name="term" type="text"><input name="csrf" type="hidden"><input type="submit" name="go"></form>
        <form action="/login" method="post"><input name="user"></form>
        <form><textarea name="note"></textarea></form>
        </body></html>
        """
        let c = ReflectedXssProbe.candidates(html: html, port: 3000)
        func has(_ p: String, _ n: String) -> Bool { c.contains { $0.path == p && $0.name == n } }
        XCTAssertTrue(has("/search", "q") && has("/search", "page") && has("/items", "id") && has("/find", "term") && has("/", "note"))
        XCTAssertFalse(has("/x", "evil") || has("/find", "csrf") || has("/find", "go") || has("/login", "user"))
        XCTAssertLessThanOrEqual(c.count, ReflectedXssProbe.maxCandidates)
        let f = ReflectedXssProbe.candidates(html: "", port: 3000)
        XCTAssertEqual(f.count, ReflectedXssProbe.fallbackParams.count)
        XCTAssertTrue(has("/", "q") || f.contains { $0.path == "/" && $0.name == "q" })
    }

    func testTheMarkerHasNoScriptAndIsPercentEncoded() {
        let m = ReflectedXssProbe.markerValue(token: "rsxssdeadbeef")
        XCTAssertFalse(m.contains("script") || m.contains("alert") || m.contains("javascript"))
        XCTAssertEqual(ReflectedXssProbe.percentEncode("a<b"), "a%3Cb")
    }

    // MARK: - against a real local server

    /// A tiny dev server: `handler(pathAndQuery) -> (contentType, body)`, answering every connection.
    private func serve(_ handler: @escaping (String) -> (String, String)) -> Int {
        let listener = try! NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        var boundPort = 0
        listener.stateUpdateHandler = { state in
            if case .ready = state, boundPort == 0 { boundPort = Int(listener.port?.rawValue ?? 0); ready.signal() }
        }
        listener.newConnectionHandler = { connection in
            connection.stateUpdateHandler = { state in
                guard state == .ready else { return }
                connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, _ in
                    let req = String(decoding: data ?? Data(), as: UTF8.self)
                    let target = req.split(separator: " ").dropFirst().first.map(String.init) ?? "/"
                    let (ct, body) = handler(target)
                    let reply = "HTTP/1.1 200 OK\r\nContent-Type: \(ct)\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
                    connection.send(content: Data(reply.utf8), completion: .contentProcessed { _ in connection.cancel() })
                }
            }
            connection.start(queue: .global())
        }
        listener.start(queue: .global())
        _ = ready.wait(timeout: .now() + 2)
        return boundPort
    }

    private func queryValue(_ target: String, _ name: String) -> String {
        guard let q = target.split(separator: "?", maxSplits: 1).dropFirst().first else { return "" }
        for pair in q.split(separator: "&") where pair.hasPrefix("\(name)=") {
            return String(pair.dropFirst(name.count + 1)).removingPercentEncoding ?? ""
        }
        return ""
    }

    private let form = #"<form action="/search"><input name="q"></form>"#

    func testAPageThatPrintsTheQueryUnescapedIsReported() {
        let port = serve { [form] t in ("text/html; charset=utf-8", "<html>\(form)<p>You searched: \(self.queryValue(t, "q"))</p></html>") }
        let r = ReflectedXssProbe.probe(port: port, timeout: 2, token: token)
        XCTAssertEqual(r.vulnerable, true)
        XCTAssertEqual(r.detail, "GET /search?q (html)")
    }

    func testAPageThatEscapesTheQueryIsConfirmedSafe() {
        let port = serve { [form] t in
            let v = self.queryValue(t, "q").replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "'", with: "&#39;")
            return ("text/html", "<html>\(form)<p>You searched: \(v)</p></html>")
        }
        let r = ReflectedXssProbe.probe(port: port, timeout: 2, token: token)
        XCTAssertEqual(r.vulnerable, false)
        XCTAssertNil(r.detail)
    }

    func testAnAttributeBreakoutIsReportedAndAScriptStringIsNot() {
        var port = serve { [form] t in ("text/html", #"<html>\#(form)<input name="q" value="\#(self.queryValue(t, "q"))"></html>"#) }
        XCTAssertEqual(ReflectedXssProbe.probe(port: port, timeout: 2, token: token).detail, "GET /search?q (attribute)")
        port = serve { [form] t in ("text/html", "<html>\(form)<script>var q = '\(self.queryValue(t, "q"))';</script></html>") }
        XCTAssertNotEqual(ReflectedXssProbe.probe(port: port, timeout: 2, token: token).vulnerable, true)
    }

    func testJSONAndPlainTextResponsesAreNeverReported() {
        var port = serve { t in ("application/json", #"{"q":"\#(self.queryValue(t, "q"))"}"#) }
        XCTAssertNil(ReflectedXssProbe.probe(port: port, timeout: 2, token: token).vulnerable)
        port = serve { t in ("text/plain", self.queryValue(t, "q")) }
        XCTAssertNil(ReflectedXssProbe.probe(port: port, timeout: 2, token: token).vulnerable)
    }

    func testAServerThatReflectsNothingIsInconclusiveNotSafe() {
        let port = serve { [form] _ in ("text/html", "<html>\(form)<p>hello</p></html>") }
        XCTAssertNil(ReflectedXssProbe.probe(port: port, timeout: 2, token: token).vulnerable)
    }

    func testAClosedPortIsInconclusive() {
        let listener = try! NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        var port = 0
        listener.stateUpdateHandler = { if case .ready = $0 { port = Int(listener.port?.rawValue ?? 0); ready.signal() } }
        listener.newConnectionHandler = { $0.cancel() }
        listener.start(queue: .global())
        _ = ready.wait(timeout: .now() + 2)
        listener.cancel()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertNil(ReflectedXssProbe.probe(port: port, timeout: 0.5, token: token).vulnerable)
    }
}
