// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.5 (build 123).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

public struct ListeningPortInfo: Identifiable, Equatable, Hashable {
    public var id: String { "\(processName):\(port):\(pid)" }
    public let processName: String
    public let pid: Int
    public let port: Int
    public let isGloballyExposed: Bool
    public let executablePath: String?
    /// The address the socket is bound to as `lsof` prints it (`*`,
    /// `127.0.0.1`, `[fe80::1]`, `192.168.1.5`), empty when unknown.
    public var bindHost: String = ""
    /// `"tcp"` or `"udp"`.
    public var proto: String = "tcp"
    /// Owned by another user (a root daemon). The app's own user can't inspect
    /// these; they come from the privileged helper's `lsof` (see
    /// `HelperManager.listeningSocketsText`).
    public var otherUser: Bool = false

    /// Reachable from the network, not just this Mac: a wildcard bind
    /// **or a bind to any concrete non-loopback address**. A backdoor that
    /// binds straight to the LAN address (`192.168.1.5:4444`) is as exposed
    /// as one on `0.0.0.0` but is not `isGloballyExposed`.
    public var isNetworkReachable: Bool {
        isGloballyExposed || Self.isReachableBind(bindHost)
    }

    static func isReachableBind(_ host: String) -> Bool {
        var h = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).lowercased()
        if let zone = h.firstIndex(of: "%") { h = String(h[..<zone]) }
        if h.isEmpty || h == "localhost" || h == "::1" || h.hasPrefix("127.") { return false }
        if h.hasPrefix("::ffff:127.") { return false }
        return true
    }
}

final class ListeningPortMonitor {
    static let shared = ListeningPortMonitor()

    func scanListeningPorts() -> [ListeningPortInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            return parseLsofOutput(output)
        } catch {
            return []
        }
    }

    /// Bound (non-connected) UDP sockets. Kept separate from
    /// `scanListeningPorts()` so the many TCP-only consumers are unaffected.
    func scanUDPListeners() -> [ListeningPortInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iUDP", "-n", "-P"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return parseLsofOutput(String(data: data, encoding: .utf8) ?? "", proto: "udp")
        } catch {
            return []
        }
    }

    /// The first non-flag argument on a process's command line — usually the
    /// script it's running when the process is an interpreter, e.g. `wsdd`
    /// for `python3 /usr/bin/wsdd --discovery`. Reads `KERN_PROCARGS2` via
    /// `sysctl`, which macOS restricts to the calling user's own processes
    /// (or root): `nil` for another user's process, one that has already
    /// exited, or one with no such argument (inline code, a bare REPL).
    static func firstCommandLineArgument(pid: Int) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, Int32(pid)]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return nil }

        // Layout: argc (Int32), then the exec path (NUL-terminated) padded
        // with extra NULs to alignment, then argv[0]..argv[argc-1], each
        // NUL-terminated with no further padding, then envp.
        let argc = Int(buffer.withUnsafeBytes { $0.load(as: Int32.self) })
        guard argc > 0 else { return nil }
        var offset = MemoryLayout<Int32>.size
        while offset < size, buffer[offset] != 0 { offset += 1 }
        while offset < size, buffer[offset] == 0 { offset += 1 }

        var args: [String] = []
        var start = offset
        var i = offset
        while i < size, args.count < argc {
            if buffer[i] == 0 {
                args.append(String(decoding: buffer[start..<i], as: UTF8.self))
                start = i + 1
            }
            i += 1
        }

        let inlineFlags: Set<String> = ["-c", "-e", "-E", "-m", "-r", "-R", "-F", "--eval", "--print", "-p", "-i"]
        for arg in args.dropFirst() { // skip argv[0], the interpreter itself
            if inlineFlags.contains(arg) { return nil }
            if arg.hasPrefix("-") { continue }
            return arg
        }
        return nil
    }

    func getProcessPath(pid: Int) -> String? {
        // libproc first: no process spawn, so scanning every few seconds stays
        // cheap. Fails for other users' processes; `ps` below covers those.
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        if proc_pidpath(Int32(pid), &buffer, UInt32(buffer.count)) > 0 {
            return String(cString: buffer)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "comm="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    /// Parses `lsof -iTCP -sTCP:LISTEN -n -P` output. `internal` (not `private`)
    /// so the adversarial-input tests can feed it crafted text directly.
    func parseLsofOutput(_ output: String, proto: String = "tcp") -> [ListeningPortInfo] {
        var seenIDs: Set<String> = []
        var results: [ListeningPortInfo] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines.dropFirst() { // Skip header
            let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 9 else { continue }
            let command = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let nameField = parts[8] // e.g. "*:8080", "127.0.0.1:3000", "0.0.0.0:22"
            // A connected UDP socket (`a:1->b:2`) is a client, not a listener.
            if nameField.contains("->") { continue }

            if let colonIndex = nameField.lastIndex(of: ":") {
                let hostPart = String(nameField[..<colonIndex])
                let portStr = String(nameField[nameField.index(after: colonIndex)...])
                if let port = Int(portStr) {
                    let isGlobal = hostPart == "*" || hostPart == "0.0.0.0" || hostPart == "::"
                    let uniqueKey = "\(proto):\(command):\(port):\(pid)"
                    if !seenIDs.contains(uniqueKey) {
                        seenIDs.insert(uniqueKey)
                        let path = getProcessPath(pid: pid)
                        results.append(ListeningPortInfo(
                            processName: command,
                            pid: pid,
                            port: port,
                            isGloballyExposed: isGlobal,
                            executablePath: path,
                            bindHost: hostPart,
                            proto: proto
                        ))
                    }
                }
            }
        }
        return results
    }
}

// MARK: - libproc scan (no process spawn) and other users' listeners

extension ListeningPortMonitor {
    /// TCP listeners of every process this user may inspect, straight from
    /// libproc. Measured on this Mac: ~2 ms per scan against ~75 ms for
    /// `lsof -iTCP -sTCP:LISTEN`, with the same listener set. Other users'
    /// processes are not inspectable without root (292 of 773 pids here), so
    /// those come from the helper instead. Empty means "libproc gave nothing"
    /// (the caller falls back to `lsof`), not necessarily "no listeners".
    func scanListeningPortsFast() -> [ListeningPortInfo] {
        libprocSockets(udp: false)
    }

    /// Bound, unconnected UDP sockets, same source and same trade-off.
    func scanUDPListenersFast() -> [ListeningPortInfo] {
        libprocSockets(udp: true)
    }

    private func libprocSockets(udp: Bool) -> [ListeningPortInfo] {
        var count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(count) + 64)
        count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        guard count > 0 else { return [] }

        var results: [ListeningPortInfo] = []
        var seen: Set<String> = []
        for pid in pids.prefix(Int(count)) where pid > 0 {
            let need = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
            guard need > 0 else { continue }   // not ours to inspect
            var fds = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(need) / MemoryLayout<proc_fdinfo>.size + 8)
            let got = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fds, Int32(fds.count * MemoryLayout<proc_fdinfo>.size))
            guard got > 0 else { continue }

            var name: String?
            var path: String?
            for fd in fds.prefix(Int(got) / MemoryLayout<proc_fdinfo>.size) where fd.proc_fdtype == UInt32(PROX_FDTYPE_SOCKET) {
                var si = socket_fdinfo()
                let r = proc_pidfdinfo(pid, fd.proc_fd, PROC_PIDFDSOCKETINFO, &si, Int32(MemoryLayout<socket_fdinfo>.size))
                guard r == Int32(MemoryLayout<socket_fdinfo>.size) else { continue }

                let ini: in_sockinfo
                if udp {
                    // A bound UDP socket is SOCKINFO_IN; a non-zero foreign port means connected (a client).
                    guard si.psi.soi_kind == Int32(SOCKINFO_IN), si.psi.soi_protocol == Int32(IPPROTO_UDP) else { continue }
                    ini = si.psi.soi_proto.pri_in
                    guard ini.insi_fport == 0 else { continue }
                } else {
                    guard si.psi.soi_kind == Int32(SOCKINFO_TCP),
                          si.psi.soi_proto.pri_tcp.tcpsi_state == Int32(TSI_S_LISTEN) else { continue }
                    ini = si.psi.soi_proto.pri_tcp.tcpsi_ini
                }
                let port = Int(UInt16(bigEndian: UInt16(truncatingIfNeeded: ini.insi_lport)))
                guard port > 0 else { continue }

                if name == nil {
                    var nameBuf = [CChar](repeating: 0, count: 64)
                    _ = proc_name(pid, &nameBuf, UInt32(nameBuf.count))
                    name = String(cString: nameBuf)
                    var pathBuf = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
                    if proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count)) > 0 { path = String(cString: pathBuf) }
                }
                let command = (name?.isEmpty == false ? name : path.map { ($0 as NSString).lastPathComponent }) ?? "unknown"
                let host = Self.bindHost(of: ini)
                let key = "\(udp ? "udp" : "tcp"):\(command):\(port):\(pid):\(host)"
                guard seen.insert(key).inserted else { continue }
                results.append(ListeningPortInfo(
                    processName: command,
                    pid: Int(pid),
                    port: port,
                    isGloballyExposed: host == "*",
                    executablePath: path,
                    bindHost: host,
                    proto: udp ? "udp" : "tcp"
                ))
            }
        }
        return results
    }

    /// The address as `lsof` prints it: `*` for a wildcard, `[::1]` for IPv6.
    private static func bindHost(of ini: in_sockinfo) -> String {
        if (ini.insi_vflag & UInt8(INI_IPV6)) != 0 {
            var addr = ini.insi_laddr.ina_6
            if withUnsafeBytes(of: &addr, { $0.allSatisfy { $0 == 0 } }) { return "*" }
            var buf = [CChar](repeating: 0, count: 64)
            inet_ntop(AF_INET6, &addr, &buf, 64)
            return "[" + String(cString: buf) + "]"
        }
        var addr = ini.insi_laddr.ina_46.i46a_addr4
        if addr.s_addr == 0 { return "*" }
        var buf = [CChar](repeating: 0, count: 32)
        inet_ntop(AF_INET, &addr, &buf, 32)
        return String(cString: buf)
    }

    /// `listeners` minus the pids in `ownPids`, the rest marked `otherUser`:
    /// what the helper's `lsof` (root) can see that the app's own scan cannot.
    static func markingOtherUsers(_ listeners: [ListeningPortInfo], excludingPids ownPids: Set<Int>) -> [ListeningPortInfo] {
        listeners
            .filter { !ownPids.contains($0.pid) }
            .map { info in
                var marked = info
                marked.otherUser = true
                return marked
            }
    }

    /// `lsof` text from the helper, reduced to the listeners the app's own scan
    /// could not see. `text` is plain `lsof` output, so the existing parser applies.
    func otherUserListeners(fromHelperLsof text: String, proto: String, excludingPids ownPids: Set<Int>) -> [ListeningPortInfo] {
        Self.markingOtherUsers(parseLsofOutput(text, proto: proto), excludingPids: ownPids)
    }
}
