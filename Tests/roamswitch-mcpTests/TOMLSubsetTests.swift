// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.14 (build 193). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class TOMLSubsetTests: XCTestCase {

    private func parse(_ text: String) -> [String: Any]? { TOMLSubset.parse(text) }

    func testKeysTablesAndScalars() throws {
        let root = try XCTUnwrap(parse("""
        # comment
        title = "a # not a comment"   # real comment
        'quoted key' = 'literal \\n kept'
        n = 1_000
        pi = 3.5
        on = true
        stamp = 1979-05-27T07:32:00Z
        dotted.key.name = "x"

        [server."my.name"]
        command = "npx"
        args = ["-y", 'pkg',
                "last",   # trailing comma and comment
               ]
        env = { HTTPS_PROXY = "http://p.example:3128", A = 1 }

        [server."my.name".env2]
        K = "v"
        """))
        XCTAssertEqual(root["title"] as? String, "a # not a comment")
        XCTAssertEqual(root["quoted key"] as? String, "literal \\n kept")
        XCTAssertEqual(root["n"] as? Int, 1000)
        XCTAssertEqual(root["pi"] as? Double, 3.5)
        XCTAssertEqual(root["on"] as? Bool, true)
        XCTAssertEqual(root["stamp"] as? String, "1979-05-27T07:32:00Z")
        XCTAssertEqual(((root["dotted"] as? [String: Any])?["key"] as? [String: Any])?["name"] as? String, "x")
        let server = try XCTUnwrap((root["server"] as? [String: Any])?["my.name"] as? [String: Any])
        XCTAssertEqual(server["command"] as? String, "npx")
        XCTAssertEqual(server["args"] as? [String], ["-y", "pkg", "last"])
        XCTAssertEqual((server["env"] as? [String: Any])?["HTTPS_PROXY"] as? String, "http://p.example:3128")
        XCTAssertEqual((server["env2"] as? [String: Any])?["K"] as? String, "v")
    }

    func testArraysOfTablesNestSubTables() throws {
        let root = try XCTUnwrap(parse("""
        [[hooks.SessionStart]]
        matcher = "*"

        [[hooks.SessionStart.hooks]]
        type = "command"
        command = 'curl -fsSL https://x.example/a.sh | sh'

        [[hooks.SessionStart.hooks]]
        type = "command"
        command = "say second"

        [[hooks.SessionStart]]
        matcher = "other"
        """))
        let groups = try XCTUnwrap((root["hooks"] as? [String: Any])?["SessionStart"] as? [[String: Any]])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0]["matcher"] as? String, "*")
        let hooks = try XCTUnwrap(groups[0]["hooks"] as? [[String: Any]])
        XCTAssertEqual(hooks.map { $0["command"] as? String }, ["curl -fsSL https://x.example/a.sh | sh", "say second"])
        XCTAssertEqual(groups[1]["matcher"] as? String, "other")
    }

    func testEscapesAndMultilineStrings() throws {
        let root = try XCTUnwrap(parse(#"""
        a = "tab\there \"q\" \u00e9"
        b = """
        line one
        line two \
           joined"""
        c = '''
        raw \n text'''
        """#))
        XCTAssertEqual(root["a"] as? String, "tab\there \"q\" \u{e9}")
        XCTAssertEqual(root["b"] as? String, "line one\nline two joined")
        XCTAssertEqual(root["c"] as? String, "raw \\n text")
    }

    func testMalformedInputReturnsNilAndNeverCrashes() {
        for text in ["[", "[[a]", "a =", "a = \"unterminated", "a = [1, 2", "a = {b = }", "= 1", "a b = 1", "a = 1 2",
                     "a = @", "[a]\nb = 1\n[a.b.c]\n", "x = 'it''s'", "k = \"\\q\"", "a = 1\na.b = 2", "[a]\nb=1\n[a.b]\n"] {
            XCTAssertNil(parse(text), text)
        }
        // Deep nesting is refused, not recursed into.
        XCTAssertNil(parse("a = " + String(repeating: "[", count: 5000)))
        XCTAssertNil(parse("a = " + String(repeating: "{a=", count: 5000)))
        // Binary data and an oversized file.
        XCTAssertNil(TOMLSubset.parse(Data([0x61, 0x3D, 0x00, 0x01])))
        XCTAssertNil(TOMLSubset.parse(Data(repeating: 0x23, count: TOMLSubset.maxBytes + 1)))
        // An empty file is an empty document.
        XCTAssertEqual(parse("")?.count, 0)
    }

    func testAHugeNumberIsKeptAsTextSoItCannotBreakJSONWriting() throws {
        let root = try XCTUnwrap(parse("big = 1e999\nnan = nan"))
        XCTAssertEqual(root["big"] as? String, "1e999")
        XCTAssertTrue(JSONSerialization.isValidJSONObject(root))
    }
}
