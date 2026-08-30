// Mirrored from RoamSwitchTests/ — RoamSwitch 1.6.3 (build 36). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Covers `ARPSpoofMonitor.inspectGateway`, the detection rule that now
/// also drives `ARPSpoofContainmentManager`'s automatic network air-gap —
/// so a regression here would mean either missing a real MITM attack or
/// spuriously cutting the user's network. Uses a fresh `ARPSpoofMonitor()`
/// per test rather than `.shared` since the type holds mutable baseline
/// state across calls by design (that's exactly what's under test), and
/// tests must not leak state into each other.
final class ARPSpoofMonitorTests: XCTestCase {

    func testFirstObservation_establishesBaselineWithoutFlagging() {
        let monitor = ARPSpoofMonitor()
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")

        XCTAssertFalse(status.isSpoofingDetected)
        XCTAssertNil(status.previousMAC)
        XCTAssertNil(status.currentMAC)
    }

    func testSameGateway_repeatedIdenticalObservation_doesNotFlag() {
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testSameGateway_caseInsensitiveMACMatch_doesNotFlag() {
        // arp/ifconfig output casing isn't guaranteed consistent between
        // reads; a same-address comparison must not be case-sensitive.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "AA:BB:CC:DD:EE:FF")
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testSameIP_differentMAC_flagsSpoofingAndReportsBothMACs() {
        // The core signal: gateway IP unchanged, but the hardware answering
        // to it changed — the classic ARP cache poisoning fingerprint.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66")

        XCTAssertTrue(status.isSpoofingDetected)
        XCTAssertEqual(status.previousMAC, "aa:bb:cc:dd:ee:ff")
        XCTAssertEqual(status.currentMAC, "11:22:33:44:55:66")
    }

    func testDifferentIP_differentMAC_doesNotFlag() {
        // A genuine network change (new Wi-Fi, new router) changes both the
        // gateway IP and MAC together — that must not be treated as spoofing.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")
        let status = monitor.inspectGateway(currentIP: "10.0.0.1", currentMAC: "11:22:33:44:55:66")

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testMissingGatewayInfo_doesNotFlag() {
        let monitor = ARPSpoofMonitor()
        let status = monitor.inspectGateway(currentIP: nil, currentMAC: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testAfterSpoofDetected_baselineIsNotAdvanced() {
        // inspectGateway returns early on a spoof hit, deliberately without
        // updating the stored baseline — so the same still-spoofed gateway
        // keeps re-flagging on every subsequent poll rather than the
        // attacker's MAC silently becoming the new "trusted" one.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66") // first spoof hit
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66") // still spoofed

        XCTAssertTrue(status.isSpoofingDetected)
        XCTAssertEqual(status.previousMAC, "aa:bb:cc:dd:ee:ff")
    }

    func testReset_clearsBaselineSoNextObservationIsTreatedAsFirst() {
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff")
        monitor.reset()
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66")

        XCTAssertFalse(status.isSpoofingDetected)
    }
}
