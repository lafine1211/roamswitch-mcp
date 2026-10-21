// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.15.0 (build 174).
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
//
// Checkpoints: the open segment has no seal yet, so by itself it would be unprotected until it
// rotates. While records arrive, the writer therefore adds a line every `checkpointInterval`
//   {"t":"cp","bytes":N,"hash":"<hex>"}
// where N is the byte length of everything before this line and hash is the chain hash of exactly
// those bytes (the same function as a seal). `verify` recomputes it, so a record edited, removed or
// reordered ahead of a checkpoint is detected even in the open segment. What stays outside is the
// stretch after the newest checkpoint (`uncheckedTailRecords`), and a checkpoint line cut off with
// everything after it. Older logs have no checkpoint lines and verify as before.
//
// Retention marker: `<dir>/retention.json` ({"v":1,"removedThroughIndex":N,"removedCount":C,"updated":ts})
// records that the oldest segments up to index N were deleted by the recorder's own
// age/size retention, so `verify` can tell that from someone deleting the oldest segments
// (which has no index gap and would otherwise be invisible). Logs without a marker
// (older builds) are verified as before.

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

public struct ExecLogRetentionMarker: Codable, Equatable {
    public var v: Int = 1
    public var removedThroughIndex: UInt64
    public var removedCount: Int
    public var updated: Double

    public static let fileName = "retention.json"

    public static func read(dir: URL) -> ExecLogRetentionMarker? {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent(fileName)) else { return nil }
        return try? JSONDecoder().decode(ExecLogRetentionMarker.self, from: data)
    }
}

public struct ExecLogVerifyResult: Codable, Equatable {
    public var segmentsChecked: Int
    public var sealedSegments: Int
    public var ok: Bool
    public var problems: [String]
    /// Records written after the newest checkpoint of the newest segment: the stretch `verify` cannot
    /// cover yet. nil when that segment has no checkpoint (an older log, or the chain is off).
    public var uncheckedTailRecords: Int? = nil
    /// The same findings as `problems`, as a kind plus arguments, so the app can write them in its own
    /// language. nil when the helper that produced this result predates the field (`ExecLogVerifyIssue.parse`
    /// then recovers the kind from the English sentence). `problems` stays English for the MCP tools.
    public var issues: [ExecLogVerifyIssue]? = nil
}

/// One finding of `ExecLogReader.verify`: what went wrong (`kind`) and where (`segment`, indexes).
/// `kind` is a plain string so a kind added by a newer helper still decodes in an older app.
public struct ExecLogVerifyIssue: Codable, Equatable {
    public enum Kind: String, CaseIterable {
        case unreadable
        case missingHeader
        /// `foundIndex` = the oldest retained segment's index, `removedThroughIndex` = what retention recorded.
        case retentionGap
        /// `expectedIndex` / `foundIndex`.
        case indexGap
        case chainDisabled
        case unchainedSealed
        case linkToUnchained
        case linkMismatch
        case checkpointMismatch
        case sealMismatch
        case notSealed
    }

    public var kind: String
    public var segment: String
    public var expectedIndex: UInt64? = nil
    public var foundIndex: UInt64? = nil
    public var removedThroughIndex: UInt64? = nil

    public init(_ kind: Kind, segment: String, expectedIndex: UInt64? = nil, foundIndex: UInt64? = nil,
                removedThroughIndex: UInt64? = nil) {
        self.kind = kind.rawValue
        self.segment = segment
        self.expectedIndex = expectedIndex
        self.foundIndex = foundIndex
        self.removedThroughIndex = removedThroughIndex
    }

    public var knownKind: Kind? { Kind(rawValue: kind) }

    /// The English sentence (what `ExecLogVerifyResult.problems` carries). nil for an unknown kind.
    public var englishText: String? {
        guard let k = knownKind else { return nil }
        let name = segment
        switch k {
        case .unreadable: return "\(name): unreadable"
        case .missingHeader: return "\(name): missing or invalid header"
        case .retentionGap:
            return "\(name): oldest retained segment is index \(foundIndex ?? 0) but retention only recorded removal through \(removedThroughIndex ?? 0) — segments were deleted outside retention"
        case .indexGap:
            return "\(name): index gap (expected \(expectedIndex ?? 0), found \(foundIndex ?? 0)) — a segment is missing"
        case .chainDisabled:
            return "\(name): hash chain disabled after chained segments (setting changed, or a sealed segment was rewritten)"
        case .unchainedSealed: return "\(name): unchained header on a sealed segment"
        case .linkToUnchained:
            return "\(name): chain link points at a segment that is now unchained — the previous segment was rewritten"
        case .linkMismatch: return "\(name): chain link does not match the previous segment's seal"
        case .checkpointMismatch:
            return "\(name): records before a checkpoint do not match it (edited, removed or reordered)"
        case .sealMismatch: return "\(name): content does not match its seal (edited or truncated)"
        case .notSealed: return "\(name): not sealed although newer segments exist"
        }
    }

    /// Recovers an issue from an English sentence written by a helper that has no `issues` field.
    /// nil when the sentence is not one `verify` writes.
    public static func parse(english text: String) -> ExecLogVerifyIssue? {
        guard let sep = text.range(of: ": ") else { return nil }
        let name = String(text[text.startIndex..<sep.lowerBound])
        let rest = String(text[sep.upperBound...])
        for k in Kind.allCases where k != .retentionGap && k != .indexGap {
            let probe = ExecLogVerifyIssue(k, segment: name)
            if probe.englishText == text { return probe }
        }
        func numbers(_ pattern: String) -> [UInt64]? {
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: rest, range: NSRange(rest.startIndex..., in: rest)) else { return nil }
            var out: [UInt64] = []
            for i in 1..<m.numberOfRanges {
                guard let r = Range(m.range(at: i), in: rest), let n = UInt64(rest[r]) else { return nil }
                out.append(n)
            }
            return out
        }
        if let n = numbers(#"^index gap \(expected (\d+), found (\d+)\) — a segment is missing$"#), n.count == 2 {
            return ExecLogVerifyIssue(.indexGap, segment: name, expectedIndex: n[0], foundIndex: n[1])
        }
        if let n = numbers(#"^oldest retained segment is index (\d+) but retention only recorded removal through (\d+) — segments were deleted outside retention$"#), n.count == 2 {
            return ExecLogVerifyIssue(.retentionGap, segment: name, foundIndex: n[0], removedThroughIndex: n[1])
        }
        return nil
    }
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
    private var recordsSinceCheckpoint = 0
    private var lastCheckpointAt = Date()

    /// Seconds between two checkpoints of the open segment (see the file header).
    public static let checkpointInterval: TimeInterval = 10

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
            recordsSinceCheckpoint += 1
        }
    }

    /// fsync the current segment (call after each flushed batch).
    public func flush() {
        if options.hashChain, recordsSinceCheckpoint > 0,
           Date().timeIntervalSince(lastCheckpointAt) >= Self.checkpointInterval {
            writeCheckpoint()
        }
        try? handle?.synchronize()
    }

    /// Seals the records written so far into the open segment with a checkpoint line, if any came in since
    /// the last one. `flush()` does this on its own every `checkpointInterval`.
    public func writeCheckpoint() {
        guard options.hashChain, let h = handle, recordsSinceCheckpoint > 0 else { return }
        let hash = ExecLogChain.hexString(hasher.finalize())
        let line = Data("{\"t\":\"cp\",\"bytes\":\(currentBytes),\"hash\":\"\(hash)\"}\n".utf8)
        do { try h.write(contentsOf: line) } catch { return }
        hasher.update(data: line)
        currentBytes += line.count
        recordsSinceCheckpoint = 0
        lastCheckpointAt = Date()
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
        var maxRemovedIndex: UInt64 = 0
        defer { if removed > 0 { writeRetentionMarker(removedThrough: maxRemovedIndex, count: removed, now: now) } }
        var urls = ExecLogReader.segmentURLs(dir: dir)
        if let cur = currentURL, let i = urls.firstIndex(of: cur) { urls.remove(at: i) }
        // Age (by file modification time — the moment the segment was last written).
        for u in urls {
            guard let m = (try? FileManager.default.attributesOfItem(atPath: u.path))?[.modificationDate] as? Date else { continue }
            if now.timeIntervalSince(m) > options.maxAgeSecs, (try? FileManager.default.removeItem(at: u)) != nil {
                removed += 1
                maxRemovedIndex = max(maxRemovedIndex, ExecLogReader.parseIndex(url: u) ?? 0)
            }
        }
        urls = ExecLogReader.segmentURLs(dir: dir)
        if let cur = currentURL, let i = urls.firstIndex(of: cur) { urls.remove(at: i) }
        var sizes: [(URL, Int)] = urls.map { ($0, ((try? FileManager.default.attributesOfItem(atPath: $0.path))?[.size] as? Int) ?? 0) }
        var total = sizes.reduce(0) { $0 + $1.1 } + currentBytes
        while total > options.maxTotalBytes, !sizes.isEmpty {
            let (u, s) = sizes.removeFirst()
            if (try? FileManager.default.removeItem(at: u)) != nil {
                removed += 1
                total -= s
                maxRemovedIndex = max(maxRemovedIndex, ExecLogReader.parseIndex(url: u) ?? 0)
            }
        }
        return removed
    }

    /// Merges this run's deletions into `retention.json` (index only ever grows).
    private func writeRetentionMarker(removedThrough: UInt64, count: Int, now: Date) {
        let prior = ExecLogRetentionMarker.read(dir: dir)
        let marker = ExecLogRetentionMarker(
            removedThroughIndex: max(prior?.removedThroughIndex ?? 0, removedThrough),
            removedCount: (prior?.removedCount ?? 0) + count,
            updated: now.timeIntervalSince1970)
        guard let data = try? JSONEncoder().encode(marker) else { return }
        let url = dir.appendingPathComponent(ExecLogRetentionMarker.fileName)
        let tmp = dir.appendingPathComponent(".retention.tmp")
        guard FileManager.default.createFile(atPath: tmp.path, contents: data, attributes: [.posixPermissions: Self.fileMode]) else { return }
        if rename(tmp.path, url.path) != 0 { try? FileManager.default.removeItem(at: tmp) }
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
        recordsSinceCheckpoint = 0
        lastCheckpointAt = Date()
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
        recordsSinceCheckpoint = 0
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
    /// When true, `text` is matched against the secret-masked command line
    /// (`ExecCommandMasker`), never the raw one, so a query can't be used to probe a
    /// secret character by character. Set on the MCP path; the app's own UI search
    /// (the user's own data) keeps the full-text match.
    public var maskedTextMatch: Bool
    /// Upper bound on bytes read per call so a query can never turn into a
    /// multi-second full scan of a 1 GB log.
    public var maxScanBytes: Int

    public init(text: String? = nil, pid: Int32? = nil, ppid: Int32? = nil, since: Double? = nil, until: Double? = nil,
                kind: String? = nil, signature: ExecSignatureClass? = nil, teamID: String? = nil,
                limit: Int = 50, maskedTextMatch: Bool = false, maxScanBytes: Int = 64 * 1024 * 1024) {
        self.text = text
        self.pid = pid
        self.ppid = ppid
        self.since = since
        self.until = until
        self.kind = kind
        self.signature = signature
        self.teamID = teamID
        self.limit = min(max(limit, 1), 5000)
        self.maskedTextMatch = maskedTextMatch
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
        if maskedTextMatch, let raw = text, !raw.isEmpty {
            // Fail closed on a query that is (or normalizes to) too short to be a real search.
            let needle = ExecCommandMasker.normalizedNeedle(raw)
            if needle.count < ExecCommandMasker.minQueryLength || !ExecCommandMasker.maskedMatch(r, needle: needle) { return false }
        } else if let t = text?.lowercased(), !t.isEmpty {
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

    /// Checks every checkpoint line of one segment: it must name the byte offset it sits at and carry the
    /// chain hash of everything before it. Returns true when one does not match.
    static func hasBadCheckpoint(data: Data, prev: String) -> Bool {
        var hasher = SHA256()
        hasher.update(data: Data((prev + "\n").utf8))
        let marker = Data("{\"t\":\"cp\"".utf8)
        var start = data.startIndex
        while start < data.endIndex {
            let nl = data[start...].firstIndex(of: 0x0A)
            let end = nl.map { $0 + 1 } ?? data.endIndex
            let line = Data(data[start..<end])
            if line.starts(with: marker) {
                let expect = ExecLogChain.hexString(hasher.finalize())
                guard let o = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
                      (o["bytes"] as? NSNumber)?.intValue == data.distance(from: data.startIndex, to: start),
                      (o["hash"] as? String) == expect else { return true }
            }
            hasher.update(data: line)
            start = end
        }
        return false
    }

    /// Records after the newest checkpoint line; nil when the segment has none.
    static func recordsAfterLastCheckpoint(_ lines: [Data]) -> Int? {
        let marker = Data("{\"t\":\"cp\"".utf8)
        guard let lastCP = lines.lastIndex(where: { $0.starts(with: marker) }) else { return nil }
        return lines[(lastCP + 1)...].filter { !ExecLogChain.isMeta($0) }.count
    }

    /// How far a segment's creation time must precede `since` before older segments are skipped.
    static let sinceSkewSecs: Double = 86_400

    private static func segmentCreated(_ data: Data) -> Double? {
        guard let nl = data.firstIndex(of: 0x0A) else { return nil }
        return parseHeader(Data(data[data.startIndex..<nl]))?.created
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
            // Segments are append-only but a wall-clock step can put an older timestamp after a
            // newer one, so `since` skips records instead of ending the scan. Whole older
            // segments are skipped once the segment itself was created `sinceSkewSecs` before
            // `since` (its records all postdate its header, modulo clock steps).
            var segmentHeaderBeforeSince = false
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
                        if query.matches(rec) {
                            out.append(rec)
                            if out.count >= query.limit { break segments }
                        }
                    }
                }
                end = nlBefore ?? data.startIndex
            }
            if let since = query.since, let created = segmentCreated(data), created < since - sinceSkewSecs { segmentHeaderBeforeSince = true }
            if segmentHeaderBeforeSince { break segments }
        }
        return ExecLogSearchResult(events: out, scannedBytes: scanned, truncatedScan: truncated, segments: urls.count, readable: true)
    }

    /// Verifies the hash chain across all segments (see the file header for
    /// what that does and does not prove).
    public static func verify(dir: URL) -> ExecLogVerifyResult {
        let urls = segmentURLs(dir: dir)
        var issues: [ExecLogVerifyIssue] = []
        var sealed = 0
        var prevSealHash: String?
        var prevIndex: UInt64?
        var sawChained = false
        var prevWasUnchained = false
        var uncheckedTail: Int?
        let marker = ExecLogRetentionMarker.read(dir: dir)
        for (i, url) in urls.enumerated() {
            let name = url.lastPathComponent
            func add(_ kind: ExecLogVerifyIssue.Kind, expectedIndex: UInt64? = nil, foundIndex: UInt64? = nil,
                     removedThroughIndex: UInt64? = nil) {
                issues.append(ExecLogVerifyIssue(kind, segment: name, expectedIndex: expectedIndex,
                                                 foundIndex: foundIndex, removedThroughIndex: removedThroughIndex))
            }
            guard let data = try? Data(contentsOf: url) else { add(.unreadable); prevSealHash = nil; continue }
            let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true).map { Data($0) }
            guard let firstLine = lines.first, let hdr = parseHeader(firstLine) else {
                add(.missingHeader); prevSealHash = nil; continue
            }
            if prevIndex == nil, let m = marker, hdr.index != m.removedThroughIndex + 1 {
                add(.retentionGap, foundIndex: hdr.index, removedThroughIndex: m.removedThroughIndex)
            }
            if let pi = prevIndex, hdr.index != pi + 1 { add(.indexGap, expectedIndex: pi + 1, foundIndex: hdr.index) }
            prevIndex = hdr.index
            if hdr.prev == "-" {
                // Chain disabled for this segment. After a chained segment that is a downgrade
                // (the setting was switched off, or a sealed segment's header was rewritten to
                // skip the seal check); a sealed segment can't have been written unchained.
                if sawChained { add(.chainDisabled) }
                if let l = lines.last, parseSeal(l) != nil { add(.unchainedSealed) }
                prevSealHash = nil
                prevWasUnchained = true
                continue
            }
            // A chain restarted after unchained segments begins at genesis (ExecLogWriter.open).
            if prevWasUnchained, hdr.prev != ExecLogChain.genesis {
                add(.linkToUnchained)
            }
            prevWasUnchained = false
            sawChained = true
            if let p = prevSealHash, p != hdr.prev { add(.linkMismatch) }
            let isLast = i == urls.count - 1
            if hasBadCheckpoint(data: data, prev: hdr.prev) {
                add(.checkpointMismatch)
            }
            if isLast { uncheckedTail = recordsAfterLastCheckpoint(lines) }
            if let lastLine = lines.last, let seal = parseSeal(lastLine) {
                sealed += 1
                // Body = everything before the seal line.
                let sealStart = data.count - lastLineByteLength(data: data)
                let body = Data(data[data.startIndex..<sealStart])
                let expect = ExecLogChain.hash(prev: hdr.prev, body: body)
                if expect != seal.hash { add(.sealMismatch) }
                prevSealHash = seal.hash
            } else {
                if !isLast { add(.notSealed) }
                prevSealHash = nil
            }
        }
        return ExecLogVerifyResult(segmentsChecked: urls.count, sealedSegments: sealed, ok: issues.isEmpty, problems: issues.compactMap(\.englishText), uncheckedTailRecords: uncheckedTail, issues: issues)
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
