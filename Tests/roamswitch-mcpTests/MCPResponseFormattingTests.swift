// Mirrored from RoamSwitchTests/ — RoamSwitch 1.11.3 (build 150). Do not edit here; see SYNC.md.

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

        XCTAssertEqual(payload.guards.count, 28)
        XCTAssertEqual(Set(payload.guards.map(\.key)).count, 28, "guard keys must be unique")
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
    // MARK: - verify_security_findings

    private func verifyItem(_ id: String, passed: Bool = true, applicable: Bool = true, reason: String? = nil) -> SecurityAuditItem {
        SecurityAuditItem(category: "cat", title: "title-\(id)", isPassed: passed, statusText: "status-\(id)", detail: "detail-\(id)", recommendation: "rec", settingsURL: nil, isApplicable: applicable, checkId: id, inconclusiveReason: reason)
    }

    private func verifyReport(_ items: [SecurityAuditItem]) -> ComprehensiveSecurityReport {
        ComprehensiveSecurityReport(score: 50, grade: "C", totalChecks: items.count, passedChecks: 0, items: items, timestamp: Date())
    }

    private func verify(_ items: [SecurityAuditItem], ids: [String]? = nil, interface: Bool = false, ssid: Bool = true) -> MCPVerifySecurityFindingsPayload {
        MCPResponseFormatting.makeVerifyPayload(report: verifyReport(items), requestedCheckIds: ids, wifiInterfacePresent: interface, wifiSSIDResolved: ssid)
    }

    func testClassify_threeVerdictsAndNotApplicable() {
        let failing = SecurityCheckVerification.classify(verifyItem("a", passed: false))
        XCTAssertEqual(failing.verdict, .stillPresent)
        XCTAssertEqual(failing.reason, "failing")

        let passing = SecurityCheckVerification.classify(verifyItem("a", passed: true))
        XCTAssertEqual(passing.verdict, .resolved)
        XCTAssertEqual(passing.reason, "passing")

        let notApplicable = SecurityCheckVerification.classify(verifyItem("a", passed: true, applicable: false))
        XCTAssertEqual(notApplicable.verdict, .resolved)
        XCTAssertEqual(notApplicable.reason, "not_applicable")

        let inconclusive = SecurityCheckVerification.classify(verifyItem("a", passed: false, reason: "helper_unavailable"))
        XCTAssertEqual(inconclusive.verdict, .inconclusive)
        XCTAssertEqual(inconclusive.reason, "helper_unavailable")
    }

    func testClassify_unreliableReadingBeatsBothPassAndNotApplicable() {
        // sudo_hygiene 相当: ヘルパー値が無いと isApplicable == false になるが、「対象外」ではなく「確認できない」。
        let unverifiedSudo = SecurityCheckVerification.classify(verifyItem("sudo_hygiene", passed: true, applicable: false, reason: "helper_unavailable"))
        XCTAssertEqual(unverifiedSudo.verdict, .inconclusive)
        XCTAssertEqual(unverifiedSudo.reason, "helper_unavailable")
        // 合格に見えても、読み取りが信頼できなければ resolved にしない。
        XCTAssertEqual(SecurityCheckVerification.classify(verifyItem("wifi", passed: true, reason: "location_unavailable")).verdict, .inconclusive)
    }

    func testMakeVerifyPayload_omittedCheckIdsReturnsAll18() {
        let ids = (0..<18).map { "check_\($0)" }
        let payload = verify(ids.map { verifyItem($0) })
        XCTAssertEqual(payload.results.count, 18)
        XCTAssertEqual(payload.results.map(\.checkId), ids)
        XCTAssertEqual(verify(ids.map { verifyItem($0) }, ids: []).results.count, 18, "empty array means all")
    }

    func testMakeVerifyPayload_filtersInRequestedOrderAndDedupes() {
        let items = [verifyItem("a"), verifyItem("b", passed: false), verifyItem("c")]
        let payload = verify(items, ids: ["c", "b", "c"])
        XCTAssertEqual(payload.results.map(\.checkId), ["c", "b"])
        XCTAssertEqual(payload.results.map(\.verdict), [.resolved, .stillPresent])
        XCTAssertEqual(payload.results[1].title, "title-b")
        XCTAssertEqual(payload.results[1].statusText, "status-b")
        XCTAssertEqual(payload.results[1].detail, "detail-b")
    }

    func testMakeVerifyPayload_unknownIdIsInconclusiveWithoutFailingTheRest() {
        let payload = verify([verifyItem("a")], ids: ["a", "nope"])
        XCTAssertEqual(payload.results.count, 2)
        XCTAssertEqual(payload.results[0].verdict, .resolved)
        XCTAssertEqual(payload.results[1].checkId, "nope")
        XCTAssertEqual(payload.results[1].verdict, .inconclusive)
        XCTAssertEqual(payload.results[1].reason, "unknown_check_id")
    }

    func testMakeVerifyPayload_capsRequestedIdsAndTruncatesEchoedUnknownId() {
        let known = verifyItem("a")
        let many = (0..<(MCPResponseFormatting.maxVerifyCheckIds + 25)).map { "x\($0)" }
        let capped = verify([known], ids: many)
        XCTAssertEqual(capped.results.count, MCPResponseFormatting.maxVerifyCheckIds)
        XCTAssertEqual(capped.caveats.count, 1)

        let long = String(repeating: "z", count: 500)
        let echoed = verify([known], ids: [long]).results[0]
        XCTAssertEqual(echoed.checkId.count, MCPResponseFormatting.maxEchoedCheckIdLength)
    }

    func testMakeVerifyPayload_encodesLanguageIndependentJSONContract() throws {
        let payload = verify([verifyItem("a", passed: false)])
        let data = try JSONEncoder().encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["results", "caveats", "timestamp"])
        let first = try XCTUnwrap((json["results"] as? [[String: Any]])?.first)
        XCTAssertEqual(Set(first.keys), ["checkId", "title", "verdict", "reason", "statusText", "detail"])
        XCTAssertEqual(first["verdict"] as? String, "stillPresent")
        XCTAssertEqual(first["reason"] as? String, "failing")
    }

    func testMakeVerifyPayload_caveatsOnlyForEvaluatedItems() {
        XCTAssertTrue(verify([verifyItem("a")]).caveats.isEmpty)
        XCTAssertEqual(verify([verifyItem("host_firewall"), verifyItem("network_stealth_mode")]).caveats.count, 1)
        XCTAssertEqual(verify([verifyItem("exposed_ports")]).caveats.count, 1)
        // 絞り込みで評価していない項目の注意書きは付けない。
        XCTAssertTrue(verify([verifyItem("host_firewall"), verifyItem("a")], ids: ["a"]).caveats.isEmpty)
        // Wi-Fi: インターフェースあり + SSID未解決のときだけ、wifi項目を返す場合に注意書き。
        XCTAssertEqual(verify([verifyItem("wifi_encryption_strength")], interface: true, ssid: false).caveats.count, 1)
        XCTAssertTrue(verify([verifyItem("wifi_encryption_strength")], interface: false, ssid: false).caveats.isEmpty)
    }

    func testMakeVerifyPayload_configOnlyChecksCarryTheSettingCaveatOnlyWhenEvaluated() {
        let configOnly = ["gateway_arp_lock", "malware_scanning", "dns_threat_guard", "usb_zero_trust"]
        for id in configOnly {
            XCTAssertEqual(verify([verifyItem(id)]).caveats, [MCPResponseFormatting.configOnlyCaveat], id)
        }
        // 4項目をまとめて返しても注意書きは1つ。
        XCTAssertEqual(verify(configOnly.map { verifyItem($0) }).caveats.count, 1)
        // 絞り込みで返さない項目の注意書きは付けない。
        XCTAssertTrue(verify(configOnly.map { verifyItem($0) } + [verifyItem("a")], ids: ["a"]).caveats.isEmpty)
        // 判定は設定どおりで、inconclusive にはしない(host_firewall と同じ方針)。
        XCTAssertEqual(verify([verifyItem("dns_threat_guard", passed: false)]).results[0].verdict, .stillPresent)
        XCTAssertEqual(verify([verifyItem("usb_zero_trust")]).results[0].verdict, .resolved)
    }

    func testMakeVerifyPayload_unmeasuredExposedPortsExplainsTheFailure() {
        let unmeasured = verify([verifyItem("exposed_ports", passed: false, applicable: false, reason: "tool_failed")])
        XCTAssertEqual(unmeasured.results[0].verdict, .inconclusive)
        XCTAssertEqual(unmeasured.results[0].reason, "tool_failed")
        XCTAssertEqual(unmeasured.caveats, [MCPResponseFormatting.exposedPortsVisibilityCaveat, MCPResponseFormatting.exposedPortsUnmeasuredCaveat])
        XCTAssertEqual(verify([verifyItem("exposed_ports")]).caveats, [MCPResponseFormatting.exposedPortsVisibilityCaveat])
    }

    func testMakeSecurityReportPayload_caveatsForSettingOnlyAndPortItems() {
        func payload(_ items: [SecurityAuditItem]) -> MCPSecurityReportPayload {
            MCPResponseFormatting.makeSecurityReportPayload(report: verifyReport(items), wifiInterfacePresent: false, wifiSSIDResolved: true)
        }
        XCTAssertTrue(payload([verifyItem("a")]).caveats.isEmpty)
        XCTAssertEqual(payload([verifyItem("usb_zero_trust")]).caveats, [MCPResponseFormatting.configOnlyCaveat])
        XCTAssertEqual(payload([verifyItem("exposed_ports")]).caveats, [MCPResponseFormatting.exposedPortsVisibilityCaveat])

        // 測定できなかった exposed_ports は、合格として見えない(対象外)うえ、caveat で理由を伝える。
        let unmeasured = payload([verifyItem("exposed_ports", passed: false, applicable: false, reason: "tool_failed")])
        XCTAssertFalse(unmeasured.items[0].isApplicable)
        XCTAssertFalse(unmeasured.items[0].isPassed)
        XCTAssertTrue(unmeasured.caveats.contains(MCPResponseFormatting.exposedPortsUnmeasuredCaveat))
    }

    func testMakeSecurityReportPayload_exposesInconclusiveReasonOnlyWhenPresent() throws {
        let report = verifyReport([verifyItem("a", reason: "tool_failed"), verifyItem("b")])
        let payload = MCPResponseFormatting.makeSecurityReportPayload(report: report, wifiInterfacePresent: false, wifiSSIDResolved: true)
        XCTAssertEqual(payload.items[0].inconclusiveReason, "tool_failed")
        XCTAssertNil(payload.items[1].inconclusiveReason)

        // 既存のキーは変えず、`inconclusiveReason` は理由があるときだけ追加される(nil のときはキー自体を出さない)。
        let base: Set<String> = ["category", "title", "isPassed", "statusText", "detail", "recommendation", "isApplicable", "checkId", "nistCsf"]
        func keys(_ item: MCPSecurityAuditItemPayload) throws -> Set<String> {
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? [String: Any])
            return Set(json.keys)
        }
        XCTAssertEqual(try keys(payload.items[0]), base.union(["inconclusiveReason"]))
        XCTAssertEqual(try keys(payload.items[1]), base)
    }

    func testMakeSecurityReportPayload_reasonMatchesVerifyForEveryItem() {
        // 同じ根拠: report の項目の inconclusiveReason は、verify が inconclusive と判定するときの reason と常に一致する。
        let items = [
            verifyItem("a"), verifyItem("b", passed: false), verifyItem("c", applicable: false),
            verifyItem("d", reason: "helper_unavailable"), verifyItem("e", passed: false, applicable: false, reason: "not_verifiable"),
        ]
        let payload = MCPResponseFormatting.makeSecurityReportPayload(report: verifyReport(items), wifiInterfacePresent: false, wifiSSIDResolved: true)
        let verified = verify(items)
        for (reportItem, verdict) in zip(payload.items, verified.results) {
            XCTAssertEqual(reportItem.checkId, verdict.checkId)
            XCTAssertEqual(reportItem.inconclusiveReason, verdict.verdict == .inconclusive ? verdict.reason : nil, reportItem.checkId)
        }
    }

    func testMakeSecurityReportPayload_wifiAndARPThatLookHealthyCarryTheirReason() throws {
        // PersonalSOC が困っていた2項目。isApplicable/isPassed は「正常」に見えるが、確認済みではない。
        let report = SecurityHealthChecker.shared.generateComprehensiveReport(
            wifiInfo: WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected),
            arpStatus: ARPMonitorStatus(isSpoofingDetected: false, message: "", previousMAC: nil, currentMAC: nil, gatewayKnown: true, hadBaseline: false),
            listeningPorts: [],
            activeSecurityLevel: .balanced,
            wifiReadingUnreliable: true
        )
        let payload = MCPResponseFormatting.makeSecurityReportPayload(report: report, wifiInterfacePresent: true, wifiSSIDResolved: false)
        let wifi = try XCTUnwrap(payload.items.first { $0.checkId == "wifi_encryption_strength" })
        let arp = try XCTUnwrap(payload.items.first { $0.checkId == "arp_spoof_monitor" })
        XCTAssertTrue(wifi.isApplicable)
        XCTAssertTrue(wifi.isPassed)
        XCTAssertEqual(wifi.inconclusiveReason, "location_unavailable")
        XCTAssertTrue(arp.isApplicable)
        XCTAssertTrue(arp.isPassed)
        XCTAssertEqual(arp.inconclusiveReason, "no_baseline")

        // 読み取れているときは出さない。
        let measured = SecurityHealthChecker.shared.generateComprehensiveReport(
            wifiInfo: WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected),
            arpStatus: ARPMonitorStatus(isSpoofingDetected: false, message: "", previousMAC: nil, currentMAC: nil, gatewayKnown: true, hadBaseline: true),
            listeningPorts: [],
            activeSecurityLevel: .balanced
        )
        let clean = MCPResponseFormatting.makeSecurityReportPayload(report: measured, wifiInterfacePresent: false, wifiSSIDResolved: true)
        XCTAssertNil(clean.items.first { $0.checkId == "wifi_encryption_strength" }?.inconclusiveReason)
        XCTAssertNil(clean.items.first { $0.checkId == "arp_spoof_monitor" }?.inconclusiveReason)
    }

    func testVerifyToolIsListedReadOnlyWithOptionalCheckIds() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        let tool = try XCTUnwrap(tools.first { ($0["name"] as? String) == "verify_security_findings" })
        let description = try XCTUnwrap(tool["description"] as? String)
        XCTAssertTrue(description.contains("READ-ONLY"))
        XCTAssertTrue(description.contains("never fixes"))
        let schema = try XCTUnwrap(tool["inputSchema"] as? [String: Any])
        XCTAssertNil(schema["required"], "checkIds is optional")
        let props = try XCTUnwrap(schema["properties"] as? [String: Any])
        let checkIds = try XCTUnwrap(props["checkIds"] as? [String: Any])
        XCTAssertEqual(checkIds["type"] as? String, "array")
        XCTAssertEqual(checkIds["maxItems"] as? Int, MCPResponseFormatting.maxVerifyCheckIds)
        // 名前の重複が無いこと(カタログに1回だけ載る)。
        XCTAssertEqual(tools.filter { ($0["name"] as? String) == "verify_security_findings" }.count, 1)
    }

    // MARK: - verify_security_findings の引数・注意書き

    func testParseVerifyCheckIds_argumentValidation() {
        func parse(_ args: [String: Any]) -> (ids: [String]?, isValid: Bool) { MCPResponseFormatting.parseVerifyCheckIds(args) }
        // 省略・null は全項目。
        XCTAssertNil(parse([:]).ids)
        XCTAssertTrue(parse([:]).isValid)
        XCTAssertNil(parse(["checkIds": NSNull()]).ids)
        XCTAssertTrue(parse(["checkIds": NSNull()]).isValid)
        // 空配列は有効(makeVerifyPayload が全項目として扱う)。
        XCTAssertEqual(parse(["checkIds": [String]()]).ids, [])
        XCTAssertTrue(parse(["checkIds": [String]()]).isValid)
        // 配列でない・文字列以外を含むものは不正。
        for bad: Any in ["host_firewall", 1, true, ["a": 1], [1, 2], ["a", 1], [NSNull()], [["a"]]] {
            XCTAssertFalse(parse(["checkIds": bad]).isValid, "\(bad)")
        }
        XCTAssertEqual(parse(["checkIds": ["a", "b"]]).ids, ["a", "b"])
    }

    func testMakeVerifyPayload_emptyArrayMeansAllAndDuplicatesAreRemoved() {
        let items = [verifyItem("a"), verifyItem("b")]
        XCTAssertEqual(verify(items, ids: []).results.map(\.checkId), ["a", "b"])
        XCTAssertEqual(verify(items, ids: ["b", "a", "b", "a"]).results.map(\.checkId), ["b", "a"])
    }

    func testMakeVerifyPayload_exactly50IdsPassAndThe51stIsDropped() {
        let max = MCPResponseFormatting.maxVerifyCheckIds
        let ids = (0..<max).map { "id\($0)" }
        let atLimit = verify([verifyItem("a")], ids: ids)
        XCTAssertEqual(atLimit.results.count, max)
        XCTAssertTrue(atLimit.caveats.isEmpty, "50 distinct ids is within the limit")
        let over = verify([verifyItem("a")], ids: ids + ["one-more"])
        XCTAssertEqual(over.results.count, max)
        XCTAssertEqual(over.caveats.count, 1)
        // 重複を除いた後の件数で上限を判定する(重複で水増しした入力は弾かない)。
        let padded = verify([verifyItem("a")], ids: ids + ids)
        XCTAssertEqual(padded.results.count, max)
        XCTAssertTrue(padded.caveats.isEmpty)
    }

    func testMakeVerifyPayload_idsThatCollideAfterTruncationYieldOneRow() {
        let prefix = String(repeating: "x", count: MCPResponseFormatting.maxEchoedCheckIdLength)
        let a = prefix + "AAAA", b = prefix + "BBBB"
        let payload = verify([verifyItem("k")], ids: [a, b, "k"])
        XCTAssertEqual(payload.results.map(\.checkId), [prefix, "k"], "the echoed (truncated) id must not appear twice")
        XCTAssertEqual(payload.results[0].reason, "unknown_check_id")
    }

    func testMakeVerifyPayload_arpAndTrustedOpenCaveats() {
        let arp = verify([verifyItem("arp_spoof_monitor", reason: "no_baseline")])
        XCTAssertEqual(arp.results[0].verdict, .inconclusive)
        XCTAssertTrue(arp.caveats.contains(MCPResponseFormatting.arpTrustedBaselineCaveat))
        XCTAssertFalse(verify([verifyItem("arp_spoof_monitor")]).caveats.contains(MCPResponseFormatting.arpTrustedBaselineCaveat))

        let open = verify([verifyItem("host_firewall", passed: true, applicable: false), verifyItem("network_stealth_mode", passed: true, applicable: false)])
        XCTAssertTrue(open.results.allSatisfy { $0.verdict == .resolved && $0.reason == "not_applicable" })
        XCTAssertTrue(open.caveats.contains(MCPResponseFormatting.trustedOpenNotApplicableCaveat))
        XCTAssertFalse(verify([verifyItem("host_firewall")]).caveats.contains(MCPResponseFormatting.trustedOpenNotApplicableCaveat))

        let report = MCPResponseFormatting.makeSecurityReportPayload(
            report: verifyReport([verifyItem("host_firewall", passed: true, applicable: false), verifyItem("arp_spoof_monitor", reason: "no_baseline")]),
            wifiInterfacePresent: false, wifiSSIDResolved: true)
        XCTAssertTrue(report.caveats.contains(MCPResponseFormatting.trustedOpenNotApplicableCaveat))
        XCTAssertTrue(report.caveats.contains(MCPResponseFormatting.arpTrustedBaselineCaveat))
    }

    func testVerifyToolDescriptionStatesTheNetworkAndSettingBasedTruth() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        let verifyTool = try XCTUnwrap(tools.first { ($0["name"] as? String) == "verify_security_findings" })
        let text = try XCTUnwrap(verifyTool["description"] as? String)
        XCTAssertFalse(text.contains("no network requests"), "the gateway MAC lookup may ping the LAN gateway")
        XCTAssertTrue(text.contains("ICMP ping"))
        XCTAssertTrue(text.contains("not a re-measurement of the OS state"))
        for name in ["get_security_report", "get_exposed_ports", "get_guard_status"] {
            let d = try XCTUnwrap(tools.first { ($0["name"] as? String) == name }?["description"] as? String)
            XCTAssertTrue(d.contains("ICMP ping"), name)
        }
    }
}
