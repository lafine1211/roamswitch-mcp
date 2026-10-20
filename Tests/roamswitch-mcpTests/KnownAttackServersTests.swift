// Mirrored from RoamSwitchTests/ — RoamSwitch 1.12.10 (build 172). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class KnownAttackServersTests: XCTestCase {
    private let anchorCall = "anchor \"com.apple/roamswitch\"\n"

    func testListIsExactlyTheThreePublishedAddresses() {
        XCTAssertEqual(KnownAttackServers.ips, ["210.149.87.120", "118.26.36.16", "69.10.51.162"])
        XCTAssertEqual(KnownAttackServers.validIPs(), KnownAttackServers.ips)
    }

    func testBadEntriesNeverBecomeRuleText() {
        let ips = ["203.0.113.5", "1.2.3.4; pass all", "not-an-ip", "300.1.1.1", "2001:db8::1", ""]
        XCTAssertEqual(KnownAttackServers.validIPs(ips), ["203.0.113.5", "2001:db8::1"])
        let rules = KnownAttackServers.egressBlockRules(ips)
        XCTAssertFalse(rules.contains("pass"))
        XCTAssertFalse(rules.contains("not-an-ip"))
        XCTAssertTrue(rules.contains("block drop quick inet from any to { 203.0.113.5 }"))
        XCTAssertTrue(rules.contains("block drop quick inet6 from { 2001:db8::1 } to any"))
    }

    func testBothDirectionsAreDropped() {
        let rules = KnownAttackServers.egressBlockRules()
        for ip in KnownAttackServers.ips { XCTAssertTrue(rules.contains(ip)) }
        XCTAssertTrue(rules.contains("block drop quick inet from any to {"))
        XCTAssertTrue(rules.contains("block drop quick inet from {"))
        XCTAssertEqual(KnownAttackServers.egressBlockRules([]), "")
    }

    func testRulesGoBeforeEveryPassHoleOfAKillSwitchRuleset() {
        let killSwitch = "# k\nset skip on lo0\n\(anchorCall)block drop all\npass quick on utun3 all\npass out quick proto tcp from any to any port 443\n"
        let out = KnownAttackServers.insertingEgressBlock(into: killSwitch, anchorCall: anchorCall)
        let block = out.range(of: "block drop quick inet from any to")!.lowerBound
        XCTAssertLessThanOrEqual(out.range(of: anchorCall)!.upperBound, block, "right after the anchor call")
        XCTAssertLessThan(block, out.range(of: "pass quick on utun3")!.lowerBound, "before the first pass hole")
        XCTAssertLessThan(block, out.range(of: "block drop all")!.lowerBound)
        XCTAssertTrue(out.hasSuffix("port 443\n"), "the rest of the ruleset is untouched")
    }

    func testNoAnchorLineFallsBackToAfterSkipThenTop() {
        let a = KnownAttackServers.insertingEgressBlock(into: "set skip on lo0\nblock drop all\n", anchorCall: anchorCall)
        XCTAssertTrue(a.hasPrefix("set skip on lo0\nblock drop quick"))
        let b = KnownAttackServers.insertingEgressBlock(into: "block drop all\n", anchorCall: anchorCall)
        XCTAssertTrue(b.hasPrefix("block drop quick"))
        XCTAssertEqual(KnownAttackServers.insertingEgressBlock(into: "x\n", anchorCall: anchorCall, ips: []), "x\n")
    }

    /// The real pf parser accepts the composed ruleset and expands every address into the rules
    /// that `pfctl -sr` prints (which is what the helper's read-back checks for). `-n` parses
    /// only, so this needs no root.
    func testPfctlParsesTheComposedRuleset() throws {
        let pfctl = "/sbin/pfctl"
        try XCTSkipUnless(FileManager.default.isExecutableFile(atPath: pfctl), "no pfctl")
        let ruleset = KnownAttackServers.insertingEgressBlock(
            into: "# t\nset skip on lo0\n\(anchorCall)block drop all\npass out quick proto udp from any port 68 to any port 67\n",
            anchorCall: anchorCall)
        let path = NSTemporaryDirectory() + "pf_known_attack_\(UUID().uuidString).conf"
        try ruleset.write(toFile: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: path) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: pfctl)
        p.arguments = ["-nvf", path]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        // `anchor "com.apple/roamswitch"` needs the anchor to exist at load time only for a real load.
        if text.contains("syntax error") || text.contains("Syntax error") { XCTFail("pf rejected the ruleset: \(text)") }
        for ip in KnownAttackServers.ips {
            XCTAssertTrue(text.contains("block drop quick inet from any to \(ip)"), "\(ip) missing: \(text)")
            XCTAssertTrue(text.contains("block drop quick inet from \(ip) to any"), "\(ip) missing: \(text)")
        }
    }
}
