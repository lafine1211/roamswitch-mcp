// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.3 (build 227).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// Ending a child process together with everything it started, and taking back what a helper that died left running.
///
/// Measured on a Mac (2026-11-17): the helper's `tcpdump -i pflog0` was still running with the parent process 1 five times, the
/// oldest for 2 days 4 hours. Each helper restart (an update, `launchctl`, a crash) left one more. The children were
/// stopped with `Process.terminate()` (SIGTERM to the direct child only, no SIGKILL, no wait), and nothing stopped them
/// when the helper itself ended. launchd cleans up by process group, and a child that has its own group is not reached.
///
/// Here:
/// - A process is named by its number AND the time it started (`Identity`). A number is reused as soon as its process
///   ends; every signal is preceded by a check that the process now there is the one that was named.
/// - Ending a tree sends SIGTERM to the child, to everything below it, and to everything in the child's own process
///   group (a grandchild that left its parent still has the group), waits a short grace, and then sends SIGKILL to what
///   is left.
/// - `TrackedChildren` writes down what the helper started (number, start time, program, full argument list) and, at the
///   next start, ends only what still matches that record exactly and has the parent process 1. Nothing is found by name:
///   a `tcpdump` that a person or another tool started is never touched.
enum ChildProcessTree {
    /// A process by number and the time it started (to the microsecond, `proc_bsdinfo`).
    struct Identity: Codable, Equatable, Hashable {
        var pid: Int32
        var startSeconds: UInt64
        var startMicroseconds: UInt64
    }

    /// One row of the process table.
    struct Entry: Equatable {
        var identity: Identity
        var ppid: Int32
        var pgid: Int32
        var isZombie: Bool
        /// The user the process runs as. `UInt32.max` when not known (a row made by hand in a test): that is never root,
        /// so a check that wants root does not pass on a row that did not say.
        var uid: UInt32 = .max
        var pid: Int32 { identity.pid }
    }

    /// The process table and the signal, replaceable in tests. `live` reads the real one.
    struct Table {
        var list: () -> [Entry]
        var send: (Int32, Int32) -> Bool
        /// The program path and the full argument list (`argv`, including `argv[0]`) of a running process.
        var command: (Int32) -> (path: String, argv: [String])?

        static let live = Table(
            list: { liveEntries() },
            send: { pid, sig in pid > 1 && kill(pid, sig) == 0 },
            command: { pid in liveCommand(pid) }
        )
    }

    // MARK: - Reading the table

    static func entry(of pid: Int32) -> Entry? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return Entry(identity: Identity(pid: pid, startSeconds: info.pbi_start_tvsec, startMicroseconds: info.pbi_start_tvusec),
                     ppid: Int32(bitPattern: info.pbi_ppid), pgid: Int32(bitPattern: info.pbi_pgid), isZombie: info.pbi_status == 5,
                     uid: info.pbi_uid)
    }

    private static func liveEntries() -> [Entry] {
        let capacity = Int(proc_listallpids(nil, 0))
        guard capacity > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: capacity + 64)
        let count = Int(proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size)))
        guard count > 0 else { return [] }
        return pids.prefix(count).compactMap { $0 > 0 ? entry(of: $0) : nil }
    }

    private static func liveCommand(_ pid: Int32) -> (path: String, argv: [String])? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 8, size <= 1 << 20 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return nil }
        return parseProcArgs2(Array(buffer.prefix(size)))
    }

    /// `KERN_PROCARGS2`: a 4-byte argument count (little endian on arm64 and x86_64), the program path, NUL padding, then
    /// `argc` NUL-terminated arguments (the environment follows and is not read). nil when the bytes are not that.
    static func parseProcArgs2(_ bytes: [UInt8]) -> (path: String, argv: [String])? {
        guard bytes.count > 8 else { return nil }
        let argc = Int(bytes[0]) | Int(bytes[1]) << 8 | Int(bytes[2]) << 16 | Int(bytes[3]) << 24
        guard argc >= 1, argc <= 4096 else { return nil }
        var i = 4
        while i < bytes.count, bytes[i] != 0 { i += 1 }
        let path = String(decoding: bytes[4..<i], as: UTF8.self)
        while i < bytes.count, bytes[i] == 0 { i += 1 }
        var argv: [String] = []
        var start = i
        while i < bytes.count, argv.count < argc {
            if bytes[i] == 0 {
                argv.append(String(decoding: bytes[start..<i], as: UTF8.self))
                start = i + 1
            }
            i += 1
        }
        guard argv.count == argc else { return nil }
        return (path, argv)
    }

    // MARK: - Who belongs to a tree

    /// `root`, everything below it (by parent number), and everything in its own process group. Empty when `root` is not
    /// in `entries` as the process that was named (gone, or the number now belongs to another process).
    ///
    /// A descendant must have started no earlier than `root`: a row whose parent number is `root`'s number but that is
    /// older than `root` was a child of an earlier process with that number. The group is taken only when `root` leads
    /// it (its group number is its own number) and it is not this process's group.
    static func members(of root: Identity, in entries: [Entry], ownGroup: Int32 = getpgrp()) -> [Entry] {
        guard let top = entries.first(where: { $0.identity == root }), !top.isZombie else { return [] }
        var result = [top]
        var seen: Set<Int32> = [top.pid]
        var queue = [top]
        func startsNoEarlier(_ e: Entry) -> Bool {
            (e.identity.startSeconds, e.identity.startMicroseconds) >= (root.startSeconds, root.startMicroseconds)
        }
        while !queue.isEmpty {
            let parent = queue.removeFirst()
            for e in entries where e.ppid == parent.pid && e.pid > 1 && !seen.contains(e.pid) && startsNoEarlier(e) {
                seen.insert(e.pid)
                result.append(e)
                queue.append(e)
            }
        }
        if top.pgid == top.pid, top.pgid != ownGroup, top.pgid > 1 {
            for e in entries where e.pgid == top.pgid && e.pid > 1 && !seen.contains(e.pid) && startsNoEarlier(e) {
                seen.insert(e.pid)
                result.append(e)
            }
        }
        return result
    }

    // MARK: - Ending a tree

    /// SIGTERM to every member of the tree. Each member is read again just before the signal; a number that now belongs
    /// to another process is skipped. Returns who was signalled.
    @discardableResult
    static func terminate(_ root: Identity, table: Table = .live) -> [Identity] {
        signalMembers(of: root, sig: SIGTERM, table: table)
    }

    @discardableResult
    private static func signalMembers(of root: Identity, sig: Int32, table: Table) -> [Identity] {
        var signalled: [Identity] = []
        for m in members(of: root, in: table.list()) where stillThere(m.identity, table: table) {
            if table.send(m.pid, sig) { signalled.append(m.identity) }
        }
        return signalled
    }

    private static func stillThere(_ id: Identity, table: Table) -> Bool {
        table.list().first(where: { $0.identity == id }).map { !$0.isZombie } ?? false
    }

    /// Of `ids`, the ones that are still running as the same process.
    static func alive(_ ids: [Identity], table: Table = .live) -> [Identity] {
        let rows = table.list()
        return ids.filter { id in rows.first(where: { $0.identity == id }).map { !$0.isZombie } ?? false }
    }

    /// SIGKILL to what is left of `ids` and of everything below them. The members were found when the tree was last
    /// signalled; a child they started since is below one of them and is taken here.
    @discardableResult
    static func killRemaining(_ ids: [Identity], table: Table = .live) -> [Identity] {
        var killed: [Identity] = []
        for id in ids {
            for m in members(of: id, in: table.list()) where stillThere(m.identity, table: table) {
                if table.send(m.pid, SIGKILL) { killed.append(m.identity) }
            }
        }
        return killed
    }

    enum Outcome: Equatable {
        /// The process named was not running (gone, or its number belongs to another process). Nothing was signalled.
        case notRunning
        /// Everything in the tree is gone.
        case stopped
        /// Still running after SIGKILL and the wait.
        case survivors([Int32])
    }

    /// Ends the tree and waits for it: SIGTERM, up to `grace` for it to go, then SIGKILL to what is left, then up to
    /// `killWait` for that. Blocks the caller for at most `grace + killWait` (the helper's shutdown, and tests).
    static func stop(_ root: Identity, grace: TimeInterval = 1.0, killWait: TimeInterval = 1.0, table: Table = .live,
                     poll: TimeInterval = 0.02) -> Outcome {
        let first = terminate(root, table: table)
        guard !first.isEmpty else { return .notRunning }
        var left = waitUntilGone(first, within: grace, poll: poll, table: table)
        if !left.isEmpty {
            // What a member started while it was going down has no name yet: killRemaining takes the tree again.
            killRemaining(left, table: table)
            left = waitUntilGone(left, within: killWait, poll: poll, table: table)
        }
        return left.isEmpty ? .stopped : .survivors(left.map(\.pid))
    }

    private static func waitUntilGone(_ ids: [Identity], within seconds: TimeInterval, poll: TimeInterval, table: Table) -> [Identity] {
        let deadline = Date().addingTimeInterval(seconds)
        var left = alive(ids, table: table)
        while !left.isEmpty, Date() < deadline {
            Thread.sleep(forTimeInterval: poll)
            left = alive(left, table: table)
        }
        return left
    }

    /// What `process.terminate()` (SIGTERM to the direct child only) was used for: SIGTERM now to the child, everything below it
    /// and its process group, SIGKILL after `grace` for what is left. Does not block. Only a child of this process is
    /// taken by number (a number that now belongs to another process is not signalled); when the process cannot be read,
    /// it is ended the old way.
    static func end(_ process: Process, grace: TimeInterval = 3, table: Table = .live) {
        guard process.isRunning else { return }
        guard let e = entry(of: process.processIdentifier), e.ppid == getpid(), !e.isZombie else {
            process.terminate()
            return
        }
        stopSoon(e.identity, grace: grace, table: table)
    }

    /// SIGTERM now; after `grace`, SIGKILL for what is left; then `done` (with true when everything is gone). Does not
    /// block: for a stop that runs on a serial queue the stream's own code also uses.
    static func stopSoon(_ root: Identity, grace: TimeInterval = 1.0, table: Table = .live,
                         on queue: DispatchQueue = .global(qos: .utility), done: ((Bool) -> Void)? = nil) {
        let signalled = terminate(root, table: table)
        guard !signalled.isEmpty else { done?(true); return }
        queue.asyncAfter(deadline: .now() + grace) {
            var left = alive(signalled, table: table)
            if !left.isEmpty {
                killRemaining(left, table: table)
                Thread.sleep(forTimeInterval: 0.2)
                left = alive(left, table: table)
            }
            done?(left.isEmpty)
        }
    }
}
