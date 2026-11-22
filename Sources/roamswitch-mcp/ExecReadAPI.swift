// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Read API for the process-exec recorder's log.
//
// The log (`ExecRecorderPaths.logDir`) and the alert file are root-only
// (0700 / 0600): command lines can contain secrets, and a group- or
// world-readable file would expose them to every admin account. Everything that
// is not root reads through the privileged helper's XPC methods
// (`searchExecEvents`, `getProcessTree`, `getExecAlerts`, `verifyExecLog`),
// which the helper only serves to the validated main app (`ClientValidator`).
//
// This file holds the pure, testable pieces:
//   * Codable request/reply types carried over XPC (and the MCP mailbox),
//   * `ExecReadService`: what the helper does with a request (bounded reply),
//   * `ExecMCPMailbox`: how the separate, unprivileged MCP server process
//     obtains that data. The MCP server binary cannot connect to the helper
//     (its code signature is not the main app's), so it asks the running app
//     through a private per-user request/response directory; the app relays the
//     request over XPC, writes the reply as an owner-only file that the MCP
//     server reads and deletes. No exec data is stored outside the root-owned
//     log.

// MARK: - Request / reply types

public struct ExecSearchRequest: Codable, Equatable {
    public var text: String?
    public var pid: Int32?
    public var ppid: Int32?
    public var since: Double?
    public var until: Double?
    public var kind: String?
    public var signature: String?
    public var teamID: String?
    public var limit: Int
    /// nil/false = full-text match (the app's own UI). true = `text` is matched against
    /// the secret-masked command line only, with a minimum query length (MCP path; see
    /// `ExecCommandMasker`). Optional so an older app's request still decodes.
    public var maskedTextMatch: Bool?
    /// true: a repeat line of the log (`ExecRepeatFolder`) comes back as one record of kind `repeat` holding the runs
    /// that matched (the viewer and the MCP tool show it that way). nil/false: as one `exec` record per run, which is
    /// what a reader that predates repeat lines expects (an older helper ignores the field and has no repeat lines).
    public var foldRepeats: Bool?
    /// Set by the app for a request that came through the MCP mailbox: the user id of the account that asked. The reply then holds only that
    /// account's processes (`ExecViewerScope`). Optional so an older app's request still decodes; an older helper ignores it, which is why the
    /// app asks only a helper of its own build (`ExecMCPBridge`).
    public var viewerUID: UInt32?

    /// Hard cap on events per reply (the app's export uses the maximum; the MCP
    /// tools ask for at most 200).
    public static let maxLimit = 5000

    public init(text: String? = nil, pid: Int32? = nil, ppid: Int32? = nil, since: Double? = nil, until: Double? = nil,
                kind: String? = nil, signature: String? = nil, teamID: String? = nil, limit: Int = 50,
                maskedTextMatch: Bool? = nil, foldRepeats: Bool? = nil, viewerUID: UInt32? = nil) {
        self.viewerUID = viewerUID
        self.text = text
        self.pid = pid
        self.ppid = ppid
        self.since = since
        self.until = until
        self.kind = kind
        self.signature = signature
        self.teamID = teamID
        self.limit = limit
        self.maskedTextMatch = maskedTextMatch
        self.foldRepeats = foldRepeats
    }

    /// Untrusted input -> a clamped `ExecLogQuery` (helper side).
    public func toQuery() -> ExecLogQuery {
        ExecLogQuery(
            text: text.map { String($0.prefix(200)) },
            pid: pid, ppid: ppid, since: since, until: until,
            kind: kind.flatMap { ["exec", "fork", "exit"].contains($0) ? $0 : nil },
            signature: signature.flatMap { ExecSignatureClass(rawValue: $0) },
            teamID: teamID.map { String($0.prefix(32)) },
            limit: min(max(limit, 1), Self.maxLimit),
            maskedTextMatch: maskedTextMatch == true,
            foldRepeats: foldRepeats == true
        )
    }
}

public struct ExecSearchReply: Codable, Equatable {
    /// Newest first.
    public var events: [ExecEventRecord]
    public var scannedBytes: Int
    public var truncatedScan: Bool
    /// True when `events` was cut to keep the reply under `ExecReadService.maxReplyBytes`.
    public var truncatedReply: Bool
    public var segments: Int
    public var readable: Bool

    public init(events: [ExecEventRecord] = [], scannedBytes: Int = 0, truncatedScan: Bool = false,
                truncatedReply: Bool = false, segments: Int = 0, readable: Bool = false) {
        self.events = events
        self.scannedBytes = scannedBytes
        self.truncatedScan = truncatedScan
        self.truncatedReply = truncatedReply
        self.segments = segments
        self.readable = readable
    }
}

public struct ExecProcessTreeRequest: Codable, Equatable {
    public var pid: Int32
    /// Epoch seconds; nil = now.
    public var at: Double?
    /// 1...168.
    public var lookbackHours: Int
    /// As in `ExecSearchRequest`: the account that asked through the MCP mailbox; the tree is given only for that account's process.
    public var viewerUID: UInt32?

    public init(pid: Int32, at: Double? = nil, lookbackHours: Int = 24, viewerUID: UInt32? = nil) {
        self.viewerUID = viewerUID
        self.pid = pid
        self.at = at
        self.lookbackHours = lookbackHours
    }
}

public struct ExecProcessTreeReply: Codable, Equatable {
    public var readable: Bool
    public var truncatedScan: Bool
    public var tree: ExecProcessTree

    public init(readable: Bool, truncatedScan: Bool, tree: ExecProcessTree) {
        self.readable = readable
        self.truncatedScan = truncatedScan
        self.tree = tree
    }
}

// MARK: - What the helper does with a request

public enum ExecReadService {
    /// Upper bound of the encoded events in one reply.
    public static let maxReplyBytes = 8 * 1024 * 1024
    public static let maxAlerts = 200

    /// `pending`: the repeat lines the recorder has not written yet (`ExecRepeatFolder.pendingLines`), so a run is
    /// found as soon as it happened.
    public static func search(_ req: ExecSearchRequest, dir: URL, now: Date = Date(),
                              pending: [ExecEventRecord] = []) -> ExecSearchReply {
        var res: ExecLogSearchResult
        if let viewer = req.viewerUID {
            // A request from the MCP mailbox: only the asking account's processes (and root's, when one of the account's started them).
            var q = req.toQuery()
            let wanted = q.limit
            q.allowedUIDs = ExecViewerScope.firstPassUIDs(viewer)
            q.limit = ExecSearchRequest.maxLimit
            let first = ExecLogReader.search(dir: dir, query: q, pending: pending)
            let history = first.events.contains(where: { $0.uid == 0 })
                ? ExecLogReader.search(dir: dir, query: ExecLogQuery(since: (first.events.map(\.time).min() ?? 0) - ExecViewerScope.lookbackSecs,
                                                                  limit: ExecSearchRequest.maxLimit, allowedUIDs: ExecViewerScope.firstPassUIDs(viewer)),
                                       pending: pending).events
                : []
            res = first
            res.events = Array(ExecViewerScope.visible(first.events, viewer: viewer, history: history).prefix(wanted))
        } else {
            res = ExecLogReader.search(dir: dir, query: req.toQuery(), pending: pending)
        }
        var events: [ExecEventRecord] = []
        var bytes = 0
        var cut = false
        let encoder = JSONEncoder()
        for e in res.events {
            bytes += (try? encoder.encode(e))?.count ?? 0
            if bytes > maxReplyBytes { cut = true; break }
            events.append(e)
        }
        return ExecSearchReply(events: events, scannedBytes: res.scannedBytes, truncatedScan: res.truncatedScan,
                               truncatedReply: cut, segments: res.segments, readable: res.readable)
    }

    public static func processTree(_ req: ExecProcessTreeRequest, dir: URL, now: Date = Date(),
                                   pending: [ExecEventRecord] = []) -> ExecProcessTreeReply {
        let lookback = Double(min(max(req.lookbackHours, 1), 168)) * 3600
        let anchor = req.at ?? now.timeIntervalSince1970
        // Each run of a repeat line is its own process here (the default of the query).
        var res = ExecLogReader.search(dir: dir, query: ExecLogQuery(since: anchor - lookback, limit: ExecSearchRequest.maxLimit,
                                                                     allowedUIDs: req.viewerUID.map(ExecViewerScope.firstPassUIDs)),
                                       pending: pending)
        if let viewer = req.viewerUID {
            // The asking account's own process, or one that one of its processes started as root; and only its own and root's around it.
            let all = res.events
            guard ExecViewerScope.ownsProcess(pid: req.pid, at: req.at ?? anchor, viewer: viewer, history: all) else {
                return ExecProcessTreeReply(readable: res.readable, truncatedScan: res.truncatedScan,
                                            tree: ExecProcessTree(ancestors: [], node: nil, descendants: [], truncated: false))
            }
            res.events = all
        }
        let tree = ExecProcessTreeBuilder.build(records: res.events, pid: req.pid, at: req.at.map { $0 + 1 })
        return ExecProcessTreeReply(readable: res.readable, truncatedScan: res.truncatedScan || tree.truncated, tree: tree)
    }

    /// The newest `limit` alerts (oldest first) from the JSON Lines alert file.
    public static func alerts(path: String, limit: Int) -> [ExecAlert] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return [] }
        let decoder = JSONDecoder()
        let all = data.split(separator: 0x0A, omittingEmptySubsequences: true).compactMap {
            try? decoder.decode(ExecAlert.self, from: Data($0))
        }
        return Array(all.suffix(min(max(limit, 1), maxAlerts)))
    }
}

// MARK: - MCP server <-> app mailbox

public enum ExecMCPMailbox {
    public struct Request: Codable, Equatable {
        public var id: String
        /// "search" | "tree"
        public var op: String
        public var search: ExecSearchRequest?
        public var tree: ExecProcessTreeRequest?
        public var createdAt: Double

        public init(id: String = UUID().uuidString, op: String, search: ExecSearchRequest? = nil,
                    tree: ExecProcessTreeRequest? = nil, createdAt: Double = Date().timeIntervalSince1970) {
            self.id = id
            self.op = op
            self.search = search
            self.tree = tree
            self.createdAt = createdAt
        }
    }

    public struct Response: Codable, Equatable {
        public var id: String
        public var ok: Bool
        /// Stable machine code when `ok == false`: "pro_required" | "helper_unavailable" | "bad_request" | "rate_limited".
        public var error: String?
        public var search: ExecSearchReply?
        public var tree: ExecProcessTreeReply?

        public init(id: String, ok: Bool, error: String? = nil, search: ExecSearchReply? = nil, tree: ExecProcessTreeReply? = nil) {
            self.id = id
            self.ok = ok
            self.error = error
            self.search = search
            self.tree = tree
        }
    }

    /// How long the MCP server waits for the app to answer.
    public static let waitSecs: Double = 8
    /// Requests older than this are discarded unanswered.
    public static let staleSecs: Double = 30
    /// Tolerated clock difference between the writer and the claimer.
    static let futureSkewSecs: Double = 5
    static let maxRequestBytes = 64 * 1024
    static let maxResponseBytes = ExecReadService.maxReplyBytes + 1024 * 1024

    /// `~/Library/Application Support/RoamSwitch/ExecMCPIPC` of the current user.
    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/RoamSwitch/ExecMCPIPC", isDirectory: true)
    }

    /// Only canonical UUID strings are accepted as ids (they become file names).
    static func isValidID(_ id: String) -> Bool { UUID(uuidString: id) != nil }

    static func requestURL(_ id: String, dir: URL) -> URL { dir.appendingPathComponent("req-\(id).json") }
    static func responseURL(_ id: String, dir: URL) -> URL { dir.appendingPathComponent("resp-\(id).json") }

    /// Creates the directory (0700) if needed and refuses one that is not a
    /// real directory owned by the current user.
    /// `create: false` (the MCP server side) only checks and never makes the directory: it is the app that
    /// creates it, so a missing one means the app has not run and a read-only tool must leave no folder behind.
    @discardableResult
    static func prepare(dir: URL, create: Bool = true) -> Bool {
        let fm = FileManager.default
        if create { try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]) }
        guard let attrs = try? fm.attributesOfItem(atPath: dir.path),
              (attrs[.type] as? FileAttributeType) == .typeDirectory,
              (attrs[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() else { return false }
        try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
        return true
    }

    static func writeAtomic(_ data: Data, to url: URL) -> Bool {
        let tmp = url.deletingLastPathComponent().appendingPathComponent(".tmp-\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: tmp.path, contents: data, attributes: [.posixPermissions: 0o600]) else { return false }
        // rename(2) is atomic on the same volume and replaces an existing file.
        if rename(tmp.path, url.path) == 0 { return true }
        try? FileManager.default.removeItem(at: tmp)
        return false
    }

    /// Reads a regular file of at most `max` bytes without ever loading more (a same-user process
    /// could plant an arbitrarily large file). nil = missing, not a regular file, or too large.
    static func readBounded(_ url: URL, max: Int) -> Data? {
        guard let h = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? h.close() }
        var st = stat()
        guard fstat(h.fileDescriptor, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG, Int(st.st_size) <= max else { return nil }
        guard let data = try? h.read(upToCount: max + 1), data.count <= max else { return nil }
        return data
    }

    // MARK: MCP-server side

    /// Writes `request`, waits up to `timeout` for the app's response file,
    /// reads and deletes it. `nil` = the app did not answer (not running, ...).
    public static func submitAndWait(_ request: Request, dir: URL = defaultDirectory, timeout: Double = waitSecs) -> Response? {
        guard isValidID(request.id), prepare(dir: dir, create: false),
              let data = try? JSONEncoder().encode(request), data.count <= maxRequestBytes else { return nil }
        let reqURL = requestURL(request.id, dir: dir)
        let respURL = responseURL(request.id, dir: dir)
        guard writeAtomic(data, to: reqURL) else { return nil }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let raw = readBounded(respURL, max: maxResponseBytes),
               let resp = try? JSONDecoder().decode(Response.self, from: raw), resp.id == request.id {
                try? FileManager.default.removeItem(at: respURL)
                return resp
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        try? FileManager.default.removeItem(at: reqURL)
        try? FileManager.default.removeItem(at: respURL)
        return nil
    }

    // MARK: App side

    /// Claims (reads and deletes) every pending well-formed request; stale or
    /// malformed request files, and old orphaned responses, are removed.
    public static func claimPendingRequests(dir: URL = defaultDirectory, now: Date = Date()) -> [Request] {
        let fm = FileManager.default
        guard prepare(dir: dir), let names = try? fm.contentsOfDirectory(atPath: dir.path) else { return [] }
        var out: [Request] = []
        for name in names {
            let url = dir.appendingPathComponent(name)
            if name.hasPrefix("resp-") || name.hasPrefix(".tmp-") {
                if let m = (try? fm.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date, now.timeIntervalSince(m) > staleSecs * 2 {
                    try? fm.removeItem(at: url)
                }
                continue
            }
            guard name.hasPrefix("req-"), name.hasSuffix(".json") else { continue }
            let raw = readBounded(url, max: maxRequestBytes)
            try? fm.removeItem(at: url)
            guard let raw, raw.count <= maxRequestBytes,
                  let req = try? JSONDecoder().decode(Request.self, from: raw),
                  isValidID(req.id), name == "req-\(req.id).json",
                  // Neither stale nor from the future (a far-future createdAt would never expire).
                  case let age = now.timeIntervalSince1970 - req.createdAt, age >= -futureSkewSecs, age <= staleSecs else { continue }
            out.append(req)
        }
        return out
    }

    public static func writeResponse(_ response: Response, dir: URL = defaultDirectory) {
        guard isValidID(response.id), prepare(dir: dir),
              let data = try? JSONEncoder().encode(response), data.count <= maxResponseBytes else { return }
        _ = writeAtomic(data, to: responseURL(response.id, dir: dir))
    }
}

// MARK: - What an account may see of the log

/// The exec log is root-only and holds every account's processes. A request that came through the MCP mailbox (any process of the account can
/// put one there, `ExecMCPBridge`) gets only the asking account's own:
///  - a record whose process has the account's user id;
///  - a record of root's (uid 0: `sudo` itself is setuid root, and what it runs) only when one of its ancestors, at that time, was the
///    account's own process: the account's own `sudo` and what it ran, not another administrator's.
/// Every other account's processes, and root's that the account did not start, are left out. The ancestors are looked for in the log of the
/// last `lookbackSecs` before the first record; one that began earlier is not found and its root children are left out (the safe side).
public enum ExecViewerScope {
    public static let lookbackSecs: Double = 6 * 3600
    public static let maxDepth = 32

    public static func firstPassUIDs(_ viewer: UInt32) -> Set<UInt32> { [viewer, 0] }

    /// The record of `pid` in force at `time`: the newest one not after it.
    private static func latest(pid: Int32, at time: Double, in byPid: [Int32: [ExecEventRecord]]) -> ExecEventRecord? {
        byPid[pid]?.last { $0.time <= time }
    }

    private static func index(_ history: [ExecEventRecord]) -> [Int32: [ExecEventRecord]] {
        var m: [Int32: [ExecEventRecord]] = [:]
        for r in history where r.kind == "exec" || r.kind == "fork" || r.kind == "repeat" { m[r.pid, default: []].append(r) }
        for k in m.keys { m[k]?.sort { ($0.time, $0.seq) < ($1.time, $1.seq) } }
        return m
    }

    private static func ancestorIsViewers(of r: ExecEventRecord, viewer: UInt32, index: [Int32: [ExecEventRecord]]) -> Bool {
        var current = r.ppid
        var at = r.time
        for _ in 0..<maxDepth {
            guard current > 1, let rec = latest(pid: current, at: at, in: index) else { return false }
            if rec.uid == viewer { return true }
            current = rec.ppid
            at = rec.time
        }
        return false
    }

    public static func visible(_ events: [ExecEventRecord], viewer: UInt32, history: [ExecEventRecord]) -> [ExecEventRecord] {
        let idx = index(history + events)
        return events.filter { r in
            if r.uid == viewer { return true }
            return r.uid == 0 && ancestorIsViewers(of: r, viewer: viewer, index: idx)
        }
    }

    /// The process `pid` (at `time`) is the account's own, or root's and started by one of the account's.
    public static func ownsProcess(pid: Int32, at time: Double, viewer: UInt32, history: [ExecEventRecord]) -> Bool {
        let idx = index(history)
        guard let rec = latest(pid: pid, at: time + 1, in: idx) else { return false }
        if rec.uid == viewer { return true }
        return rec.uid == 0 && ancestorIsViewers(of: rec, viewer: viewer, index: idx)
    }
}
