// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.33 (build 212). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Adoption plan #14: the hash chain of the incident timeline, the blind spot around a record, and the joining of
/// records by remote address and by SSH session.
final class IncidentChainTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_790_000_000)

    private func event(_ minute: Double, _ source: ContainmentIncidentSource = .sshGuard, code: ContainmentSummaryCode? = nil,
                       process: String? = nil, pid: Int32? = nil, session: String? = nil, blind: Bool = false) -> ContainmentIncidentEvent {
        ContainmentIncidentEvent(timestamp: t0.addingTimeInterval(minute * 60), source: source, severity: "high", summary: "s",
                                 processName: process, processID: pid, actionTaken: "notify_only", summaryCode: code,
                                 blindNear: blind, sshSession: session)
    }

    /// Stores `events` (oldest first) the way `record` does: each linked to the newest stored one, newest first.
    private func chained(_ oldestFirst: [ContainmentIncidentEvent], after legacy: [ContainmentIncidentEvent] = []) -> [ContainmentIncidentEvent] {
        var stored = legacy.reversed() as [ContainmentIncidentEvent]
        for var e in oldestFirst {
            IncidentChain.link(&e, after: stored.first)
            stored.insert(e, at: 0)
        }
        return stored
    }

    // MARK: Chain

    func testAFreshChainStartsAtGenesisAndVerifies() {
        let stored = chained([event(0), event(1), event(2)])
        XCTAssertEqual(stored.last?.prevHash, IncidentChain.genesis)
        let v = IncidentChain.verify(stored)
        XCTAssertTrue(v.intact)
        XCTAssertEqual(v.verified, 3)
        XCTAssertEqual(v.legacy, 0)
    }

    func testExistingRecordsStartTheChainAndAreNotChecked() {
        let legacy = [event(0), event(1)]
        let stored = chained([event(2), event(3)], after: legacy)
        XCTAssertEqual(stored[1].prevHash, IncidentChain.hash(of: legacy[1]), "the first new record links to the newest old one")
        let v = IncidentChain.verify(stored)
        XCTAssertTrue(v.intact)
        XCTAssertEqual(v.legacy, 2)
        XCTAssertEqual(v.verified, 2)
    }

    func testAnEditedRecordBreaksTheLinkOfTheRecordAfterIt() throws {
        var stored = chained([event(0), event(1), event(2)])
        let edited = stored[1]
        stored[1] = ContainmentIncidentEvent(id: edited.id, timestamp: edited.timestamp, source: edited.source, severity: "low",
                                             summary: edited.summary, actionTaken: edited.actionTaken, prevHash: edited.prevHash)
        let v = IncidentChain.verify(stored)
        XCTAssertFalse(v.intact)
        XCTAssertEqual(v.breaks, [stored[0].id])
    }

    func testARemovedRecordBreaksTheChainAndTheRestIsStillRead() {
        var stored = chained([event(0), event(1), event(2), event(3)])
        stored.remove(at: 2)
        let v = IncidentChain.verify(stored)
        XCTAssertEqual(v.breaks, [stored[1].id])
        XCTAssertEqual(v.verified, 2)
    }

    func testAnUnlinkedRecordAfterTheChainBeganIsABreak() {
        var stored = chained([event(0), event(1)])
        stored.insert(event(2), at: 0)
        XCTAssertEqual(IncidentChain.verify(stored).breaks, [stored[0].id])
    }

    func testTheOldestKeptRecordIsAcceptedWhenItsPredecessorWasDroppedByTheCap() {
        var stored = chained([event(0), event(1), event(2)])
        stored.removeLast()
        XCTAssertTrue(IncidentChain.verify(stored).intact)
    }

    func testLaterAnnotationsDoNotChangeTheHash() {
        var e = event(0)
        let before = IncidentChain.hash(of: e)
        e.resolvedAt = t0.addingTimeInterval(99)
        e.resolution = .released
        e.evidenceRefs = [ContainmentEvidenceRef(bundle: "b")]
        XCTAssertEqual(IncidentChain.hash(of: e), before)
        e.blindNear = true
        XCTAssertNotEqual(IncidentChain.hash(of: e), before, "fixed fields are covered")
    }

    func testTheHashSurvivesAFileRoundTrip() throws {
        let stored = chained([event(0, code: ContainmentSummaryText.ssh(.banned, source: "203.0.113.9"), session: "100@5"), event(1.5)])
        let data = try JSONEncoder().encode(stored)
        let read = try JSONDecoder().decode([ContainmentIncidentEvent].self, from: data)
        XCTAssertEqual(read, stored)
        XCTAssertTrue(IncidentChain.verify(read).intact)
    }

    func testTheHashIsFixedForAKnownRecord() {
        // Pinned so a change to the canonical form is deliberate (the Linux edition follows the same form).
        let e = ContainmentIncidentEvent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, timestamp: t0,
                                         source: .sshGuard, severity: "high", summary: "x", actionTaken: "notify_only",
                                         summaryCode: ContainmentSummaryCode("ssh_guard.source_banned", ["source": "203.0.113.9"]),
                                         prevHash: IncidentChain.genesis)
        XCTAssertEqual(IncidentChain.hash(of: e), "c511e3f14859cac57974ce406e2a21d244aff3c445c23eb234088ac55c91a6ba",
                       "the same value is pinned in the Linux edition's test")
        XCTAssertEqual(IncidentChain.hash(of: e).count, 64)
        XCTAssertEqual(IncidentChain.hash(of: e), IncidentChain.hash(of: e))
        var other = e
        other.summaryCode = ContainmentSummaryCode("ssh_guard.source_banned", ["source": "203.0.113.10"])
        XCTAssertNotEqual(IncidentChain.hash(of: e), IncidentChain.hash(of: other))
    }

    func testOldFilesDecodeWithoutTheNewFields() throws {
        let json = #"[{"id":"00000000-0000-0000-0000-000000000002","timestamp":800000000,"source":"sshGuard","severity":"high","summary":"s","actionTaken":"notify_only"}]"#
        let read = try JSONDecoder().decode([ContainmentIncidentEvent].self, from: Data(json.utf8))
        XCTAssertNil(read[0].prevHash)
        XCTAssertFalse(read[0].blindNear)
        XCTAssertNil(read[0].sshSession)
        let written = String(data: try JSONEncoder().encode(read), encoding: .utf8) ?? ""
        XCTAssertFalse(written.contains("blindNear"), "false is not written")
    }

    // MARK: Blind spot

    private func health(gapAt: Double? = nil, restartAt: Double? = nil, inGap: Bool = false) -> GuardReaderHealth {
        var h = GuardReaderHealth()
        h.active = true
        h.lastGapAt = gapAt
        h.lastRestartAt = restartAt
        h.inGap = inGap
        return h
    }

    func testAGapJustBeforeOrJustAfterMarksTheRecord() {
        let t = t0.timeIntervalSince1970
        XCTAssertTrue(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: ["sshLogStream": health(gapAt: t - 299)]))
        XCTAssertTrue(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: ["sshLogStream": health(restartAt: t + 59)]))
        XCTAssertFalse(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: ["sshLogStream": health(gapAt: t - 301)]))
        XCTAssertFalse(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: ["sshLogStream": health(gapAt: t + 61)]))
        XCTAssertTrue(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: ["sshLogStream": health(inGap: true)]))
        XCTAssertFalse(IncidentBlindSpot.isBlindNear(time: t, guardKey: "sshGuard", records: [:]), "no record is not a gap")
    }

    func testOnlyTheInputsOfTheRecordsGuardCount() {
        let t = t0.timeIntervalSince1970
        let records = ["portScanTcpdump": health(gapAt: t)]
        XCTAssertFalse(IncidentBlindSpot.isBlindNear(event(0), records: records))
        let scan = event(0, .portAnomaly, code: ContainmentSummaryText.portScanIncoming(source: "198.51.100.4"))
        XCTAssertTrue(IncidentBlindSpot.isBlindNear(scan, records: records))
        let listener = event(0, .portAnomaly, code: ContainmentSummaryText.exposedPort(8080, udp: false))
        XCTAssertFalse(IncidentBlindSpot.isBlindNear(listener, records: records), "the port-anomaly guard has no reader record")
        XCTAssertNil(IncidentBlindSpot.guardKey(for: .arpSpoof, code: nil))
    }

    func testEveryGuardKeyNamedExists() {
        for source in [ContainmentIncidentSource.sshGuard, .runtimeThreat, .clickFix, .execRecorder, .ransomwareCanary, .ransomwareEntropy,
                       .honeytoken, .browserCredentialWatch, .criticalPathFim, .reverseShellWatch, .networkSettingsWatch, .persistence,
                       .rmmInstallerUnofficialSource] {
            let key = IncidentBlindSpot.guardKey(for: source, code: nil)
            XCTAssertNotNil(key.flatMap { GuardReaderHealthStore.guardSources[$0] }, "\(source)")
        }
    }

    // MARK: Address and session

    func testTheSourceAddressComesFromTheSummaryValues() {
        XCTAssertEqual(IncidentCorrelation.sourceAddress(of: event(0, code: ContainmentSummaryText.ssh(.detected, source: "203.0.113.9"))), "203.0.113.9")
        XCTAssertEqual(IncidentCorrelation.sourceAddress(of: event(0, .reverseShellWatch, code: ContainmentSummaryText.reverseShell(process: "nc", peer: "[2001:DB8::1]:4444"))), "2001:db8::1")
        XCTAssertEqual(IncidentCorrelation.sourceAddress(of: event(0, .reverseShellWatch, code: ContainmentSummaryText.reverseShell(process: "nc", peer: "198.51.100.7:443"))), "198.51.100.7")
        XCTAssertNil(IncidentCorrelation.sourceAddress(of: event(0, .reverseShellWatch, code: ContainmentSummaryText.reverseShell(process: "nc", peer: "127.0.0.1:4444"))))
        XCTAssertNil(IncidentCorrelation.sourceAddress(of: event(0, .reverseShellWatch, code: ContainmentSummaryText.reverseShell(process: "nc", peer: "[::1]:4444"))))
        XCTAssertNil(IncidentCorrelation.sourceAddress(of: event(0, code: ContainmentSummaryText.ssh(.detected, source: "not an address"))))
        XCTAssertNil(IncidentCorrelation.sourceAddress(of: event(0)))
    }

    func testTheSessionIsTheOutermostSshdWithItsStartTime() {
        let table: [Int32: IncidentCorrelation.ProcessFacts] = [
            900: .init(parentPID: 800, name: "nc", startedAt: 30),
            800: .init(parentPID: 700, name: "zsh", startedAt: 20),
            700: .init(parentPID: 600, name: "sshd-session", startedAt: 11),
            600: .init(parentPID: 1, name: "sshd", startedAt: 10),
            500: .init(parentPID: 1, name: "Terminal", startedAt: 5),
            501: .init(parentPID: 500, name: "zsh", startedAt: 6),
        ]
        let lookup: (Int32) -> IncidentCorrelation.ProcessFacts? = { table[$0] }
        XCTAssertEqual(IncidentCorrelation.sshSession(ofPID: 900, lookup: lookup), "600@10")
        XCTAssertEqual(IncidentCorrelation.sshSession(ofPID: 700, lookup: lookup), "600@10", "an sshd itself is in its session")
        XCTAssertNil(IncidentCorrelation.sshSession(ofPID: 501, lookup: lookup))
        XCTAssertNil(IncidentCorrelation.sshSession(ofPID: 4242, lookup: lookup), "an ended process")
    }

    func testTheSameAddressWithinAnHourJoinsAndALongerGapSplits() {
        let a = event(0, code: ContainmentSummaryText.ssh(.detected, source: "203.0.113.9"))
        let b = event(50, .portAnomaly, code: ContainmentSummaryText.portScanIncoming(source: "203.0.113.9"))
        let c = event(111, code: ContainmentSummaryText.ssh(.banned, source: "203.0.113.9"))
        let other = event(10, code: ContainmentSummaryText.ssh(.detected, source: "203.0.113.10"))
        let incidents = MCPResponseFormatting.reconcileIncidents(events: [a, b, c, other])
        XCTAssertEqual(incidents.count, 3)
        let joined = incidents.first { $0.eventIds.contains(a.id.uuidString) }
        XCTAssertEqual(joined?.eventIds, [a.id, b.id].map(\.uuidString))
        XCTAssertEqual(joined?.sourceAddresses, ["203.0.113.9"])
        XCTAssertEqual(joined?.crossSource, true)
    }

    func testTheSameSshSessionJoinsWithoutATimeLimit() {
        let listener = event(0, .portAnomaly, code: ContainmentSummaryText.sshForwardListener(address: "127.0.0.1:8080", process: "sshd", pid: 600),
                             process: "sshd", pid: 600, session: "600@10")
        let shell = event(300, .reverseShellWatch, process: "nc", pid: 900, session: "600@10")
        let elsewhere = event(301, .reverseShellWatch, process: "nc", pid: 901, session: "601@12")
        let incidents = MCPResponseFormatting.reconcileIncidents(events: [listener, shell, elsewhere])
        XCTAssertEqual(incidents.count, 2)
        let joined = incidents.first { $0.eventIds.contains(listener.id.uuidString) }
        XCTAssertEqual(joined?.eventIds, [listener.id, shell.id].map(\.uuidString))
        XCTAssertEqual(joined?.sshSessions, ["600@10"])
    }

    // MARK: Payload

    func testThePayloadReportsTheChainAndTheBlindRecords() {
        var stored = chained([event(0, code: ContainmentSummaryText.ssh(.detected, source: "203.0.113.9")), event(1), event(2, blind: true)])
        stored.remove(at: 1)
        let chain = IncidentChain.verify(stored)
        let health = ["sshLogStream": health(gapAt: t0.timeIntervalSince1970 - 10)]
        let p = MCPResponseFormatting.makeIncidentTimelinePayload(events: stored, chain: chain, readerHealth: health)
        XCTAssertEqual(p.chain?.intact, false)
        XCTAssertEqual(p.chain?.breakEventIds, [stored[0].id.uuidString])
        XCTAssertEqual(p.events.first?.chainBreak, true)
        XCTAssertEqual(p.events.map(\.blindNear), [true, true], "the stored mark, and a gap read now")
        XCTAssertEqual(p.events.last?.sourceAddress, "203.0.113.9")
        XCTAssertEqual(p.caveats.count, 4)
        let intact = MCPResponseFormatting.makeIncidentTimelinePayload(events: chained([event(0)]), chain: IncidentChain.verify(chained([event(0)])))
        XCTAssertEqual(intact.chain?.intact, true)
        XCTAssertNil(intact.events[0].blindNear)
        XCTAssertNil(intact.events[0].chainBreak)
        XCTAssertEqual(intact.caveats.count, 2)
    }
}
