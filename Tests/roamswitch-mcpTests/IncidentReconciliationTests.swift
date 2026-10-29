// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.13 (build 192). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `MCPResponseFormatting.reconcileIncidents`: the incident timeline grouped by `rootEventID` and by the same
/// process within 15 minutes. `events` stays the record of truth, so these tests also check nothing is lost.
final class IncidentReconciliationTests: XCTestCase {

    private let t0 = Date(timeIntervalSince1970: 1_790_000_000)

    private func event(_ minute: Double, _ source: ContainmentIncidentSource = .runtimeThreat, severity: String = "high",
                       summary: String = "s", process: String? = nil, pid: Int32? = nil, technique: String? = nil,
                       resolution: ContainmentIncidentResolution? = nil, parent: UUID? = nil, root: UUID? = nil,
                       refs: [ContainmentEvidenceRef] = [], id: UUID = UUID()) -> ContainmentIncidentEvent {
        ContainmentIncidentEvent(id: id, timestamp: t0.addingTimeInterval(minute * 60), source: source, severity: severity, summary: summary,
                                 processName: process, processID: pid, attackTechnique: technique, actionTaken: "notify_only",
                                 resolvedAt: resolution == nil ? nil : t0.addingTimeInterval(minute * 60 + 1), resolution: resolution,
                                 parentEventID: parent, rootEventID: root, evidenceRefs: refs)
    }

    private func reconcile(_ events: [ContainmentIncidentEvent]) -> [MCPReconciledIncidentPayload] {
        MCPResponseFormatting.reconcileIncidents(events: events)
    }

    func testNothingToGroup() {
        XCTAssertEqual(reconcile([]), [])
    }

    func testRecordsWithNoLinkAreSeparateIncidentsNewestFirst() {
        let a = event(0, process: "a", pid: 10), b = event(5, process: "b", pid: 11), c = event(9)
        let incidents = reconcile([a, b, c])
        XCTAssertEqual(incidents.map(\.incidentId), [c.id, b.id, a.id].map(\.uuidString))
        XCTAssertTrue(incidents.allSatisfy { $0.eventCount == 1 && !$0.crossSource })
    }

    func testTheSameRootJoinsRecordsEvenWithoutAProcess() {
        let root = event(0, .portAnomaly, severity: "warning")
        let child = event(2, .forensicCapture, severity: "info", parent: root.id, root: root.id)
        let other = event(3, .sshGuard, root: root.id)
        let incidents = reconcile([child, other, root])
        XCTAssertEqual(incidents.count, 1)
        XCTAssertEqual(incidents[0].incidentId, root.id.uuidString)
        XCTAssertEqual(incidents[0].eventIds, [root.id, child.id, other.id].map(\.uuidString), "oldest first")
        XCTAssertEqual(incidents[0].sources, ["portAnomaly", "forensicCapture", "sshGuard"])
        XCTAssertTrue(incidents[0].crossSource)
    }

    func testAParentLinkJoinsAndTheIncidentIdIsTheRootEvenWhenItAgedOut() {
        let gone = UUID()   // the root record is no longer in the retained timeline
        let a = event(0, root: gone), b = event(1, parent: a.id, root: gone)
        let incidents = reconcile([a, b])
        XCTAssertEqual(incidents.count, 1)
        XCTAssertEqual(incidents[0].incidentId, gone.uuidString)
    }

    func testTheSameProcessWithinFifteenMinutesJoinsAndAGapSplits() {
        let a = event(0, .portAnomaly, process: "nc", pid: 77)
        let b = event(15, .reverseShellWatch, process: "nc", pid: 77)     // exactly 15 minutes: joins
        let c = event(31, .runtimeThreat, process: "nc", pid: 77)          // 16 minutes after b: a new incident
        let incidents = reconcile([a, b, c])
        XCTAssertEqual(incidents.count, 2)
        XCTAssertEqual(incidents[0].eventIds, [c.id.uuidString])
        XCTAssertEqual(incidents[1].eventIds, [a.id, b.id].map(\.uuidString))
    }

    func testChainsOfCloseRecordsAreTransitive() {
        let events = (0..<5).map { event(Double($0) * 14, process: "p", pid: 5) }   // 56 minutes in all, no gap above 15
        XCTAssertEqual(reconcile(events).count, 1)
    }

    func testDifferentPidOrNameOrNoPidDoNotJoin() {
        let a = event(0, process: "x", pid: 100)
        XCTAssertEqual(reconcile([a, event(1, process: "x", pid: 101)]).count, 2, "another pid")
        XCTAssertEqual(reconcile([a, event(1, process: "y", pid: 100)]).count, 2, "another name for the same pid number")
        XCTAssertEqual(reconcile([event(0, process: "x"), event(1, process: "x")]).count, 2, "no pid")
        XCTAssertEqual(reconcile([event(0, process: "x", pid: 0), event(1, process: "x", pid: 0)]).count, 2, "pid 0 is not a process")
    }

    func testProcessAndRootLinksCombine() {
        let root = event(0, .portAnomaly, process: "a", pid: 1)
        let viaRoot = event(60, .forensicCapture, severity: "info", parent: root.id, root: root.id)
        let viaProcess = event(10, .runtimeThreat, process: "a", pid: 1)
        let unrelated = event(5, .arpSpoof, process: "z", pid: 2)
        let incidents = reconcile([root, viaRoot, viaProcess, unrelated])
        XCTAssertEqual(incidents.count, 2)
        XCTAssertEqual(Set(incidents.first { $0.eventCount == 3 }?.eventIds ?? []), Set([root.id, viaRoot.id, viaProcess.id].map(\.uuidString)))
    }

    func testSeverityStatusSummaryProcessTechniquesAndEvidence() {
        let ref1 = ContainmentEvidenceRef(bundle: "b1", artifact: "a.txt", sha256: String(repeating: "a", count: 64))
        let ref2 = ContainmentEvidenceRef(bundle: "b2", artifact: nil, sha256: nil)
        let first = event(0, .portAnomaly, severity: "warning", summary: "first", process: "node", pid: 9, technique: "T1571", refs: [ref1])
        let second = event(1, .runtimeThreat, severity: "critical", summary: "worst", technique: "T1059", parent: first.id, root: first.id, refs: [ref1, ref2])
        let incidents = reconcile([first, second])
        XCTAssertEqual(incidents.count, 1)
        let i = incidents[0]
        XCTAssertEqual(i.severity, "critical")
        XCTAssertEqual(i.summary, "worst")
        XCTAssertEqual(i.processName, "node")
        XCTAssertEqual(i.processID, 9)
        XCTAssertEqual(i.attackTechniques, ["T1571", "T1059"])
        XCTAssertEqual(i.evidenceRefs, [MCPEvidenceRefPayload(bundle: "b1", artifact: "a.txt", sha256: String(repeating: "a", count: 64)),
                                        MCPEvidenceRefPayload(bundle: "b2", artifact: nil, sha256: nil)], "duplicates dropped, order kept")
        XCTAssertEqual(i.status, "open")
        XCTAssertEqual(i.firstTimestamp, ISO8601DateFormatter().string(from: t0))
        XCTAssertEqual(i.lastTimestamp, ISO8601DateFormatter().string(from: t0.addingTimeInterval(60)))
    }

    func testTheOldestRecordOfTheHighestSeverityGivesTheSummary() {
        let a = event(0, severity: "high", summary: "old high", process: "p", pid: 3)
        let b = event(1, severity: "high", summary: "newer high", process: "p", pid: 3)
        let c = event(2, severity: "medium", summary: "medium", process: "p", pid: 3)
        XCTAssertEqual(reconcile([c, b, a])[0].summary, "old high")
        XCTAssertEqual(MCPResponseFormatting.severityRank("warning"), MCPResponseFormatting.severityRank("medium"))
        XCTAssertGreaterThan(MCPResponseFormatting.severityRank("critical"), MCPResponseFormatting.severityRank("high"))
        XCTAssertGreaterThan(MCPResponseFormatting.severityRank("info"), MCPResponseFormatting.severityRank("unheard-of"))
    }

    func testStatusIsOpenWhileAnyDetectionIsOpenElseTheLastDetectionsStatus() {
        let a = event(0, process: "p", pid: 4, resolution: .released)
        let b = event(1, process: "p", pid: 4, resolution: .autoTimeout)
        XCTAssertEqual(reconcile([a, b])[0].status, "autoTimeout")
        let open = event(2, process: "p", pid: 4)
        XCTAssertEqual(reconcile([a, b, open])[0].status, "open")
        // An evidence capture is never resolved; it does not keep an incident open.
        let root = event(0, .portAnomaly, resolution: .released)
        let evidence = event(1, .forensicCapture, severity: "info", parent: root.id, root: root.id)
        XCTAssertEqual(reconcile([root, evidence])[0].status, "released")
        // Evidence alone (its detection is gone) has nothing to resolve.
        XCTAssertEqual(reconcile([event(1, .forensicCapture, severity: "info")])[0].status, "recorded")
        // An expired risk acceptance is never resolved either: it is a reminder, not a detection.
        let expired = event(5, .vulnerabilityAcceptance, severity: "warning")
        XCTAssertEqual(reconcile([expired])[0].status, "recorded")
        let released = event(6, .portAnomaly, process: "q", pid: 9, resolution: .released)
        let linked = event(7, .vulnerabilityAcceptance, severity: "warning", process: "q", pid: 9)
        XCTAssertEqual(reconcile([released, linked])[0].status, "released")
    }

    func testEvidenceRefsAreCappedAtEight() {
        let refs = (0..<12).map { ContainmentEvidenceRef(bundle: "bundle-\($0)", artifact: nil, sha256: nil) }
        let a = event(0, process: "p", pid: 8, refs: Array(refs.prefix(6)))
        let b = event(1, process: "p", pid: 8, refs: Array(refs.suffix(6)))
        XCTAssertEqual(reconcile([a, b])[0].evidenceRefs?.count, 8)
    }

    func testEveryRecordIsInExactlyOneIncident() {
        var events: [ContainmentIncidentEvent] = []
        for n in 0..<40 { events.append(event(Double(n) * 7, ContainmentIncidentSource.arpSpoof, process: "p\(n % 4)", pid: Int32(n % 4 + 1))) }
        let incidents = reconcile(events)
        let ids = incidents.flatMap(\.eventIds)
        XCTAssertEqual(ids.count, events.count)
        XCTAssertEqual(Set(ids), Set(events.map(\.id.uuidString)))
        XCTAssertEqual(incidents.map(\.eventCount).reduce(0, +), events.count)
    }

    func testThePayloadCarriesIncidentsAndTheOpenCountAndTheCaveat() throws {
        let root = event(0, .portAnomaly)
        let evidence = event(1, .forensicCapture, severity: "info", parent: root.id, root: root.id)
        let closed = event(120, .arpSpoof, resolution: .released)
        let payload = MCPResponseFormatting.makeIncidentTimelinePayload(events: [root, evidence, closed])
        XCTAssertEqual(payload.events.count, 3, "the records themselves are unchanged")
        XCTAssertEqual(payload.incidents.count, 2)
        XCTAssertEqual(payload.openIncidentCount, 1)
        XCTAssertEqual(payload.unresolvedCount, 2, "unresolvedCount still counts records: the detection and the evidence capture")
        XCTAssertTrue(payload.caveats.contains { $0.lowercased().contains("incidents") })
        let json = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any])
        XCTAssertNotNil(object["incidents"] as? [[String: Any]])
        XCTAssertEqual(object["openIncidentCount"] as? Int, 1)
    }
}
