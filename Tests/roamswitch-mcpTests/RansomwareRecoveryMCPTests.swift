// Mirrored from RoamSwitchTests/ — RoamSwitch 1.10.2 (build 120). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class RansomwareRecoveryMCPTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private func suite() -> UserDefaults {
        let name = "test.ransomware-snapshots.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }
    private func store(_ records: [RansomwareSnapshot], in d: UserDefaults) {
        d.set(try! JSONEncoder().encode(records), forKey: "RoamSwitch.RansomwareSnapshots.RecordsV1")
    }
    private func snap(_ id: String, _ kind: RansomwareSnapshotKind, hoursAgo: Double, exists: Bool = true) -> RansomwareSnapshot {
        RansomwareSnapshot(id: id, kind: kind, createdAt: now.addingTimeInterval(-hoursAgo * 3600), exists: exists)
    }

    func testStatusRechecksExistenceAgainstTheDiskAndRecommendsTheNewestPreDamage() {
        let d = suite()
        store([snap("2026-09-21-060000", .preDamage, hoursAgo: 2), snap("2026-09-21-000000", .preDamage, hoursAgo: 8),
               snap("2026-09-21-070000", .detection, hoursAgo: 1)], in: d)
        // The newest pre-damage snapshot is gone from the disk: the recommendation falls back to the older one.
        let status = RansomwareSnapshotStatusReader.currentStatus(defaults: d, now: now, presentIDs: ["2026-09-21-000000", "2026-09-21-070000"])
        XCTAssertEqual(status.recommendedID, "2026-09-21-000000")
        XCTAssertEqual(status.snapshots.map(\.exists), [true, false, true])   // newest first: detection, pre(2h, gone), pre(8h)
        XCTAssertTrue(status.retentionMode)                                     // a detection snapshot is newest
        XCTAssertEqual(status.intervalHours, RansomwareSnapshotPolicy.defaultIntervalHours)
    }

    func testStatusKeepsStoredFlagsWhenTmutilCannotBeRun() {
        let d = suite()
        store([snap("2026-09-21-060000", .preDamage, hoursAgo: 2)], in: d)
        let status = RansomwareSnapshotStatusReader.currentStatus(defaults: d, now: now, presentIDs: nil)
        XCTAssertEqual(status.snapshots.count, 1)
        XCTAssertTrue(status.snapshots[0].exists)
    }

    func testIntervalSettingIsReadAndAnInvalidOneFallsBackToTheDefault() {
        let d = suite()
        d.set(12, forKey: "RoamSwitch.RansomwareSnapshots.IntervalHours")
        XCTAssertEqual(RansomwareSnapshotStatusReader.currentStatus(defaults: d, now: now, presentIDs: []).intervalHours, 12)
        d.set(7, forKey: "RoamSwitch.RansomwareSnapshots.IntervalHours")     // not a choice
        XCTAssertEqual(RansomwareSnapshotStatusReader.currentStatus(defaults: d, now: now, presentIDs: []).intervalHours, 6)
    }

    func testPayloadExplainsDetectionSnapshotsAndIsReadOnly() throws {
        let d = suite()
        store([snap("2026-09-21-060000", .preDamage, hoursAgo: 2), snap("2026-09-21-070000", .detection, hoursAgo: 1)], in: d)
        let status = RansomwareSnapshotStatusReader.currentStatus(defaults: d, now: now, presentIDs: ["2026-09-21-060000", "2026-09-21-070000"])
        let payload = MCPRansomwareRecoveryFormatting.payload(status)

        let detection = try XCTUnwrap(payload.snapshots.first { $0.kind == "detection" })
        XCTAssertNotNil(detection.note)                       // says it may already hold encrypted files
        XCTAssertFalse(detection.recommended)                 // never recommended
        let pre = try XCTUnwrap(payload.snapshots.first { $0.kind == "pre_damage" })
        XCTAssertTrue(pre.recommended)
        XCTAssertNil(pre.note)
        XCTAssertEqual(payload.recommendedSnapshotId, "2026-09-21-060000")
        XCTAssertTrue(payload.notes.joined(separator: " ").contains("no MCP tool that restores"))
    }

    func testToolIsListedAndTakesNoArguments() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        let tool = try XCTUnwrap(tools.first { ($0["name"] as? String) == "get_ransomware_recovery_snapshots" })
        let schema = try XCTUnwrap(tool["inputSchema"] as? [String: Any])
        XCTAssertEqual((schema["properties"] as? [String: Any])?.count, 0)
        let description = try XCTUnwrap(tool["description"] as? String)
        XCTAssertTrue(description.contains("NOT a recovery source"))
        XCTAssertTrue(description.contains("no MCP tool restores anything"))
    }
}
