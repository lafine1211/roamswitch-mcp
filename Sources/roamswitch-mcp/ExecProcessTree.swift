// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.5 (build 123).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// One process in a reconstructed tree. `depth` is negative for ancestors
/// (-1 = parent), 0 for the queried process, positive for descendants.
public struct ExecProcessNode: Codable, Equatable {
    public var pid: Int32
    public var ppid: Int32
    public var depth: Int
    public var time: Double
    public var path: String
    public var args: [String]?
    public var signingID: String?
    public var teamID: String?
    public var signature: ExecSignatureClass
}

public struct ExecProcessTree: Codable, Equatable {
    /// Root-most ancestor first, ending with the queried process's parent.
    public var ancestors: [ExecProcessNode]
    public var node: ExecProcessNode?
    /// Breadth-first order.
    public var descendants: [ExecProcessNode]
    public var truncated: Bool
}

/// Rebuilds a process tree from recorded exec/fork events. Pure and
/// order-independent. Only what the recorder actually saw is known: a process
/// that started before recording began has no node (the chain just stops).
public enum ExecProcessTreeBuilder {
    public static func build(records: [ExecEventRecord], pid: Int32, at: Double? = nil,
                             maxAncestors: Int = 16, maxNodes: Int = 200) -> ExecProcessTree {
        // Incarnations: fork/exec lines only. For a pid, exec supersedes the
        // fork line that came just before it (same process, new image).
        let procs = records.filter { $0.kind == "exec" || $0.kind == "fork" }.sorted { $0.time < $1.time }
        var byPid: [Int32: [ExecEventRecord]] = [:]
        var byPpid: [Int32: [ExecEventRecord]] = [:]
        for r in procs {
            byPid[r.pid, default: []].append(r)
            byPpid[r.ppid, default: []].append(r)
        }

        func latest(pid p: Int32, notAfter t: Double?) -> ExecEventRecord? {
            guard let list = byPid[p] else { return nil }
            let eligible = t.map { limit in list.filter { $0.time <= limit } } ?? list
            // Prefer the newest exec (final image), else the newest fork.
            return eligible.last(where: { $0.kind == "exec" }) ?? eligible.last
        }
        func node(_ r: ExecEventRecord, depth: Int) -> ExecProcessNode {
            ExecProcessNode(pid: r.pid, ppid: r.ppid, depth: depth, time: r.time, path: r.path, args: r.args,
                            signingID: r.signingID, teamID: r.teamID, signature: r.signatureClass)
        }

        guard let start = latest(pid: pid, notAfter: at) else {
            return ExecProcessTree(ancestors: [], node: nil, descendants: [], truncated: false)
        }

        var ancestors: [ExecProcessNode] = []
        var seen: Set<Int32> = [start.pid]
        var cur = start
        var truncated = false
        while cur.ppid > 0, ancestors.count < maxAncestors {
            guard !seen.contains(cur.ppid), let p = latest(pid: cur.ppid, notAfter: cur.time) else { break }
            seen.insert(p.pid)
            ancestors.append(node(p, depth: -(ancestors.count + 1)))
            cur = p
        }
        if cur.ppid > 0, ancestors.count >= maxAncestors { truncated = true }
        ancestors.reverse()

        var descendants: [ExecProcessNode] = []
        var queue: [(ExecEventRecord, Int)] = [(start, 0)]
        var visited: Set<Int32> = [start.pid]
        var qi = 0
        bfs: while qi < queue.count {
            let (parent, depth) = queue[qi]
            qi += 1
            let kids = (byPpid[parent.pid] ?? []).filter { $0.time >= parent.time && $0.pid != parent.pid }
            // One entry per child pid: first sighting time, final (exec) image.
            var seenKids: Set<Int32> = []
            for k in kids where !seenKids.contains(k.pid) {
                seenKids.insert(k.pid)
                guard !visited.contains(k.pid), let final = latest(pid: k.pid, notAfter: nil) else { continue }
                visited.insert(k.pid)
                if descendants.count >= maxNodes { truncated = true; break bfs }
                descendants.append(node(final, depth: depth + 1))
                queue.append((final, depth + 1))
            }
        }
        return ExecProcessTree(ancestors: ancestors, node: node(start, depth: 0), descendants: descendants, truncated: truncated)
    }
}
