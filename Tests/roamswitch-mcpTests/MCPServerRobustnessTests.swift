// Mirrored from RoamSwitchTests/ — RoamSwitch 1.5.7 (build 30). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Adversarial-input tests for the MCP server's JSON-RPC parse + dispatch path
/// (`MCPServer.handleLine`). Swift is memory-safe, so the bug class here is
/// traps (force-unwrap, overflow) and hangs (unbounded loops, ReDoS,
/// pathological allocation) — not RCE. Each test asserts the call both
/// completes and stays within a wall-clock budget.
final class MCPServerRobustnessTests: XCTestCase {

    /// Run `handleLine` on a background queue; fail if it doesn't finish in time
    /// (a hang can't be interrupted, but the test reports which input caused it).
    private func expectHandled(_ data: Data, within seconds: TimeInterval = 2,
                               _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            _ = MCPServer.handleLine(data)
            done.signal()
        }
        if done.wait(timeout: .now() + seconds) == .timedOut {
            XCTFail("handleLine did not return within \(seconds)s — possible hang. \(message)", file: file, line: line)
        }
    }

    func testEmptyAndWhitespaceAndGarbage() {
        for s in ["", " ", "\t", "{", "}", "[", "null", "12345", "\"a string\"",
                  "{ not json", "{\"jsonrpc\"", "\u{0000}\u{0001}", "{}",
                  "{\"method\":123}", "{\"method\":\"x\",\"id\":{\"nested\":true}}"] {
            expectHandled(Data(s.utf8), s)
        }
    }

    func testDeeplyNestedJSON_boundedTime() {
        let depth = 100_000
        let bomb = String(repeating: "[", count: depth) + String(repeating: "]", count: depth)
        // JSONSerialization enforces a depth limit; this should be rejected fast,
        // not walked.
        expectHandled(Data(bomb.utf8), within: 3, "nested-array bomb")
    }

    func testDeeplyNestedObject_boundedTime() {
        let depth = 50_000
        let bomb = String(repeating: "{\"a\":", count: depth) + "1" + String(repeating: "}", count: depth)
        expectHandled(Data(bomb.utf8), within: 3, "nested-object bomb")
    }

    func testGiantStringArgument_boundedTime() {
        let big = String(repeating: "A", count: 5_000_000)
        let msg = #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":"https://\#(big).com"}}}"#
        expectHandled(Data(msg.utf8), within: 5, "5MB url argument")
    }

    func testPathologicalHelpQuery_boundedTime() {
        for q in [String(repeating: "a", count: 200_000),
                  String(repeating: "(", count: 50_000),
                  String(repeating: ".*", count: 20_000),
                  "\\" + String(repeating: "\\", count: 10_000)] {
            let esc = q.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let msg = #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_app_help","arguments":{"query":"\#(esc)"}}}"#
            expectHandled(Data(msg.utf8), within: 3, "pathological get_app_help query")
        }
    }

    func testLargeBatch_boundedTime() {
        // The old code looped an uncapped batch array. Fast methods only, so this
        // documents the current behaviour rather than asserting a cap.
        let one = #"{"jsonrpc":"2.0","id":1,"method":"ping"}"#
        let batch = "[" + Array(repeating: one, count: 10_000).joined(separator: ",") + "]"
        expectHandled(Data(batch.utf8), within: 5, "10k-element ping batch")
    }

    func testMalformedToolAndResourceParams() {
        for s in [
            #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{}}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":42}}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"audit_url_safety"}}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":42}}}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":42}}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"resources/read"}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":42}}"#,
        ] {
            expectHandled(Data(s.utf8), s)
        }
    }
}
