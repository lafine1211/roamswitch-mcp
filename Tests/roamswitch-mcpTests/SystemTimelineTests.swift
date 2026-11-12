// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.31 (build 210). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The daily record of listeners, Homebrew packages and configuration hashes, and `get_system_timeline` (adoption
/// plan P2, the Linux edition's `roamswitch timeline --since`).
final class SystemTimelineTests: XCTestCase {
    private var dir: URL!
    private let t0 = Date(timeIntervalSince1970: 1_790_000_000)
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-systl-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    private func snap(_ dayOffset: Int, listeners: [String]? = ["tcp *:22 sshd"], others: [String]? = nil,
                      packages: [String]? = ["git 2.50.0"], configs: [String: String] = ["/etc/hosts": "sha256:aa"]) -> SystemTimelineSnapshot {
        let at = t0.addingTimeInterval(Double(dayOffset) * 86_400)
        return SystemTimelineSnapshot(day: SystemTimeline.dayString(at, calendar: utc), takenAt: at, listeners: listeners,
                                      otherUserListeners: others, packages: packages, configs: configs)
    }

    // MARK: Differences

    func testTheChangeListsWhatWasAddedRemovedAndChanged() {
        let a = snap(0, listeners: ["tcp *:22 sshd", "tcp 127.0.0.1:5432 postgres"], others: ["tcp *:88 kdc"],
                     packages: ["git 2.50.0", "openssl@3 3.5.0", "wget 1.25.0"], configs: ["/etc/hosts": "sha256:aa", "~/.zshrc": "missing"])
        let b = snap(1, listeners: ["tcp *:22 sshd", "tcp *:4444 nc"], others: ["tcp *:88 kdc"],
                     packages: ["git 2.51.0", "openssl@3 3.5.0", "nmap 7.98"], configs: ["/etc/hosts": "sha256:bb", "~/.zshrc": "missing"])
        let c = SystemTimeline.change(from: a, to: b)
        XCTAssertEqual(c.listenersAdded, ["tcp *:4444 nc"])
        XCTAssertEqual(c.listenersRemoved, ["tcp 127.0.0.1:5432 postgres"])
        XCTAssertEqual(c.packagesAdded, ["nmap 7.98"])
        XCTAssertEqual(c.packagesRemoved, ["wget 1.25.0"])
        XCTAssertEqual(c.packagesChanged, ["git: 2.50.0 -> 2.51.0"])
        XCTAssertEqual(c.configsChanged, ["/etc/hosts: sha256:aa -> sha256:bb"])
        XCTAssertEqual(c.notCompared, [])
        XCTAssertFalse(c.isEmpty)
        XCTAssertTrue(SystemTimeline.change(from: a, to: a).isEmpty)
    }

    func testASideThatCouldNotBeListedIsNotCompared() {
        let c = SystemTimeline.change(from: snap(0, others: ["tcp *:88 kdc"], packages: nil), to: snap(1, others: nil, packages: ["git 2.50.0"]))
        XCTAssertEqual(c.notCompared, ["otherUserListeners", "packages"])
        XCTAssertEqual(c.listenersAdded, [])
        XCTAssertEqual(c.packagesAdded, [])
    }

    func testAConfigThatAppearsOrGoesIsAChange() {
        let c = SystemTimeline.change(from: snap(0, configs: [:]), to: snap(1, configs: ["~/.ssh/authorized_keys": "sha256:cc"]))
        XCTAssertEqual(c.configsChanged, ["~/.ssh/authorized_keys: missing -> sha256:cc"])
    }

    // MARK: Window and since

    func testTheWindowKeepsTheSnapshotBeforeSinceAsTheBase() {
        let all = (0..<5).map { snap($0) }
        let w = SystemTimeline.window(all, since: all[3].day)
        XCTAssertEqual(w.snapshots.map(\.day), [all[2].day, all[3].day, all[4].day])
        XCTAssertEqual(w.changes.count, 2)
        XCTAssertEqual(SystemTimeline.window(all, since: nil).snapshots.count, 5)
        XCTAssertEqual(SystemTimeline.window(all, since: "2099-01-01").snapshots.map(\.day), [all[4].day], "only the newest, as the base")
        XCTAssertEqual(SystemTimeline.window([], since: "2026-01-01").snapshots, [])
    }

    func testSinceIsADayOrANumberOfDays() {
        XCTAssertEqual(SystemTimeline.parseSince("2026-11-01"), "2026-11-01")
        XCTAssertEqual(SystemTimeline.parseSince("7d", now: t0, calendar: utc), SystemTimeline.dayString(t0.addingTimeInterval(-7 * 86_400), calendar: utc))
        XCTAssertNil(SystemTimeline.parseSince("yesterday"))
        XCTAssertNil(SystemTimeline.parseSince("2026-1-1"))
        XCTAssertNil(SystemTimeline.parseSince("-3d"))
    }

    // MARK: Store

    func testOneSnapshotADayIsKeptPrivatelyAndCapped() throws {
        let path = dir.appendingPathComponent("system_timeline.json").path
        XCTAssertTrue(SystemTimeline.append(snap(0), path: path))
        XCTAssertFalse(SystemTimeline.append(snap(0, listeners: []), path: path), "the first of the day stays")
        let mode = (try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
        XCTAssertEqual(mode, 0o600)
        for d in 1...(SystemTimeline.maxSnapshots + 5) { XCTAssertTrue(SystemTimeline.append(snap(d), path: path)) }
        let kept = SystemTimeline.load(path: path).value(or: [])
        XCTAssertEqual(kept.count, SystemTimeline.maxSnapshots)
        XCTAssertEqual(kept.last?.day, snap(SystemTimeline.maxSnapshots + 5).day)
        XCTAssertEqual(kept.first?.listeners, ["tcp *:22 sshd"])
    }

    func testADamagedFileIsKeptAsideBeforeANewSnapshot() throws {
        let path = dir.appendingPathComponent("system_timeline.json").path
        try Data("[{\"day\": 1".utf8).write(to: URL(fileURLWithPath: path))
        XCTAssertTrue(SystemTimeline.load(path: path).isUnreadable)
        XCTAssertTrue(SystemTimeline.append(snap(0), path: path))
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(names.contains { $0.hasPrefix("system_timeline.json.corrupt-") })
    }

    // MARK: Hashing files

    func testFileStates() throws {
        let file = dir.appendingPathComponent("hosts").path
        try Data("127.0.0.1 localhost\n".utf8).write(to: URL(fileURLWithPath: file))
        XCTAssertEqual(SystemTimeline.fileState(file), "sha256:" + SystemTimeline.digest(Data("127.0.0.1 localhost\n".utf8)))
        XCTAssertEqual(SystemTimeline.fileState(dir.appendingPathComponent("none").path), "missing")
        let link = dir.appendingPathComponent("link").path
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: file)
        XCTAssertEqual(SystemTimeline.fileState(link), "sha256:" + SystemTimeline.digest("symlink:" + file), "a link is its target, not the file read through it")
        chmod(file, 0o000)
        defer { chmod(file, 0o644) }
        if geteuid() != 0 { XCTAssertEqual(SystemTimeline.fileState(file), "unreadable") }
    }

    func testAFolderOfNamesChangesWhenAnEntryIsAdded() throws {
        let folder = dir.appendingPathComponent("LaunchAgents").path
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let source = SystemTimeline.ConfigSource(name: "x", path: folder, folder: true, namesOnly: true)
        let before = SystemTimeline.folderState(source)
        try Data("a".utf8).write(to: URL(fileURLWithPath: folder + "/com.evil.agent.plist"))
        XCTAssertNotEqual(SystemTimeline.folderState(source), before)
        let withContent = SystemTimeline.ConfigSource(name: "y", path: folder, folder: true)
        let first = SystemTimeline.folderState(withContent)
        try Data("b".utf8).write(to: URL(fileURLWithPath: folder + "/com.evil.agent.plist"))
        XCTAssertNotEqual(SystemTimeline.folderState(withContent), first, "a folder with content is hashed by its files too")
    }

    func testListenerAndPackageLinesCarryNoPid() {
        let l = [ListeningPortInfo(processName: "nc", pid: 77, port: 4444, isGloballyExposed: true, executablePath: nil),
                 ListeningPortInfo(processName: "nc", pid: 78, port: 4444, isGloballyExposed: true, executablePath: nil)]
        XCTAssertEqual(SystemTimeline.listenerLines(l), ["tcp *:4444 nc"])
        let p = SystemTimeline.packageLines([.init(name: "node", version: "24.1.0"), .init(name: "git", version: "2.50.0"),
                                             .init(name: "node", version: "22.3.0")])
        XCTAssertEqual(p, ["git 2.50.0", "node 22.3.0,24.1.0"])
    }

    // MARK: MCP payload

    func testThePayloadShowsOnlyTheStepsThatChangedAndComparesNow() {
        let all = [snap(0), snap(1), snap(2, listeners: ["tcp *:22 sshd", "tcp *:4444 nc"])]
        let now = snap(3, packages: ["git 2.51.0"])
        let p = SystemTimeline.mcpPayload(read: .loaded(all), since: nil, current: now)
        XCTAssertEqual(p.recordFile, "ok")
        XCTAssertEqual(p.snapshotCount, 3)
        XCTAssertEqual(p.changes.map(\.to), [all[2].day])
        XCTAssertEqual(p.current?.comparedWith, all[2].day)
        XCTAssertEqual(p.current?.change?.listenersRemoved, ["tcp *:4444 nc"])
        XCTAssertEqual(p.current?.change?.packagesChanged, ["git: 2.50.0 -> 2.51.0"])
        XCTAssertEqual(p.caveats.count, 2)
        let unreadable = SystemTimeline.mcpPayload(read: .unreadable(.corrupt), since: nil, current: nil)
        XCTAssertEqual(unreadable.recordFile, "unreadable")
        XCTAssertNil(unreadable.current)
        XCTAssertEqual(unreadable.caveats.count, 2)
    }
}
