// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.0 (build 224).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

// "Who read / wrote this file?" for the Mac: the model behind the helper's file-event recorder.
//
// macOS does not tell an app who opened a file. Apple's own `/usr/bin/eslogger` (the same tool the
// process-exec recorder runs) can: its `open`, `create`, `rename` and `unlink` events carry the acting
// process. eslogger cannot filter by path, so it sends EVERY open on the Mac. (Since 2026-11-14 the events can also come
// from the Endpoint Security extension's own clients, which the kernel narrows to the registered paths
// (`ESPathWatchRegistry`, `ESFileActorBridge`); the extension writes the same eslogger-shaped lines. The helper reads
// one source or the other, never both: `ESRouteCoordinator`.) The helper therefore
// looks only at the file paths in each line, keeps the few events that touch a watched file (a decoy
// credential file, an AI agent's setup file, a start-up file), and forgets everything else at once.
// What it keeps lives in memory only, for a few minutes (`FileActorRing`); nothing is written to disk.
//
// Two eslogger processes, because the two kinds of event cost very different amounts (measured on a Mac in normal
// use, 2026-10-24): `open` is ~256 lines/s and ~5% of one core; the rest (create, rename, unlink, clone, copyfile,
// truncate) is a few lines/s. Each has its own load limit, so a busy hour stops the expensive one and keeps the cheap one.
//
// This file holds the pure parts (rules, parser, line filter, ring, load governor) so they are unit-tested
// without a process, a root helper or eslogger.

/// One file event that touched a watched file, with the process that did it.
public struct FileActorRecord: Codable, Equatable {
    /// Unix epoch seconds (the last time, when the same process did the same thing again within a moment).
    public var time: Double
    /// "open" | "create" | "rename" | "unlink" | "clone" | "copyfile" | "truncate"
    public var kind: String
    /// `open` only: the kernel's open flags (FREAD 0x1, FWRITE 0x2).
    public var fflag: Int32?
    /// Every file path the event names (an open names one, a rename two). At most 2.
    public var paths: [String]
    public var pid: Int32
    public var ppid: Int32
    public var uid: UInt32?
    public var processPath: String
    public var signingID: String?
    public var teamID: String?
    public var isPlatform: Bool?
    public var csFlags: UInt32?

    // Filled in by the helper once the event is known to matter.
    /// The watched path the event touched.
    public var matchedPath: String?
    public var label: FileActorLabel?
    /// How many times the same process did the same thing within `FileActorRing.dedupeWindow`.
    public var count: Int
    /// The command line, from the exec recorder's log (nil when that did not see the process start).
    public var args: [String]?
    public var parentPath: String?

    public init(time: Double, kind: String, fflag: Int32? = nil, paths: [String], pid: Int32, ppid: Int32, uid: UInt32? = nil,
                processPath: String, signingID: String? = nil, teamID: String? = nil, isPlatform: Bool? = nil,
                csFlags: UInt32? = nil, matchedPath: String? = nil, label: FileActorLabel? = nil, count: Int = 1,
                args: [String]? = nil, parentPath: String? = nil) {
        self.time = time
        self.kind = kind
        self.fflag = fflag
        self.paths = paths
        self.pid = pid
        self.ppid = ppid
        self.uid = uid
        self.processPath = processPath
        self.signingID = signingID
        self.teamID = teamID
        self.isPlatform = isPlatform
        self.csFlags = csFlags
        self.matchedPath = matchedPath
        self.label = label
        self.count = count
        self.args = args
        self.parentPath = parentPath
    }

    public var readsFile: Bool { kind == "open" && ((fflag ?? 0) & 0x1) != 0 }
    /// An open for writing, or a create, a rename or a delete.
    public var writesFile: Bool { kind != "open" || ((fflag ?? 0) & 0x2) != 0 }

    public var signatureClass: ExecSignatureClass {
        if isPlatform == true { return .platform }
        if let t = teamID, !t.isEmpty { return .developer }
        if let f = csFlags, f & 0x2 != 0 { return .adhoc }
        if let s = signingID, !s.isEmpty { return .adhoc }
        return .unsigned
    }
}

extension FileWatchRule {
    /// Whether this kind of access to a matching file is worth keeping.
    public func accepts(_ record: FileActorRecord) -> Bool {
        reads || record.writesFile
    }
}

// MARK: - The two eslogger streams

/// The helper runs one eslogger per stream.
public enum FileActorStream: String, Codable, Equatable, CaseIterable {
    /// `create rename unlink clone copyfile truncate`: a file appears, moves, disappears or is emptied. Rare.
    case write
    /// `open`: every open on the Mac, a read or a write (FREAD / FWRITE). The only way to see who READ a decoy, and who
    /// wrote into an existing file in place (`echo >> ~/.zshrc`). eslogger cannot select the read-only opens.
    case open

    public var events: [String] {
        switch self {
        case .write: return ["create", "rename", "unlink", "clone", "copyfile", "truncate"]
        case .open: return ["open"]
        }
    }

    /// Percent of one core, averaged over five minutes, above which the stream stops itself.
    public var defaultBudgetPercent: Double {
        switch self {
        case .write: return FileActorLoadGovernor.defaultWriteBudgetPercent
        case .open: return FileActorLoadGovernor.defaultOpenBudgetPercent
        }
    }
}

// MARK: - Parser (runs in the unprivileged, sandboxed parse worker)

public enum FileActorParser {
    /// eslogger's event names (both streams). `open` is by far the busiest; the rest are rare. `clone` and `copyfile` are how
    /// Finder and `cp -c` put a file in place without opening it for writing; `truncate` empties one without an open.
    public static let kinds = FileActorStream.allCases.flatMap { $0.events }.sorted()

    public enum Result: Equatable {
        case record(FileActorRecord)
        /// A valid message of a kind we do not record.
        case ignored
        case malformed
    }

    /// One line of `eslogger open create rename unlink` output. The fields used (Apple's es_message_t as JSON):
    /// `process` (the actor), `event.open.{fflag,file.path}`, `event.create.destination.{existing_file.path |
    /// new_path.{dir.path,filename}}`, `event.rename.{source.path,destination...}`, `event.unlink.target.path`.
    /// A shape that is not there yields `.malformed`, so a change in eslogger's output shows in the status
    /// instead of silently recording nothing.
    public static func parse(_ line: Data) -> Result {
        guard !line.isEmpty, line.count <= ESLoggerParser.maxLineBytes else { return .malformed }
        guard let obj = try? JSONSerialization.jsonObject(with: line, options: []),
              let root = obj as? [String: Any],
              let event = root["event"] as? [String: Any] else { return .malformed }
        let process = root["process"] as? [String: Any] ?? [:]
        let acting = ESLoggerParser.info(process)
        let time = ESLoggerParser.parseTime(root["time"]) ?? Date().timeIntervalSince1970

        var kind: String?
        var paths: [String] = []
        var fflag: Int32?
        if let open = event["open"] as? [String: Any] {
            kind = "open"
            guard let p = filePath(open["file"]) else { return .malformed }
            paths = [p]
            fflag = ESLoggerParser.int(open["fflag"]).flatMap { Int32(exactly: $0) }
        } else if let create = event["create"] as? [String: Any] {
            kind = "create"
            guard let p = destination(create) else { return .malformed }
            paths = [p]
        } else if let rename = event["rename"] as? [String: Any] {
            kind = "rename"
            guard let source = filePath(rename["source"]) else { return .malformed }
            paths = [source]
            if let target = destination(rename) { paths.append(target) }
        } else if let unlink = event["unlink"] as? [String: Any] {
            kind = "unlink"
            guard let p = filePath(unlink["target"]) else { return .malformed }
            paths = [p]
        } else if let clone = event["clone"] as? [String: Any] {
            // The file that appears: the target folder and name (the source is only read).
            kind = "clone"
            guard let p = folderAndName(clone) else { return .malformed }
            paths = [p]
        } else if let copy = event["copyfile"] as? [String: Any] {
            kind = "copyfile"
            guard let p = filePath(copy["target_file"]) ?? folderAndName(copy) else { return .malformed }
            paths = [p]
        } else if let truncate = event["truncate"] as? [String: Any] {
            kind = "truncate"
            guard let p = filePath(truncate["target"]) else { return .malformed }
            paths = [p]
        }
        guard let kind else { return .ignored }
        guard let pid = acting.pid, let processPath = acting.path else { return .malformed }
        return .record(FileActorRecord(
            time: time, kind: kind, fflag: fflag, paths: paths, pid: pid, ppid: acting.ppid ?? 0, uid: acting.uid,
            processPath: processPath, signingID: acting.signingID, teamID: acting.teamID, isPlatform: acting.isPlatform,
            csFlags: acting.csFlags))
    }

    private static func filePath(_ file: Any?) -> String? {
        guard let dict = file as? [String: Any] else { return nil }
        return ESLoggerParser.str(dict["path"], max: ESLoggerParser.maxPathChars)
    }

    /// `target_dir` and `target_name` (clone, copyfile).
    private static func folderAndName(_ event: [String: Any]) -> String? {
        guard let dir = filePath(event["target_dir"]), let name = ESLoggerParser.str(event["target_name"], max: 255) else { return nil }
        return dir == "/" ? "/" + name : dir + "/" + name
    }

    /// `destination` is either an existing file or a new name in a folder.
    private static func destination(_ event: [String: Any]) -> String? {
        guard let d = event["destination"] as? [String: Any] else { return nil }
        if let existing = filePath(d["existing_file"]) { return existing }
        if let np = d["new_path"] as? [String: Any], let dir = filePath(np["dir"]),
           let name = ESLoggerParser.str(np["filename"], max: 255) {
            return dir == "/" ? "/" + name : dir + "/" + name
        }
        return nil
    }
}

// MARK: - Line filter (runs in the root helper; byte search only, no JSON)

/// Decides whether an eslogger line is worth handing to the parse worker: does any `"path":"..."` in it fall on a
/// watched path? Superset test: the worker's parse and `FileWatchRule.matches` make the final decision. The helper
/// does not parse the JSON itself (the paths are chosen by whoever touches the files), so this only searches bytes,
/// within bounds.
public struct FileActorLineFilter {
    /// A rule in bytes, with the same meaning as `FileWatchRule.matches`.
    private struct Compiled {
        var mode: FileWatchRule.Mode
        var pattern: [UInt8]
        /// For `prefix` rules written with a trailing slash: the folder itself, without it.
        var folder: [UInt8]?
        var requirePrefix: [UInt8]?
        var requireSuffixes: [[UInt8]]
        var requireContains: [UInt8]?
        var excludeSuffixes: [[UInt8]]
        var excludeContains: [[UInt8]]
    }

    private let rules: [Compiled]
    private static let pathKey = Array("\"path\":\"".utf8)
    private static let filenameKeys = [Array("\"filename\":\"".utf8), Array("\"target_name\":\"".utf8)]
    public static let maxPathBytes = 1024
    public var isEmpty: Bool { rules.isEmpty }

    public init(rules: [FileWatchRule]) {
        self.rules = rules.map { r in
            var folder: [UInt8]?
            var pattern = r.pattern
            if r.mode == .prefix {
                if !pattern.hasSuffix("/") { pattern += "/" }
                folder = Array(pattern.dropLast().utf8)
            }
            return Compiled(mode: r.mode, pattern: Array(pattern.utf8), folder: folder,
                            requirePrefix: r.requirePrefix.map { Array($0.utf8) },
                            requireSuffixes: r.requireSuffixes.map { Array($0.utf8) },
                            requireContains: r.requireContains.map { Array($0.utf8) },
                            excludeSuffixes: r.excludeSuffixes.map { Array($0.utf8) },
                            excludeContains: r.excludeContains.map { Array($0.utf8) })
        }
    }

    public func mayMatch(_ line: Data) -> Bool {
        guard !rules.isEmpty, !line.isEmpty else { return false }
        return line.withUnsafeBytes { raw -> Bool in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return false }
            let n = raw.count
            var paths: [[UInt8]] = []
            var offset = 0
            while offset < n, paths.count < 8 {
                guard let hit = Self.find(Self.pathKey, in: base, count: n, from: offset) else { break }
                let start = hit + Self.pathKey.count
                let (value, end) = Self.readString(base, count: n, from: start)
                if let value, value.count <= Self.maxPathBytes {
                    let canonical = Self.canonical(value)
                    if matchesAny(canonical) { return true }
                    paths.append(canonical)
                }
                offset = max(end, start)
            }
            // A new file is named by a folder and a file name: test the two together.
            if !paths.isEmpty {
                for key in Self.filenameKeys {
                    guard let hit = Self.find(key, in: base, count: n, from: 0) else { continue }
                    let (name, _) = Self.readString(base, count: n, from: hit + key.count)
                    guard let name, name.count <= 255 else { continue }
                    for dir in paths {
                        let joined = dir == [0x2F] ? [0x2F] + name : dir + [0x2F] + name
                        if matchesAny(joined) { return true }
                    }
                }
            }
            return false
        }
    }

    private func matchesAny(_ path: [UInt8]) -> Bool {
        for rule in rules where Self.matches(rule, path) { return true }
        return false
    }

    /// The same decision as `FileWatchRule.matches`, on bytes (the line filter is a superset test for the access kind only).
    private static func matches(_ rule: Compiled, _ path: [UInt8]) -> Bool {
        switch rule.mode {
        case .exact:
            guard path == rule.pattern else { return false }
        case .prefix:
            guard (path.count >= rule.pattern.count && path.starts(with: rule.pattern)) || rule.folder.map({ path == $0 }) == true else { return false }
        case .contains:
            guard contains(path, rule.pattern) else { return false }
        }
        if let prefix = rule.requirePrefix, !path.starts(with: prefix) { return false }
        if !rule.requireSuffixes.isEmpty, !rule.requireSuffixes.contains(where: { hasSuffix(path, $0) }) { return false }
        if let need = rule.requireContains, !contains(path, need) { return false }
        if rule.excludeSuffixes.contains(where: { hasSuffix(path, $0) }) { return false }
        if rule.excludeContains.contains(where: { contains(path, $0) }) { return false }
        return true
    }

    private static func hasSuffix(_ path: [UInt8], _ suffix: [UInt8]) -> Bool {
        path.count >= suffix.count && path.suffix(suffix.count).elementsEqual(suffix)
    }

    /// `/private/var/..` -> `/var/..` (same as `FileActorPaths.canonical`).
    private static let privateVar = Array("/private/var/".utf8)
    private static let privateEtc = Array("/private/etc/".utf8)
    private static let privateTmp = Array("/private/tmp/".utf8)
    private static func canonical(_ path: [UInt8]) -> [UInt8] {
        for p in [privateVar, privateEtc, privateTmp] where path.starts(with: p) { return Array(path.dropFirst(8)) }
        return path
    }

    /// The JSON string that starts at `from` (just after its opening quote), unescaped for `\/` only: the bytes up to
    /// the closing quote and the index of that quote. nil when the string is not closed within bounds.
    private static func readString(_ base: UnsafePointer<UInt8>, count n: Int, from: Int) -> ([UInt8]?, Int) {
        var out: [UInt8] = []
        var i = from
        let limit = min(n, from + maxPathBytes + 8)
        while i < limit {
            let c = base[i]
            if c == 0x22 { return (out, i) }
            if c == 0x5C {
                guard i + 1 < n else { return (nil, i) }
                let next = base[i + 1]
                if next == 0x2F { out.append(0x2F) } else if next == 0x5C { out.append(0x5C) } else if next == 0x22 { out.append(0x22) } else {
                    // Another escape (\uXXXX ...): keep it as it is; a path that needs it will not match here
                    // and is not reported. Rare, and the worst case is a missed watched path.
                    out.append(c); out.append(next)
                }
                i += 2
                continue
            }
            out.append(c)
            i += 1
        }
        return (nil, limit)
    }

    private static func find(_ needle: [UInt8], in base: UnsafePointer<UInt8>, count n: Int, from: Int) -> Int? {
        guard from < n, needle.count <= n - from else { return nil }
        return needle.withUnsafeBufferPointer { nb -> Int? in
            guard let found = memmem(base + from, n - from, nb.baseAddress!, nb.count) else { return nil }
            return base.distance(to: found.assumingMemoryBound(to: UInt8.self))
        }
    }

    private static func contains(_ haystack: [UInt8], _ needle: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        return haystack.withUnsafeBufferPointer { hb in
            needle.withUnsafeBufferPointer { nb in
                memmem(hb.baseAddress!, hb.count, nb.baseAddress!, nb.count) != nil
            }
        }
    }
}

// MARK: - Ring buffer (memory only, bounded in count and age)

/// The last few minutes of events that touched a watched file. One bucket per label so a noisy source (an agent that
/// rewrites its own state every second) cannot push out the rarer, more telling events (a read of a decoy).
public final class FileActorRing {
    public static let defaultCapacity: [FileActorLabel: Int] = [.decoy: 256, .agent: 1024, .startup: 1024]
    public static let defaultMaxAge: Double = 180
    public static let dedupeWindow: Double = 2

    private var buckets: [FileActorLabel: [FileActorRecord]] = [:]
    private let capacity: [FileActorLabel: Int]
    private let maxAge: Double

    public init(capacity: [FileActorLabel: Int] = FileActorRing.defaultCapacity, maxAge: Double = FileActorRing.defaultMaxAge) {
        self.capacity = capacity
        self.maxAge = maxAge
    }

    public var count: Int { buckets.values.reduce(0) { $0 + $1.count } }
    public func count(label: FileActorLabel) -> Int { buckets[label]?.count ?? 0 }

    public func removeAll() { buckets.removeAll() }

    /// Forgets the events that `predicate` selects (one stream stopped: its events stop being a complete picture).
    public func removeAll(where predicate: (FileActorRecord) -> Bool) {
        for (label, bucket) in buckets { buckets[label] = bucket.filter { !predicate($0) } }
    }

    /// `record.label` and `record.matchedPath` must be set; otherwise the record is not kept.
    public func add(_ record: FileActorRecord) {
        guard let label = record.label, let matched = record.matchedPath else { return }
        var bucket = buckets[label] ?? []
        // The same process doing the same thing again right away is one entry with a count.
        var index = bucket.count - 1
        var looked = 0
        while index >= 0, looked < 32 {
            let e = bucket[index]
            if e.pid == record.pid, e.kind == record.kind, e.matchedPath == matched,
               e.readsFile == record.readsFile, e.writesFile == record.writesFile,
               abs(record.time - e.time) <= Self.dedupeWindow {
                bucket[index].time = max(e.time, record.time)
                bucket[index].count += record.count
                buckets[label] = bucket
                return
            }
            index -= 1
            looked += 1
        }
        bucket.append(record)
        let cap = max(1, capacity[label] ?? 256)
        if bucket.count > cap { bucket.removeFirst(bucket.count - cap) }
        // Age is measured from the newest event, so an idle recorder keeps what it has until something new arrives.
        let cutoff = record.time - maxAge
        if let first = bucket.first, first.time < cutoff { bucket.removeAll { $0.time < cutoff } }
        buckets[label] = bucket
    }

    /// Drops what is older than `maxAge` before `now`.
    public func prune(now: Double) {
        let cutoff = now - maxAge
        for (label, bucket) in buckets { buckets[label] = bucket.filter { $0.time >= cutoff } }
    }

    /// Events that touched one of `paths` between `since` and `until`, newest first.
    public func search(paths: [String], since: Double, until: Double, limit: Int = 20) -> [FileActorRecord] {
        let wanted = Set(paths.map(FileActorPaths.canonical))
        guard !wanted.isEmpty else { return [] }
        var out: [FileActorRecord] = []
        for bucket in buckets.values {
            for r in bucket where r.time >= since && r.time <= until {
                let touched = (r.matchedPath.map { [$0] } ?? []) + r.paths
                if touched.contains(where: { wanted.contains(FileActorPaths.canonical($0)) }) { out.append(r) }
            }
        }
        out.sort { $0.time > $1.time }
        return Array(out.prefix(max(1, limit)))
    }
}

// MARK: - Request / reply over XPC

public struct FileActorSearchRequest: Codable, Equatable {
    public var paths: [String]
    public var since: Double
    public var until: Double
    public var limit: Int

    public static let maxPaths = 8
    public static let maxLimit = 20

    public init(paths: [String], since: Double, until: Double, limit: Int = 10) {
        self.paths = paths
        self.since = since
        self.until = until
        self.limit = limit
    }

    /// Untrusted input -> bounded values (helper side).
    public func clamped() -> FileActorSearchRequest {
        FileActorSearchRequest(paths: Array(paths.prefix(Self.maxPaths).map { String($0.prefix(1024)) }),
                               since: since, until: until, limit: min(max(limit, 1), Self.maxLimit))
    }
}

public struct FileActorSearchReply: Codable, Equatable {
    /// `FileActorState` raw value of the create / rename / unlink stream (the one that is always cheap).
    public var state: String
    /// When the file-event recording that is running now started: an event earlier than this cannot be in `events`.
    public var coveredSince: Double?
    /// The last time lines were lost (a queue overflow, a restart of eslogger, a pause for load).
    public var lastGapAt: Double?
    /// Whether one of the queried paths is a watched path at all (otherwise "nothing found" says nothing).
    public var covered: Bool
    public var events: [FileActorRecord]
    /// The same three for the `open` stream, which can be paused for load while the other keeps running.
    /// nil: the reply of a helper that has only one stream (`state` covers everything).
    public var openState: String?
    public var openCoveredSince: Double?
    public var openLastGapAt: Double?

    public init(state: String, coveredSince: Double? = nil, lastGapAt: Double? = nil, covered: Bool = false, events: [FileActorRecord] = [],
                openState: String? = nil, openCoveredSince: Double? = nil, openLastGapAt: Double? = nil) {
        self.state = state
        self.coveredSince = coveredSince
        self.lastGapAt = lastGapAt
        self.covered = covered
        self.events = events
        self.openState = openState
        self.openCoveredSince = openCoveredSince
        self.openLastGapAt = openLastGapAt
    }

    /// What "nothing found" is worth. A read (a decoy) can only be seen by the `open` stream. A change can be an open for
    /// writing (an append to `.zshrc`) or a create / rename (an editor's atomic save): both streams must have been running.
    public func coverage(readsOnly: Bool) -> (state: String, coveredSince: Double?, lastGapAt: Double?) {
        guard let openState else { return (state, coveredSince, lastGapAt) }
        if readsOnly { return (openState, openCoveredSince, openLastGapAt) }
        let running = FileActorState.running.rawValue
        let paused = FileActorState.pausedForLoad.rawValue
        let combinedState: String
        if state == running && openState == running { combinedState = running }
        else if state == paused || openState == paused { combinedState = paused }
        else { combinedState = state == running ? openState : state }
        func newest(_ a: Double?, _ b: Double?) -> Double? { [a, b].compactMap { $0 }.max() }
        return (combinedState, newest(coveredSince, openCoveredSince), newest(lastGapAt, openLastGapAt))
    }
}

public enum FileActorState: String, Codable, Equatable {
    case off, starting, running, needsFullDiskAccess, esloggerMissing, backoff, failed
    /// Stopped by the load limit; it starts again by itself after `pausedUntil`.
    case pausedForLoad
    /// Switched on, but the app has not sent any path to watch.
    case noRules
}

/// One eslogger's part of the status.
public struct FileActorStreamStatus: Codable, Equatable {
    public var state: String
    /// Where this stream's events come from now: "es" (the extension's Endpoint Security client) or "eslogger". nil: not running.
    public var source: String?
    public var startedAt: Double?
    /// Average CPU of this stream over the last five minutes, in percent of one core (its eslogger plus the helper's filtering).
    /// While paused: the average that stopped it.
    public var cpuPercent: Double?
    /// The limit in force, percent of one core.
    public var budgetPercent: Double
    public var pausedUntil: Double?
    public var pauseCount: Int
    public var lastError: String?
    public var lastGapAt: Double?
    public var linesSeen: UInt64
    public var linesMatched: UInt64
    public var linesDropped: UInt64

    public init(state: String = FileActorState.off.rawValue, source: String? = nil, startedAt: Double? = nil, cpuPercent: Double? = nil, budgetPercent: Double,
                pausedUntil: Double? = nil, pauseCount: Int = 0, lastError: String? = nil, lastGapAt: Double? = nil,
                linesSeen: UInt64 = 0, linesMatched: UInt64 = 0, linesDropped: UInt64 = 0) {
        self.state = state
        self.source = source
        self.startedAt = startedAt
        self.cpuPercent = cpuPercent
        self.budgetPercent = budgetPercent
        self.pausedUntil = pausedUntil
        self.pauseCount = pauseCount
        self.lastError = lastError
        self.lastGapAt = lastGapAt
        self.linesSeen = linesSeen
        self.linesMatched = linesMatched
        self.linesDropped = linesDropped
    }
}

/// Counters only, no paths and no processes. Root-only (mode 0600) like the exec recorder's status; read through `HelperHealthMirror`.
public struct FileActorStatus: Codable, Equatable {
    /// The create / rename / unlink stream's state (the open stream's is in `open`): "running" here with the open stream
    /// paused means the cheap part still works.
    public var state: String
    public var updatedAt: Double
    public var startedAt: Double?
    public var linesSeen: UInt64
    public var linesMatched: UInt64
    public var linesDropped: UInt64
    public var malformedLines: UInt64
    public var recordsKept: UInt64
    /// Both streams together: percent of one core, five-minute average.
    public var cpuPercent: Double?
    public var pausedUntil: Double?
    public var pauseCount: Int
    public var lastError: String?
    public var lastGapAt: Double?
    public var ruleCount: Int
    /// Per stream. nil in a file written by a helper that had a single stream.
    public var write: FileActorStreamStatus?
    public var open: FileActorStreamStatus?

    public init(state: String = FileActorState.off.rawValue, updatedAt: Double = Date().timeIntervalSince1970, startedAt: Double? = nil,
                linesSeen: UInt64 = 0, linesMatched: UInt64 = 0, linesDropped: UInt64 = 0, malformedLines: UInt64 = 0,
                recordsKept: UInt64 = 0, cpuPercent: Double? = nil, pausedUntil: Double? = nil, pauseCount: Int = 0,
                lastError: String? = nil, lastGapAt: Double? = nil, ruleCount: Int = 0,
                write: FileActorStreamStatus? = nil, open: FileActorStreamStatus? = nil) {
        self.state = state
        self.updatedAt = updatedAt
        self.startedAt = startedAt
        self.linesSeen = linesSeen
        self.linesMatched = linesMatched
        self.linesDropped = linesDropped
        self.malformedLines = malformedLines
        self.recordsKept = recordsKept
        self.cpuPercent = cpuPercent
        self.pausedUntil = pausedUntil
        self.pauseCount = pauseCount
        self.lastError = lastError
        self.lastGapAt = lastGapAt
        self.ruleCount = ruleCount
        self.write = write
        self.open = open
    }

    /// The whole status from the two streams' parts (the top-level fields are what an app that does not know the streams reads).
    public static func combined(write: FileActorStreamStatus, open: FileActorStreamStatus, updatedAt: Double,
                                malformedLines: UInt64, recordsKept: UInt64, ruleCount: Int) -> FileActorStatus {
        let cpus = [write.cpuPercent, open.cpuPercent].compactMap { $0 }
        return FileActorStatus(
            state: write.state, updatedAt: updatedAt, startedAt: write.startedAt,
            linesSeen: write.linesSeen + open.linesSeen, linesMatched: write.linesMatched + open.linesMatched,
            linesDropped: write.linesDropped + open.linesDropped, malformedLines: malformedLines, recordsKept: recordsKept,
            cpuPercent: cpus.isEmpty ? nil : cpus.reduce(0, +),
            pausedUntil: [write.pausedUntil, open.pausedUntil].compactMap { $0 }.max(),
            pauseCount: write.pauseCount + open.pauseCount,
            lastError: write.lastError ?? open.lastError, lastGapAt: [write.lastGapAt, open.lastGapAt].compactMap { $0 }.max(),
            ruleCount: ruleCount, write: write, open: open)
    }

    public static let path = ExecRecorderPaths.stateDir + "/file_actor_status.json"

    public static func read(path: String = FileActorStatus.path) -> FileActorStatus? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(FileActorStatus.self, from: data)
    }
}

// MARK: - Load governor

/// Stops one eslogger when it costs too much. eslogger sends every event of its kinds and spends CPU on each one whether
/// or not we want it, so the cost depends on what the Mac is doing and cannot be known in advance.
/// The helper measures it (CPU time of the eslogger child plus its own filtering time) and gives up for a while
/// when the five-minute average stays over the budget (`strikesToPause` evaluations in a row, 15 s apart). The
/// pauses grow: 15 minutes, 1 hour, 6 hours.
///
/// The budgets come from a measurement on a Mac in normal use (2026-10-24, root, 60 s): `eslogger open` alone was
/// 15,348 lines (256/s) and 3.04 s of CPU, 5.1% of one core. The `open` budget is 12%: 2.3 times that, so ordinary use does
/// not stop it and a build or an install that doubles it still fits, but a Mac that is hammering the disk does stop it.
/// The other stream (create, rename, ...) is a few lines a second; 3% is far above what it costs.
public struct FileActorLoadGovernor {
    public enum Decision: Equatable {
        case ok(percent: Double?)
        case pause(seconds: Double, percent: Double)
    }

    public static let defaultOpenBudgetPercent: Double = 12
    public static let defaultWriteBudgetPercent: Double = 3
    /// The person can change the `open` limit (a setting); these bound what a config file may say.
    public static let minBudgetPercent: Double = ExecRecorderConfig.minFileActorBudgetPercent
    public static let maxBudgetPercent: Double = ExecRecorderConfig.maxFileActorBudgetPercent
    /// What the settings screen offers for the `open` stream.
    public static let openBudgetChoices: [Double] = [6, 12, 20, 30]

    public static func clampedBudget(_ percent: Double?, default fallback: Double) -> Double {
        guard let percent, percent.isFinite else { return fallback }
        return min(max(percent, minBudgetPercent), maxBudgetPercent)
    }
    /// A busy minute (a build, an install) is not what the budget is about: the average is taken over five minutes,
    /// judged only once two minutes of it are known, and must be over the budget four evaluations in a row.
    public static let windowSecs: Double = 300
    public static let minSpanSecs: Double = 120
    public static let strikesToPause = 4
    public static let pauseSteps: [Double] = [900, 3600, 21_600]
    public static let healthyResetSecs: Double = 3600

    public var budgetPercent: Double
    private var samples: [(t: Double, cpu: Double)] = []
    public private(set) var strikes = 0
    public private(set) var pauses = 0
    private var startedAt: Double?

    public init(stream: FileActorStream = .open, budgetPercent: Double? = nil) {
        self.budgetPercent = Self.clampedBudget(budgetPercent, default: stream.defaultBudgetPercent)
    }

    /// Call when eslogger (re)starts: its CPU counter starts from zero again.
    public mutating func noteStarted(at t: Double) {
        samples.removeAll()
        strikes = 0
        startedAt = t
    }

    /// `cumulativeCPU` is CPU seconds used since `noteStarted` (eslogger's own, plus the helper's filtering time).
    public mutating func record(at t: Double, cumulativeCPU: Double) {
        samples.append((t, cumulativeCPU))
        samples.removeAll { t - $0.t > Self.windowSecs + 5 }
    }

    /// Average percent of one core over the window, once there are enough samples.
    public func averagePercent() -> Double? {
        guard let first = samples.first, let last = samples.last, last.t - first.t >= Self.minSpanSecs else { return nil }
        return max(0, (last.cpu - first.cpu) / (last.t - first.t) * 100)
    }

    public mutating func evaluate(now: Double) -> Decision {
        guard let percent = averagePercent() else { return .ok(percent: nil) }
        if percent > budgetPercent {
            strikes += 1
            if strikes >= Self.strikesToPause {
                pauses += 1
                strikes = 0
                samples.removeAll()
                return .pause(seconds: Self.pauseSteps[min(pauses - 1, Self.pauseSteps.count - 1)], percent: percent)
            }
        } else {
            strikes = 0
            if let startedAt, now - startedAt >= Self.healthyResetSecs { pauses = 0 }
        }
        return .ok(percent: percent)
    }
}

// MARK: - The list the app pushes

/// The rules the app asks the helper to keep an eye on. Pure: the app passes in what it knows.
public enum FileActorWatchList {
    public static let maxRules = 400

    /// Files that agents write all the time and that say nothing about the setup (session logs, caches, locks).
    static let agentNoiseSuffixes = [".jsonl", ".log", ".lock", ".swp", ".swx", ".tmp", "~", ".DS_Store"]
    static let agentExcludes = ["/.git/", "/node_modules/", "/.claude/shell-snapshots/", "/.claude/todos/", "/.claude/statsig/",
                                "/.claude/debug/", "/.claude/file-history/", "/.claude/session-env/", "/.claude/ide/",
                                "/.claude/cache/", "/.claude/plugins/cache/", "/.codex/sessions/", "/.codex/log/"]

    /// Names that steer an agent inside a project folder (matched anywhere, below any folder).
    static let projectNames = ["/CLAUDE.md", "/AGENTS.md", "/GEMINI.md", "/.mcp.json", "/.cursorrules", "/.windsurfrules",
                               "/.vscode/mcp.json", "/.vscode/settings.json", "/.vscode/tasks.json"]

    public static func rules(home: String, decoyRelativePaths: [String], agentRoots: [String]) -> [FileWatchRule] {
        var out: [FileWatchRule] = []
        // Decoys: a read is the signal.
        for rel in decoyRelativePaths {
            out.append(FileWatchRule(mode: .exact, pattern: home + "/" + rel, label: .decoy, reads: true))
        }
        // AI agent setup: a write is the signal.
        for root in agentRoots {
            let base = home + "/" + root
            if root == ".claude" {
                out.append(FileWatchRule(mode: .prefix, pattern: base + "/", label: .agent, excludeSuffixes: agentNoiseSuffixes,
                                         excludeContains: ["/.claude/projects/"] + agentExcludes))
                out.append(FileWatchRule(mode: .prefix, pattern: base + "/projects/", label: .agent, requireContains: "/memory/",
                                         excludeSuffixes: agentNoiseSuffixes, excludeContains: agentExcludes))
            } else {
                out.append(FileWatchRule(mode: .prefix, pattern: base + "/", label: .agent, excludeSuffixes: agentNoiseSuffixes,
                                         excludeContains: agentExcludes))
            }
        }
        out.append(FileWatchRule(mode: .exact, pattern: home + "/.claude.json", label: .agent))
        for name in projectNames {
            out.append(FileWatchRule(mode: .contains, pattern: name, label: .agent, excludeSuffixes: agentNoiseSuffixes,
                                     excludeContains: ["/.git/", "/node_modules/"]))
        }
        // Start-up places: a write is the signal.
        for name in [".zshrc", ".zshenv", ".zprofile", ".zlogin", ".zlogout", ".bashrc", ".bash_profile", ".bash_login", ".profile",
                     ".bash_logout", ".config/fish/config.fish", ".ssh/rc"] {
            out.append(FileWatchRule(mode: .exact, pattern: home + "/" + name, label: .startup))
        }
        for path in ["/etc/zshrc", "/etc/zprofile", "/etc/zshenv", "/etc/zlogin", "/etc/profile", "/etc/bashrc", "/etc/ssh/sshrc",
                     "/etc/daily.local", "/etc/weekly.local", "/etc/monthly.local"] {
            out.append(FileWatchRule(mode: .exact, pattern: path, label: .startup))
        }
        // fish runs every conf.d/*.fish at each start.
        out.append(FileWatchRule(mode: .prefix, pattern: home + "/.config/fish/conf.d/", label: .startup, requireSuffixes: [".fish"]))
        for folder in [home + "/Library/LaunchAgents/", "/Library/LaunchAgents/", "/Library/LaunchDaemons/", "/etc/periodic/",
                       "/usr/local/etc/periodic/", "/var/at/tabs/", home + "/.git-templates/hooks/", home + "/.config/git/hooks/",
                       home + "/Library/Scripts/Folder Action Scripts/", "/Library/Scripts/Folder Action Scripts/"] {
            out.append(FileWatchRule(mode: .prefix, pattern: folder, label: .startup))
        }
        // The hooks of a working copy, of a submodule (`.git/modules/x/hooks`) and of a linked worktree (`.git/worktrees/x/hooks`).
        out.append(FileWatchRule(mode: .contains, pattern: "/hooks/", label: .startup, requirePrefix: home + "/", requireContains: "/.git/",
                                 excludeSuffixes: [".sample"]))
        out.append(FileWatchRule(mode: .contains, pattern: "/site-packages/", label: .startup,
                                 requireSuffixes: [".pth", "/sitecustomize.py", "/usercustomize.py"]))
        return Array(out.prefix(maxRules))
    }
}

// MARK: - Engine (rules + ring), pure

/// Takes parsed file events, keeps those that touch a watched file, and answers searches. The helper owns one.
public final class FileActorEngine {
    public private(set) var rules: [FileWatchRule] = []
    public let ring: FileActorRing

    public init(ring: FileActorRing = FileActorRing()) { self.ring = ring }

    public func setRules(_ newRules: [FileWatchRule]) {
        rules = newRules
    }

    /// Keeps `record` when it touches a watched file in a way the rule cares about. Returns whether it was kept.
    @discardableResult
    public func ingest(_ record: FileActorRecord) -> Bool {
        for path in record.paths {
            for rule in rules where rule.matches(path) && rule.accepts(record) {
                var kept = record
                kept.matchedPath = path
                kept.label = rule.label
                ring.add(kept)
                return true
            }
        }
        return false
    }

    /// Whether any of `paths` is watched at all (so "no event found" means something).
    public func watches(_ paths: [String]) -> Bool {
        paths.contains { p in rules.contains { $0.matches(p) } }
    }

    public func search(_ request: FileActorSearchRequest) -> (events: [FileActorRecord], covered: Bool) {
        let r = request.clamped()
        return (ring.search(paths: r.paths, since: r.since, until: r.until, limit: r.limit), watches(r.paths))
    }
}
