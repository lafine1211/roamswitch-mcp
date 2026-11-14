// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.2 (build 218). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `get_detection_coverage`: the table must stay tied to things that exist.
final class DetectionCoverageTests: XCTestCase {

    private func guardVocabulary() -> [MCPGuardEntryPayload] {
        let suite = "com.tetsuharu.RoamSwitch.tests.detection-coverage"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        return MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults).guards
    }

    func testEveryGuardSourceExistsInTheGuardStatusVocabulary() {
        let known = Set(guardVocabulary().map(\.key))
        XCTAssertFalse(known.isEmpty)
        for entry in DetectionCoverage.entries {
            for source in entry.sources where source.kind == "guard" {
                XCTAssertTrue(known.contains(source.id), "\(entry.technique): guard \(source.id) is not in get_guard_status")
            }
        }
    }

    /// The other direction: a guard that `get_guard_status` lists must either back some technique or be on the exempt list
    /// with a reason, so a new guard cannot be added without deciding what it covers.
    func testEveryGuardInTheVocabularyIsCoveredOrExempt() {
        let vocabulary = Set(guardVocabulary().map(\.key))
        let covered = Set(DetectionCoverage.entries.flatMap { $0.sources.filter { $0.kind == "guard" }.map(\.id) })
        let exempt = Set(DetectionCoverage.exemptGuards.keys)
        let missing = vocabulary.subtracting(covered).subtracting(exempt)
        XCTAssertTrue(missing.isEmpty, "guards in get_guard_status that no technique relies on and that are not exempt: \(missing.sorted())")
        XCTAssertTrue(exempt.isSubset(of: vocabulary), "exempt guards that are not in get_guard_status: \(exempt.subtracting(vocabulary).sorted())")
        XCTAssertTrue(exempt.isDisjoint(with: covered), "listed as both covering a technique and exempt: \(exempt.intersection(covered).sorted())")
        for (key, reason) in DetectionCoverage.exemptGuards {
            XCTAssertFalse(reason.isEmpty, key)
            XCTAssertFalse(reason.contains("\n"), "\(key): one line")
        }
    }

    /// Every reader-health record has to belong to a guard (so `get_guard_status` shows it), and every guard that reads
    /// something is covered or exempt.
    func testEveryReaderHealthSourceBelongsToAGuardThatIsCoveredOrExempt() throws {
        let linked = Set(GuardReaderHealthStore.guardSources.values.flatMap { $0.sources + $0.auxiliary })
        let covered = Set(DetectionCoverage.entries.flatMap { $0.sources.filter { $0.kind == "guard" }.map(\.id) })
        let exempt = Set(DetectionCoverage.exemptGuards.keys)
        for guardKey in GuardReaderHealthStore.guardSources.keys {
            XCTAssertTrue(covered.contains(guardKey) || exempt.contains(guardKey), "\(guardKey) reads input but is neither covered nor exempt")
        }
        // Sources named in the code: forApp(source: "x") and friends. The app's sources are not in the mirror.
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        try XCTSkipUnless(FileManager.default.fileExists(atPath: root.appendingPathComponent("RoamSwitch").path), "app sources not present")
        let regex = try NSRegularExpression(pattern: #"(?:forApp\(source:|GuardReaderHealthRecorder\(source:|writeApp\(source:|writeHelper\(source:)\s*"([A-Za-z]+)""#)
        var used: Set<String> = []
        for dir in ["RoamSwitch", "RoamSwitchHelper", "Shared"] {
            let files = (try? FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent(dir).path)) ?? []
            for name in files where name.hasSuffix(".swift") {
                let text = (try? String(contentsOf: root.appendingPathComponent(dir).appendingPathComponent(name), encoding: .utf8)) ?? ""
                let range = NSRange(text.startIndex..., in: text)
                for m in regex.matches(in: text, range: range) {
                    if let r = Range(m.range(at: 1), in: text) { used.insert(String(text[r])) }
                }
            }
        }
        XCTAssertFalse(used.isEmpty, "the scan found no reader-health sources: the pattern is stale")
        XCTAssertTrue(used.subtracting(linked).isEmpty, "reader-health sources no guard shows: \(used.subtracting(linked).sorted())")
    }

    func testEveryAuditCheckAndFeatureSourceExists() {
        let report = SecurityHealthChecker(overlaySource: StubOverlayExposureSource()).generateComprehensiveReport(
            wifiInfo: WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected),
            arpStatus: ARPMonitorStatus(isSpoofingDetected: false, message: "", previousMAC: nil, currentMAC: nil, gatewayKnown: true, hadBaseline: true),
            listeningPorts: [],
            activeSecurityLevel: .balanced
        )
        let checks = Set(report.items.map(\.checkId))
        for entry in DetectionCoverage.entries {
            for source in entry.sources {
                switch source.kind {
                case "audit_check": XCTAssertTrue(checks.contains(source.id), "\(entry.technique): audit check \(source.id)")
                case "feature": XCTAssertTrue(DetectionCoverage.knownFeatures.contains(source.id), "\(entry.technique): feature \(source.id)")
                case "guard", "exec_rule": break
                default: XCTFail("\(entry.technique): unknown source kind \(source.kind)")
                }
            }
        }
    }

    func testCoverageIsHonestByConstruction() {
        for entry in DetectionCoverage.entries {
            switch entry.coverage {
            case .none:
                XCTAssertTrue(entry.sources.isEmpty, "\(entry.technique): a technique with no coverage lists no sources")
            case .detects, .partial:
                XCTAssertFalse(entry.sources.isEmpty, "\(entry.technique): detects/partial needs something that provides it")
            }
            XCTAssertFalse(entry.blindSpot.isEmpty, "\(entry.technique) states its limit")
            XCTAssertNotNil(entry.technique.range(of: #"^T\d{4}(\.\d{3})?$"#, options: .regularExpression), entry.technique)
            XCTAssertFalse(entry.name.isEmpty)
        }
        let ids = DetectionCoverage.entries.map(\.technique)
        XCTAssertEqual(ids.count, Set(ids).count, "no technique is listed twice")
        // The names the task asked to be covered are all present, none rounded up to more than the code supports.
        for required in ["T1685", "T1686", "T1685.006", "T1070.003", "T1553.001", "T1574.004", "T1574.006",
                         "T1036", "T1059.002", "T1055", "T1027.010", "T1543.001", "T1543.004", "T1547.015", "T1555.001", "T1548.003",
                         // the guards that had no technique until the vocabulary check was added
                         "T1110.001", "T1046", "T1486", "T1557.002", "T1200", "T1091", "T1204.002", "T1204.004", "T1195.001",
                         "T1505.003", "T1566.002", "T1610"] {
            XCTAssertTrue(ids.contains(required), required)
        }
    }

    func testTechniquesWithNoMatchingCodeStayNone() {
        // These were searched for and not found; promoting one needs code and a new test, not a text edit.
        for id in ["T1686", "T1574.004"] {
            let entry = DetectionCoverage.entries.first { $0.technique == id }
            XCTAssertEqual(entry?.coverage, DetectionCoverage.Coverage.none, id)
        }
    }

    func testTechniquesTheEndpointSecurityWatchesNowCoverArePartialAndSayWhatTheyNeed() {
        // Promoted with code (`LogTamperWatchGuard`, `CredentialFileWatchGuard`) and their tests (`ESGuardCredentialAndLogTests`).
        for id in ["T1685.006", "T1070.003"] {
            let e = DetectionCoverage.entries.first { $0.technique == id }
            XCTAssertEqual(e?.coverage, .partial, id)
            XCTAssertEqual(e?.sources.map(\.id), ["logTamperWatchGuard"], id)
            XCTAssertTrue(e?.blindSpot.contains("Endpoint Security") ?? false, "\(id): the limit says it needs the extension")
        }
        let creds = DetectionCoverage.entries.first { $0.technique == "T1552.001" }
        XCTAssertTrue(creds?.sources.contains { $0.kind == "guard" && $0.id == "credentialFileWatchGuard" } ?? false)
        XCTAssertFalse(creds?.blindSpot.contains("Reading a real credential file is not detected") ?? true, "the old \"cannot\" sentence is gone")
        XCTAssertTrue(creds?.blindSpot.contains("~/.kube/config") ?? false, "what is left out is said")
    }

    /// Promoted with code and tests: the exec rule `exec.name_masquerade` (`ExecNameMasqueradeTests`).
    func testMasqueradingIsPartialThroughTheNameMasqueradeRule() {
        let entry = DetectionCoverage.entries.first { $0.technique == "T1036" }
        XCTAssertEqual(entry?.coverage, DetectionCoverage.Coverage.partial)
        XCTAssertEqual(entry?.sources.map(\.id), ["execRecorder", "exec.name_masquerade"])
    }

    /// Promoted with code and tests: ES's task-port, thread and trace events (`ESInjectionRules`, `ESInjectionRulesTests`).
    func testProcessInjectionIsPartialThroughTheTaskPortEvents() {
        let entry = DetectionCoverage.entries.first { $0.technique == "T1055" }
        XCTAssertEqual(entry?.coverage, DetectionCoverage.Coverage.partial)
        XCTAssertEqual(entry?.sources.map(\.id), ["esInjectionWatch"])
        XCTAssertTrue(entry?.blindSpot.contains("allow-list") == true, "it says how false alarms are kept down")
    }

    /// Promoted with code and tests: ES's NOTIFY_BTM_LAUNCH_ITEM_ADD (`PersistenceMonitorGuard.handleBTM`, `ESSystemEventsTests`).
    func testLoginItemsArePartialThroughTheRegistrationEvent() {
        let entry = DetectionCoverage.entries.first { $0.technique == "T1547.015" }
        XCTAssertEqual(entry?.coverage, DetectionCoverage.Coverage.partial)
        XCTAssertEqual(entry?.sources.map(\.id), ["persistenceMonitor"])
        XCTAssertTrue(entry?.blindSpot.contains("Endpoint Security") == true, "it says what the detection needs")
    }

    private func entry(_ technique: String) -> DetectionCoverage.Entry { DetectionCoverage.entries.first { $0.technique == technique }! }

    func testLiveStateFollowsTheGuardToggles() {
        // T1574.006: one covering guard (execRecorder). T1543.001: execRecorder and persistenceMonitor.
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1574.006"), guardStates: ["execRecorder": "on"]), .on)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1574.006"), guardStates: ["execRecorder": "off"]), .off)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1543.001"), guardStates: ["execRecorder": "on", "persistenceMonitor": "off"]), .partial)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1543.001"), guardStates: ["execRecorder": "on"]), .unknown, "a guard missing from the vocabulary is unknown")
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1685"), guardStates: [:]), .unknown, "a feature has no toggle to read")
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1574.004"), guardStates: [:]), .notApplicable, "nothing covers it")
    }

    func testPayloadShapeMatchesTheLinuxEdition() throws {
        let guards = guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: $0.key == "execRecorder", usingDefault: false) }
        let payload = DetectionCoverage.payload(guards: guards)
        let data = try JSONEncoder().encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["platform", "summary", "techniques", "guards", "caveats"])
        XCTAssertEqual(json["platform"] as? String, "macos")
        XCTAssertEqual(Set((json["summary"] as? [String: Any] ?? [:]).keys), ["total", "detects", "partial", "none", "coveredButOff"])
        let first = try XCTUnwrap((json["techniques"] as? [[String: Any]])?.first)
        XCTAssertEqual(Set(first.keys), ["id", "name", "platform", "coverage", "coveredBy", "blindSpot", "liveState"])
        XCTAssertEqual(first["platform"] as? String, "macos")
        XCTAssertEqual(first["coveredBy"] as? [String], ["watchdog"], "plain id strings, not objects")
        let guardRows = try XCTUnwrap(json["guards"] as? [[String: Any]])
        XCTAssertTrue(guardRows.allSatisfy { Set($0.keys) == ["id", "state"] })
        XCTAssertEqual(payload.caveats.count, 3)
    }

    func testSummaryCountsAndCoveredButOff() throws {
        let allOff = guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: false, usingDefault: false) }
        let off = DetectionCoverage.payload(guards: allOff)
        XCTAssertEqual(off.summary.total, DetectionCoverage.entries.count)
        XCTAssertEqual(off.summary.detects + off.summary.partial + off.summary.none, off.summary.total)
        let expectedOff = off.techniques.filter { $0.coverage != "none" && $0.liveState == "off" }.count
        XCTAssertGreaterThan(expectedOff, 0)
        XCTAssertEqual(off.summary.coveredButOff, expectedOff)
        // A technique covered only by a feature is unknown, not off, so it never counts as covered-but-off.
        XCTAssertEqual(try XCTUnwrap(off.techniques.first { $0.id == "T1685" }).liveState, "unknown")

        let allOn = DetectionCoverage.payload(guards: guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: true, usingDefault: false) })
        XCTAssertEqual(allOn.summary.coveredButOff, 0)
    }

    func testGuardsListHoldsEveryGuardReliedOnOnceInOrderOfUse() throws {
        // The first guard is the first one an entry of the list relies on (the history and log watch, since it was added to the first entries).
        let relied = DetectionCoverage.entries.flatMap { $0.sources }.filter { $0.kind == "guard" }.map(\.id)
        let firstUsed = try XCTUnwrap(relied.first)
        let guards = guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: $0.key == firstUsed, usingDefault: false) }
        let payload = DetectionCoverage.payload(guards: guards)
        XCTAssertEqual(Set(payload.guards.map(\.id)), Set(relied))
        XCTAssertEqual(payload.guards.count, Set(relied).count)
        XCTAssertEqual(payload.guards.first?.id, firstUsed)
        XCTAssertEqual(payload.guards.first?.state, "on")
        XCTAssertEqual(payload.guards.first { $0.id == "persistenceMonitor" }?.state, "off")
        // Unknown guard id -> unknown.
        let none = DetectionCoverage.payload(guards: [])
        XCTAssertTrue(none.guards.allSatisfy { $0.state == "unknown" })
    }

    func testPayloadPerTechniqueState() throws {
        let guards = guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: $0.key == "execRecorder", usingDefault: false) }
        let payload = DetectionCoverage.payload(guards: guards)
        func t(_ id: String) throws -> DetectionCoverage.TechniquePayload { try XCTUnwrap(payload.techniques.first { $0.id == id }) }
        XCTAssertEqual(try t("T1574.006").liveState, "on")
        XCTAssertEqual(try t("T1574.006").coveredBy, ["execRecorder", "exec.dyld_insert_libraries"])
        XCTAssertEqual(try t("T1543.001").liveState, "partial")
        XCTAssertEqual(try t("T1685").liveState, "unknown")
        XCTAssertEqual(try t("T1574.004").liveState, "not_applicable")
        XCTAssertEqual(try t("T1574.004").coverage, "none")
    }

    func testToolIsListedAndCallable() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        let tool = try XCTUnwrap(tools.first { $0["name"] as? String == "get_detection_coverage" })
        XCTAssertTrue((tool["description"] as? String ?? "").contains("what can RoamSwitch NOT see"))
        let responses = MCPServer.handleMessage(["jsonrpc": "2.0", "id": 7, "method": "tools/call",
                                                 "params": ["name": "get_detection_coverage", "arguments": [String: Any]()]])
        let result = try XCTUnwrap(responses.first?["result"] as? [String: Any])
        XCTAssertEqual(result["isError"] as? Bool, false)
        let text = try XCTUnwrap(((result["content"] as? [[String: Any]])?.first?["text"]) as? String)
        let decoded = try JSONDecoder().decode(DetectionCoverage.Payload.self, from: Data(text.utf8))
        XCTAssertEqual(decoded.techniques.count, DetectionCoverage.entries.count)
        XCTAssertEqual(decoded.platform, "macos")
        // Nothing in this result is outside data, so there is no untrusted-data notice.
        XCTAssertEqual((result["content"] as? [[String: Any]])?.count, 1)
    }
}

/// The same table as an ATT&CK Navigator layer (layer format 4.5).
final class DetectionCoverageNavigatorLayerTests: XCTestCase {

    private func payload() -> DetectionCoverage.Payload { DetectionCoverage.payload(guards: []) }

    private func layer() throws -> [String: Any] {
        let json = DetectionCoverage.navigatorLayerJSON(payload())
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
    }

    func testTheLayerCarriesTheKeysTheNavigatorRequires() throws {
        let l = try layer()
        for key in ["name", "versions", "domain", "techniques"] {
            XCTAssertNotNil(l[key], key)
        }
        XCTAssertEqual(l["domain"] as? String, "enterprise-attack")
        let versions = try XCTUnwrap(l["versions"] as? [String: String])
        XCTAssertEqual(versions["layer"], "4.5")
        XCTAssertEqual(versions["attack"], DetectionCoverage.navigatorAttackVersion)
        XCTAssertFalse((versions["navigator"] ?? "").isEmpty)
        XCTAssertFalse((l["name"] as? String ?? "").isEmpty)
    }

    func testEveryAssessedTechniqueIsListedOnceAndNothingElse() throws {
        let techniques = try XCTUnwrap(try layer()["techniques"] as? [[String: Any]])
        let ids = techniques.compactMap { $0["techniqueID"] as? String }
        XCTAssertEqual(ids, DetectionCoverage.entries.map(\.technique))
        XCTAssertEqual(Set(ids).count, ids.count)
        for id in ids {
            XCTAssertNotNil(id.range(of: #"^T\d{4}(\.\d{3})?$"#, options: .regularExpression), id)
        }
    }

    /// ATT&CK v19 revoked four of the ids this table used to carry (checked against MITRE's STIX data for v20, the
    /// version the layer names). They must not come back, and the layer must show every technique it lists: the
    /// Navigator hides a technique whose platforms are not in the filter (T1091 and T1557.001 are Windows only,
    /// T1610 is Containers only in v20).
    func testNoRevokedIdAndTheVersionAndPlatformsOfTheLayer() throws {
        let l = try layer()
        XCTAssertEqual((l["versions"] as? [String: String])?["attack"], "20")
        let ids = DetectionCoverage.entries.map(\.technique)
        for old in ["T1562.001", "T1562.004", "T1562.006", "T1562.012", "T1070.002"] {
            XCTAssertFalse(ids.contains(old), "\(old) was revoked in ATT&CK v19")
        }
        XCTAssertTrue(ids.contains("T1685") && ids.contains("T1686") && ids.contains("T1685.006"))
        let platforms = try XCTUnwrap((l["filters"] as? [String: Any])?["platforms"] as? [String])
        for needed in ["macOS", "Windows", "Containers"] {
            XCTAssertTrue(platforms.contains(needed), "\(needed): a technique tagged only with it would be hidden by the filter")
        }
    }

    func testColoursFollowTheCoverage() throws {
        let techniques = try XCTUnwrap(try layer()["techniques"] as? [[String: Any]])
        func color(_ id: String) -> String? { techniques.first { $0["techniqueID"] as? String == id }?["color"] as? String }
        // T1543.001 detects, T1685 partial, T1574.004 none.
        XCTAssertEqual(color("T1543.001"), "#3fb950")
        XCTAssertEqual(color("T1685"), "#e3b341")
        XCTAssertEqual(color("T1574.004"), "#f85149")
        for t in techniques {
            let coverage = DetectionCoverage.entries.first { $0.technique == t["techniqueID"] as? String }?.coverage
            let expected: Int = coverage == .detects ? 2 : (coverage == .partial ? 1 : 0)
            XCTAssertEqual(t["score"] as? Int, expected, t["techniqueID"] as? String ?? "")
        }
    }

    func testEveryCommentCarriesTheBlindSpot() throws {
        let techniques = try XCTUnwrap(try layer()["techniques"] as? [[String: Any]])
        for entry in DetectionCoverage.entries {
            let t = try XCTUnwrap(techniques.first { $0["techniqueID"] as? String == entry.technique })
            XCTAssertTrue((t["comment"] as? String ?? "").contains(entry.blindSpot), entry.technique)
        }
    }

    func testTheDescriptionSaysItIsASelfAssessment() throws {
        let description = try XCTUnwrap(try layer()["description"] as? String)
        XCTAssertTrue(description.contains("not a third-party test"))
        XCTAssertTrue(description.contains("not assessed"))
    }

    func testTheOutputIsStable() {
        XCTAssertEqual(DetectionCoverage.navigatorLayerJSON(payload()), DetectionCoverage.navigatorLayerJSON(payload()))
    }

    func testTheToolReturnsTheLayerOnlyWhenAsked() throws {
        func call(_ arguments: [String: Any]) throws -> String {
            let responses = MCPServer.handleMessage(["jsonrpc": "2.0", "id": 9, "method": "tools/call",
                                                     "params": ["name": "get_detection_coverage", "arguments": arguments]])
            let result = try XCTUnwrap(responses.first?["result"] as? [String: Any])
            XCTAssertEqual(result["isError"] as? Bool, false)
            return try XCTUnwrap(((result["content"] as? [[String: Any]])?.first?["text"]) as? String)
        }
        let layerText = try call(["format": "navigator"])
        let layer = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(layerText.utf8)) as? [String: Any])
        XCTAssertEqual(layer["domain"] as? String, "enterprise-attack")
        // Default and unknown values keep the existing payload.
        for arguments: [String: Any] in [[:], ["format": "json"], ["format": "xml"]] {
            let decoded = try JSONDecoder().decode(DetectionCoverage.Payload.self, from: Data(try call(arguments).utf8))
            XCTAssertEqual(decoded.platform, "macos")
        }
        let tools = MCPServer.toolDefinitionsForTesting()
        let tool = try XCTUnwrap(tools.first { $0["name"] as? String == "get_detection_coverage" })
        let schema = try XCTUnwrap(tool["inputSchema"] as? [String: Any])
        let format = try XCTUnwrap((schema["properties"] as? [String: Any])?["format"] as? [String: Any])
        XCTAssertEqual(format["enum"] as? [String], ["json", "navigator"])
    }
}
