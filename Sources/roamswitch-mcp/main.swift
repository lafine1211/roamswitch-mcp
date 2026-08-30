// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.6.0 (build 33).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

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
