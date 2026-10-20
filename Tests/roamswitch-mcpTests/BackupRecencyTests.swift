// Mirrored from RoamSwitchTests/ — RoamSwitch 1.12.10 (build 172). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `backup_recency`: Time Machine's record of its newest backup. The plist shapes below follow the
/// documented `Destinations[].SnapshotDates` layout; a shape that is not recognised must come out as
/// "not measured", never as a pass.
final class BackupRecencyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_792_000_000)

    private func days(_ n: Double) -> Date { now.addingTimeInterval(-n * 86_400) }

    private func prefs(_ destinations: [[String: Any]]?, version: Int? = 6) -> [String: Any] {
        var p: [String: Any] = [:]
        if let version { p["PreferencesVersion"] = version }
        if let destinations { p["Destinations"] = destinations }
        return p
    }

    private func eval(_ p: [String: Any]?, snapshots: Int? = nil, apps: [String] = []) -> BackupRecency.Outcome {
        BackupRecency.evaluate(preferences: p, localSnapshotCount: snapshots, installedApps: apps, now: now)
    }

    func testRecentBackupPasses() {
        XCTAssertEqual(eval(prefs([["SnapshotDates": [days(3), days(10)]]])), .recent(days: 3))
        XCTAssertEqual(eval(prefs([["SnapshotDates": [days(0.2)]]])), .recent(days: 0))
    }

    func testTheSeventhDayStillPassesAndTheEighthFails() {
        XCTAssertEqual(eval(prefs([["SnapshotDates": [days(7.5)]]])), .recent(days: 7))
        XCTAssertEqual(eval(prefs([["SnapshotDates": [days(8.1)]]])), .stale(days: 8))
    }

    func testTheNewestSnapshotOfAnyDestinationDecides() {
        let p = prefs([["SnapshotDates": [days(40)]], ["SnapshotDates": [days(2), days(30)]]])
        XCTAssertEqual(eval(p), .recent(days: 2))
    }

    func testAFutureDateCountsAsToday() {
        XCTAssertEqual(eval(prefs([["SnapshotDates": [now.addingTimeInterval(3 * 86_400)]]])), .recent(days: 0))
    }

    func testDatesWrittenAsStringsAreRead() {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        XCTAssertEqual(eval(prefs([["SnapshotDates": [f.string(from: days(12))]]])), .stale(days: 12))
    }

    func testADestinationWithAnEmptyRecordIsNeverBackedUp() {
        XCTAssertEqual(eval(prefs([["SnapshotDates": [Date]()]])), .neverBackedUp)
        // Entries that are not dates do not count either.
        XCTAssertEqual(eval(prefs([["SnapshotDates": ["not a date", 5]]])), .neverBackedUp)
    }

    func testNoDestinationIsNotConfigured() {
        XCTAssertEqual(eval(prefs(nil)), .notConfigured(localSnapshots: false))
        XCTAssertEqual(eval(prefs([])), .notConfigured(localSnapshots: false))
        XCTAssertEqual(eval(prefs(nil), snapshots: 4), .notConfigured(localSnapshots: true))
        XCTAssertEqual(eval(prefs(nil), snapshots: 0), .notConfigured(localSnapshots: false))
    }

    func testAnotherBackupAppIsReportedButNeverPasses() {
        XCTAssertEqual(eval(prefs(nil), snapshots: 3, apps: ["Arq"]), .otherToolOnly(names: ["Arq"]))
    }

    func testUnrecognisedShapesAreNotMeasured() {
        XCTAssertEqual(eval(nil), .unreadable)
        // A readable file that is not Time Machine's preferences.
        XCTAssertEqual(eval(prefs(nil, version: nil)), .unreadable)
        // A destination with no record key at all: this macOS may keep it elsewhere.
        XCTAssertEqual(eval(prefs([["DestinationID": "x"]])), .unreadable)
    }

    func testLocalSnapshotCountReadsOnlySnapshotDateLines() {
        let ok = CommandOutput(status: 0, stdout: "Snapshot dates for all disks:\n2026-10-18-192349\n2026-10-19-012349\n")
        XCTAssertEqual(BackupRecency.localSnapshotCount(ok), 2)
        XCTAssertEqual(BackupRecency.localSnapshotCount(CommandOutput(status: 0, stdout: "Snapshot dates for all disks:\n")), 0)
        XCTAssertNil(BackupRecency.localSnapshotCount(CommandOutput(status: 1, stdout: "2026-10-18-192349\n")))
    }

    func testTheRealExportFromAMacWithNoDestinationIsNotConfigured() throws {
        // Captured with `defaults export /Library/Preferences/com.apple.TimeMachine -` on a Mac with Time Machine unset.
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>PreferencesVersion</key>
        \t<integer>6</integer>
        </dict>
        </plist>
        """
        let p = try XCTUnwrap(BackupRecency.decodePreferences(xml))
        XCTAssertEqual(eval(p), .notConfigured(localSnapshots: false))
    }

    func testAnExportWithDestinationsAndDateValuesIsDecoded() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
        <key>PreferencesVersion</key><integer>6</integer>
        <key>Destinations</key>
        <array><dict>
        <key>DestinationID</key><string>ABC</string>
        <key>SnapshotDates</key>
        <array><date>2026-10-10T03:00:00Z</date><date>2026-10-17T03:00:00Z</date></array>
        </dict></array>
        </dict>
        </plist>
        """
        let p = try XCTUnwrap(BackupRecency.decodePreferences(xml))
        let latest = ISO8601DateFormatter().date(from: "2026-10-17T03:00:00Z")!
        XCTAssertEqual(BackupRecency.evaluate(preferences: p, localSnapshotCount: nil, installedApps: [], now: latest.addingTimeInterval(2 * 86_400)), .recent(days: 2))
    }

    func testGarbageIsNotDecoded() {
        XCTAssertNil(BackupRecency.decodePreferences(""))
        XCTAssertNil(BackupRecency.decodePreferences("Error: domain not found"))
    }

    // MARK: - The audit item

    private struct FakeBackupSource: BackupSource {
        var preferences: [String: Any]?
        var apps: [String] = []
        func timeMachinePreferences() -> [String: Any]? { preferences }
        func installedBackupApps() -> [String] { apps }
    }

    private func item(_ source: FakeBackupSource, snapshots: String = "Snapshot dates for all disks:\n") -> SecurityAuditItem {
        let checker = SecurityHealthChecker(
            runner: { path, _ in path == "/usr/bin/tmutil" ? CommandOutput(status: 0, stdout: snapshots) : nil },
            backupSource: source)
        return checker.backupRecencyItem(now: now)
    }

    func testItemCarriesTheStableIdAndFrameworkMappings() {
        let i = item(FakeBackupSource(preferences: prefs([["SnapshotDates": [days(1)]]])))
        XCTAssertEqual(i.checkId, "backup_recency")
        XCTAssertEqual(i.cisControlID, "11.2")
        XCTAssertEqual(i.nistCsfCategories, ["PR.DS-11"])
    }

    func testRecentBackupIsAPassingApplicableItem() {
        let i = item(FakeBackupSource(preferences: prefs([["SnapshotDates": [days(1)]]])))
        XCTAssertTrue(i.isPassed)
        XCTAssertTrue(i.isApplicable)
        XCTAssertNil(i.inconclusiveReason)
        XCTAssertFalse(i.needsAttention)
    }

    func testStaleAndMissingBackupsNeedAttention() {
        XCTAssertTrue(item(FakeBackupSource(preferences: prefs([["SnapshotDates": [days(20)]]]))).needsAttention)
        XCTAssertTrue(item(FakeBackupSource(preferences: prefs(nil))).needsAttention)
        XCTAssertTrue(item(FakeBackupSource(preferences: prefs([["SnapshotDates": [Date]()]]))).needsAttention)
    }

    func testUnreadableAndOtherToolAreInconclusiveAndOutOfTheScore() {
        for source in [FakeBackupSource(preferences: nil), FakeBackupSource(preferences: prefs(nil), apps: ["Arq"])] {
            let i = item(source)
            XCTAssertFalse(i.isApplicable)
            XCTAssertFalse(i.isPassed)
            XCTAssertEqual(i.inconclusiveReason, "not_verifiable")
            XCTAssertEqual(SecurityCheckVerification.classify(i).verdict, .inconclusive)
        }
    }

    func testTheDescriptionSaysRestoreIsNotTested() {
        let i = item(FakeBackupSource(preferences: prefs(nil)))
        XCTAssertTrue(i.detail.contains("復元できるかは確認しません"))
    }

    func testLocalSnapshotsAreExplainedButDoNotCountAsABackup() {
        let withSnapshots = item(FakeBackupSource(preferences: prefs(nil)), snapshots: "Snapshot dates for all disks:\n2026-10-19-132809\n")
        XCTAssertFalse(withSnapshots.isPassed)
        XCTAssertTrue(withSnapshots.detail.contains("同じディスクの中"))
        let without = item(FakeBackupSource(preferences: prefs(nil)))
        XCTAssertFalse(without.detail.contains("同じディスクの中"))
    }

    func testTheReportIncludesTheItemOnce() {
        let checker = SecurityHealthChecker(runner: { _, _ in nil }, backupSource: FakeBackupSource(preferences: prefs([["SnapshotDates": [Date()]]])))
        let report = checker.generateComprehensiveReport(
            wifiInfo: WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected),
            arpStatus: ARPMonitorStatus(isSpoofingDetected: false, message: "", previousMAC: nil, currentMAC: nil),
            listeningPorts: [], activeSecurityLevel: .balanced)
        XCTAssertEqual(report.items.filter { $0.checkId == "backup_recency" }.count, 1)
    }
}
