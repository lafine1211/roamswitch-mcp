// Mirrored from RoamSwitchTests/ — RoamSwitch 1.12.9 (build 171). Do not edit here; see SYNC.md.

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

    func testEveryAuditCheckAndFeatureSourceExists() {
        let report = SecurityHealthChecker.shared.generateComprehensiveReport(
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
        for required in ["T1562.001", "T1562.004", "T1562.006", "T1070.002", "T1070.003", "T1553.001", "T1574.004", "T1574.006",
                         "T1036", "T1059.002", "T1055", "T1027.010", "T1543.001", "T1543.004", "T1547.015", "T1555.001", "T1548.003"] {
            XCTAssertTrue(ids.contains(required), required)
        }
    }

    func testTechniquesWithNoMatchingCodeStayNone() {
        // These were searched for and not found; promoting one needs code and a new test, not a text edit.
        for id in ["T1562.004", "T1562.006", "T1070.002", "T1070.003", "T1574.004", "T1036", "T1055", "T1547.015"] {
            let entry = DetectionCoverage.entries.first { $0.technique == id }
            XCTAssertEqual(entry?.coverage, DetectionCoverage.Coverage.none, id)
        }
    }

    private func entry(_ technique: String) -> DetectionCoverage.Entry { DetectionCoverage.entries.first { $0.technique == technique }! }

    func testLiveStateFollowsTheGuardToggles() {
        // T1553.001: one covering guard (execRecorder). T1543.001: execRecorder and persistenceMonitor.
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1553.001"), guardStates: ["execRecorder": "on"]), .on)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1553.001"), guardStates: ["execRecorder": "off"]), .off)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1543.001"), guardStates: ["execRecorder": "on", "persistenceMonitor": "off"]), .partial)
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1543.001"), guardStates: ["execRecorder": "on"]), .unknown, "a guard missing from the vocabulary is unknown")
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1562.001"), guardStates: [:]), .unknown, "a feature has no toggle to read")
        XCTAssertEqual(DetectionCoverage.liveState(of: entry("T1055"), guardStates: [:]), .notApplicable, "nothing covers it")
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
        XCTAssertEqual(try XCTUnwrap(off.techniques.first { $0.id == "T1562.001" }).liveState, "unknown")

        let allOn = DetectionCoverage.payload(guards: guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: true, usingDefault: false) })
        XCTAssertEqual(allOn.summary.coveredButOff, 0)
    }

    func testGuardsListHoldsEveryGuardReliedOnOnceInOrderOfUse() throws {
        let guards = guardVocabulary().map { MCPGuardEntryPayload(key: $0.key, enabledInSettings: $0.key == "execRecorder", usingDefault: false) }
        let payload = DetectionCoverage.payload(guards: guards)
        let relied = DetectionCoverage.entries.flatMap { $0.sources }.filter { $0.kind == "guard" }.map(\.id)
        XCTAssertEqual(Set(payload.guards.map(\.id)), Set(relied))
        XCTAssertEqual(payload.guards.count, Set(relied).count)
        XCTAssertEqual(payload.guards.first?.id, "execRecorder")
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
        XCTAssertEqual(try t("T1553.001").liveState, "on")
        XCTAssertEqual(try t("T1553.001").coveredBy, ["execRecorder", "exec.quarantine_stripped_then_exec", "gatekeeper_app_verification"])
        XCTAssertEqual(try t("T1543.001").liveState, "partial")
        XCTAssertEqual(try t("T1562.001").liveState, "unknown")
        XCTAssertEqual(try t("T1055").liveState, "not_applicable")
        XCTAssertEqual(try t("T1055").coverage, "none")
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
