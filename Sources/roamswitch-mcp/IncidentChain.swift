// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.36 (build 215).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit
import Darwin

// The evidence chain of the incident timeline, the blind spots around a record, and the keys that tie records of one
// source address or one SSH session together (adoption plan #14). Kept apart from `ContainmentIncidentTimeline` so the
// rules are pure and testable; the timeline calls them when it records and when it is read.

// MARK: - Hash chain

/// Each new record carries `prevHash`, the hash of the record stored just before it, so a record edited or removed
/// from the middle of the file shows as a break at the record after it. The hash covers only what a record never
/// changes after it is written; `resolvedAt`, `resolution` and `evidenceRefs` are filled in later and are left out.
///
/// What it does not do: there is no key, so whoever can write the file can also recompute every hash. It shows a
/// careless or partial edit (and a damaged record), not a determined one. Removing the newest records is not seen
/// either. A break is reported, never repaired, and reading goes on.
public enum IncidentChain {
    /// `prevHash` of the first record when the file had none before it.
    public static let genesis = String(repeating: "0", count: 64)
    static let formatTag = "roamswitch-incident-chain-v1"

    /// SHA-256 (lowercase hex) of the record's fixed fields. Each field is written as `name=<UTF-8 byte count>:<value>`
    /// on its own line, in this order, so no value can be mistaken for another field: id (lowercase UUID), ts (unix
    /// milliseconds), source, severity, summary, process_name, pid, technique, action, parent, root, summary_code
    /// (`code` then each `key=value` sorted by key, joined by U+001E), blind_near (`1` or empty), ssh_session, prev.
    /// An absent value is empty.
    public static func hash(of e: ContainmentIncidentEvent) -> String {
        let ms = Int64((e.timestamp.timeIntervalSince1970 * 1000).rounded())
        let code = e.summaryCode.map { c in
            ([c.code] + c.args.keys.sorted().map { "\($0)=\(c.args[$0] ?? "")" }).joined(separator: "\u{1E}")
        } ?? ""
        let fields: [(String, String)] = [
            ("id", e.id.uuidString.lowercased()),
            ("ts", String(ms)),
            ("source", e.source.rawValue),
            ("severity", e.severity),
            ("summary", e.summary),
            ("process_name", e.processName ?? ""),
            ("pid", e.processID.map { String($0) } ?? ""),
            ("technique", e.attackTechnique ?? ""),
            ("action", e.actionTaken),
            ("parent", e.parentEventID?.uuidString.lowercased() ?? ""),
            ("root", e.rootEventID?.uuidString.lowercased() ?? ""),
            ("summary_code", code),
            ("blind_near", e.blindNear ? "1" : ""),
            ("ssh_session", e.sshSession ?? ""),
            ("prev", e.prevHash ?? ""),
        ]
        var text = formatTag + "\n"
        for (name, value) in fields { text += "\(name)=\(value.utf8.count):\(value)\n" }
        return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Sets `prevHash` of a record about to be stored in front of `newestStored`.
    static func link(_ event: inout ContainmentIncidentEvent, after newestStored: ContainmentIncidentEvent?) {
        event.prevHash = newestStored.map(hash(of:)) ?? genesis
    }

    public struct Verification: Equatable {
        /// Records whose link to the one before them checked out (the oldest kept record counts when its link points to
        /// a record that was dropped by the cap, or is the genesis value).
        public var verified = 0
        /// Records from before the chain existed: they start it and are not checked.
        public var legacy = 0
        /// Records whose link does not match the record before them, or that have no link after the chain began.
        public var breaks: [UUID] = []
        public var intact: Bool { breaks.isEmpty }
    }

    /// Checks the links of records as stored (newest first).
    public static func verify(_ newestFirst: [ContainmentIncidentEvent]) -> Verification {
        var v = Verification()
        var previous: ContainmentIncidentEvent?
        var started = false
        for e in newestFirst.reversed() {
            if let link = e.prevHash {
                if let previous, link != hash(of: previous) {
                    v.breaks.append(e.id)
                } else {
                    v.verified += 1
                }
                started = true
            } else if started {
                v.breaks.append(e.id)
            } else {
                v.legacy += 1
            }
            previous = e
        }
        return v
    }
}

// MARK: - Blind spots

/// Whether the input of the guard that made a record was lost around the record's time: then something related may not
/// have been seen. The same reading as `ExecContext.files` (a gap just before or just after the moment counts), with a
/// window sized for incidents rather than for one file event.
public enum IncidentBlindSpot {
    public static let windowBefore: TimeInterval = 300
    public static let windowAfter: TimeInterval = 60

    /// The guard in `GuardReaderHealthStore.guardSources` whose input a record of `source` came from; nil when the
    /// source has no reader record (ARP, evidence captures, risk acceptances).
    public static func guardKey(for source: ContainmentIncidentSource, code: ContainmentSummaryCode?) -> String? {
        switch source {
        case .sshGuard: return "sshGuard"
        case .portAnomaly:
            // Incoming port scans are recorded under the port-anomaly source; their input is the pf log capture.
            return code?.code.hasPrefix("port_scan.") == true ? "portScanGuard" : nil
        case .runtimeThreat: return "runtimeThreatContainment"
        case .clickFix: return "clickFixGuard"
        case .execRecorder: return "execRecorder"
        case .ransomwareCanary: return "ransomwareCanaryGuard"
        case .ransomwareEntropy: return "ransomwareEntropyGuard"
        case .honeytoken: return "credentialHoneytokenGuard"
        case .browserCredentialWatch: return "browserCredentialWatchGuard"
        case .criticalPathFim: return "criticalPathFim"
        case .reverseShellWatch: return "reverseShellWatch"
        case .networkSettingsWatch: return "networkSettingsWatch"
        case .persistence: return "persistenceMonitor"
        case .rmmInstallerUnofficialSource: return "webMailDownloadGuard"
        case .arpSpoof, .vulnerabilityAcceptance, .forensicCapture: return nil
        }
    }

    /// Pure: true when a record of the guard's inputs is in a gap or cannot be read, or lost input (a gap, a restart)
    /// within `windowBefore` before `time` to `windowAfter` after it.
    public static func isBlindNear(time: Double, guardKey: String, records: [String: GuardReaderHealth]) -> Bool {
        for id in GuardReaderHealthStore.sourceIDs(forGuard: guardKey) {
            guard let h = records[id] else { continue }
            if h.inGap || h.unreadable { return true }
            for at in [h.lastGapAt, h.lastRestartAt].compactMap({ $0 }) where at >= time - windowBefore && at <= time + windowAfter {
                return true
            }
        }
        return false
    }

    /// The same check against the records saved now (the helper's file, the app's preferences, the exec recorder).
    public static func isBlindNear(_ event: ContainmentIncidentEvent, records: [String: GuardReaderHealth]) -> Bool {
        guard let key = guardKey(for: event.source, code: event.summaryCode) else { return false }
        return isBlindNear(time: event.timestamp.timeIntervalSince1970, guardKey: key, records: records)
    }
}

// MARK: - Source address and SSH session

public enum IncidentCorrelation {
    /// The remote address a record is about, normalised (IPv6 compressed, lowercase), from the values its summary was
    /// written with: `source` of the SSH guard and of an incoming port scan, the host part of `peer` of a reverse shell.
    /// Loopback and unspecified addresses tie nothing together and give nil.
    public static func sourceAddress(of e: ContainmentIncidentEvent) -> String? {
        guard let c = e.summaryCode else { return nil }
        let raw: String?
        if c.code.hasPrefix("ssh_guard.") || c.code == "port_scan.incoming" {
            raw = c.args["source"]
        } else if c.code == "reverse_shell.suspected" {
            raw = c.args["peer"].map(hostPart)
        } else {
            raw = nil
        }
        return raw.flatMap(normalizedAddress)
    }

    /// `[v6]:port` -> `v6`, `v4:port` -> `v4`; anything else as it is.
    static func hostPart(_ peer: String) -> String {
        if peer.hasPrefix("["), let close = peer.firstIndex(of: "]") {
            return String(peer[peer.index(after: peer.startIndex)..<close])
        }
        if peer.filter({ $0 == ":" }).count == 1, let colon = peer.firstIndex(of: ":") { return String(peer[..<colon]) }
        return peer
    }

    static func normalizedAddress(_ s: String) -> String? {
        let text = s.trimmingCharacters(in: .whitespaces)
        var v4 = in_addr()
        if inet_pton(AF_INET, text, &v4) == 1 {
            let host = UInt32(bigEndian: v4.s_addr)
            if host >> 24 == 127 || host == 0 { return nil }
            var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            return inet_ntop(AF_INET, &v4, &buf, socklen_t(buf.count)).map { String(cString: $0) }
        }
        var v6 = in6_addr()
        if inet_pton(AF_INET6, text, &v6) == 1 {
            let bytes = withUnsafeBytes(of: v6) { Array($0) }
            if bytes.allSatisfy({ $0 == 0 }) || bytes == [UInt8](repeating: 0, count: 15) + [1] { return nil }
            var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            return inet_ntop(AF_INET6, &v6, &buf, socklen_t(buf.count)).map { String(cString: $0).lowercased() }
        }
        return nil
    }

    /// One process as the session walk sees it.
    public struct ProcessFacts: Equatable {
        public let parentPID: Int32
        /// The executable's file name (`sshd`, `sshd-session`).
        public let name: String
        /// Start time, unix seconds.
        public let startedAt: Int64
        public init(parentPID: Int32, name: String, startedAt: Int64) {
            self.parentPID = parentPID; self.name = name; self.startedAt = startedAt
        }
    }

    static let sshdNames: Set<String> = ["sshd", "sshd-session", "sshd-auth"]
    static let maxAncestors = 32

    /// The SSH session a process runs in, as `<pid>@<start time>` of the outermost sshd of its ancestry (the
    /// per-connection sshd that launchd started), or nil when no sshd is among its ancestors (the process itself
    /// included). The start time keeps a reused PID from joining two sessions.
    public static func sshSession(ofPID pid: Int32, lookup: (Int32) -> ProcessFacts?) -> String? {
        var current = pid
        var outermost: (Int32, Int64)?
        for _ in 0..<maxAncestors {
            guard current > 1, let facts = lookup(current) else { break }
            if sshdNames.contains(facts.name) { outermost = (current, facts.startedAt) }
            else if outermost != nil { break }
            if facts.parentPID == current { break }
            current = facts.parentPID
        }
        return outermost.map { "\($0.0)@\($0.1)" }
    }

    /// The facts of a running process from the process table (nil once it has ended).
    public static func liveFacts(_ pid: Int32) -> ProcessFacts? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        var pathBuf = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let name: String
        if proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count)) > 0 {
            name = (String(cString: pathBuf) as NSString).lastPathComponent
        } else {
            name = withUnsafeBytes(of: info.pbi_comm) { raw in
                String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
            }
        }
        return ProcessFacts(parentPID: Int32(bitPattern: info.pbi_ppid), name: name, startedAt: Int64(info.pbi_start_tvsec))
    }
}
