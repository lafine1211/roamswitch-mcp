// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.2 (build 181). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Declared side effects and evidence kinds of the active probes, and how they reach the scan results.
final class ProbeCatalogTests: XCTestCase {

    func testWebChecksDeclareWhatTheirCodeSends() {
        let cors = ProbeCatalog.declaration(forProbeName: "webvuln-cors")
        XCTAssertEqual(cors?.sideEffects, [.iocInLogs])
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: "webvuln-traversal")?.sideEffects, [.iocInLogs])
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: "webvuln-redirect")?.sideEffects, [.iocInLogs, .manyRequests])
        // The SSRF check opens two loopback listeners (ActiveVulnScan.HopListener) and sends up to 12 requests.
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: "webvuln-ssrf")?.sideEffects, [.iocInLogs, .temporaryListener, .manyRequests])
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: "webvuln-ssrf")?.evidenceKind, .confirmed)
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: "webvuln-unauth-admin")?.sideEffects, [.iocInLogs, .manyRequests])
        XCTAssertEqual(ProbeCatalog.declaration(forProbeName: ProbeCatalog.nmapNSEProbeName)?.evidenceKind, .externalToolReport)
    }

    func testSignatureProbesAreSingleOrdinaryRequestsWithConfirmedEvidence() {
        for id in ["redis-default-noauth", "memcached-noauth", "mongod-default-noauth", "jenkins-noauth", "vnc-noauth",
                   "smb1-enabled", "ollama-exposed", "gradio-noauth"] {
            let declaration = ProbeCatalog.declaration(forProbeName: id)
            XCTAssertEqual(declaration?.sideEffects, [], id)
            XCTAssertEqual(declaration?.evidenceKind, .confirmed, id)
        }
    }

    func testRawValuesAreTheStableWireNames() {
        XCTAssertEqual(ProbeSideEffect.allCases.map(\.rawValue), ["ioc_in_logs", "temporary_listener", "many_requests"])
        XCTAssertEqual(EvidenceKind.allCases.map(\.rawValue), ["confirmed", "version_range_match", "port_open_only", "external_tool_report"])
    }

    func testPlannedSideEffectsFollowTheChecksThatApplyToAPort() {
        let redis = ListeningPortInfo(processName: "redis-server", pid: 1, port: 16379, isGloballyExposed: true, executablePath: nil)
        XCTAssertEqual(ActiveVulnScan.plannedSideEffects(for: redis), [])
        let devServer = ListeningPortInfo(processName: "node", pid: 2, port: 3000, isGloballyExposed: false, executablePath: nil)
        XCTAssertTrue(PortSecurityAuditor.isKnownDevServerPort(3000))
        XCTAssertEqual(ActiveVulnScan.plannedSideEffects(for: devServer), [.iocInLogs, .temporaryListener, .manyRequests])
        let other = ListeningPortInfo(processName: "sshd", pid: 3, port: 22, isGloballyExposed: true, executablePath: nil)
        XCTAssertEqual(ActiveVulnScan.plannedSideEffects(for: other), [])
    }

    func testProbeStatusCarriesTheDeclarationAndStaysDecodableWithoutIt() throws {
        let record = ActiveVulnScan.ProbeRunRecord(probeName: "webvuln-ssrf", port: 3000, lastStartedAt: "2026-10-19T00:00:00Z",
                                                   lastFinishedAt: "2026-10-19T00:00:01Z", outcome: "safe")
        let unknown = ActiveVulnScan.ProbeRunRecord(probeName: "future-probe", port: 1, lastStartedAt: "2026-10-19T00:00:00Z",
                                                    lastFinishedAt: "2026-10-19T00:00:01Z", outcome: "safe")
        let statuses = ActiveVulnScan.probeStatusSummary(from: [record, unknown], now: Date())
        let ssrf = try XCTUnwrap(statuses.first { $0.probeName == "webvuln-ssrf" })
        XCTAssertEqual(ssrf.sideEffects, ["ioc_in_logs", "temporary_listener", "many_requests"])
        XCTAssertEqual(ssrf.evidenceKind, "confirmed")
        let future = try XCTUnwrap(statuses.first { $0.probeName == "future-probe" })
        XCTAssertNil(future.sideEffects)
        XCTAssertNil(future.evidenceKind)

        // Output from an older version (no new keys) still decodes, and the new keys are only added.
        let old = Data(#"{"probeName":"x","port":1,"lastOutcome":"safe","lastFinishedAt":"2026-10-19T00:00:00Z","passAgeDays":0}"#.utf8)
        let decoded = try JSONDecoder().decode(ActiveVulnScan.ProbeStatus.self, from: old)
        XCTAssertNil(decoded.sideEffects)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(ssrf)) as? [String: Any])
        XCTAssertNotNil(json["probeName"]); XCTAssertNotNil(json["passAgeDays"]); XCTAssertNotNil(json["sideEffects"])
    }

    func testFindingsAreConfirmedExceptTheirVersionOnlyFollowUps() {
        let finding = ActiveVulnScan.Finding(port: 1, processName: "p", title: "t", description: "d", recommendation: "r")
        XCTAssertEqual(finding.evidenceKind, .confirmed)
        XCTAssertNil(finding.probeName)
    }
}
