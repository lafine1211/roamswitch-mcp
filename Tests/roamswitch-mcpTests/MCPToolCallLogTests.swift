// Mirrored from RoamSwitchTests/ — RoamSwitch 2.2.2 (build 226). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class MCPToolCallLogTests: XCTestCase {
    private func decode(_ json: String) -> MCPToolCallLog.Entry {
        try! JSONDecoder().decode(MCPToolCallLog.Entry.self, from: Data(json.utf8))
    }

    func testLineCarriesToolNameAndSortedArgumentKeysOnly() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let json = MCPToolCallLog.line(for: "run_active_vuln_scan", argumentKeys: ["target", "deep"], now: now)!
        let entry = decode(json)
        XCTAssertEqual(entry.tool, "run_active_vuln_scan")
        XCTAssertEqual(entry.argumentKeys, ["deep", "target"], "sorted, for a stable diff/read")
        XCTAssertEqual(entry.timestamp, ISO8601DateFormatter().string(from: now))
    }

    func testNoArgumentsProducesAnEmptyKeyListNotANilOrCrash() {
        let json = MCPToolCallLog.line(for: "get_guard_status", argumentKeys: [], now: Date())!
        XCTAssertEqual(decode(json).argumentKeys, [])
    }

    /// The whole point of logging only key names: this file must never become
    /// a second copy of whatever sensitive path/content a tool argument held.
    func testArgumentValuesAreNeverPartOfTheLineEvenIfTheKeyNameLooksLikeOne() {
        let json = MCPToolCallLog.line(for: "audit_secrets", argumentKeys: ["path"], now: Date())!
        XCTAssertFalse(json.contains("/Users/"), "only the key name 'path' is logged, never a value")
        XCTAssertTrue(json.contains("\"path\""))
    }

    func testEachLineIsSingleLineJSONSuitableForJSONLines() {
        let json = MCPToolCallLog.line(for: "get_guard_status", argumentKeys: [], now: Date())!
        XCTAssertFalse(json.contains("\n"), "must stay one line — the log file is JSON Lines")
    }

    // MARK: - Outcome, one line per call, private file

    private func scratchLog() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-mcp-call-log-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir.appendingPathComponent("log.jsonl")
    }

    private func entries(_ url: URL) throws -> [MCPToolCallLog.Entry] {
        try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map { decode(String($0)) }
    }

    func testALineWrittenByAnOlderVersionStillReads() {
        let old = "{\"argumentKeys\":[\"path\"],\"timestamp\":\"2026-01-01T00:00:00Z\",\"tool\":\"audit_secrets\"}"
        let e = decode(old)
        XCTAssertEqual(e.tool, "audit_secrets")
        XCTAssertNil(e.outcome)
        XCTAssertNil(e.durationMs)
    }

    func testACallIsOneLineThatSaysStartedThenHowItEnded() throws {
        let url = try scratchLog()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let call = MCPToolCallLog.begin(tool: "get_guard_status", arguments: [:], now: t0, to: url)
        let started = try entries(url)
        XCTAssertEqual(started.count, 1)
        XCTAssertEqual(started[0].outcome, "started", "a call that crashes the process stays on record as never finished")
        XCTAssertEqual(started[0].callId, call.id)
        MCPToolCallLog.complete(call, tool: "get_guard_status", arguments: [:], outcome: .ok, now: t0.addingTimeInterval(1.5), to: url)
        let ended = try entries(url)
        XCTAssertEqual(ended.count, 1, "the same line is replaced, so the bound counts calls")
        XCTAssertEqual(ended[0].outcome, "ok")
        XCTAssertEqual(ended[0].durationMs, 1500)
        XCTAssertEqual(ended[0].timestamp, ISO8601DateFormatter().string(from: t0), "the time is the start of the call")
    }

    func testTwoCallsAtOnceKeepTheirOwnLines() throws {
        let url = try scratchLog()
        let a = MCPToolCallLog.begin(tool: "get_guard_status", arguments: [:], to: url)
        let b = MCPToolCallLog.begin(tool: "audit_secrets", arguments: ["path": "/x"], to: url)
        MCPToolCallLog.complete(b, tool: "audit_secrets", arguments: ["path": "/x"], outcome: .error, to: url)
        MCPToolCallLog.complete(a, tool: "get_guard_status", arguments: [:], outcome: .ok, to: url)
        let e = try entries(url)
        XCTAssertEqual(e.map(\.tool), ["get_guard_status", "audit_secrets"])
        XCTAssertEqual(e.map { $0.outcome ?? "" }, ["ok", "error"])
    }

    func testAnUnknownToolNameIsWrittenSafeAndCappedAndMarkedUnknown() throws {
        let url = try scratchLog()
        let hostile = "evil\"tool\n\u{202e}name" + String(repeating: "x", count: 500)
        let call = MCPToolCallLog.begin(tool: hostile, arguments: [:], isKnownTool: false, to: url)
        MCPToolCallLog.complete(call, tool: hostile, arguments: [:], outcome: .unknownTool, isKnownTool: false, to: url)
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(text.split(separator: "\n").count, 1)
        let e = try entries(url)[0]
        XCTAssertEqual(e.outcome, "unknown_tool")
        XCTAssertLessThanOrEqual(e.tool.count, MCPToolCallLog.maxToolNameLength)
        XCTAssertTrue(e.tool.hasPrefix("evil_tool__name"))
        XCTAssertFalse(text.contains("\u{202e}"))
    }

    func testTheFileIsPrivateEvenWhenItWasWorldReadableBefore() throws {
        let url = try scratchLog()
        try "".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        MCPToolCallLog.begin(tool: "get_guard_status", arguments: [:], to: url)
        let mode = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.intValue, 0o600)
    }

    func testTheFileIsBoundedByCalls() throws {
        let url = try scratchLog()
        // Seeding the file directly: 2,000 calls through the lock and fsync would only make the test slow.
        let seed = (0..<MCPToolCallLog.maxEntries).map { i in
            MCPToolCallLog.line(for: "get_guard_status", argumentKeys: [], outcome: .ok, durationMs: 1, callId: String(format: "%08x", i))!
        }
        try (seed.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
        let call = MCPToolCallLog.begin(tool: "audit_secrets", arguments: [:], to: url)
        MCPToolCallLog.complete(call, tool: "audit_secrets", arguments: [:], outcome: .ok, to: url)
        let e = try entries(url)
        XCTAssertEqual(e.count, MCPToolCallLog.maxEntries)
        XCTAssertEqual(e.last?.tool, "audit_secrets")
        XCTAssertEqual(e.last?.outcome, "ok")
    }

    /// Through the real dispatch: a known tool ends `ok`, a name that is not a tool ends `unknown_tool` with a safe name.
    func testTheDispatchWritesTheOutcomeOfEachCall() throws {
        let url = try scratchLog()
        MCPToolCallLog.overrideURLForTesting = url
        addTeardownBlock { MCPToolCallLog.overrideURLForTesting = nil }
        func call(_ name: String, _ args: [String: Any] = [:]) {
            _ = MCPServer.handleMessage(["jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": ["name": name, "arguments": args]])
        }
        call("get_vpn_status")
        call("no/such tool", ["secret_path": "/Users/x/.ssh/id_rsa"])
        let e = try entries(url)
        XCTAssertEqual(e.count, 2)
        XCTAssertEqual(e[0].tool, "get_vpn_status")
        XCTAssertEqual(e[0].outcome, "ok")
        XCTAssertNotNil(e[0].durationMs)
        XCTAssertEqual(e[1].tool, "no_such_tool")
        XCTAssertEqual(e[1].outcome, "unknown_tool")
        XCTAssertEqual(e[1].argumentKeys, ["secret_path"])
        XCTAssertFalse(try String(contentsOf: url, encoding: .utf8).contains(".ssh"), "no argument value is written")
    }
}
