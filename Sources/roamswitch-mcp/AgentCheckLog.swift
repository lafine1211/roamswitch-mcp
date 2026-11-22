// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The audit log of `RoamSwitchMCPServer agent-check`: one JSON line for every call it asked about or refused, in the
/// account of the person (`~/Library/Application Support/RoamSwitch/agent_check_log.jsonl`, mode 0600, the newest
/// `maxEntries`). The same rules as `MCPToolCallLog`: the tool name and the reason keys, never a value. A call that was
/// allowed is not written to the log (it is nearly all of them, and would push the few that matter out of a bounded file).
///
/// Next to it, `agent_check_counts.json` (mode 0600) counts every judged call per day (`allow`, `ask`, `deny`; the day
/// is UTC) and keeps the time of the last one, for `countDays` days. It is how "the hook ran and everything was allowed"
/// is told from "the hook did not run": the log alone cannot, since it holds no allowed call. It holds numbers and a
/// time, no tool name and no value.
/// Linux: `crates/roamswitch-core/src/agent_check_log.rs` (the same file names and keys).
enum AgentCheckLog {
    static let maxEntries = 2000
    /// How many days (today and the days before it) the counter keeps.
    static let countDays = 30

    private static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static var logURL: URL { supportDirectory.appendingPathComponent("agent_check_log.jsonl") }
    static var countsURL: URL { supportDirectory.appendingPathComponent("agent_check_counts.json") }

    struct Entry: Codable {
        let timestamp: String
        let tool: String
        let verdict: String
        let reasons: [String]
    }

    /// What one day held: the calls the hook judged, by answer.
    struct DayCounts: Codable, Equatable {
        var allow = 0
        var ask = 0
        var deny = 0
    }

    /// The content of `agent_check_counts.json`.
    struct Counts: Codable, Equatable {
        var version = 1
        /// When the hook last judged a call (any answer), ISO 8601 UTC.
        var lastDecisionAt: String?
        /// `yyyy-MM-dd` (UTC) -> counts.
        var days: [String: DayCounts] = [:]

        enum CodingKeys: String, CodingKey {
            case version
            case lastDecisionAt = "last_decision_at"
            case days
        }
    }

    /// The JSON line for `decision` on `tool`, or nil for an allowed call.
    static func line(tool: String, decision: AgentCheck.Decision, now: Date = Date()) -> String? {
        if decision.verdict == .allow { return nil }
        let entry = Entry(
            timestamp: ISO8601DateFormatter().string(from: now), tool: AgentCheck.logToolName(tool),
            verdict: decision.verdict.rawValue, reasons: decision.reasons)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(entry) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// `counts` with `decision` added for `now`, and the days older than `countDays` dropped.
    static func counted(_ counts: Counts, decision: AgentCheck.Decision, now: Date = Date()) -> Counts {
        var next = counts
        next.version = 1
        next.lastDecisionAt = ISO8601DateFormatter().string(from: now)
        var day = next.days[dayKey(now)] ?? DayCounts()
        switch decision.verdict {
        case .allow: day.allow += 1
        case .ask: day.ask += 1
        case .deny: day.deny += 1
        }
        next.days[dayKey(now)] = day
        let oldest = dayKey(now.addingTimeInterval(-Double(countDays - 1) * 86_400))
        next.days = next.days.filter { $0.key >= oldest }
        return next
    }

    /// The counter as it is on disk; nil when there is none or it cannot be read.
    static func readCounts(from url: URL? = nil) -> Counts? {
        guard let data = try? Data(contentsOf: url ?? countsURL) else { return nil }
        return try? JSONDecoder().decode(Counts.self, from: data)
    }

    /// Adds the call to the counter: one locked read, add and write of a small file. A file that cannot be read is
    /// started over (it holds only numbers and a time).
    @discardableResult
    static func recordCount(decision: AgentCheck.Decision, to url: URL? = nil, now: Date = Date()) -> Bool {
        let target = url ?? countsURL
        var ok = true
        AtomicFile.withLock(target.path) {
            let next = counted(readCounts(from: target) ?? Counts(), decision: decision, now: now)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(next) else { ok = false; return }
            do { try AtomicFile.write(data, to: target, mode: 0o600, newFileMode: 0o600) } catch { ok = false }
        }
        return ok
    }

    /// Appends the line (an `ask` or a `deny`) and keeps the newest `maxEntries`; counts the call in the per-day counter
    /// whatever the answer. Best effort: a failure must never change the answer of the hook. `to` is the log file; the
    /// counter is then the file next to it (what the tests use).
    @discardableResult
    static func record(tool: String, decision: AgentCheck.Decision, to url: URL? = nil) -> Bool {
        let countsTarget = url.map { $0.deletingLastPathComponent().appendingPathComponent("agent_check_counts.json") }
        let counted = recordCount(decision: decision, to: countsTarget)
        guard let newLine = line(tool: tool, decision: decision) else { return counted }
        let target = url ?? logURL
        var ok = counted
        // Several agents run hooks at the same time: one at a time reads, adds and writes.
        AtomicFile.withLock(target.path) {
            let existing = (try? String(contentsOf: target, encoding: .utf8)) ?? ""
            var lines = existing.isEmpty ? [] : existing.components(separatedBy: "\n").filter { !$0.isEmpty }
            lines.append(newLine)
            if lines.count > maxEntries { lines.removeFirst(lines.count - maxEntries) }
            do { try AtomicFile.write(lines.joined(separator: "\n") + "\n", to: target, mode: 0o600, newFileMode: 0o600) } catch { ok = false }
        }
        return ok
    }
}
