// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.1 (build 217).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Local, append-only record of every MCP `tools/call` this process handles.
///
/// Scoped-down S4 (APT_REPORT applicability analysis): the full "chain
/// gating + approval ticket" design that section assumed (Anthropic
/// GTG-1002 / Hugging Face incident style) doesn't fit this MCP server --
/// none of its ~33 tools can fetch a URL, run an arbitrary command, or write
/// to an arbitrary path (see the conversation record: every state-writing
/// tool only touches RoamSwitch-managed files, and the one tool that reaches
/// an external host is Pro-gated and off by default). Building an approval
/// layer for a chain that cannot exist here would just be new, untested
/// complexity. What is still worth having is the plain forensic trail this
/// file provides: which tool ran, when, and which argument *keys* it got --
/// not the values, since several tools take folder paths and this file must
/// not become a sensitive-path archive of its own. Read with any text tool;
/// nothing in this app currently builds a dedicated viewer for it.
enum MCPToolCallLog {
    /// Capped like `WebMailDownloadGuard`'s own recent-items lists -- a
    /// bounded JSON Lines file, not an unbounded audit log.
    static let maxEntries = 2000

    private static var logURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("mcp_tool_call_log.jsonl")
    }

    /// One line of the log file: never includes argument values, only the
    /// names of whichever arguments were present.
    struct Entry: Codable {
        let timestamp: String
        let tool: String
        let argumentKeys: [String]
    }

    /// `Encodable` line-serialization, kept separate from file I/O so this
    /// is testable without touching the filesystem.
    static func line(for tool: String, argumentKeys: [String], now: Date = Date()) -> String? {
        let entry = Entry(
            timestamp: ISO8601DateFormatter().string(from: now),
            tool: tool,
            argumentKeys: argumentKeys.sorted()
        )
        guard let data = try? JSONEncoder().encode(entry), let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    /// Appends one line, then enforces `maxEntries` by trimming the oldest
    /// lines. Best-effort: a write failure here must never fail or even slow
    /// down the tool call it is recording.
    static func record(tool: String, arguments: [String: Any]) {
        guard let newLine = line(for: tool, argumentKeys: Array(arguments.keys)) else { return }
        let url = logURL
        // Every MCP client starts its own server process: hold the file while reading and replacing it, or two calls
        // at once keep only one of the two lines.
        AtomicFile.withLock(url.path) {
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            var lines = existing.isEmpty ? [] : existing.components(separatedBy: "\n").filter { !$0.isEmpty }
            lines.append(newLine)
            if lines.count > maxEntries {
                lines.removeFirst(lines.count - maxEntries)
            }
            try? AtomicFile.write(lines.joined(separator: "\n") + "\n", to: url)
        }
    }
}
