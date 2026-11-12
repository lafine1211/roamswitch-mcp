// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit
import Darwin

/// A daily record of what this Mac listens on, what Homebrew has installed and the hashes of the main configuration
/// files, kept so a later look can say what changed and when (adoption plan P2, the Linux edition's
/// `roamswitch timeline --since`). The Mac has no command line of its own: the app takes one snapshot a day
/// (`SystemTimelineRecorder`) and the MCP tool `get_system_timeline` shows the changes. Nothing is sent anywhere.
///
/// Only names, versions, ports and hashes are kept: never the content of a configuration file.
public struct SystemTimelineSnapshot: Codable, Equatable {
    /// Local calendar day, `yyyy-MM-dd`.
    public let day: String
    public let takenAt: Date
    /// `proto host:port process` of this user's processes, sorted, one per distinct listener. nil when they could
    /// not be listed.
    public var listeners: [String]?
    /// The same for other users' processes (root daemons), which only the helper can see. nil when it did not answer
    /// (the MCP server has no helper connection).
    public var otherUserListeners: [String]?
    /// `name version`, sorted. nil when Homebrew could not be read; empty when it has nothing or is not installed.
    public var packages: [String]?
    /// Configuration name -> `sha256:<hex>`, `missing` or `unreadable`.
    public var configs: [String: String]

    public init(day: String, takenAt: Date, listeners: [String]?, otherUserListeners: [String]? = nil, packages: [String]?,
                configs: [String: String]) {
        self.day = day; self.takenAt = takenAt; self.listeners = listeners; self.otherUserListeners = otherUserListeners
        self.packages = packages; self.configs = configs
    }

    public var listenersHash: String? { listeners.map { SystemTimeline.digest($0.joined(separator: "\n")) } }
    public var otherUserListenersHash: String? { otherUserListeners.map { SystemTimeline.digest($0.joined(separator: "\n")) } }
    public var packagesHash: String? { packages.map { SystemTimeline.digest($0.joined(separator: "\n")) } }
    public var configsHash: String {
        SystemTimeline.digest(configs.keys.sorted().map { "\($0)=\(configs[$0] ?? "")" }.joined(separator: "\n"))
    }
}

/// What changed from one snapshot to the next.
public struct SystemTimelineChange: Codable, Equatable {
    public let from: String
    public let to: String
    public var listenersAdded: [String] = []
    public var listenersRemoved: [String] = []
    public var packagesAdded: [String] = []
    public var packagesRemoved: [String] = []
    /// `name: old -> new`.
    public var packagesChanged: [String] = []
    /// `name: old -> new` of the state (`sha256:…`, `missing`, `unreadable`).
    public var configsChanged: [String] = []
    /// A side could not be listed in one of the two, so its difference is unknown.
    public var notCompared: [String] = []

    public var isEmpty: Bool {
        listenersAdded.isEmpty && listenersRemoved.isEmpty && packagesAdded.isEmpty && packagesRemoved.isEmpty
            && packagesChanged.isEmpty && configsChanged.isEmpty && notCompared.isEmpty
    }
}

public enum SystemTimeline {
    public static let maxSnapshots = 90

    public static var storeURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
            .appendingPathComponent("system_timeline.json")
    }

    static func digest(_ s: String) -> String { digest(Data(s.utf8)) }
    static func digest(_ d: Data) -> String { SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined() }

    public static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Store

    public static func load(path: String = storeURL.path) -> StoredRecordRead<[SystemTimelineSnapshot]> {
        StoredRecordFile.read([SystemTimelineSnapshot].self, path: path)
    }

    /// Adds `snapshot` unless one for its day is already stored (one a day; the first of the day stays), keeping the
    /// newest `maxSnapshots`, oldest first. A file that cannot be read is copied aside first. `false` when nothing was saved.
    @discardableResult
    public static func append(_ snapshot: SystemTimelineSnapshot, path: String = storeURL.path) -> Bool {
        try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        return AtomicFile.withLock(path) {
            guard var all = StoredRecordFile.loadForUpdate([SystemTimelineSnapshot].self, path: path, empty: []) else { return false }
            guard !all.contains(where: { $0.day == snapshot.day }) else { return false }
            all.append(snapshot)
            all.sort { $0.takenAt < $1.takenAt }
            if all.count > maxSnapshots { all.removeFirst(all.count - maxSnapshots) }
            guard let data = try? JSONEncoder().encode(all) else { return false }
            return (try? AtomicFile.write(data, toPath: path, mode: 0o600)) != nil
        }
    }

    // MARK: Differences (pure)

    public static func change(from a: SystemTimelineSnapshot, to b: SystemTimelineSnapshot) -> SystemTimelineChange {
        var c = SystemTimelineChange(from: a.day, to: b.day)
        for (name, la, lb) in [("listeners", a.listeners, b.listeners), ("otherUserListeners", a.otherUserListeners, b.otherUserListeners)] {
            if let la, let lb {
                c.listenersAdded += lb.filter { !Set(la).contains($0) }
                c.listenersRemoved += la.filter { !Set(lb).contains($0) }
            } else if la != nil || lb != nil {
                c.notCompared.append(name)
            }
        }
        if let pa = a.packages, let pb = b.packages {
            let va = versions(pa), vb = versions(pb)
            for name in vb.keys.sorted() {
                guard let old = va[name] else { c.packagesAdded.append("\(name) \(vb[name] ?? "")"); continue }
                if old != vb[name] { c.packagesChanged.append("\(name): \(old) -> \(vb[name] ?? "")") }
            }
            for name in va.keys.sorted() where vb[name] == nil { c.packagesRemoved.append("\(name) \(va[name] ?? "")") }
        } else if a.packages != b.packages {
            c.notCompared.append("packages")
        }
        for name in Set(a.configs.keys).union(b.configs.keys).sorted() {
            let old = a.configs[name] ?? "missing", new = b.configs[name] ?? "missing"
            if old != new { c.configsChanged.append("\(name): \(old) -> \(new)") }
        }
        return c
    }

    /// `name version` lines -> name: version (several versions of one formula stay one value, as listed).
    static func versions(_ lines: [String]) -> [String: String] {
        var out: [String: String] = [:]
        for line in lines {
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            guard let name = parts.first else { continue }
            out[name] = parts.count > 1 ? parts[1] : ""
        }
        return out
    }

    /// The snapshots from `since` on (a local day, inclusive) and the changes between consecutive ones, oldest first.
    /// The snapshot just before `since` is kept as the base of the first change.
    public static func window(_ all: [SystemTimelineSnapshot], since: String?) -> (snapshots: [SystemTimelineSnapshot], changes: [SystemTimelineChange]) {
        let sorted = all.sorted { $0.takenAt < $1.takenAt }
        var start = 0
        if let since, let first = sorted.firstIndex(where: { $0.day >= since }) { start = max(first - 1, 0) }
        else if since != nil { start = max(sorted.count - 1, 0) }
        let shown = Array(sorted[start...])
        let changes = zip(shown, shown.dropFirst()).map { change(from: $0, to: $1) }
        return (shown, changes)
    }

    /// `yyyy-MM-dd`, or `<n>d` for that many days before `now`. nil for anything else.
    public static func parseSince(_ text: String, now: Date = Date(), calendar: Calendar = .current) -> String? {
        let t = text.trimmingCharacters(in: .whitespaces)
        if t.hasSuffix("d"), let n = Int(t.dropLast()), (0...3650).contains(n),
           let date = calendar.date(byAdding: .day, value: -n, to: now) {
            return dayString(date, calendar: calendar)
        }
        let parts = t.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return nil }
        return t
    }

    // MARK: Taking a snapshot

    /// The configuration files and folders that are hashed: name -> path. A folder marked `namesOnly` is hashed by
    /// the names in it (what is installed), any other folder by the names and hashes of its files.
    struct ConfigSource {
        let name: String
        let path: String
        var folder = false
        var namesOnly = false
    }

    static func configSources(home: String) -> [ConfigSource] {
        [
            ConfigSource(name: "/etc/hosts", path: "/etc/hosts"),
            ConfigSource(name: "/etc/ssh/sshd_config", path: "/etc/ssh/sshd_config"),
            ConfigSource(name: "/etc/ssh/sshd_config.d", path: "/etc/ssh/sshd_config.d", folder: true),
            ConfigSource(name: "/etc/pam.d", path: "/etc/pam.d", folder: true),
            ConfigSource(name: "/etc/sudoers", path: "/etc/sudoers"),
            ConfigSource(name: "/etc/sudoers.d", path: "/etc/sudoers.d", folder: true),
            ConfigSource(name: "~/.ssh/authorized_keys", path: home + "/.ssh/authorized_keys"),
            ConfigSource(name: "~/.ssh/config", path: home + "/.ssh/config"),
            ConfigSource(name: "~/.zshrc", path: home + "/.zshrc"),
            ConfigSource(name: "~/.zprofile", path: home + "/.zprofile"),
            ConfigSource(name: "~/.bash_profile", path: home + "/.bash_profile"),
            ConfigSource(name: "/Library/LaunchDaemons", path: "/Library/LaunchDaemons", folder: true, namesOnly: true),
            ConfigSource(name: "/Library/LaunchAgents", path: "/Library/LaunchAgents", folder: true, namesOnly: true),
            ConfigSource(name: "~/Library/LaunchAgents", path: home + "/Library/LaunchAgents", folder: true, namesOnly: true),
        ]
    }

    static let maxFileBytes = 4 * 1024 * 1024

    /// `sha256:<hex>` of a file (a symbolic link: of its target text, so a swapped link shows), `missing` or `unreadable`.
    static func fileState(_ path: String) -> String {
        var st = stat()
        guard lstat(path, &st) == 0 else { return errno == ENOENT ? "missing" : "unreadable" }
        if (st.st_mode & S_IFMT) == S_IFLNK {
            guard let target = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else { return "unreadable" }
            return "sha256:" + digest("symlink:" + target)
        }
        guard (st.st_mode & S_IFMT) == S_IFREG, st.st_size <= maxFileBytes else { return "unreadable" }
        let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { return "unreadable" }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        guard let data = try? handle.readToEnd() else { return "unreadable" }
        return "sha256:" + digest(data ?? Data())
    }

    static func folderState(_ source: ConfigSource) -> String {
        var st = stat()
        guard lstat(source.path, &st) == 0 else { return errno == ENOENT ? "missing" : "unreadable" }
        guard (st.st_mode & S_IFMT) == S_IFDIR, let names = try? FileManager.default.contentsOfDirectory(atPath: source.path) else {
            return "unreadable"
        }
        let lines = names.sorted().map { name in source.namesOnly ? name : name + "\t" + fileState(source.path + "/" + name) }
        return "sha256:" + digest(lines.joined(separator: "\n"))
    }

    static func configStates(home: String) -> [String: String] {
        var out: [String: String] = [:]
        for s in configSources(home: home) { out[s.name] = s.folder ? folderState(s) : fileState(s.path) }
        return out
    }

    /// `proto host:port process`, sorted and distinct.
    static func listenerLines(_ listeners: [ListeningPortInfo]) -> [String] {
        Array(Set(listeners.map { "\($0.proto) \($0.bindHost.isEmpty ? "*" : $0.bindHost):\($0.port) \($0.processName)" })).sorted()
    }

    static func packageLines(_ packages: [PackageCveScan.InstalledPackage]) -> [String] {
        var byName: [String: [String]] = [:]
        for p in packages where !byName[p.name, default: []].contains(p.version) { byName[p.name, default: []].append(p.version) }
        return byName.keys.sorted().map { "\($0) \(byName[$0]!.sorted().joined(separator: ","))" }
    }

    /// A snapshot of now. `otherUserListeners`: the root daemons' listeners from the helper, nil when it did not answer
    /// (the MCP server has no helper connection).
    static func capture(now: Date = Date(), otherUserListeners: [ListeningPortInfo]? = nil) -> SystemTimelineSnapshot {
        let monitor = ListeningPortMonitor.shared
        let own = monitor.scanListeningPortsFast() + monitor.scanUDPListenersFast()
        let inventory = PackageCveScan.enumerateHomebrewInventory()
        let packages: [String]?
        switch inventory.state {
        case .brewFailed: packages = nil
        case .brewMissing, .read: packages = packageLines(inventory.packages)
        }
        return SystemTimelineSnapshot(
            day: dayString(now), takenAt: now,
            listeners: own.isEmpty ? nil : listenerLines(own),
            otherUserListeners: otherUserListeners.map(listenerLines),
            packages: packages,
            configs: configStates(home: FileManager.default.homeDirectoryForCurrentUser.path))
    }
}

// MARK: - MCP `get_system_timeline`

public struct MCPSystemTimelineSnapshotPayload: Codable, Equatable {
    public let day: String
    public let takenAt: String
    public let listenerCount: Int?
    public let otherUserListenerCount: Int?
    public let packageCount: Int?
    public let listenersHash: String?
    public let otherUserListenersHash: String?
    public let packagesHash: String?
    public let configsHash: String
    public let configs: [String: String]
}

public struct MCPSystemTimelineCurrentPayload: Codable, Equatable {
    public let takenAt: String
    public let comparedWith: String?
    public let change: SystemTimelineChange?
}

public struct MCPSystemTimelinePayload: Codable, Equatable {
    public let since: String?
    /// `ok`, `missing` (no snapshot was ever taken) or `unreadable`.
    public let recordFile: String
    public let snapshotCount: Int
    public let snapshots: [MCPSystemTimelineSnapshotPayload]
    /// Only the steps where something changed, oldest first.
    public let changes: [SystemTimelineChange]
    public var current: MCPSystemTimelineCurrentPayload? = nil
    public var caveats: [String]
}

extension SystemTimeline {
    /// Pure: the answer of `get_system_timeline` from what was read. `current` is a snapshot taken now (nil when not asked).
    static func mcpPayload(read: StoredRecordRead<[SystemTimelineSnapshot]>, since: String?,
                           current: SystemTimelineSnapshot?) -> MCPSystemTimelinePayload {
        let iso = ISO8601DateFormatter()
        let all = read.value(or: [])
        let w = window(all, since: since)
        let recordFile: String
        switch read {
        case .missing: recordFile = "missing"
        case .loaded: recordFile = "ok"
        case .unreadable: recordFile = "unreadable"
        }
        var caveats = [locLLM("記録は RoamSwitch のアプリが1日1回取ります。設定ファイルの中身は保存せず、ハッシュだけを比べます。")]
        if recordFile == "unreadable" {
            caveats.append(locLLM("日次の記録のファイルを読めませんでした。snapshots が空でも、記録がなかったとは限りません。"))
        }
        var payload = MCPSystemTimelinePayload(
            since: since, recordFile: recordFile, snapshotCount: w.snapshots.count,
            snapshots: w.snapshots.map { s in
                MCPSystemTimelineSnapshotPayload(
                    day: s.day, takenAt: iso.string(from: s.takenAt), listenerCount: s.listeners?.count,
                    otherUserListenerCount: s.otherUserListeners?.count, packageCount: s.packages?.count,
                    listenersHash: s.listenersHash, otherUserListenersHash: s.otherUserListenersHash, packagesHash: s.packagesHash,
                    configsHash: s.configsHash, configs: s.configs)
            },
            changes: w.changes.filter { !$0.isEmpty },
            caveats: caveats)
        if let current {
            let base = all.max { $0.takenAt < $1.takenAt }
            payload.current = MCPSystemTimelineCurrentPayload(
                takenAt: iso.string(from: current.takenAt), comparedWith: base?.day,
                change: base.map { change(from: $0, to: current) })
            payload.caveats.append(locLLM("current はこの問い合わせの時点の状態です。MCP サーバーからは他のユーザー(root)のプロセスの待ち受けが見えないため、otherUserListeners は比べていません。"))
        }
        return payload
    }
}
