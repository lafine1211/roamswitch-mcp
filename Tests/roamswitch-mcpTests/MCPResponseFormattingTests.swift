// Mirrored from RoamSwitchTests/ — RoamSwitch 1.5.6 (build 29). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Covers the pure/near-pure formatting functions behind the
/// `RoamSwitchMCPServer` CLI's tool responses. Uses a dedicated
/// `UserDefaults(suiteName:)` per test (cleared in tearDown) rather than
/// `.standard`, since these functions read real UserDefaults keys and must
/// not depend on — or pollute — this machine's actual RoamSwitch settings.
final class MCPResponseFormattingTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "MCPResponseFormattingTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - resolveActiveSecurityLevel

    func testResolveActiveSecurityLevel_noSettings_defaultsToLockdown() {
        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: nil, defaults: defaults)
        XCTAssertEqual(level, .lockdown)
    }

    func testResolveActiveSecurityLevel_awayLevelOverridesDefault() {
        defaults.set(SecurityLevel.open.rawValue, forKey: "RoamSwitch.awaySecurityLevel")
        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: nil, defaults: defaults)
        XCTAssertEqual(level, .open)
    }

    func testResolveActiveSecurityLevel_trustedNetworkOverridesAwayLevel() {
        defaults.set(SecurityLevel.lockdown.rawValue, forKey: "RoamSwitch.awaySecurityLevel")
        let network = TrustedNetwork(macAddress: "aa:bb:cc:dd:ee:ff", name: "自宅", securityLevel: .balanced)
        defaults.set(try! JSONEncoder().encode([network]), forKey: "RoamSwitch.trustedNetworks")

        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: "aa:bb:cc:dd:ee:ff", defaults: defaults)
        XCTAssertEqual(level, .balanced)
    }

    func testResolveActiveSecurityLevel_unmatchedGatewayFallsBackToAwayLevel() {
        defaults.set(SecurityLevel.open.rawValue, forKey: "RoamSwitch.awaySecurityLevel")
        let network = TrustedNetwork(macAddress: "aa:bb:cc:dd:ee:ff", name: "自宅", securityLevel: .balanced)
        defaults.set(try! JSONEncoder().encode([network]), forKey: "RoamSwitch.trustedNetworks")

        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: "11:22:33:44:55:66", defaults: defaults)
        XCTAssertEqual(level, .open)
    }

    func testResolveActiveSecurityLevel_manualOverrideBeatsEverything() {
        defaults.set(SecurityLevel.lockdown.rawValue, forKey: "RoamSwitch.manualOverrideLevel")
        defaults.set(SecurityLevel.open.rawValue, forKey: "RoamSwitch.awaySecurityLevel")
        let network = TrustedNetwork(macAddress: "aa:bb:cc:dd:ee:ff", name: "自宅", securityLevel: .balanced)
        defaults.set(try! JSONEncoder().encode([network]), forKey: "RoamSwitch.trustedNetworks")

        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: "aa:bb:cc:dd:ee:ff", defaults: defaults)
        XCTAssertEqual(level, .lockdown)
    }

    func testResolveActiveSecurityLevel_matchIsCaseInsensitive() {
        let network = TrustedNetwork(macAddress: "AA:BB:CC:DD:EE:FF", name: "自宅", securityLevel: .balanced)
        defaults.set(try! JSONEncoder().encode([network]), forKey: "RoamSwitch.trustedNetworks")

        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: "aa:bb:cc:dd:ee:ff", defaults: defaults)
        XCTAssertEqual(level, .balanced)
    }

    // MARK: - isCurrentNetworkTrusted

    func testIsCurrentNetworkTrusted_noNetworks_isFalse() {
        XCTAssertFalse(MCPResponseFormatting.isCurrentNetworkTrusted(gatewayMAC: "aa:bb:cc:dd:ee:ff", defaults: defaults))
    }

    func testIsCurrentNetworkTrusted_matchingNetwork_isTrue() {
        let network = TrustedNetwork(macAddress: "aa:bb:cc:dd:ee:ff", name: "自宅", securityLevel: .balanced)
        defaults.set(try! JSONEncoder().encode([network]), forKey: "RoamSwitch.trustedNetworks")

        XCTAssertTrue(MCPResponseFormatting.isCurrentNetworkTrusted(gatewayMAC: "aa:bb:cc:dd:ee:ff", defaults: defaults))
    }

    // MARK: - makeGuardStatusPayload

    func testMakeGuardStatusPayload_defaultsToAllDisabled() {
        defaults.set(false, forKey: MCPResponseFormatting.webMailDownloadGuardKey)
        defaults.set(false, forKey: MCPResponseFormatting.dnsThreatGuardKey)
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)

        XCTAssertEqual(payload.guards.count, 6)
        XCTAssertTrue(payload.guards.allSatisfy { !$0.enabledInSettings })
        XCTAssertFalse(payload.caveats.isEmpty)
    }

    func testMakeGuardStatusPayload_reflectsEnabledGuards() {
        defaults.set(false, forKey: MCPResponseFormatting.webMailDownloadGuardKey)
        defaults.set(false, forKey: MCPResponseFormatting.dnsThreatGuardKey)
        defaults.set(true, forKey: MCPResponseFormatting.portAnomalyGuardKey)
        defaults.set(true, forKey: MCPResponseFormatting.arpSpoofAutoContainmentKey)

        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)
        let enabledKeys = Set(payload.guards.filter(\.enabledInSettings).map(\.key))

        XCTAssertEqual(enabledKeys, ["portAnomalyGuard", "arpSpoofAutoContainment"])
    }

    // MARK: - makeLinkAuditPayload

    func testMakeLinkAuditPayload_passesFieldsThrough() {
        let factor = LinkRiskFactor(title: "IP直打ち", detail: "desc", isSevere: true)
        let report = LinkAuditReport(
            originalURLString: "http://1.2.3.4",
            finalURLString: "http://1.2.3.4/login",
            redirectChain: ["http://1.2.3.4", "http://1.2.3.4/login"],
            domain: "1.2.3.4",
            score: 30,
            riskLevel: .dangerous,
            riskFactors: [factor],
            isHTTPS: false
        )

        let payload = MCPResponseFormatting.makeLinkAuditPayload(report: report)
        XCTAssertEqual(payload.originalURL, "http://1.2.3.4")
        XCTAssertEqual(payload.finalURL, "http://1.2.3.4/login")
        XCTAssertEqual(payload.redirectChain.count, 2)
        XCTAssertEqual(payload.score, 30)
        XCTAssertEqual(payload.riskLevel, "dangerous")
        XCTAssertFalse(payload.isHTTPS)
        XCTAssertEqual(payload.riskFactors.count, 1)
        XCTAssertEqual(payload.riskFactors[0].title, "IP直打ち")
        XCTAssertTrue(payload.riskFactors[0].isSevere)
    }

    // MARK: - makeSecurityReportPayload

    private func makeSampleReport() -> ComprehensiveSecurityReport {
        ComprehensiveSecurityReport(
            score: 90,
            grade: "A",
            totalChecks: 10,
            passedChecks: 9,
            items: [
                SecurityAuditItem(category: "cat", title: "title", isPassed: true, statusText: "ok", detail: "detail", recommendation: "rec", settingsURL: nil)
            ],
            timestamp: Date()
        )
    }

    func testMakeSecurityReportPayload_passesFieldsThrough() {
        let payload = MCPResponseFormatting.makeSecurityReportPayload(
            report: makeSampleReport(),
            wifiInterfacePresent: true,
            wifiSSIDResolved: true
        )

        XCTAssertEqual(payload.score, 90)
        XCTAssertEqual(payload.items.count, 1)
        XCTAssertEqual(payload.items[0].title, "title")
        XCTAssertTrue(payload.caveats.isEmpty)
    }

    func testMakeSecurityReportPayload_interfacePresentButNoSSID_addsCaveat() {
        // Ambiguous case a bare CLI can't resolve without Location Services
        // authorization: could be genuinely disconnected, or just denied.
        let payload = MCPResponseFormatting.makeSecurityReportPayload(
            report: makeSampleReport(),
            wifiInterfacePresent: true,
            wifiSSIDResolved: false
        )

        XCTAssertEqual(payload.caveats.count, 1)
    }

    func testMakeSecurityReportPayload_noInterfaceAtAll_noCaveat() {
        // No Wi-Fi hardware (e.g. Ethernet-only Mac) — "not connected" is a
        // trustworthy reading, not an ambiguous permission gap.
        let payload = MCPResponseFormatting.makeSecurityReportPayload(
            report: makeSampleReport(),
            wifiInterfacePresent: false,
            wifiSSIDResolved: false
        )

        XCTAssertTrue(payload.caveats.isEmpty)
    }

    // MARK: - makePortPayload

    func testMakePortPayload_unaudited_hasNilRiskAndEmptyFindings() {
        let portInfo = ListeningPortInfo(processName: "node", pid: 123, port: 3000, isGloballyExposed: false, executablePath: nil)
        let payload = MCPResponseFormatting.makePortPayload(portInfo: portInfo, auditResult: nil)

        XCTAssertFalse(payload.auditPerformed)
        XCTAssertNil(payload.overallRisk)
        XCTAssertTrue(payload.findings.isEmpty)
    }

    func testMakePortPayload_audited_passesFindingsThrough() {
        let portInfo = ListeningPortInfo(processName: "redis-server", pid: 456, port: 6379, isGloballyExposed: true, executablePath: nil)
        let finding = PortAuditFinding(title: "Redis露出", riskLevel: .critical, description: "desc", recommendation: "rec")
        let result = PortSecurityAuditResult(portInfo: portInfo, overallRisk: .critical, isFirewallShielded: false, findings: [finding], httpHeaders: nil)

        let payload = MCPResponseFormatting.makePortPayload(portInfo: portInfo, auditResult: result)

        XCTAssertTrue(payload.auditPerformed)
        XCTAssertEqual(payload.overallRisk, "critical")
        XCTAssertEqual(payload.findings.count, 1)
        XCTAssertEqual(payload.findings[0].title, "Redis露出")
    }
}
