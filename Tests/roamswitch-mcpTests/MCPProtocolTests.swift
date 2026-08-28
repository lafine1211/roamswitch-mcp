// Mirrored from RoamSwitchTests/ — RoamSwitch 1.4.5 (build 19). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Covers `initialize` protocol-version negotiation for `RoamSwitchMCPServer`.
final class MCPProtocolTests: XCTestCase {
    func testEchoesClientVersionWhenSupported() {
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: "2024-11-05"), "2024-11-05")
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: "2025-03-26"), "2025-03-26")
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: "2025-06-18"), "2025-06-18")
    }

    func testFallsBackToPreferredWhenClientVersionAbsent() {
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: nil), MCPProtocol.preferredVersion)
    }

    func testFallsBackToPreferredWhenClientVersionUnknown() {
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: "1999-01-01"), MCPProtocol.preferredVersion)
        XCTAssertEqual(MCPProtocol.negotiateVersion(clientRequested: ""), MCPProtocol.preferredVersion)
    }

    func testPreferredVersionIsItselfSupported() {
        XCTAssertTrue(MCPProtocol.supportedVersions.contains(MCPProtocol.preferredVersion))
    }
}
