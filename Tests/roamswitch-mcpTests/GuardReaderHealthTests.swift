// Mirrored from RoamSwitchTests/ — RoamSwitch 1.14.0 (build 173). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `GuardReaderHealth`: the counted record of input a guard's reader lost, how it is stored, and the one word
/// (`liveState`) it becomes in `get_guard_status` and `get_detection_coverage`.
final class GuardReaderHealthTests: XCTestCase {

    // MARK: Transitions

    func testAnUnexpectedEndOpensOneGapAndARestartClosesIt() {
        var h = GuardReaderHealth()
        h.markStarted(now: 100)
        XCTAssertTrue(h.active)
        XCTAssertEqual(h.gaps, 0)

        h.markEnded(now: 200)
        XCTAssertEqual(h.gaps, 1)
        XCTAssertEqual(h.lastGapAt, 200)
        XCTAssertTrue(h.inGap)

        h.markEnded(now: 210)                       // still the same gap
        XCTAssertEqual(h.gaps, 1)

        h.markRestarting(now: 202)
        h.markStarted(now: 202)
        XCTAssertEqual(h.restarts, 1)
        XCTAssertEqual(h.lastRestartAt, 202)
        XCTAssertFalse(h.inGap)
        XCTAssertFalse(h.unreadable)

        h.markEnded(now: 300)
        XCTAssertEqual(h.gaps, 2)
    }

    func testAReaderThatCannotStartIsUnreadableUntilItReads() {
        var h = GuardReaderHealth()
        h.markUnreadable(reason: "reader_not_running", now: 10)
        XCTAssertTrue(h.unreadable)
        XCTAssertEqual(h.reason, "reader_not_running")
        XCTAssertEqual(h.gaps, 1, "switched on but never reading is a gap from the start")
        h.markUnreadable(reason: "start_refused", now: 70)
        XCTAssertEqual(h.gaps, 1, "retrying does not count a new gap")
        XCTAssertEqual(h.reason, "start_refused")
        h.markStarted(now: 80)
        XCTAssertFalse(h.unreadable)
        XCTAssertNil(h.reason)
    }

    func testAnIntentionalStopIsNotAGap() {
        var h = GuardReaderHealth()
        h.markStarted(now: 1)
        h.markStopped(now: 2)
        XCTAssertFalse(h.active)
        XCTAssertEqual(h.gaps, 0)
        // A stop while down closes the gap state without hiding that it happened.
        h.markStarted(now: 3); h.markEnded(now: 4); h.markStopped(now: 5)
        XCTAssertEqual(h.gaps, 1)
        XCTAssertFalse(h.inGap)
    }

    func testDropCountersExistOnlyWhereTheStepDoes() {
        var h = GuardReaderHealth()
        XCTAssertNil(h.linesDropped)
        XCTAssertNil(h.oversizeDropped)
        h.addDropped(0, now: 1)
        XCTAssertNil(h.linesDropped, "nothing dropped, nothing invented")
        h.enableDropCounters()
        XCTAssertEqual(h.linesDropped, 0)
        h.addDropped(3, now: 2)
        h.addDropped(2, now: 3)
        h.addOversize(now: 4)
        XCTAssertEqual(h.linesDropped, 5)
        XCTAssertEqual(h.oversizeDropped, 1)
    }

    func testAProcessThatDiedWhileTheReaderRanLeavesAGapOnTheNextRun() {
        var prior = GuardReaderHealth()
        prior.markStarted(now: 50)
        prior.updatedAt = 120                       // last written at 120
        var h = prior
        h.markLostWhileProcessWasDown(now: 500)
        XCTAssertEqual(h.gaps, 1)
        XCTAssertEqual(h.lastGapAt, 120, "the gap began when the record was last written")
        XCTAssertEqual(h.restarts, 1)
        XCTAssertEqual(h.lastRestartAt, 500)

        var stopped = GuardReaderHealth()
        stopped.markStarted(now: 1); stopped.markStopped(now: 2)
        let before = stopped
        stopped.markLostWhileProcessWasDown(now: 500)
        XCTAssertEqual(stopped, before, "a clean stop leaves nothing to account for")
    }

    func testRecordsDecodeFromOlderOrSparseJSON() throws {
        let h = try JSONDecoder().decode(GuardReaderHealth.self, from: Data(#"{"restarts":2}"#.utf8))
        XCTAssertEqual(h.restarts, 2)
        XCTAssertEqual(h.gaps, 0)
        XCTAssertFalse(h.unreadable)
        let round = try JSONDecoder().decode(GuardReaderHealth.self, from: JSONEncoder().encode(h))
        XCTAssertEqual(round, h)
    }

    // MARK: Recorder

    func testRecorderPersistsOnForceAndThrottlesTheRest() {
        var written: [GuardReaderHealth] = []
        let r = GuardReaderHealthRecorder(source: "s", prior: nil, now: 0) { _, h in written.append(h) }
        XCTAssertTrue(written.isEmpty, "no prior record, nothing to write at creation")
        r.update(now: 100, force: true) { h, now in h.markStarted(now: now) }
        XCTAssertEqual(written.count, 1)
        r.update(now: 101) { h, now in h.addDropped(1, now: now) }
        r.update(now: 102) { h, now in h.addDropped(1, now: now) }
        XCTAssertEqual(written.count, 1, "within five seconds only the first change is written")
        XCTAssertEqual(r.snapshot.linesDropped, 2)
        r.flush()
        XCTAssertEqual(written.count, 2)
        XCTAssertEqual(written.last?.linesDropped, 2, "the last counter change is not left behind")
        r.update(now: 200) { h, now in h.addDropped(1, now: now) }
        XCTAssertEqual(written.count, 3, "after the interval the next change is written at once")
    }

    func testRecorderCountsTheGapOfAnUncleanPreviousRun() {
        var prior = GuardReaderHealth()
        prior.markStarted(now: 10)
        var written: [GuardReaderHealth] = []
        let r = GuardReaderHealthRecorder(source: "s", prior: prior, now: 900) { _, h in written.append(h) }
        XCTAssertEqual(r.snapshot.gaps, 1)
        XCTAssertEqual(written.count, 1, "the lost interval is written straight away")
    }

    // MARK: Storage

    private func tempPath() -> String {
        NSTemporaryDirectory() + "reader-health-\(UUID().uuidString).json"
    }

    func testHelperFileRoundTripsAndIsWorldReadable() throws {
        let path = tempPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        var a = GuardReaderHealth(); a.markUnreadable(reason: "launch_failed", now: 5)
        var b = GuardReaderHealth(); b.markStarted(now: 6)
        GuardReaderHealthStore.writeHelper(source: "portScanTcpdump", health: a, path: path)
        GuardReaderHealthStore.writeHelper(source: "linkSource", health: b, path: path)
        let read = GuardReaderHealthStore.readHelper(path: path)
        XCTAssertEqual(read["portScanTcpdump"], a)
        XCTAssertEqual(read["linkSource"], b)
        let mode = (try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
        XCTAssertEqual(mode, 0o644, "the app and the MCP server run as the user and read it")
        XCTAssertTrue(GuardReaderHealthStore.readHelper(path: "/nonexistent/x.json").isEmpty)
    }

    func testAppRecordsRoundTripThroughPreferences() {
        let suite = "com.tetsuharu.RoamSwitch.tests.reader-health"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        var h = GuardReaderHealth(); h.markEnded(now: 9)
        GuardReaderHealthStore.writeApp(source: "clickFixHistory", health: h, defaults: defaults)
        XCTAssertEqual(GuardReaderHealthStore.readApp(defaults: defaults)["clickFixHistory"], h)
        XCTAssertEqual(GuardReaderHealthStore.all(defaults: defaults, helperPath: "/nonexistent/x.json", execStatusPath: "/nonexistent/y.json")["clickFixHistory"], h)
    }

    func testExecRecorderHealthIsDerivedFromItsOwnStatus() {
        XCTAssertNil(GuardReaderHealthStore.health(fromExecRecorder: nil))
        var s = ExecRecorderStatus(state: "running", restartCount: 3, lastRestartAt: 777)
        s.eventsDropped = 12
        let ok = GuardReaderHealthStore.health(fromExecRecorder: s)!
        XCTAssertFalse(ok.unreadable)
        XCTAssertEqual(ok.restarts, 3)
        XCTAssertEqual(ok.gaps, 3)
        XCTAssertEqual(ok.lastGapAt, 777)
        XCTAssertEqual(ok.linesDropped, 12)
        for (state, reason) in [("needsFullDiskAccess", "permission"), ("esloggerMissing", "tool_missing"), ("failed", "too_many_restarts"), ("backoff", "restarting")] {
            let h = GuardReaderHealthStore.health(fromExecRecorder: ExecRecorderStatus(state: state))!
            XCTAssertTrue(h.unreadable, state)
            XCTAssertEqual(h.reason, reason, state)
        }
        XCTAssertFalse(GuardReaderHealthStore.health(fromExecRecorder: ExecRecorderStatus(state: "stopped"))!.active)
    }

    // MARK: liveState

    private func healthy(active: Bool = true) -> GuardReaderHealth { var h = GuardReaderHealth(); if active { h.markStarted(now: 1) }; return h }

    func testLiveStateWordsPerSituation() {
        let now = 1_000_000.0
        func state(_ key: String, on: Bool = true, _ records: [String: GuardReaderHealth]) -> String {
            GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: on, records: records, now: now)
        }
        XCTAssertEqual(state("sshGuard", on: false, [:]), "off")
        XCTAssertEqual(state("usbKeyboardGuard", [:]), "on", "a guard with no reader to check follows its toggle")
        XCTAssertEqual(state("sshGuard", [:]), "unknown", "never reported: not shown as healthy")
        XCTAssertEqual(state("sshGuard", ["sshLogStream": healthy()]), "on")

        var down = healthy(); down.markUnreadable(reason: "reader_not_running", now: now - 5)
        XCTAssertEqual(state("sshGuard", ["sshLogStream": down]), "off", "reader down is never on")

        var recentGap = healthy(); recentGap.markEnded(now: now - 3600); recentGap.markStarted(now: now - 3590)
        XCTAssertEqual(state("sshGuard", ["sshLogStream": recentGap]), "partial")
        var oldGap = healthy(); oldGap.markEnded(now: now - 3 * 86_400); oldGap.markStarted(now: now - 3 * 86_400 + 5)
        XCTAssertEqual(state("sshGuard", ["sshLogStream": oldGap]), "on", "an old, closed gap is counted but no longer marks the guard")
    }

    func testIdleIsHealthyOnlyWhereTheGuardHasNothingToReadByDesign() {
        let now = 5_000.0
        let idle = healthy(active: false)
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "sshGuard", enabledInSettings: true, records: ["sshLogStream": idle], now: now), "on",
                       "the SSH guard reads only while Remote Login is on")
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "runtimeThreatContainment", enabledInSettings: true, records: ["runtimeThreatLogStream": idle], now: now), "off")
    }

    func testAnAuxiliaryInputDownOnlyMakesTheGuardPartial() {
        let now = 5_000.0
        var link = healthy(); link.markUnreadable(reason: "too_many_restarts", now: now - 10)
        let scan = healthy()
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "portScanGuard", enabledInSettings: true, records: ["portScanTcpdump": scan, "linkSource": link], now: now), "partial")
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "portScanGuard", enabledInSettings: true, records: ["portScanTcpdump": scan], now: now), "on",
                       "a link-source record that does not exist is not held against the guard")
        var main = healthy(); main.markUnreadable(reason: "launch_failed", now: now)
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "portScanGuard", enabledInSettings: true, records: ["portScanTcpdump": main, "linkSource": healthy()], now: now), "off")
    }

    func testEveryReaderBackedGuardExistsInTheGuardStatusVocabulary() {
        let suite = "com.tetsuharu.RoamSwitch.tests.reader-health-vocab"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let keys = Set(MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults, readerHealth: [:]).guards.map(\.key))
        for key in GuardReaderHealthStore.guardSources.keys { XCTAssertTrue(keys.contains(key), key) }
    }

    // MARK: FSEvents watches and unreadable files

    func testAWatchThatCannotStartMeansOffWhenItIsTheOnlyInputAndPartialWhenATimerBacksItUp() {
        let now = 9_000.0
        var failed = healthy(); failed.markUnreadable(reason: "watch_failed", now: now - 1)
        let onlyInput: [(guard: String, source: String)] = [
            ("ransomwareEntropyGuard", "ransomwareEntropyFSEvents"), ("persistenceMonitor", "persistenceMonitorFSEvents"),
            ("webMailDownloadGuard", "webMailDownloadFSEvents"), ("browserCredentialWatchGuard", "browserCredentialWatchFSEvents"),
        ]
        for (key, source) in onlyInput {
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [source: failed], now: now), "off", key)
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [source: healthy()], now: now), "on", key)
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [:], now: now), "unknown", key)
        }
        // A timer scan still runs, so losing only the trigger is partial, never on.
        for (key, main, aux) in [("criticalPathFim", "criticalPathFimHelper", "criticalPathFimFSEvents"), ("lockfileTamperGuard", "lockfileTamperScan", "lockfileTamperFSEvents")] {
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [main: healthy(), aux: failed], now: now), "partial", key)
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [main: healthy(), aux: healthy()], now: now), "on", key)
            var scanDown = healthy(); scanDown.markUnreadable(reason: "helper_unreachable", now: now)
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: [main: scanDown, aux: healthy()], now: now), "off", key)
        }
    }

    func testTheDownloadGuardIsPartialWhileTheLastStaticScanSkippedSomethingAndOnAgainWhenItDidNot() {
        let now = 9_000.0
        var skipped = GuardReaderHealth()
        skipped.setScanResult(filesUnreadable: 2, foldersUnreadable: 0, filesTruncated: 0, now: now - 5)
        var truncated = GuardReaderHealth()
        truncated.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 1, now: now - 5)
        var clean = GuardReaderHealth()
        clean.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 0, now: now - 5)
        let key = "webMailDownloadGuard"
        XCTAssertTrue(GuardReaderHealthStore.sourceIDs(forGuard: key).contains("staticSignatureScan"))
        for (name, record, expected) in [("skipped", skipped, "partial"), ("truncated", truncated, "partial"), ("clean", clean, "on")] {
            XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true,
                                                                 records: ["webMailDownloadFSEvents": healthy(), "staticSignatureScan": record], now: now), expected, name)
        }
        // No batch yet: not held against the guard.
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: ["webMailDownloadFSEvents": healthy()], now: now), "on")
        // The watch itself failing still wins.
        var failed = healthy(); failed.markUnreadable(reason: "watch_failed", now: now - 1)
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: true, records: ["webMailDownloadFSEvents": failed, "staticSignatureScan": clean], now: now), "off")
    }

    func testFilesUnreadableIsTheLastScansCountWithTheTimeSomethingWasLastSkipped() {
        var h = GuardReaderHealth()
        XCTAssertNil(h.filesUnreadable)
        h.enableFileCounter()
        XCTAssertEqual(h.filesUnreadable, 0)
        XCTAssertNil(h.filesUnreadableAt, "nothing skipped yet")
        h.setFilesUnreadable(3, now: 100)
        XCTAssertEqual(h.filesUnreadable, 3)
        XCTAssertEqual(h.filesUnreadableAt, 100)
        h.setFilesUnreadable(0, now: 200)
        XCTAssertEqual(h.filesUnreadable, 0, "replaced, not accumulated")
        XCTAssertEqual(h.filesUnreadableAt, 100, "the time stays at the last scan that skipped something")
        let round = try? JSONDecoder().decode(GuardReaderHealth.self, from: JSONEncoder().encode(h))
        XCTAssertEqual(round, h)
        let old = try? JSONDecoder().decode(GuardReaderHealth.self, from: Data(#"{"active":true}"#.utf8))
        XCTAssertNil(old?.filesUnreadable, "records written before this field existed still decode")
    }

    func testASkippedFileMakesTheGuardPartialUntilTheNextCleanScan() {
        let now = 50_000.0
        var scan = healthy(); scan.enableFileCounter(); scan.setFilesUnreadable(2, now: now - 10)
        func state(_ h: GuardReaderHealth) -> String {
            GuardReaderHealthStore.guardLiveState(guardKey: "ransomwareCanaryGuard", enabledInSettings: true, records: ["ransomwareCanaryFiles": h], now: now)
        }
        XCTAssertEqual(state(scan), "partial", "some files were not looked at")
        scan.setFilesUnreadable(0, now: now - 5)
        XCTAssertEqual(state(scan), "on")
    }

    func testAFolderScanThatSkippedFoldersOrTruncatedFilesIsPartialUntilACleanScan() {
        let now = 70_000.0
        func state(_ h: GuardReaderHealth) -> String {
            GuardReaderHealthStore.guardLiveState(guardKey: "webRulesFolderScan", enabledInSettings: true, records: ["webRuleFolderScan": h], now: now)
        }
        var h = healthy()
        h.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 0, now: now - 100)
        XCTAssertEqual(state(h), "on")
        h.setScanResult(filesUnreadable: 0, foldersUnreadable: 1, filesTruncated: 0, now: now - 90)
        XCTAssertEqual(state(h), "partial", "a folder was not listed")
        h.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 2, now: now - 80)
        XCTAssertEqual(state(h), "partial", "only the start of two files was read")
        h.setScanResult(filesUnreadable: 1, foldersUnreadable: 0, filesTruncated: 0, now: now - 70)
        XCTAssertEqual(state(h), "partial")
        XCTAssertEqual(h.filesUnreadableAt, now - 70)
        h.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 0, now: now - 60)
        XCTAssertEqual(state(h), "on")
        XCTAssertEqual(h.filesUnreadableAt, now - 70, "the last skip is remembered")
        XCTAssertEqual(GuardReaderHealthStore.guardLiveState(guardKey: "webRulesFolderScan", enabledInSettings: true, records: [:], now: now), "unknown",
                       "no scan has reported yet")
    }

    func testGuardStatusListsTheWebRulesFolderScanWithItsCounts() throws {
        var h = healthy(); h.setScanResult(filesUnreadable: 2, foldersUnreadable: 1, filesTruncated: 3, now: 999_000)
        let suite = "com.tetsuharu.RoamSwitch.tests.reader-health-webscan"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "RoamSwitch.IsProCache")
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults, readerHealth: ["webRuleFolderScan": h],
                                                                    now: Date(timeIntervalSince1970: 1_000_000))
        let scan = try XCTUnwrap(payload.guards.first { $0.key == "webRulesFolderScan" })
        XCTAssertTrue(scan.enabledInSettings)
        XCTAssertEqual(scan.liveState, "partial")
        let reader = try XCTUnwrap(scan.readers?.first)
        XCTAssertEqual(reader.filesUnreadable, 2)
        XCTAssertEqual(reader.foldersUnreadable, 1)
        XCTAssertEqual(reader.filesTruncated, 3)
        // Free: no daily scan runs.
        defaults.set(false, forKey: "RoamSwitch.IsProCache")
        let free = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults, readerHealth: [:])
        XCTAssertEqual(free.guards.first { $0.key == "webRulesFolderScan" }?.liveState, "off")
    }

    func testGuardStatusShowsTheUnreadableFileCount() throws {
        var h = healthy(); h.enableFileCounter(); h.setFilesUnreadable(4, now: 999_000)
        let suite = "com.tetsuharu.RoamSwitch.tests.reader-health-files"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: MCPResponseFormatting.ransomwareCanaryGuardKey)
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults, readerHealth: ["ransomwareCanaryFiles": h],
                                                                    now: Date(timeIntervalSince1970: 1_000_000))
        let canary = try XCTUnwrap(payload.guards.first { $0.key == "ransomwareCanaryGuard" })
        let reader = try XCTUnwrap(canary.readers?.first)
        XCTAssertEqual(reader.source, "ransomwareCanaryFiles")
        XCTAssertEqual(reader.filesUnreadable, 4)
        XCTAssertNotNil(reader.filesUnreadableAt)
        XCTAssertTrue(canary.enabledInSettings)
        XCTAssertEqual(canary.liveState, "partial")
    }

    // MARK: get_guard_status and get_detection_coverage

    private func guardStatus(_ records: [String: GuardReaderHealth], enabled: [String: Bool]) -> MCPGuardStatusPayload {
        let suite = "com.tetsuharu.RoamSwitch.tests.reader-health-status"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(enabled["sshGuard"] ?? false, forKey: MCPResponseFormatting.sshGuardKey)
        defaults.set(enabled["execRecorder"] ?? false, forKey: MCPResponseFormatting.execRecorderKey)
        return MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: defaults, readerHealth: records, now: Date(timeIntervalSince1970: 1_000_000))
    }

    func testGuardStatusShowsAReaderThatCannotReadInsteadOfLookingHealthy() throws {
        var down = healthy(); down.markUnreadable(reason: "start_refused", now: 999_990); down.enableDropCounters(); down.addDropped(4, now: 999_991)
        let payload = guardStatus(["sshLogStream": down], enabled: ["sshGuard": true])
        let ssh = try XCTUnwrap(payload.guards.first { $0.key == "sshGuard" })
        XCTAssertTrue(ssh.enabledInSettings, "the toggle is on")
        XCTAssertEqual(ssh.liveState, "off", "but it cannot read its source")
        let reader = try XCTUnwrap(ssh.readers?.first)
        XCTAssertEqual(reader.source, "sshLogStream")
        XCTAssertTrue(reader.unreadable)
        XCTAssertEqual(reader.reason, "start_refused")
        XCTAssertEqual(reader.gaps, 1)
        XCTAssertEqual(reader.linesDropped, 4)
        XCTAssertNotNil(reader.lastGapAt)

        let plain = try XCTUnwrap(payload.guards.first { $0.key == "usbKeyboardGuard" })
        XCTAssertNil(plain.readers)
        XCTAssertEqual(plain.liveState, plain.enabledInSettings ? "on" : "off")
        XCTAssertTrue(payload.caveats.contains { $0.contains("liveState") })
    }

    func testGuardStatusReportsRestartsAndGapsOfAWorkingReader() throws {
        var h = healthy(); h.markEnded(now: 999_000); h.markRestarting(now: 999_002); h.markStarted(now: 999_002)
        let payload = guardStatus(["sshLogStream": h], enabled: ["sshGuard": true])
        let ssh = try XCTUnwrap(payload.guards.first { $0.key == "sshGuard" })
        XCTAssertEqual(ssh.liveState, "partial")
        XCTAssertEqual(ssh.readers?.first?.restarts, 1)
        XCTAssertEqual(ssh.readers?.first?.gaps, 1)
        XCTAssertEqual(ssh.readers?.first?.unreadable, false)
    }

    func testCoverageNeverCallsAGuardWithADeadReaderOn() throws {
        var down = ExecRecorderStatus(state: "needsFullDiskAccess")
        down.restartCount = 2
        let health = ["execRecorder": GuardReaderHealthStore.health(fromExecRecorder: down)!]
        let payload = guardStatus(health, enabled: ["execRecorder": true])
        let exec = try XCTUnwrap(payload.guards.first { $0.key == "execRecorder" })
        XCTAssertEqual(exec.liveState, "off")

        let coverage = DetectionCoverage.payload(guards: payload.guards)
        let gatekeeper = try XCTUnwrap(coverage.techniques.first { $0.id == "T1553.001" })
        XCTAssertEqual(gatekeeper.liveState, "off", "its only guard is the exec recorder, which cannot read")
        XCTAssertEqual(coverage.guards.first { $0.id == "execRecorder" }?.state, "off")
        XCTAssertGreaterThan(coverage.summary.coveredButOff, 0)

        // A reader with a recent gap makes a technique partial, never on.
        var gap = healthy(); gap.markEnded(now: 999_900); gap.markStarted(now: 999_901)
        let partialPayload = guardStatus(["execRecorder": gap], enabled: ["execRecorder": true])
        XCTAssertEqual(partialPayload.guards.first { $0.key == "execRecorder" }?.liveState, "partial")
        let partialCoverage = DetectionCoverage.payload(guards: partialPayload.guards)
        XCTAssertEqual(partialCoverage.techniques.first { $0.id == "T1553.001" }?.liveState, "partial")
    }
}
