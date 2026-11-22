// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
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
/// none of its tools (see `MCPServer.toolDefinitionsForTesting`) can fetch a
/// URL, run an arbitrary command, or write to an arbitrary path (every
/// state-writing tool only touches RoamSwitch-managed files, and the one tool
/// that reaches an external host is Pro-gated and off by default). Building an
/// approval layer for a chain that cannot exist here would just be new,
/// untested complexity. What is still worth having is the plain forensic trail
/// this file provides: which tool ran, when, which argument *keys* it got --
/// not the values, since several tools take folder paths and this file must
/// not become a sensitive-path archive of its own -- and how the call ended.
/// Read with any text tool; nothing in this app currently builds a dedicated
/// viewer for it.
///
/// One line per call. The line is written before the tool runs (`outcome` is
/// `started`: a call that crashes the process is still on record, and stays
/// `started`, which says it never finished) and replaced when the call ends,
/// with `outcome` (`ok`, `error` or `unknown_tool`) and `durationMs`. The two
/// writes carry the same `callId`, so the file's `maxEntries` counts calls,
/// not half-calls. A name that is not a tool is written as a safe string (ASCII
/// letters, digits and a few marks, 80 characters at most): a client chooses it.
/// The file is mode 0600, like `AgentCheckLog`.
enum MCPToolCallLog {
    /// Capped like `WebMailDownloadGuard`'s own recent-items lists -- a
    /// bounded JSON Lines file, not an unbounded audit log.
    static let maxEntries = 2000

    static let maxToolNameLength = 80

    /// A test sets this so its calls go to a scratch file, not to the person's own log.
    static var overrideURLForTesting: URL?

    private static var logURL: URL {
        if let overrideURLForTesting { return overrideURLForTesting }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("mcp_tool_call_log.jsonl")
    }

    /// How a call ended. `started` is only ever on a line whose call has not ended (or never did).
    enum Outcome: String {
        case started
        case ok
        case error
        case unknownTool = "unknown_tool"
    }

    /// One line of the log file: never includes argument values, only the
    /// names of whichever arguments were present. `outcome`, `durationMs` and
    /// `callId` are absent from lines written by older versions.
    struct Entry: Codable {
        let timestamp: String
        let tool: String
        let argumentKeys: [String]
        var outcome: String? = nil
        var durationMs: Int? = nil
        var callId: String? = nil
    }

    /// A call in progress: what `complete` needs to replace its line.
    struct Call {
        let id: String
        let started: Date
    }

    /// `name` as it is written to the file: a tool's own name as it is, anything else reduced to ASCII letters,
    /// digits and `_ . : -` (another character becomes `_`), at most `maxToolNameLength` characters.
    static func loggedName(_ name: String, isKnownTool: Bool) -> String {
        if isKnownTool { return name }
        return String(name.unicodeScalars.prefix(maxToolNameLength).map { c in
            (c.isASCII && (c.properties.isAlphabetic || ("0"..."9").contains(c))) || c == "_" || c == "." || c == ":" || c == "-" ? Character(c) : "_"
        })
    }

    /// `Encodable` line-serialization, kept separate from file I/O so this
    /// is testable without touching the filesystem.
    static func line(for tool: String, argumentKeys: [String], now: Date = Date(),
                     outcome: Outcome? = nil, durationMs: Int? = nil, callId: String? = nil) -> String? {
        let entry = Entry(
            timestamp: ISO8601DateFormatter().string(from: now),
            tool: tool,
            argumentKeys: argumentKeys.sorted(),
            outcome: outcome?.rawValue,
            durationMs: durationMs,
            callId: callId
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(entry), let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    /// Writes the line of a call that is starting (`outcome` `started`), keeping the newest `maxEntries`. Best-effort: a
    /// write failure here must never fail or even slow down the tool call it is recording. Returns the handle for
    /// `complete`.
    @discardableResult
    static func begin(tool: String, arguments: [String: Any], isKnownTool: Bool = true, now: Date = Date(), to url: URL? = nil) -> Call {
        let call = Call(id: String(UUID().uuidString.prefix(8)).lowercased(), started: now)
        let name = loggedName(tool, isKnownTool: isKnownTool)
        guard let newLine = line(for: name, argumentKeys: Array(arguments.keys), now: now, outcome: .started, callId: call.id) else { return call }
        replaceOrAppend(call: call, with: newLine, to: url ?? logURL)
        return call
    }

    /// Replaces the line `begin` wrote with one that says how the call ended and how long it took (the line is
    /// appended when it is no longer in the file). Best-effort, like `begin`.
    static func complete(_ call: Call, tool: String, arguments: [String: Any], outcome: Outcome, isKnownTool: Bool = true,
                         now: Date = Date(), to url: URL? = nil) {
        let name = loggedName(tool, isKnownTool: isKnownTool)
        let ms = max(0, Int((now.timeIntervalSince(call.started) * 1000).rounded()))
        guard let newLine = line(for: name, argumentKeys: Array(arguments.keys), now: call.started, outcome: outcome, durationMs: ms, callId: call.id) else { return }
        replaceOrAppend(call: call, with: newLine, to: url ?? logURL)
    }

    private static func replaceOrAppend(call: Call, with newLine: String, to url: URL) {
        let marker = "\"callId\":\"\(call.id)\""
        // Every MCP client starts its own server process: hold the file while reading and replacing it, or two calls
        // at once keep only one of the two lines.
        AtomicFile.withLock(url.path) {
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            var lines = existing.isEmpty ? [] : existing.components(separatedBy: "\n").filter { !$0.isEmpty }
            if let at = lines.lastIndex(where: { $0.contains(marker) }) {
                lines[at] = newLine
            } else {
                lines.append(newLine)
            }
            if lines.count > maxEntries {
                lines.removeFirst(lines.count - maxEntries)
            }
            try? AtomicFile.write(lines.joined(separator: "\n") + "\n", to: url, mode: 0o600, newFileMode: 0o600)
        }
    }
}
