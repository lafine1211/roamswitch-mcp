// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.53 (build 114).
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

    /// Hard cap on events per reply (the app's export uses the maximum; the MCP
    /// tools ask for at most 200).
    public static let maxLimit = 5000

    public init(text: String? = nil, pid: Int32? = nil, ppid: Int32? = nil, since: Double? = nil, until: Double? = nil,
                kind: String? = nil, signature: String? = nil, teamID: String? = nil, limit: Int = 50) {
        self.text = text
        self.pid = pid
        self.ppid = ppid
        self.since = since
        self.until = until
        self.kind = kind
        self.signature = signature
        self.teamID = teamID
        self.limit = limit
    }

    /// Untrusted input -> a clamped `ExecLogQuery` (helper side).
    public func toQuery() -> ExecLogQuery {
        ExecLogQuery(
            text: text.map { String($0.prefix(200)) },
            pid: pid, ppid: ppid, since: since, until: until,
            kind: kind.flatMap { ["exec", "fork", "exit"].contains($0) ? $0 : nil },
            signature: signature.flatMap { ExecSignatureClass(rawValue: $0) },
            teamID: teamID.map { String($0.prefix(32)) },
            limit: min(max(limit, 1), Self.maxLimit)
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

    public init(pid: Int32, at: Double? = nil, lookbackHours: Int = 24) {
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

    public static func search(_ req: ExecSearchRequest, dir: URL, now: Date = Date()) -> ExecSearchReply {
        let res = ExecLogReader.search(dir: dir, query: req.toQuery())
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

    public static func processTree(_ req: ExecProcessTreeRequest, dir: URL, now: Date = Date()) -> ExecProcessTreeReply {
        let lookback = Double(min(max(req.lookbackHours, 1), 168)) * 3600
        let anchor = req.at ?? now.timeIntervalSince1970
        let res = ExecLogReader.search(dir: dir, query: ExecLogQuery(since: anchor - lookback, limit: ExecSearchRequest.maxLimit))
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
        /// Stable machine code when `ok == false`: "pro_required" | "helper_unavailable" | "bad_request".
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
    @discardableResult
    static func prepare(dir: URL) -> Bool {
        let fm = FileManager.default
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
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

    // MARK: MCP-server side

    /// Writes `request`, waits up to `timeout` for the app's response file,
    /// reads and deletes it. `nil` = the app did not answer (not running, ...).
    public static func submitAndWait(_ request: Request, dir: URL = defaultDirectory, timeout: Double = waitSecs) -> Response? {
        guard isValidID(request.id), prepare(dir: dir),
              let data = try? JSONEncoder().encode(request), data.count <= maxRequestBytes else { return nil }
        let reqURL = requestURL(request.id, dir: dir)
        let respURL = responseURL(request.id, dir: dir)
        guard writeAtomic(data, to: reqURL) else { return nil }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let raw = try? Data(contentsOf: respURL), raw.count <= maxResponseBytes,
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
            let raw = try? Data(contentsOf: url)
            try? fm.removeItem(at: url)
            guard let raw, raw.count <= maxRequestBytes,
                  let req = try? JSONDecoder().decode(Request.self, from: raw),
                  isValidID(req.id), name == "req-\(req.id).json",
                  now.timeIntervalSince1970 - req.createdAt <= staleSecs else { continue }
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
