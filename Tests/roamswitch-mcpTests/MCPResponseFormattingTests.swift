// Mirrored from RoamSwitchTests/ — RoamSwitch 1.9.48 (build 105). Do not edit here; see SYNC.md.

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

    /// Every toggle whose getter defaults to ON when unset — forced OFF so a
    /// test can start from an all-disabled baseline.
    private func disableDefaultOnGuards() {
        for key in [
            MCPResponseFormatting.webMailDownloadGuardKey,
            MCPResponseFormatting.dnsThreatGuardKey,
            MCPResponseFormatting.persistenceMonitorKey,
            MCPResponseFormatting.secretLeakAuditorKey,
            MCPResponseFormatting.airGapAutoWiFiKillKey,
            MCPResponseFormatting.linkGuardUpdatesKey,
        ] {
            defaults.set(false, forKey: key)
        }
        defaults.set(LinkGuardMode.off.rawValue, forKey: MCPResponseFormatting.linkGuardModeKey)
    }

    func testMakeGuardStatusPayload_defaultsToAllDisabled() {
        disableDefaultOnGuards()
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)

        XCTAssertEqual(payload.guards.count, 22)
        XCTAssertEqual(Set(payload.guards.map(\.key)).count, 22, "guard keys must be unique")
        XCTAssertTrue(payload.guards.allSatisfy { !$0.enabledInSettings })
        XCTAssertFalse(payload.caveats.isEmpty)
    }

    func testMakeGuardStatusPayload_reflectsEnabledGuards() {
        disableDefaultOnGuards()
        defaults.set(true, forKey: MCPResponseFormatting.portAnomalyGuardKey)
        defaults.set(true, forKey: MCPResponseFormatting.arpSpoofAutoContainmentKey)
        defaults.set(true, forKey: MCPResponseFormatting.clickFixGuardKey)

        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)
        let enabledKeys = Set(payload.guards.filter(\.enabledInSettings).map(\.key))

        XCTAssertEqual(enabledKeys, ["portAnomalyGuard", "arpSpoofAutoContainment", "clickFixGuard"])
        XCTAssertTrue(payload.guards.allSatisfy { $0.usingDefault != nil })
        XCTAssertEqual(payload.guards.first { $0.key == "clickFixGuard" }?.usingDefault, false)
        XCTAssertEqual(payload.guards.first { $0.key == "bluetoothGuard" }?.usingDefault, true)
    }

    func testMakeGuardStatusPayload_unsetKeysFollowGetterDefaults() {
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)
        let enabledKeys = Set(payload.guards.filter(\.enabledInSettings).map(\.key))

        XCTAssertEqual(enabledKeys, [
            "webMailDownloadGuard", "dnsThreatGuard", "persistenceMonitor",
            "secretLeakClipboardAuditor", "airGapAutoWiFiKill", "linkGuard", "linkGuardFeedUpdates",
        ])
        XCTAssertTrue(payload.guards.allSatisfy { $0.usingDefault == true })
        XCTAssertEqual(payload.linkGuardMode, "block")
        XCTAssertEqual(payload.vpnBackend, "wireguard")
        XCTAssertEqual(payload.tailscaleExitNodeConfigured, false)
        XCTAssertEqual(payload.dnsThreatGuardProvider, "quad9")
        XCTAssertEqual(payload.dnsThreatGuardScope, "awayOnly")
        XCTAssertEqual(payload.isolatedDevPorts, [])
        XCTAssertEqual(payload.usbStorageAllowedVolumeCount, 0)
    }

    func testMakeGuardStatusPayload_readsNonBooleanSettings() {
        defaults.set("warn", forKey: MCPResponseFormatting.linkGuardModeKey)
        defaults.set("ts", forKey: MCPResponseFormatting.vpnBackendKey)
        defaults.set("exit-node.tailnet.ts.net", forKey: MCPResponseFormatting.tailscaleExitNodeKey)
        defaults.set("adguard", forKey: MCPResponseFormatting.dnsThreatGuardProviderKey)
        defaults.set("always", forKey: MCPResponseFormatting.dnsThreatGuardScopeKey)
        defaults.set([8080, 3000], forKey: MCPResponseFormatting.isolatedDevPortsKey)
        defaults.set(Data(#"[{"a":1},{"b":2}]"#.utf8), forKey: MCPResponseFormatting.usbAllowedVolumesKey)

        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)

        XCTAssertEqual(payload.linkGuardMode, "warn")
        XCTAssertEqual(payload.guards.first { $0.key == "linkGuard" }?.enabledInSettings, true)
        XCTAssertEqual(payload.vpnBackend, "tailscale")
        XCTAssertEqual(payload.tailscaleExitNodeConfigured, true)
        XCTAssertEqual(payload.dnsThreatGuardProvider, "adguard")
        XCTAssertEqual(payload.dnsThreatGuardScope, "always")
        XCTAssertEqual(payload.isolatedDevPorts, [3000, 8080])
        XCTAssertEqual(payload.usbStorageAllowedVolumeCount, 2)
    }

    func testMakeGuardStatusPayload_unknownDNSProviderFallsBackToQuad9() {
        defaults.set("not-a-provider", forKey: MCPResponseFormatting.dnsThreatGuardProviderKey)
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults)
        XCTAssertEqual(payload.dnsThreatGuardProvider, "quad9")
    }

    // MARK: - makeIncidentTimelinePayload

    func testMakeIncidentTimelinePayload_mapsStatusAndCountsUnresolved() {
        let open = ContainmentIncidentEvent(
            source: .arpSpoof,
            severity: "critical",
            summary: "gateway changed",
            attackTechnique: "T1557",
            actionTaken: "air_gap"
        )
        let released = ContainmentIncidentEvent(
            source: .portAnomaly,
            severity: "warning",
            summary: "port exposed",
            processName: "nc",
            processID: 4242,
            actionTaken: "port_block",
            resolvedAt: Date(),
            resolution: .allowlisted
        )
        let unknownAction = ContainmentIncidentEvent(
            source: .runtimeThreat,
            severity: "critical",
            summary: "xprotect",
            actionTaken: "something_new"
        )

        let payload = MCPResponseFormatting.makeIncidentTimelinePayload(events: [open, released, unknownAction])

        XCTAssertEqual(payload.events.count, 3)
        XCTAssertEqual(payload.unresolvedCount, 2)
        XCTAssertEqual(payload.events[0].source, "arpSpoof")
        XCTAssertEqual(payload.events[0].status, "open")
        XCTAssertNil(payload.events[0].resolvedAt)
        XCTAssertEqual(payload.events[0].attackTechnique, "T1557")
        XCTAssertFalse(payload.events[0].sourceLabel.isEmpty)
        XCTAssertEqual(payload.events[1].status, "allowlisted")
        XCTAssertNotNil(payload.events[1].resolvedAt)
        XCTAssertEqual(payload.events[1].processID, 4242)
        XCTAssertEqual(payload.events[2].actionTakenLabel, "something_new")
        XCTAssertFalse(payload.caveats.isEmpty)
    }

    // MARK: - get_network_history

    func testNetworkHistorySnapshot_hidesMACsAndFindsLookalikes() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("network_history_test_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        // `SSIDRecord` is encoded with JSONEncoder's default date strategy
        // (seconds since the 2001 reference date).
        let json = #"""
        {
          "CafeWiFi-5G": {"gatewayMACs": ["aa:aa:aa:aa:aa:aa"], "lastSeen": 1000},
          "CafeWlFi-5G": {"gatewayMACs": ["bb:bb:bb:bb:bb:bb"], "lastSeen": 3000},
          "HomeNetwork": {"gatewayMACs": ["cc:cc:cc:cc:cc:cc", "dd:dd:dd:dd:dd:dd"], "lastSeen": 2000},
          "HomeNetwork-Guest": {"gatewayMACs": ["CC:CC:CC:CC:CC:CC"], "lastSeen": 500}
        }
        """#
        try Data(json.utf8).write(to: url)

        let snapshot = NetworkHistoryGuard.readSnapshot(from: url)

        XCTAssertEqual(snapshot.entries.map(\.ssid), ["CafeWlFi-5G", "HomeNetwork", "CafeWiFi-5G", "HomeNetwork-Guest"])
        XCTAssertEqual(snapshot.entries.first { $0.ssid == "HomeNetwork" }?.gatewayCount, 2)
        XCTAssertEqual(snapshot.lookalikes.count, 1)
        XCTAssertEqual(Set([snapshot.lookalikes[0].ssid, snapshot.lookalikes[0].similarTo]), ["CafeWiFi-5G", "CafeWlFi-5G"])

        let payload = MCPResponseFormatting.makeNetworkHistoryPayload(
            entries: snapshot.entries,
            lookalikes: snapshot.lookalikes,
            limit: 2
        )
        XCTAssertEqual(payload.knownNetworkCount, 4)
        XCTAssertEqual(payload.networks.count, 2)
        XCTAssertEqual(payload.lookalikePairs.count, 1)

        let encoded = String(decoding: try JSONEncoder().encode(payload), as: UTF8.self)
        XCTAssertFalse(encoded.lowercased().contains("aa:aa"), "gateway MACs must never be emitted")
    }

    func testNetworkHistorySnapshot_missingFileIsEmpty() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist-\(UUID().uuidString).json")
        let snapshot = NetworkHistoryGuard.readSnapshot(from: url)
        XCTAssertTrue(snapshot.entries.isEmpty)
        XCTAssertTrue(snapshot.lookalikes.isEmpty)
    }

    // MARK: - makeLinkAuditPayload

    func testMakeLinkAuditPayload_passesFieldsThrough() {
        let factor = LinkRiskFactor(title: "IP直打ち", detail: "desc", isSevere: true, kind: .ipAddressHost)
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
        XCTAssertEqual(payload.riskFactors[0].kind, "ipAddressHost")
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
