// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.13 (build 192). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Every MCP tool tells the client what it does to the world (read-only, destructive, repeatable, open-world).
final class MCPToolAnnotationsTests: XCTestCase {

    /// The only tools that write state on this Mac, listed by hand. A new tool is read-only unless it is added here
    /// together with the reason (see MCPServer.stateWritingTools).
    private let nonReadOnlyAllowlist: Set<String> = ["run_active_vuln_scan", "audit_security_logs", "run_npm_audit_signatures"]
    /// Of those, the ones whose repeat call adds something (a log row, a baseline that absorbs the last report).
    private let nonIdempotentAllowlist: Set<String> = ["run_active_vuln_scan", "audit_security_logs"]

    func testEveryToolCarriesAnnotationsAndOnlyTheAllowlistedOnesAreNotReadOnly() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        XCTAssertGreaterThan(tools.count, 30)
        var seen: Set<String> = []
        for tool in tools {
            let name = try XCTUnwrap(tool["name"] as? String)
            seen.insert(name)
            let annotations = try XCTUnwrap(tool["annotations"] as? [String: Any], "\(name) has no annotations")
            XCTAssertEqual(annotations["readOnlyHint"] as? Bool, !nonReadOnlyAllowlist.contains(name), "\(name) readOnlyHint")
            XCTAssertEqual(annotations["destructiveHint"] as? Bool, false, "\(name) destructiveHint")
            XCTAssertEqual(annotations["idempotentHint"] as? Bool, !nonIdempotentAllowlist.contains(name), "\(name) idempotentHint")
            XCTAssertNotNil(annotations["openWorldHint"] as? Bool, "\(name) openWorldHint")
            XCTAssertFalse((tool["description"] as? String ?? "").isEmpty, "\(name) keeps its description")
            XCTAssertNotNil(tool["inputSchema"], "\(name) keeps its input schema")
        }
        // Every allowlisted name is a real tool (a renamed tool must not silently become "read-only").
        XCTAssertTrue(nonReadOnlyAllowlist.isSubset(of: seen))
        XCTAssertTrue(nonIdempotentAllowlist.isSubset(of: nonReadOnlyAllowlist))
    }

    func testTheDescriptionOfAWritingToolSaysSo() throws {
        for name in nonReadOnlyAllowlist {
            let tool = try XCTUnwrap(MCPServer.toolDefinitionsForTesting().first { $0["name"] as? String == name })
            let description = try XCTUnwrap(tool["description"] as? String)
            XCTAssertTrue(description.contains("not annotated read-only"), "\(name) should explain why it is not read-only")
        }
    }

    func testOnlyTheNpmRegistryToolIsOpenWorld() {
        let openWorld = MCPServer.toolDefinitionsForTesting().compactMap { tool -> String? in
            guard (tool["annotations"] as? [String: Any])?["openWorldHint"] as? Bool == true else { return nil }
            return tool["name"] as? String
        }
        XCTAssertEqual(openWorld, ["run_npm_audit_signatures"])
        // run_active_vuln_scan reaches 127.0.0.1 only.
        let active = MCPServer.toolDefinitionsForTesting().first { $0["name"] as? String == "run_active_vuln_scan" }
        XCTAssertEqual((active?["annotations"] as? [String: Any])?["openWorldHint"] as? Bool, false)
    }

    func testInitializeInstructionsNameTheThreeWritingTools() throws {
        let responses = MCPServer.handleMessage(["jsonrpc": "2.0", "id": 1, "method": "initialize", "params": ["protocolVersion": "2025-03-26"]])
        let result = try XCTUnwrap(responses.first?["result"] as? [String: Any])
        let instructions = try XCTUnwrap(result["instructions"] as? String)
        XCTAssertFalse(instructions.hasPrefix("Read-only access"), "three tools write local state")
        for name in nonReadOnlyAllowlist {
            XCTAssertTrue(instructions.contains("'\(name)'"), "\(name) should be named in the instructions")
        }
        XCTAssertTrue(instructions.contains("not annotated read-only"))
    }

    func testToolNamesAreUnique() {
        let names = MCPServer.toolDefinitionsForTesting().compactMap { $0["name"] as? String }
        XCTAssertEqual(names.count, Set(names).count)
    }

    func testToolsListSendsTheAnnotations() throws {
        let responses = MCPServer.handleMessage(["jsonrpc": "2.0", "id": 1, "method": "tools/list"])
        let result = try XCTUnwrap(responses.first?["result"] as? [String: Any])
        let tools = try XCTUnwrap(result["tools"] as? [[String: Any]])
        XCTAssertTrue(tools.allSatisfy { $0["annotations"] != nil })
    }
}
