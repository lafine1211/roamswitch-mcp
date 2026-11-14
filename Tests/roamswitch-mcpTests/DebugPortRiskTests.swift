// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.2 (build 218). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The same cases as roamswitch-linux `debug_port.rs` and the `ports.rs` test.
final class DebugPortRiskTests: XCTestCase {

    func testTheProcessAndThePortTogetherConfirm() {
        XCTAssertEqual(DebugPortRisk.identify(port: 5005, processName: "java", executablePath: nil)?.confidence, .confirmed)
        XCTAssertEqual(DebugPortRisk.identify(port: 8453, processName: "x", executablePath: "/Library/Java/jdk/bin/java")?.id, "jdwp")
        XCTAssertEqual(DebugPortRisk.identify(port: 9229, processName: "node", executablePath: nil)?.id, "node-inspector")
        XCTAssertEqual(DebugPortRisk.identify(port: 5858, processName: "nodejs", executablePath: nil)?.confidence, .confirmed)
        XCTAssertEqual(DebugPortRisk.identify(port: 9000, processName: "php-fpm8.3", executablePath: nil)?.id, "php-fpm-xdebug")
        XCTAssertEqual(DebugPortRisk.identify(port: 1080, processName: "ssh", executablePath: nil)?.id, "socks")
        XCTAssertEqual(DebugPortRisk.identify(port: 1080, processName: "microsocks", executablePath: nil)?.confidence, .confirmed)
    }

    func testAGenericPortIsNamedOnlyWithItsProcess() {
        for p in ["minio", "portainer", "java", "clickhouse-serv", "python3"] {
            XCTAssertNil(DebugPortRisk.identify(port: 9000, processName: p, executablePath: nil), p)
        }
        XCTAssertNil(DebugPortRisk.identify(port: 8453, processName: "python3", executablePath: nil))
        XCTAssertNil(DebugPortRisk.identify(port: 5858, processName: "python3", executablePath: nil))
    }

    func testADedicatedPortWithoutTheProcessIsAGuess() {
        XCTAssertEqual(DebugPortRisk.identify(port: 5005, processName: "python3", executablePath: nil)?.confidence, .guess)
        XCTAssertEqual(DebugPortRisk.identify(port: 9229, processName: "unknown", executablePath: nil)?.confidence, .guess)
        XCTAssertEqual(DebugPortRisk.identify(port: 1080, processName: "docker-proxy", executablePath: "/usr/bin/docker-proxy")?.confidence, .guess)
    }

    func testSshdAndOtherLookalikesAreNotSsh() {
        XCTAssertEqual(DebugPortRisk.identify(port: 1080, processName: "sshd", executablePath: nil)?.confidence, .guess)
        XCTAssertNil(DebugPortRisk.identify(port: 9000, processName: "phpstorm", executablePath: nil))
    }

    func testTheFindingLevels() {
        let confirmed = DebugPortRisk.identify(port: 9229, processName: "node", executablePath: nil)!
        XCTAssertEqual(DebugPortRisk.finding(for: confirmed, isGlobal: true, isFirewallBlocking: false).riskLevel, .critical)
        XCTAssertEqual(DebugPortRisk.finding(for: confirmed, isGlobal: true, isFirewallBlocking: true).riskLevel, .warning)
        let guess = DebugPortRisk.identify(port: 9229, processName: "weird", executablePath: nil)!
        let f = DebugPortRisk.finding(for: guess, isGlobal: true, isFirewallBlocking: false)
        XCTAssertEqual(f.riskLevel, .info)
        XCTAssertTrue(f.title.contains("Node.js inspector"))
    }
}
