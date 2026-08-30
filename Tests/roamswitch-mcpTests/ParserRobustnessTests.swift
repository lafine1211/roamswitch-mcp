// Mirrored from RoamSwitchTests/ — RoamSwitch 1.5.0 (build 23). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Adversarial-input tests for the parsers that consume subprocess output
/// (`lsof`, `arp`). A local unprivileged process can influence some of this
/// text (odd process names, weird bind addresses). The parsers must not trap,
/// must stay bounded, and must err safe — a line they can't make sense of
/// should be dropped, never classified as a globally-exposed port.
final class ParserRobustnessTests: XCTestCase {

    // MARK: lsof

    private func ports(_ raw: String) -> [ListeningPortInfo] {
        ListeningPortMonitor.shared.parseLsofOutput(raw)
    }

    func testLsof_garbageAndTruncatedLines_noCrash() {
        for raw in [
            "",
            "COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n",
            "only one field\n",
            "a b c\n",
            "\u{0000}\u{0001}\u{FFFF}\n",
            String(repeating: "x ", count: 10_000) + "\n",
            "node 999999999999999999999999 u 0 TCP dev 0 0 *:8080\n",   // pid overflows Int
            "node abc u 0 TCP dev 0 0 *:8080\n",                        // non-numeric pid
            "node 1 u 0 TCP dev 0 0 :::::\n",                           // weird name field
            "node 1 u 0 TCP dev 0 0 *:notaport\n",
            "node 1 u 0 TCP dev 0 0 *:-5\n",
        ] {
            XCTAssertNoThrow(ports(raw))
        }
    }

    func testLsof_processNameWithSpaces_doesNotFabricateGlobalPort() {
        // A crafted comm with spaces shifts the columns, so `parts[1]` is no
        // longer the PID and the line is dropped. It must never turn into a
        // globally-exposed port for a name field that's actually localhost.
        let raw = """
        COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
        my evil app 1234 u 5 TCP dev 0 0 127.0.0.1:3000
        """
        XCTAssertFalse(ports(raw).contains { $0.isGloballyExposed })
    }

    func testLsof_realisticLine_parsesGlobalPort() {
        let raw = """
        COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
        node 4321 u 22 IPv4 0xabc 0t0 TCP *:8080 (LISTEN)
        redis 8899 u 6 IPv4 0xdef 0t0 TCP 127.0.0.1:6379 (LISTEN)
        """
        let result = ports(raw)
        XCTAssertTrue(result.contains { $0.port == 8080 && $0.isGloballyExposed })
        XCTAssertTrue(result.contains { $0.port == 6379 && !$0.isGloballyExposed })
    }

    // MARK: arp

    func testArp_adversarialOutput_neverCrashesAndOnlyMatchesRealMAC() {
        for raw in [
            "",
            "no mac here at all",
            "at zz:zz:zz:zz:zz:zz",
            "at 1:2:3:4:5",                         // too few octets
            String(repeating: "at ", count: 100_000),
            "\u{0000} at a1:b2:c3:d4:e5:f6 on en0",
            "? (192.168.1.1) at a1:b2:c3:d4:e5:f6 on en0 ifscope [ethernet]",
        ] {
            let mac = GatewayFingerprint.parseMACAddress(fromArpOutput: raw)
            if let mac {
                XCTAssertNotNil(mac.range(of: #"^([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}$"#, options: .regularExpression),
                                "parseMACAddress returned a non-MAC string: \(mac)")
            }
        }
    }
}
