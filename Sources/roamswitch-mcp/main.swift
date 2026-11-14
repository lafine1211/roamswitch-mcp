// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.1 (build 217).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// `agent-check`: the destination check an AI coding agent's hook runs before a tool call. Not the MCP protocol: it
// reads the hook's JSON on stdin and exits (see AgentCheckCommand.swift).
if CommandLine.arguments.dropFirst().first == AgentCheckCommand.flag {
    exit(AgentCheckCommand.run(Array(CommandLine.arguments.dropFirst(2))))
}

// Thin stdin→stdout pump for the MCP server. All parsing and dispatch lives
// in `MCPServer.handleLine` (MCPServer.swift) so it can be unit tested and
// fuzzed without a process.
//
// Newline-delimited JSON-RPC 2.0. Each line is either a single request object
// or — from pre-2025-06-18 clients that still batch — an array of them.

// Prevent libc stdio buffering from holding response lines back when stdout
// is a pipe (the normal case — an MCP client launches this as a subprocess)
// rather than a terminal; the spec requires every stdout write to be a
// complete, immediately-delivered MCP message.
setvbuf(stdout, nil, _IONBF, 0)

let newline = Data([0x0A])

while let line = readLine(strippingNewline: true) {
    guard let data = line.data(using: .utf8) else { continue }
    for response in MCPServer.handleLine(data) {
        FileHandle.standardOutput.write(response)
        FileHandle.standardOutput.write(newline)
    }
}
