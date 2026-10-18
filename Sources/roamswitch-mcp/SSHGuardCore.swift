// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.12.6 (build 168).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// SSH brute-force guard, the pure parts: reading an sshd line out of the unified log, counting failures per
/// source, deciding who is exempt, how long a ban lasts, and the pf text for it. Everything here is free of
/// processes and files so it is unit-tested (`SSHGuardCoreTests`) against real log lines; the helper side
/// (`SSHGuardDetector`) only wires it to `log stream`, pf and the disk.
///
/// The Linux edition's `ssh_guard.rs` is the same design on journald and nftables. What differs here:
/// - the stream is `log stream --style ndjson`, whose JSON carries the process image path, so a line that
///   some other program wrote with `logger -t sshd` is dropped by the path, not by the name;
/// - sshd on macOS runs one process per connection (launchd socket activation), and newer OpenSSH splits it
///   into sshd-session and sshd-auth, so a connection is identified by `(address, port)`, never by pid.

// MARK: - Records

/// One sshd event worth looking at, reduced to fixed fields. This is the only thing the unprivileged parse
/// worker hands back to the root helper (see `ParseWorkerWire`).
struct SSHLogRecord: Codable, Equatable {
    enum Kind: String, Codable {
        /// `Failed password for ...` and `Failed keyboard-interactive/pam for ...`. `Failed publickey` and
        /// `Failed none` are not failures of a guess and are never turned into a record.
        case failedPassword
        case invalidUser
        /// `Connection closed by authenticating user ...` / `Disconnected from authenticating user ... [preauth]`.
        case preauthClose
        case maxAuthExceeded
        case accepted
    }

    var kind: Kind
    /// Canonical address of the peer: IPv4, or IPv6 (an IPv4-mapped IPv6 address is already unwrapped).
    var ip: String
    var port: UInt16
    var pid: Int32
    /// The account the peer named. Attacker-controlled for a failure (shown only after `sanitizedUser`);
    /// for `accepted` it is a real account.
    var user: String?
    /// `publickey`, `password`, `keyboard-interactive/pam`, ... (`accepted` only).
    var method: String?
    var keyType: String?
    var fingerprint: String?
}

// MARK: - Parsing an sshd line

enum SSHLogParser {
    /// The programs whose log lines count as sshd's. Checked against the log entry's image path, not its
    /// name, because anyone can write a line under the name `sshd` (`logger -t sshd`).
    static let sshdImagePaths: Set<String> = ["/usr/sbin/sshd", "/usr/libexec/sshd-session", "/usr/libexec/sshd-auth"]
    static let maxLineBytes = 16 * 1024
    static let maxMessageChars = 2048

    /// One line of `log stream --style ndjson`.
    static func parse(ndjson line: Data) -> SSHLogRecord? {
        guard line.count <= maxLineBytes,
              let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let path = object["processImagePath"] as? String, sshdImagePaths.contains(path),
              let message = object["eventMessage"] as? String else { return nil }
        let pid: Int32
        if let n = object["processID"] as? Int, n > 0, n <= Int(Int32.max) { pid = Int32(n) } else { pid = 0 }
        return parse(message: message, pid: pid)
    }

    static func parse(message raw: String, pid: Int32) -> SSHLogRecord? {
        guard raw.count <= maxMessageChars else { return nil }
        var msg = raw
        if msg.hasSuffix(" [preauth]") { msg.removeLast(" [preauth]".count) }
        // Optional prefix some sshd builds put on a line ("error: ", "fatal: ").
        for prefix in ["error: ", "fatal: "] where msg.hasPrefix(prefix) { msg.removeFirst(prefix.count) }
        let tokens = msg.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        guard tokens.count >= 4 else { return nil }

        if msg.hasPrefix("Accepted ") { return parseAccepted(tokens, pid: pid) }

        let kind: SSHLogRecord.Kind
        var userFirst: Int           // index of the first token of the user name, when it can be found
        var userEndsAtFrom = true    // the user name is followed by "from <ip>"
        if msg.hasPrefix("Failed password for ") || msg.hasPrefix("Failed keyboard-interactive") {
            // "Failed password for [invalid user ]NAME from IP port N ssh2"
            guard tokens[2] == "for" else { return nil }
            kind = .failedPassword
            userFirst = 3
            if tokens.count > 5, tokens[3] == "invalid", tokens[4] == "user" { userFirst = 5 }
        } else if msg.hasPrefix("Invalid user ") {
            kind = .invalidUser
            userFirst = 2
        } else if msg.hasPrefix("maximum authentication attempts exceeded for ") {
            kind = .maxAuthExceeded
            userFirst = 5
            if tokens.count > 7, tokens[5] == "invalid", tokens[6] == "user" { userFirst = 7 }
        } else if msg.hasPrefix("Connection closed by authenticating user ") || msg.hasPrefix("Connection closed by invalid user ")
                    || msg.hasPrefix("Disconnected from authenticating user ") || msg.hasPrefix("Disconnected from invalid user ") {
            // Only a connection that never got past authentication is a failed login; the same lines without
            // "[preauth]" are a normal logout.
            guard raw.hasSuffix(" [preauth]") else { return nil }
            kind = .preauthClose
            userEndsAtFrom = false
            userFirst = msg.hasPrefix("Connection closed by ") ? 5 : 4
        } else {
            return nil
        }

        guard let tail = splitTail(tokens, acceptsSSH2Trailer: false) else { return nil }
        var user: String?
        if userFirst < tail.ipIndex {
            var end = tail.ipIndex
            if userEndsAtFrom {
                guard tokens[tail.ipIndex - 1] == "from" else { return nil }
                end -= 1
            }
            if userFirst < end { user = sanitizedUser(tokens[userFirst..<end].joined(separator: " ")) }
        }
        return SSHLogRecord(kind: kind, ip: tail.ip, port: tail.port, pid: pid, user: user,
                            method: nil, keyType: nil, fingerprint: nil)
    }

    /// `Accepted publickey for NAME from IP port N ssh2: ED25519 SHA256:...` (and `Accepted password for ...`).
    private static func parseAccepted(_ tokens: [String], pid: Int32) -> SSHLogRecord? {
        guard tokens.count >= 8, tokens[2] == "for" else { return nil }
        guard let tail = splitTail(tokens, acceptsSSH2Trailer: true), tokens[tail.ipIndex - 1] == "from", tail.ipIndex - 1 > 3 else { return nil }
        let user = sanitizedUser(tokens[3..<(tail.ipIndex - 1)].joined(separator: " "))
        var keyType: String?
        var fingerprint: String?
        let rest = tokens[(tail.portIndex + 2)...]          // "ssh2:" / "ssh2" and what follows
        if rest.first == "ssh2:", rest.count >= 3 {
            let r = Array(rest)
            keyType = String(r[1].prefix(40))
            if r[2].hasPrefix("SHA256:") || r[2].hasPrefix("MD5:") { fingerprint = String(r[2].prefix(80)) }
        }
        return SSHLogRecord(kind: .accepted, ip: tail.ip, port: tail.port, pid: pid, user: user,
                            method: String(tokens[1].prefix(40)), keyType: keyType, fingerprint: fingerprint)
    }

    private struct Tail { var ipIndex: Int; var portIndex: Int; var ip: String; var port: UInt16 }

    /// Finds the peer's `IP port N` from the END of the line. A user name is chosen by the peer and can
    /// contain a fake "from 1.2.3.4 port 1", so the address is only ever read from the fixed tail sshd writes
    /// itself: `IP port N`, `IP port N ssh2`, and for an accepted login `IP port N ssh2: TYPE FINGERPRINT ...`.
    /// A line whose tail is anything else is rejected rather than searched further left.
    private static func splitTail(_ t: [String], acceptsSSH2Trailer: Bool) -> Tail? {
        func make(portIndex: Int) -> Tail? {
            guard portIndex >= 2, t[portIndex] == "port", let n = UInt16(t[portIndex + 1]), n > 0,
                  let ip = SSHGuardAddress.canonical(t[portIndex - 1]) else { return nil }
            return Tail(ipIndex: portIndex - 1, portIndex: portIndex, ip: ip, port: n)
        }
        let n = t.count
        if acceptsSSH2Trailer {
            // The LAST "port N ssh2:" / "port N ssh2" wins.
            var i = n - 3
            while i >= 2 {
                if t[i] == "port", UInt16(t[i + 1]) != nil, t[i + 2] == "ssh2" || t[i + 2] == "ssh2:" {
                    if let tail = make(portIndex: i) { return tail }
                }
                i -= 1
            }
            return nil
        }
        if n >= 5, t[n - 1] == "ssh2" { return make(portIndex: n - 3) }
        if n >= 4 { return make(portIndex: n - 2) }
        return nil
    }

    /// A user name as it may be stored or shown: at most 32 characters, only `[A-Za-z0-9._@$-]`, anything else
    /// becomes `?`. The name is chosen by the peer (and sshd escapes control characters, not spaces or
    /// look-alike characters), so it is never stored as received.
    static func sanitizedUser(_ s: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._@$-")
        let mapped = s.unicodeScalars.prefix(32).map { allowed.contains($0) ? Character($0) : "?" }
        return String(mapped)
    }
}

// MARK: - Addresses

/// A network: one host or a prefix. The ban key for IPv4 is the host, for IPv6 the /64.
struct SSHNet: Equatable {
    var bytes: [UInt8]       // 4 or 16
    var prefix: Int

    var isV6: Bool { bytes.count == 16 }

    /// Whether the two networks share any address.
    func overlaps(_ other: SSHNet) -> Bool {
        guard bytes.count == other.bytes.count else { return false }
        let bits = min(prefix, other.prefix)
        var remaining = bits
        var i = 0
        while remaining > 0 {
            let take = min(8, remaining)
            let mask = UInt8(truncatingIfNeeded: 0xFF << (8 - take))
            if (bytes[i] & mask) != (other.bytes[i] & mask) { return false }
            remaining -= take
            i += 1
        }
        return true
    }

    /// `1.2.3.4`, `10.0.0.0/8`, `2001:db8::1`, `2001:db8::/32`. IPv4-mapped IPv6 is read as IPv4.
    init?(parsing raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.utf8.count <= 64 else { return nil }
        let parts = trimmed.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard parts.count <= 2 else { return nil }
        guard let host = SSHGuardAddress.bytes(of: parts[0]) else { return nil }
        var bits = host.count * 8
        if parts.count == 2 {
            guard let p = Int(parts[1]), String(p) == parts[1], p >= 0, p <= bits else { return nil }
            bits = p
        }
        // An IPv4-mapped IPv6 prefix is not worth supporting; only the host form was unwrapped above.
        self.bytes = host
        self.prefix = bits
    }

    init(bytes: [UInt8], prefix: Int) { self.bytes = bytes; self.prefix = prefix }
}

enum SSHGuardAddress {
    /// Raw bytes of an IPv4/IPv6 literal (zone id dropped, IPv4-mapped IPv6 unwrapped to 4 bytes).
    static func bytes(of raw: String) -> [UInt8]? {
        let noZone = raw.split(separator: "%", maxSplits: 1).first.map(String.init) ?? raw
        var v4 = in_addr()
        if inet_pton(AF_INET, noZone, &v4) == 1 {
            return withUnsafeBytes(of: &v4) { Array($0) }
        }
        var v6 = in6_addr()
        if inet_pton(AF_INET6, noZone, &v6) == 1 {
            let b = withUnsafeBytes(of: &v6) { Array($0) }
            if b[0..<10].allSatisfy({ $0 == 0 }), b[10] == 0xFF, b[11] == 0xFF { return Array(b[12..<16]) }
            return b
        }
        return nil
    }

    static func text(of bytes: [UInt8]) -> String? {
        var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        if bytes.count == 4 {
            var a = in_addr()
            withUnsafeMutableBytes(of: &a) { $0.copyBytes(from: bytes) }
            guard inet_ntop(AF_INET, &a, &buf, socklen_t(INET_ADDRSTRLEN)) != nil else { return nil }
        } else if bytes.count == 16 {
            var a = in6_addr()
            withUnsafeMutableBytes(of: &a) { $0.copyBytes(from: bytes) }
            guard inet_ntop(AF_INET6, &a, &buf, socklen_t(INET6_ADDRSTRLEN)) != nil else { return nil }
        } else {
            return nil
        }
        return String(cString: buf)
    }

    /// Canonical text of a literal address (no prefix), or nil. IPv4-mapped IPv6 comes back as IPv4.
    static func canonical(_ raw: String) -> String? {
        guard !raw.contains("/"), let b = bytes(of: raw) else { return nil }
        return text(of: b)
    }

    /// What failures are counted against and what a ban covers: the address for IPv4, the /64 for IPv6
    /// (one customer is normally handed a /64, and rotating inside it is free).
    static func sourceKey(for canonicalIP: String) -> String? {
        guard let b = bytes(of: canonicalIP) else { return nil }
        if b.count == 4 { return text(of: b) }
        let masked = Array(b[0..<8]) + [UInt8](repeating: 0, count: 8)
        guard let t = text(of: masked) else { return nil }
        return t + "/64"
    }

    /// A ban key accepted for a pf rule: a host IPv4, or an IPv6 /64 in canonical form. Anything else is nil,
    /// so nothing but these two shapes can reach the ruleset text.
    static func validBlockKey(_ raw: String) -> String? {
        if raw.contains("/") {
            guard let net = SSHNet(parsing: raw), net.isV6, net.prefix == 64 else { return nil }
            return sourceKey(for: text(of: net.bytes) ?? "")
        }
        guard let b = bytes(of: raw), b.count == 4 else { return nil }
        return text(of: b)
    }

    static func net(forKey key: String) -> SSHNet? { SSHNet(parsing: key) }
}

// MARK: - Failure counting

/// Failures per source inside a sliding window. Times are monotonic seconds supplied by the caller.
struct SSHFailureTracker {
    private(set) var windowSecs: TimeInterval
    private var hits: [String: [TimeInterval]] = [:]
    static let maxKeys = 4096

    init(windowSecs: TimeInterval) { self.windowSecs = windowSecs }

    @discardableResult
    mutating func record(key: String, count: Int = 1, now: TimeInterval) -> Int {
        if hits[key] == nil, hits.count >= Self.maxKeys {
            // Bounded: drop everything that has already aged out; if that is not enough, the oldest source.
            hits = hits.filter { ($0.value.last ?? 0) > now - windowSecs }
            if hits.count >= Self.maxKeys, let oldest = hits.min(by: { ($0.value.last ?? 0) < ($1.value.last ?? 0) })?.key {
                hits.removeValue(forKey: oldest)
            }
        }
        var list = (hits[key] ?? []).filter { $0 > now - windowSecs }
        list.append(contentsOf: Array(repeating: now, count: max(0, min(count, 1000))))
        hits[key] = list
        return list.count
    }

    func count(key: String, now: TimeInterval) -> Int {
        (hits[key] ?? []).filter { $0 > now - windowSecs }.count
    }

    mutating func reset(key: String) { hits.removeValue(forKey: key) }
}

/// Turns the several lines one login attempt produces into one failure each. A wrong password for an unknown
/// user logs `Invalid user`, then `Failed password for invalid user`, then (after the last try) a
/// `Connection closed ... [preauth]`: three lines, one or two attempts. Per connection (address and port) the
/// count is the larger of the number of `Failed password` lines and 1 (when any other failure line was seen),
/// and only the increase is reported.
struct SSHConnectionLedger {
    private struct Entry { var failedLines = 0; var otherSeen = false; var counted = 0; var lastSeen: TimeInterval = 0 }
    private var entries: [String: Entry] = [:]
    static let maxEntries = 8192
    static let retainSecs: TimeInterval = 3600

    /// How many NEW failures this record adds (0 or more). `accepted` adds none.
    mutating func newFailures(for record: SSHLogRecord, now: TimeInterval) -> Int {
        guard record.kind != .accepted else { return 0 }
        if entries.count >= Self.maxEntries {
            entries = entries.filter { now - $0.value.lastSeen < Self.retainSecs }
            if entries.count >= Self.maxEntries { entries.removeAll() }
        }
        let key = "\(record.ip)|\(record.port)"
        var e = entries[key] ?? Entry()
        if now - e.lastSeen >= Self.retainSecs, e.lastSeen > 0 { e = Entry() }   // the source port was reused much later
        switch record.kind {
        case .failedPassword: e.failedLines += 1
        default: e.otherSeen = true
        }
        let total = max(e.failedLines, e.otherSeen ? 1 : 0)
        let delta = total - e.counted
        e.counted = total
        e.lastSeen = now
        entries[key] = e
        return max(0, delta)
    }
}

// MARK: - Configuration, bans, exemptions

struct SSHGuardConfig: Codable, Equatable {
    var enabled: Bool = false
    var blockEnabled: Bool = true
    var maxFailures: Int = 6
    var windowSecs: TimeInterval = 600
    var firstBanSecs: TimeInterval = 3600
    var repeatMultiplier: Int = 4
    var maxBanSecs: TimeInterval = 604_800
    /// An address that logged in with a public key this recently is never banned.
    var pubkeyExemptDays: Int = 30
    /// Addresses / prefixes the user never wants banned.
    var exemptList: [String] = []

    static let maxExemptEntries = 256

    /// The same configuration with every number inside its range and the exemption list cut down to entries
    /// that parse. A value from the app is never trusted: it ends up deciding which addresses may be cut off.
    func sanitized() -> SSHGuardConfig {
        var c = self
        c.maxFailures = min(max(maxFailures, 3), 100)
        c.windowSecs = windowSecs.isFinite ? min(max(windowSecs, 60), 86_400) : 600
        c.maxBanSecs = maxBanSecs.isFinite ? min(max(maxBanSecs, 60), 30 * 86_400) : 604_800
        c.firstBanSecs = firstBanSecs.isFinite ? min(max(firstBanSecs, 60), c.maxBanSecs) : 3600
        c.repeatMultiplier = min(max(repeatMultiplier, 1), 10)
        c.pubkeyExemptDays = min(max(pubkeyExemptDays, 0), 365)
        var seen = Set<String>()
        c.exemptList = exemptList.compactMap { raw -> String? in
            let t = raw.trimmingCharacters(in: .whitespaces)
            guard SSHNet(parsing: t) != nil, seen.insert(t).inserted else { return nil }
            return t
        }
        if c.exemptList.count > Self.maxExemptEntries { c.exemptList = Array(c.exemptList.prefix(Self.maxExemptEntries)) }
        return c
    }
}

enum SSHBanPolicy {
    /// First ban `firstBanSecs`; each earlier ban of the same source multiplies it by `repeatMultiplier`, up to `maxBanSecs`.
    static func duration(priorBans: Int, config: SSHGuardConfig) -> TimeInterval {
        var d = config.firstBanSecs
        var n = max(0, priorBans)
        while n > 0, d < config.maxBanSecs {
            d *= Double(config.repeatMultiplier)
            n -= 1
        }
        return min(d, config.maxBanSecs)
    }
}

enum SSHExemptionPolicy {
    /// Why `key` (a ban key) must not be banned, or nil if it may be.
    /// - `userList`: the user's own entries.
    /// - `sessionIPs`: sources of SSH connections that are established right now.
    /// - `pubkeyOK`: sources that logged in with a public key, with the time they last did.
    static func reason(forKey key: String, userList: [String], sessionIPs: [String],
                       pubkeyOK: [String: Date], pubkeyDays: Int, now: Date) -> String? {
        guard let target = SSHGuardAddress.net(forKey: key) else { return "not a valid address" }
        for entry in userList {
            if let net = SSHNet(parsing: entry), net.overlaps(target) { return "it is on the exemption list (\(entry))" }
        }
        for ip in sessionIPs {
            if let net = SSHNet(parsing: ip), net.overlaps(target) { return "an SSH session from it is open now" }
        }
        if pubkeyDays > 0 {
            let cutoff = now.addingTimeInterval(-Double(pubkeyDays) * 86_400)
            for (k, at) in pubkeyOK where at >= cutoff {
                if let net = SSHNet(parsing: k), net.overlaps(target) { return "it logged in with a public key within \(pubkeyDays) days" }
            }
        }
        return nil
    }
}

// MARK: - Open SSH connections (ps and lsof)

enum SSHActiveConnections {
    /// `(peer address, peer port)` of the TCP connections in `lsof -nP -iTCP -F n` output
    /// (`n192.168.64.4:22->192.168.64.1:50000`, IPv6 as `n[fda0::1]:22->[fda0::2]:50100`). With `localPorts`,
    /// only those whose local port is in it. (`netstat -an` is not used: it cuts a long IPv6 address short,
    /// `fda0:ff0b:429c:5.22`, measured on macOS 26.6.)
    static func parsePeers(lsofFields text: String, localPorts: Set<Int>? = nil) -> [(ip: String, port: Int)] {
        var out: [(String, Int)] = []
        var seen = Set<String>()
        for line in text.split(whereSeparator: \.isNewline) where line.hasPrefix("n") {
            let body = String(line.dropFirst())
            let halves = body.components(separatedBy: "->")
            guard halves.count == 2, let local = splitHostPort(halves[0]), let remote = splitHostPort(halves[1]),
                  let ip = SSHGuardAddress.canonical(remote.host) else { continue }
            if let localPorts, !localPorts.contains(local.port) { continue }
            if seen.insert("\(ip)|\(remote.port)").inserted { out.append((ip, remote.port)) }
        }
        return out
    }

    private static func splitHostPort(_ s: String) -> (host: String, port: Int)? {
        if s.hasPrefix("[") {
            guard let close = s.firstIndex(of: "]"), s[s.index(after: close)...].hasPrefix(":"),
                  let port = Int(s[s.index(close, offsetBy: 2)...]) else { return nil }
            return (String(s[s.index(after: s.startIndex)..<close]), port)
        }
        guard let colon = s.lastIndex(of: ":"), let port = Int(s[s.index(after: colon)...]) else { return nil }
        return (String(s[..<colon]), port)
    }

    /// Whether an sshd process title belongs to a LOGGED-IN session. After login it is `sshd-session: NAME@ttys000`
    /// (or `@notty`); before it is `sshd-session: NAME [priv]` or `sshd-session: [accepted]`. The name in the
    /// second form is chosen by the peer, but it is always followed by ` [priv]`, so a title that ends in
    /// `NAME@TTY` with nothing after it cannot be made up by a peer that has not authenticated. Older OpenSSH
    /// titles its processes `sshd:`.
    static func isAuthenticatedSessionTitle(_ rawTitle: String) -> Bool {
        let command = rawTitle.trimmingCharacters(in: .whitespaces)
        for prefix in ["sshd-session: ", "sshd: "] where command.hasPrefix(prefix) {
            let title = String(command.dropFirst(prefix.count))
            guard !title.hasSuffix("]"), let at = title.lastIndex(of: "@"),
                  at != title.startIndex, title.index(after: at) != title.endIndex,
                  !title[title.index(after: at)...].contains(" ") else { continue }
            return true
        }
        return false
    }

    /// pids of logged-in sessions from `ps -axww -o pid=,command=` output.
    static func authenticatedSessionPIDs(psOutput: String) -> [Int32] {
        var pids: [Int32] = []
        for raw in psOutput.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard let space = line.firstIndex(of: " "), let pid = Int32(line[..<space]), pid > 1 else { continue }
            if isAuthenticatedSessionTitle(String(line[line.index(after: space)...])) { pids.append(pid) }
        }
        return pids
    }

    /// The process title out of a `sysctl(KERN_PROCARGS2)` buffer: an Int32 `argc`, the executable path, NUL
    /// padding, then the arguments (`setproctitle` rewrites them, so for sshd the title is argv[0]). The helper
    /// reads it this way because `/bin/ps` cannot be started inside the helper's sandbox (measured on macOS 26.6:
    /// "Operation not permitted").
    static func title(fromProcArgs2 bytes: [UInt8]) -> String? {
        guard bytes.count > 8 else { return nil }
        var i = 4
        while i < bytes.count, bytes[i] != 0 { i += 1 }            // executable path
        while i < bytes.count, bytes[i] == 0 { i += 1 }            // padding
        guard i < bytes.count else { return nil }
        var parts: [String] = []
        var start = i
        let argc = Int(bytes[0]) | Int(bytes[1]) << 8 | Int(bytes[2]) << 16 | Int(bytes[3]) << 24    // little endian (arm64, x86_64)
        while i < bytes.count, parts.count < min(max(argc, 1), 16) {
            if bytes[i] == 0 {
                parts.append(String(decoding: bytes[start..<i], as: UTF8.self))
                start = i + 1
            }
            i += 1
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// MARK: - Other tools that ban SSH sources

enum SSHExternalGuardDetection {
    /// Names whose presence in the process list means another tool is already banning SSH sources.
    static let knownNames: Set<String> = ["fail2ban-server", "fail2ban-client", "fail2ban", "sshguard", "denyhosts", "denyhosts.py", "sshit", "blockhosts"]
    private static let interpreters = ["python", "python3", "perl", "ruby", "sh", "bash", "zsh"]

    /// `ps -axww -o command` output. Returns the name found, or nil. A match is by program name: the first
    /// word's last path component, or, after an interpreter, the script name. It is not a substring search, so
    /// an editor open on "fail2ban.conf" does not count.
    static func detect(psOutput: String) -> String? {
        for line in psOutput.split(whereSeparator: \.isNewline) {
            let words = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard let first = words.first else { continue }
            let base = (first as NSString).lastPathComponent.lowercased()
            if knownNames.contains(base) { return base }
            let isInterpreter = interpreters.contains(base) || base.hasPrefix("python")
            if isInterpreter, let script = words.dropFirst().first(where: { !$0.hasPrefix("-") }) {
                let name = (script as NSString).lastPathComponent.lowercased()
                if knownNames.contains(name) { return name }
            }
        }
        return nil
    }
}

// MARK: - pf text for the bans

/// One active ban as pf needs it.
struct SSHBlockSpec: Equatable {
    var key: String        // from `SSHGuardAddress.validBlockKey`
    var ports: [Int]
}

enum SSHBlockRules {
    /// `block drop in quick proto tcp from { ... } to any port { ... } flags S/SA` per distinct port list: only
    /// new connections (SYN) to the SSH ports are refused, so a connection that is already established keeps
    /// working and nothing but SSH is affected. Keys and ports are re-validated here; an entry that does not
    /// pass is left out, so a corrupt state file can never put text into the ruleset.
    static func rules(_ specs: [SSHBlockSpec]) -> String {
        var groups: [[Int]: [String]] = [:]
        for s in specs {
            guard let key = SSHGuardAddress.validBlockKey(s.key) else { continue }
            let ports = Array(Set(s.ports.filter { (1...65535).contains($0) })).sorted()
            guard !ports.isEmpty else { continue }
            groups[ports, default: []].append(key)
        }
        var out = ""
        for ports in groups.keys.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            let keys = Set(groups[ports] ?? []).sorted()
            out += "block drop in quick proto tcp from { \(keys.joined(separator: ", ")) } to any port { \(ports.map(String.init).joined(separator: ", ")) } flags S/SA\n"
        }
        return out
    }

    /// Puts the ban rules right after `anchorCall` (the main ruleset's anchor line): they are `quick`, so they
    /// must come before the `pass quick` holes of a kill-switch ruleset to win. Same placement rule as
    /// `KnownAttackServers.insertingEgressBlock`.
    static func inserting(into rules: String, anchorCall: String, specs: [SSHBlockSpec]) -> String {
        let block = Self.rules(specs)
        guard !block.isEmpty else { return rules }
        if let r = rules.range(of: anchorCall) {
            return rules.replacingCharacters(in: r, with: anchorCall + block)
        }
        let skip = "set skip on lo0\n"
        if let r = rules.range(of: skip) {
            return rules.replacingCharacters(in: r, with: skip + block)
        }
        return block + rules
    }

    /// Strings `pfctl -sr` should contain for the ban keys, to confirm the ruleset really loaded.
    static func expectedFragments(_ specs: [SSHBlockSpec]) -> [String] {
        specs.compactMap { SSHGuardAddress.validBlockKey($0.key) }
    }

    /// The ports sshd listens on: 22 (launchd's own socket for Remote Login) plus any `Port` line of
    /// sshd_config and its drop-ins. Pure, so it can be tested; the caller reads the files.
    static func ports(fromSSHDConfigTexts texts: [String]) -> [Int] {
        var ports: Set<Int> = [22]
        for text in texts {
            for line in text.split(whereSeparator: \.isNewline) {
                let words = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
                guard words.count >= 2, words[0].lowercased() == "port", !words[0].hasPrefix("#"),
                      let p = Int(words[1]), (1...65535).contains(p) else { continue }
                ports.insert(p)
            }
        }
        return ports.sorted()
    }
}

// MARK: - State the helper hands to the app (JSON over XPC)

/// One SSH login (an `Accepted` line).
struct SSHSession: Codable, Identifiable, Equatable {
    var id: UUID
    var time: Date
    var user: String
    var ip: String
    var port: Int
    var method: String
    var keyType: String?
    var fingerprint: String?
    /// Filled in when the app asks (the helper looks at the live connections then); not stored.
    var active: Bool?
}

struct SSHGuardIncident: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        /// The source reached the limit and was banned.
        case banned
        /// The source reached the limit but was not banned (exempt, banning off, another tool does it, or pf failed); see `note`.
        case detected
        /// A login succeeded from a source that had been failing: possible successful guess.
        case successAfterFailures
    }
    var id: UUID
    var timestamp: Date
    var kind: Kind
    /// Ban key: the address, or the /64 for IPv6.
    var source: String
    var failureCount: Int
    var windowSecs: TimeInterval
    var banSecs: TimeInterval?
    var ports: [Int]
    /// Why nothing was banned (kind `detected`), or the error pf reported.
    var note: String?
    /// Up to 5 account names the source tried (sanitized).
    var usersTried: [String]
    /// For `successAfterFailures`: the login.
    var session: SSHSession?
    /// Whether the app should raise a notification for this record. A ban and a success after failures always
    /// do; a record of a ban that was withheld on purpose (an exempt source, the gateway) does not.
    var notifyUser: Bool = true
}

struct SSHGuardBan: Codable, Identifiable, Equatable {
    var id: String { source }
    var source: String
    var expiresAt: Date
    var remainingSecs: TimeInterval
    var ports: [Int]
}

struct SSHGuardStatus: Codable, Equatable {
    var enabled: Bool
    /// Remote Login (sshd) is on in this moment.
    var sshdActive: Bool
    /// The log stream is running (enabled and sshdActive).
    var watching: Bool
    var ports: [Int]
    var bans: [SSHGuardBan]
    /// Name of another tool that bans SSH sources and is running, if any (then this guard only notifies).
    var externalGuard: String?
}
