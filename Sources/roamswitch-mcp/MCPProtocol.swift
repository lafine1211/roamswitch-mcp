// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.2 (build 25).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// MCP protocol-version negotiation for `RoamSwitchMCPServer`'s `initialize`
/// handler.
///
/// Per the spec, the server must reply with the client's requested version
/// when it supports it, and otherwise fall back to its own preferred version:
/// https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle
///
/// Hardcoding a single value (the previous behaviour) makes the `initialize`
/// result carry a `protocolVersion` the client never asked for, which stricter
/// MCP hosts — notably some Go-based clients that unmarshal the result into a
/// fixed struct — reject outright, so no tool call ever runs.
public enum MCPProtocol {
    /// Newest spec revision this server implements. Used when the client
    /// requests nothing, or requests a version we don't recognize.
    public static let preferredVersion = "2025-06-18"

    /// Every revision whose `initialize` / `tools/list` / `tools/call` message
    /// shapes this server is wire-compatible with. The server's surface (no
    /// pagination, no JSON-RPC batching, text-only tool content) is identical
    /// across these, so any of them is safe to speak.
    public static let supportedVersions: Set<String> = [
        "2024-11-05",
        "2025-03-26",
        "2025-06-18",
    ]

    /// Resolves the `protocolVersion` to return from `initialize`, given the
    /// value the client sent in `params.protocolVersion` (may be nil/absent).
    public static func negotiateVersion(clientRequested: String?) -> String {
        guard let clientRequested, supportedVersions.contains(clientRequested) else {
            return preferredVersion
        }
        return clientRequested
    }
}
