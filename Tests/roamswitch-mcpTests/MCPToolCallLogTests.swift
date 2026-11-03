// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.26 (build 205). Do not edit here; see SYNC.md.

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
}
