// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.1 (build 119).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

// Segmented JSON Lines store for the exec recorder.
//
// Layout:  <dir>/exec-<created ms, 13 digits>-<index, 6 digits>.jsonl
// Each segment:
//   line 1      {"t":"hdr","v":1,"index":N,"created":<epoch>,"prev":"<hex|->"}
//   lines 2..   one ExecEventRecord JSON object per line
//   last line   {"t":"seal","hash":"<hex>","count":N,"closed":<epoch>}   (written on rotation / next start)
//
// Hash chain: hash_i = SHA256( prev_hex + "\n" + bytes(header line ... last record line, incl. newlines) ),
// and segment i+1's header carries prev = hash_i. This makes deletion of a middle
// segment, edits inside a sealed segment and tail truncation of a sealed segment
// DETECTABLE. It is tamper-EVIDENT, not tamper-proof: an attacker with root can
// rewrite the whole chain, and dropping the newest, still-open segment (or
// everything after the last seal) is not detectable.

public enum ExecLogChain {
    public static let genesis = String(repeating: "0", count: 64)

    public static func hash(prev: String, body: Data) -> String {
        var h = SHA256()
        h.update(data: Data((prev + "\n").utf8))
        h.update(data: body)
        return hexString(h.finalize())
    }

    static func hexString(_ digest: SHA256.Digest) -> String {
        digest.map { String(format: "%02x", $0) }.joined()
    }

    static func isMeta(_ line: Data) -> Bool {
        line.starts(with: Data("{\"t\":\"".utf8))
    }
}

public struct ExecLogVerifyResult: Codable, Equatable {
    public var segmentsChecked: Int
    public var sealedSegments: Int
    public var ok: Bool
    public var problems: [String]
}

public final class ExecLogWriter {
    public struct Options {
        public var segmentBytes: Int
        public var maxTotalBytes: Int
        public var maxAgeSecs: Double
        public var hashChain: Bool

        public init(segmentBytes: Int = 8 * 1024 * 1024, maxTotalBytes: Int = 200 * 1024 * 1024,
                    maxAgeSecs: Double = 14 * 86_400, hashChain: Bool = true) {
            self.segmentBytes = max(64 * 1024, segmentBytes)
            self.maxTotalBytes = max(1024 * 1024, maxTotalBytes)
            self.maxAgeSecs = max(3600, maxAgeSecs)
            self.hashChain = hashChain
        }
    }

    public let dir: URL
    public var options: Options
    private var handle: FileHandle?
    private var currentURL: URL?
    private var currentBytes = 0
    private var currentCount = 0
    private var nextIndex: UInt64 = 1
    private var lastChainHash = ExecLogChain.genesis
    private var hasher = SHA256()

    /// Command lines can contain secrets: the directory is owner-only (0700) and
    /// so is every segment (0600). Readers other than the owner (root, in the
    /// helper) do not exist — the app and the MCP server go through the helper's
    /// XPC methods (`ExecReadService`).
    static let dirMode: Int = 0o700
    static let fileMode: Int = 0o600

    /// Tightens a directory / segments created by an older build that shared
    /// them read-only with the `admin` group (0750 / 0640).
    func restrictPermissions() {
        let fm = FileManager.default
        try? fm.setAttributes([.posixPermissions: Self.dirMode], ofItemAtPath: dir.path)
        for url in ExecLogReader.segmentURLs(dir: dir) {
            try? fm.setAttributes([.posixPermissions: Self.fileMode], ofItemAtPath: url.path)
        }
    }

    public init(dir: URL, options: Options = Options()) {
        self.dir = dir
        self.options = options
    }

    /// Creates the directory and repairs whatever a crash left behind: a partial
    /// last line is cut off and an unsealed last segment gets sealed.
    public func open() throws {
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true,
            attributes: [.posixPermissions: Self.dirMode])
        restrictPermissions()
        guard let last = ExecLogReader.segmentURLs(dir: dir).last else { return }
        guard var data = try? Data(contentsOf: last) else { return }
        if let lastNL = data.lastIndex(of: 0x0A) {
            if lastNL != data.count - 1 {
                data = Data(data[...lastNL])
                try? truncate(last, to: data.count)
            }
        } else {
            // No complete line at all: an empty/garbage segment. Leave it; the
            // next segment continues after its index.
            nextIndex = (ExecLogReader.parseIndex(url: last) ?? 0) + 1
            return
        }
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true).map { Data($0) }
        guard let first = lines.first, let hdr = ExecLogReader.parseHeader(first) else {
            nextIndex = (ExecLogReader.parseIndex(url: last) ?? 0) + 1
            return
        }
        nextIndex = hdr.index + 1
        if let lastLine = lines.last, ExecLogReader.parseSeal(lastLine) != nil {
            lastChainHash = ExecLogReader.parseSeal(lastLine)?.hash ?? ExecLogChain.genesis
        } else if hdr.prev != "-" {
            let hash = ExecLogChain.hash(prev: hdr.prev, body: data)
            lastChainHash = hash
            appendRaw(to: last, Data(sealLine(hash: hash, count: max(0, lines.count - 1)).utf8))
        }
    }

    /// Appends complete JSON lines (no trailing newline in each element).
    public func append(lines: [Data]) {
        guard !lines.isEmpty else { return }
        for line in lines {
            if handle == nil || currentBytes >= options.segmentBytes { rotate() }
            guard let h = handle else { return }
            var buf = line
            buf.append(0x0A)
            do { try h.write(contentsOf: buf) } catch { closeSegment(seal: false); return }
            if options.hashChain { hasher.update(data: buf) }
            currentBytes += buf.count
            currentCount += 1
        }
    }

    /// fsync the current segment (call after each flushed batch).
    public func flush() {
        try? handle?.synchronize()
    }

    /// Seals and closes the current segment (helper stop / shutdown).
    public func close() {
        closeSegment(seal: true)
    }

    /// Deletes the oldest sealed segments beyond the size / age budget. The
    /// open segment is never deleted. Returns the number of segments removed.
    @discardableResult
    public func applyRetention(now: Date = Date()) -> Int {
        var removed = 0
        var urls = ExecLogReader.segmentURLs(dir: dir)
        if let cur = currentURL, let i = urls.firstIndex(of: cur) { urls.remove(at: i) }
        // Age (by file modification time — the moment the segment was last written).
        for u in urls {
            guard let m = (try? FileManager.default.attributesOfItem(atPath: u.path))?[.modificationDate] as? Date else { continue }
            if now.timeIntervalSince(m) > options.maxAgeSecs, (try? FileManager.default.removeItem(at: u)) != nil { removed += 1 }
        }
        urls = ExecLogReader.segmentURLs(dir: dir)
        if let cur = currentURL, let i = urls.firstIndex(of: cur) { urls.remove(at: i) }
        var sizes: [(URL, Int)] = urls.map { ($0, ((try? FileManager.default.attributesOfItem(atPath: $0.path))?[.size] as? Int) ?? 0) }
        var total = sizes.reduce(0) { $0 + $1.1 } + currentBytes
        while total > options.maxTotalBytes, !sizes.isEmpty {
            let (u, s) = sizes.removeFirst()
            if (try? FileManager.default.removeItem(at: u)) != nil { removed += 1; total -= s }
        }
        return removed
    }

    public static func totalBytes(dir: URL) -> Int {
        ExecLogReader.segmentURLs(dir: dir).reduce(0) {
            $0 + (((try? FileManager.default.attributesOfItem(atPath: $1.path))?[.size] as? Int) ?? 0)
        }
    }

    // MARK: internals

    private func rotate() {
        closeSegment(seal: true)
        let created = Date().timeIntervalSince1970
        let name = String(format: "exec-%013lld-%06lld.jsonl", Int64(created * 1000), Int64(nextIndex))
        let url = dir.appendingPathComponent(name)
        let prev = options.hashChain ? lastChainHash : "-"
        let header = "{\"t\":\"hdr\",\"v\":1,\"index\":\(nextIndex),\"created\":\(created),\"prev\":\"\(prev)\"}\n"
        guard FileManager.default.createFile(atPath: url.path, contents: nil,
                                             attributes: [.posixPermissions: Self.fileMode]),
              let h = try? FileHandle(forWritingTo: url) else { return }
        handle = h
        currentURL = url
        nextIndex += 1
        let hdrData = Data(header.utf8)
        do { try h.write(contentsOf: hdrData) } catch { handle = nil; return }
        currentBytes = hdrData.count
        currentCount = 0
        hasher = SHA256()
        if options.hashChain {
            hasher.update(data: Data((prev + "\n").utf8))
            hasher.update(data: hdrData)
        }
    }

    private func closeSegment(seal: Bool) {
        guard let h = handle else { return }
        if seal && options.hashChain {
            let hash = ExecLogChain.hexString(hasher.finalize())
            lastChainHash = hash
            try? h.write(contentsOf: Data(sealLine(hash: hash, count: currentCount).utf8))
        }
        try? h.synchronize()
        try? h.close()
        handle = nil
        currentURL = nil
        currentBytes = 0
        currentCount = 0
    }

    private func sealLine(hash: String, count: Int) -> String {
        "{\"t\":\"seal\",\"hash\":\"\(hash)\",\"count\":\(count),\"closed\":\(Date().timeIntervalSince1970)}\n"
    }

    private func appendRaw(to url: URL, _ data: Data) {
        guard let h = try? FileHandle(forWritingTo: url) else { return }
        defer { try? h.close() }
        _ = try? h.seekToEnd()
        try? h.write(contentsOf: data)
        try? h.synchronize()
    }

    private func truncate(_ url: URL, to length: Int) throws {
        let h = try FileHandle(forWritingTo: url)
        defer { try? h.close() }
        try h.truncate(atOffset: UInt64(length))
    }
}

// MARK: - Reader / search / verify

public struct ExecLogQuery {
    public var text: String?
    public var pid: Int32?
    public var ppid: Int32?
    public var since: Double?
    public var until: Double?
    public var kind: String?
    public var signature: ExecSignatureClass?
    public var teamID: String?
    public var limit: Int
    /// Upper bound on bytes read per call so a query can never turn into a
    /// multi-second full scan of a 1 GB log.
    public var maxScanBytes: Int

    public init(text: String? = nil, pid: Int32? = nil, ppid: Int32? = nil, since: Double? = nil, until: Double? = nil,
                kind: String? = nil, signature: ExecSignatureClass? = nil, teamID: String? = nil,
                limit: Int = 50, maxScanBytes: Int = 64 * 1024 * 1024) {
        self.text = text
        self.pid = pid
        self.ppid = ppid
        self.since = since
        self.until = until
        self.kind = kind
        self.signature = signature
        self.teamID = teamID
        self.limit = min(max(limit, 1), 5000)
        self.maxScanBytes = maxScanBytes
    }

    public func matches(_ r: ExecEventRecord) -> Bool {
        if let pid, r.pid != pid { return false }
        if let ppid, r.ppid != ppid { return false }
        if let since, r.time < since { return false }
        if let until, r.time > until { return false }
        if let kind, r.kind != kind { return false }
        if let signature, r.signatureClass != signature { return false }
        if let teamID, r.teamID != teamID { return false }
        if let t = text?.lowercased(), !t.isEmpty {
            var hay = r.path.lowercased()
            if let a = r.args { hay += " " + a.joined(separator: " ").lowercased() }
            if let s = r.signingID { hay += " " + s.lowercased() }
            if let s = r.teamID { hay += " " + s.lowercased() }
            if let c = r.cwd { hay += " " + c.lowercased() }
            if !hay.contains(t) { return false }
        }
        return true
    }
}

public struct ExecLogSearchResult {
    /// Newest first.
    public var events: [ExecEventRecord]
    public var scannedBytes: Int
    /// True when the scan budget ran out before the whole log was covered.
    public var truncatedScan: Bool
    public var segments: Int
    /// False when the directory does not exist or cannot be read (no recorder,
    /// or the caller is not root — only the helper reads the log).
    public var readable: Bool
}

public enum ExecLogReader {
    public static func segmentURLs(dir: URL) -> [URL] {
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return items.filter { $0.lastPathComponent.hasPrefix("exec-") && $0.pathExtension == "jsonl" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    static func parseIndex(url: URL) -> UInt64? {
        // exec-<13 digits>-<6 digits>.jsonl
        let parts = url.deletingPathExtension().lastPathComponent.split(separator: "-")
        guard parts.count == 3 else { return nil }
        return UInt64(parts[2])
    }

    struct Header { var index: UInt64; var prev: String; var created: Double }
    struct Seal { var hash: String; var count: Int }

    static func parseHeader(_ line: Data) -> Header? {
        guard let o = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
              (o["t"] as? String) == "hdr", let idx = (o["index"] as? NSNumber)?.uint64Value,
              let prev = o["prev"] as? String else { return nil }
        return Header(index: idx, prev: prev, created: (o["created"] as? NSNumber)?.doubleValue ?? 0)
    }

    static func parseSeal(_ line: Data) -> Seal? {
        guard line.starts(with: Data("{\"t\":\"seal\"".utf8)),
              let o = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
              let h = o["hash"] as? String else { return nil }
        return Seal(hash: h, count: (o["count"] as? NSNumber)?.intValue ?? 0)
    }

    /// Newest-first search across segments, bounded by `query.maxScanBytes`.
    public static func search(dir: URL, query: ExecLogQuery) -> ExecLogSearchResult {
        let urls = segmentURLs(dir: dir)
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        guard exists, isDir.boolValue, FileManager.default.isReadableFile(atPath: dir.path) else {
            return ExecLogSearchResult(events: [], scannedBytes: 0, truncatedScan: false, segments: 0, readable: false)
        }
        var out: [ExecEventRecord] = []
        var scanned = 0
        var truncated = false
        let decoder = JSONDecoder()
        segments: for url in urls.reversed() {
            guard let data = try? Data(contentsOf: url) else { continue }
            if scanned + data.count > query.maxScanBytes && scanned > 0 { truncated = true; break }
            scanned += data.count
            var end = data.endIndex
            while end > data.startIndex {
                // Walk lines backwards.
                let searchRange = data.startIndex..<end
                let nlBefore = data[searchRange].lastIndex(of: 0x0A)
                let lineStart = nlBefore.map { $0 + 1 } ?? data.startIndex
                var lineEnd = end
                if lineEnd > lineStart, data[lineEnd - 1] == 0x0A { lineEnd -= 1 }
                if lineEnd > lineStart {
                    let line = Data(data[lineStart..<lineEnd])
                    if !ExecLogChain.isMeta(line), let rec = try? decoder.decode(ExecEventRecord.self, from: line) {
                        if let since = query.since, rec.time < since { break segments }
                        if query.matches(rec) {
                            out.append(rec)
                            if out.count >= query.limit { break segments }
                        }
                    }
                }
                end = nlBefore ?? data.startIndex
            }
        }
        return ExecLogSearchResult(events: out, scannedBytes: scanned, truncatedScan: truncated, segments: urls.count, readable: true)
    }

    /// Verifies the hash chain across all segments (see the file header for
    /// what that does and does not prove).
    public static func verify(dir: URL) -> ExecLogVerifyResult {
        let urls = segmentURLs(dir: dir)
        var problems: [String] = []
        var sealed = 0
        var prevSealHash: String?
        var prevIndex: UInt64?
        for (i, url) in urls.enumerated() {
            let name = url.lastPathComponent
            guard let data = try? Data(contentsOf: url) else { problems.append("\(name): unreadable"); prevSealHash = nil; continue }
            let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true).map { Data($0) }
            guard let firstLine = lines.first, let hdr = parseHeader(firstLine) else {
                problems.append("\(name): missing or invalid header"); prevSealHash = nil; continue
            }
            if let pi = prevIndex, hdr.index != pi + 1 { problems.append("\(name): index gap (expected \(pi + 1), found \(hdr.index)) — a segment is missing") }
            prevIndex = hdr.index
            if hdr.prev == "-" { prevSealHash = nil; continue } // chain disabled for this segment
            if let p = prevSealHash, p != hdr.prev { problems.append("\(name): chain link does not match the previous segment's seal") }
            let isLast = i == urls.count - 1
            if let lastLine = lines.last, let seal = parseSeal(lastLine) {
                sealed += 1
                // Body = everything before the seal line.
                let sealStart = data.count - lastLineByteLength(data: data)
                let body = Data(data[data.startIndex..<sealStart])
                let expect = ExecLogChain.hash(prev: hdr.prev, body: body)
                if expect != seal.hash { problems.append("\(name): content does not match its seal (edited or truncated)") }
                prevSealHash = seal.hash
            } else {
                if !isLast { problems.append("\(name): not sealed although newer segments exist") }
                prevSealHash = nil
            }
        }
        return ExecLogVerifyResult(segmentsChecked: urls.count, sealedSegments: sealed, ok: problems.isEmpty, problems: problems)
    }

    /// Byte length of the final line including its trailing newline.
    private static func lastLineByteLength(data: Data) -> Int {
        var end = data.endIndex
        while end > data.startIndex, data[end - 1] == 0x0A { end -= 1 }
        let nl = data[data.startIndex..<end].lastIndex(of: 0x0A)
        let start = nl.map { $0 + 1 } ?? data.startIndex
        return data.endIndex - start
    }
}
