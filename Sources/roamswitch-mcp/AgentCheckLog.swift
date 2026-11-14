// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The audit log of `RoamSwitchMCPServer agent-check`: one JSON line for every call it asked about or refused, in the
/// account of the person (`~/Library/Application Support/RoamSwitch/agent_check_log.jsonl`, mode 0600, the newest
/// `maxEntries`). The same rules as `MCPToolCallLog`: the tool name and the reason keys, never a value. A call that was
/// allowed is not written (it is nearly all of them, and would push the few that matter out of a bounded file).
/// Linux: `crates/roamswitch-core/src/agent_check_log.rs`.
enum AgentCheckLog {
    static let maxEntries = 2000

    static var logURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("agent_check_log.jsonl")
    }

    struct Entry: Codable {
        let timestamp: String
        let tool: String
        let verdict: String
        let reasons: [String]
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

    /// Appends the line and keeps the newest `maxEntries`. Best effort: a failure must never change the answer of the hook.
    @discardableResult
    static func record(tool: String, decision: AgentCheck.Decision, to url: URL? = nil) -> Bool {
        guard let newLine = line(tool: tool, decision: decision) else { return true }
        let target = url ?? logURL
        var ok = true
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
