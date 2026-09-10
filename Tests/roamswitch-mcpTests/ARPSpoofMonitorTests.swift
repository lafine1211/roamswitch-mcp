// Mirrored from RoamSwitchTests/ — RoamSwitch 1.9.21 (build 78). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Covers `ARPSpoofMonitor.inspectGateway`, the detection rule that now
/// also drives `ARPSpoofContainmentManager`'s automatic network air-gap —
/// so a regression here would mean either missing a real MITM attack or
/// spuriously cutting the user's network. Uses a fresh `ARPSpoofMonitor()`
/// per test rather than `.shared` since the type holds mutable baseline
/// state across calls by design (that's exactly what's under test), and
/// tests must not leak state into each other.
///
/// Most cases pass `currentSSID: nil` throughout (a wired-link stand-in),
/// which never corroborates a roam — see `testSSID...` below for the
/// corroboration behavior itself.
final class ARPSpoofMonitorTests: XCTestCase {

    func testFirstObservation_establishesBaselineWithoutFlagging() {
        let monitor = ARPSpoofMonitor()
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
        XCTAssertNil(status.previousMAC)
        XCTAssertNil(status.currentMAC)
    }

    func testSameGateway_repeatedIdenticalObservation_doesNotFlag() {
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testSameGateway_caseInsensitiveMACMatch_doesNotFlag() {
        // arp/ifconfig output casing isn't guaranteed consistent between
        // reads; a same-address comparison must not be case-sensitive.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "AA:BB:CC:DD:EE:FF", currentSSID: nil)
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testSameIP_differentMAC_flagsSpoofingAndReportsBothMACs() {
        // The core signal: gateway IP unchanged, but the hardware answering
        // to it changed — the classic ARP cache poisoning fingerprint.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil)

        XCTAssertTrue(status.isSpoofingDetected)
        XCTAssertEqual(status.previousMAC, "aa:bb:cc:dd:ee:ff")
        XCTAssertEqual(status.currentMAC, "11:22:33:44:55:66")
    }

    func testDifferentIP_differentMAC_doesNotFlag() {
        // A genuine network change (new Wi-Fi, new router) changes both the
        // gateway IP and MAC together — that must not be treated as spoofing.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        let status = monitor.inspectGateway(currentIP: "10.0.0.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testMissingGatewayInfo_doesNotFlag() {
        let monitor = ARPSpoofMonitor()
        let status = monitor.inspectGateway(currentIP: nil, currentMAC: nil, currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testAfterSpoofDetected_baselineIsNotAdvanced() {
        // inspectGateway returns early on a spoof hit, deliberately without
        // updating the stored baseline — so the same still-spoofed gateway
        // keeps re-flagging on every subsequent poll rather than the
        // attacker's MAC silently becoming the new "trusted" one.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil) // first spoof hit
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil) // still spoofed

        XCTAssertTrue(status.isSpoofingDetected)
        XCTAssertEqual(status.previousMAC, "aa:bb:cc:dd:ee:ff")
    }

    func testReset_clearsBaselineSoNextObservationIsTreatedAsFirst() {
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        monitor.reset()
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil)

        XCTAssertFalse(status.isSpoofingDetected)
    }

    // MARK: - SSID corroboration (mirrors the Linux daemon's `confirmed_roam`)

    func testSameIP_differentMAC_butSSIDAlsoChanged_isTreatedAsGenuineRoamNotSpoofing() {
        // Many routers reuse the same default private gateway IP
        // (192.168.1.1, 192.168.0.1, ...). Walking from one Wi-Fi network
        // into an unrelated one that happens to reuse that IP must not be
        // flagged just because the MAC differs too — the SSID change is
        // independent proof this is a real move.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: "CafeWiFi")
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: "AirportWiFi")

        XCTAssertFalse(status.isSpoofingDetected)
    }

    func testSameIP_differentMAC_sameSSID_stillFlagsSpoofing() {
        // The SSID didn't change — the far likelier explanation is someone
        // on the *same* network answering ARP for the gateway with a new MAC.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: "CafeWiFi")
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: "CafeWiFi")

        XCTAssertTrue(status.isSpoofingDetected)
    }

    func testSameIP_differentMAC_nilSSID_stillFlagsSpoofing() {
        // A `nil` SSID (wired, or the Wi-Fi read failed) does NOT corroborate
        // a roam on Mac — unlike the Linux daemon, there is no independent
        // full-ARP-cache backstop layer here, so this stays conservative.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: nil)
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: nil)

        XCTAssertTrue(status.isSpoofingDetected)
    }

    func testCorroboratedRoam_advancesSSIDBaselineToo() {
        // After a corroborated roam, the accepted gateway becomes the new
        // baseline — a *subsequent* MAC flip on that same (new) SSID must
        // flag again rather than being silently trusted forever.
        let monitor = ARPSpoofMonitor()
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "aa:bb:cc:dd:ee:ff", currentSSID: "CafeWiFi")
        _ = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "11:22:33:44:55:66", currentSSID: "AirportWiFi") // corroborated roam
        let status = monitor.inspectGateway(currentIP: "192.168.1.1", currentMAC: "77:88:99:aa:bb:cc", currentSSID: "AirportWiFi")

        XCTAssertTrue(status.isSpoofingDetected)
        XCTAssertEqual(status.previousMAC, "11:22:33:44:55:66")
    }
}
