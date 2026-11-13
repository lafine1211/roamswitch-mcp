// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.34 (build 213).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

/// SARIF 2.1.0 form of one `audit_mcp_configs` run, for CI and code-scanning tools. Same shape as the agent-setup
/// audit's log (`AgentSetupSarif.swift`): the rule id is the finding id, ids never change
/// (`docs/sarif_rule_id_policy.md`), a rule describes the kind of finding and the result carries the instance.
/// A file that exists but could not be parsed is a tool execution notification, so an empty result list is never
/// read as "everything was checked".
extension MCPConfigAuditor {

    /// Every finding id the audit can report, in a stable order (the SARIF rule table).
    static let findingIDs: [String] = [
        "auto_approve", "remote_plain_http", "remote_no_auth", "shell_wrapper", "unpinned_package_launcher",
        "container_host_access", "code_loading_env", "traffic_interception_env", "mcp_wide_bind", "hexstrike",
        "world_writable_config", "auto_trust_project_servers", "injection_exposure", "egress_exposure",
    ]

    /// Short English titles (SARIF consumers are English-first).
    static let sarifRuleTitles: [String: String] = [
        "auto_approve": "MCP tools run without a per-call confirmation",
        "remote_plain_http": "MCP server reached over plaintext http on another host",
        "remote_no_auth": "Remote https MCP server with no authentication in the config",
        "shell_wrapper": "MCP server launch command is a shell or interpreter one-liner",
        "unpinned_package_launcher": "MCP server fetched at launch without a pinned version",
        "container_host_access": "MCP server container gets host-level access",
        "code_loading_env": "MCP server environment loads extra code at start-up",
        "traffic_interception_env": "MCP server environment routes or trusts traffic through a third party",
        "mcp_wide_bind": "MCP server listens on every network interface",
        "hexstrike": "Entry points at HexStrike AI",
        "world_writable_config": "MCP client config writable by other users",
        "auto_trust_project_servers": "Project MCP servers are trusted automatically",
        "injection_exposure": "Untrusted-content reader and command-running server in one setup",
        "egress_exposure": "Untrusted-content reader and data-sending server in one setup",
    ]

    /// What each rule is about, in English (the localized explanation is in the JSON form's `message`).
    static let sarifRuleDescriptions: [String: String] = [
        "auto_approve": "Tools of this server are auto-approved, so a model steered by prompt injection runs them without the user seeing the call.",
        "remote_plain_http": "The client talks to a server on another host over unencrypted http, so anyone on the path can read or change the tool calls.",
        "remote_no_auth": "A remote https server whose config carries no credential (no Authorization-style header, token or OAuth setting). Fine when the client logs in with OAuth at connect time; otherwise the server's tools may be callable by anyone who knows the URL.",
        "shell_wrapper": "The launch command is inline shell or interpreter code, so whoever can edit the config runs arbitrary commands at every client start.",
        "unpinned_package_launcher": "npx, uvx, docker run and similar launchers fetch an unpinned package or image at every start; a hijacked or look-alike package runs with the client's rights.",
        "container_host_access": "The server's container runs privileged, mounts the Docker socket or the host root, or shares the host PID namespace.",
        "code_loading_env": "The server's environment makes the process load extra code first (LD_PRELOAD, DYLD_INSERT_LIBRARIES, NODE_OPTIONS --require and similar).",
        "traffic_interception_env": "The server's environment sends its traffic through a proxy, trusts an extra certificate authority or turns certificate checks off.",
        "mcp_wide_bind": "The server is started to listen on every interface (0.0.0.0, ::, or a docker -p without an address), so others on the network can call its tools.",
        "hexstrike": "The entry references HexStrike AI, a backend that runs attack tools and shell strings without authentication.",
        "world_writable_config": "The client configuration file can be rewritten by other users of this machine.",
        "auto_trust_project_servers": "Claude Code's enableAllProjectMcpServers trusts every server a repository's .mcp.json declares.",
        "injection_exposure": "One setup has a server that reads text others write and a different server that runs commands or writes files, the combination indirect prompt injection needs.",
        "egress_exposure": "One setup has a server that reads text others write and a different server that can send data off this machine (mail, chat posts, cloud storage, webhooks), so an injected instruction can send files or conversation out (ATT&CK T1567).",
    ]

    static func sarifLog(_ result: Result, toolVersion: String) -> [String: Any] {
        var ruleIDs = findingIDs
        for f in result.findings where !ruleIDs.contains(f.id) { ruleIDs.append(f.id) }
        let rules: [[String: Any]] = ruleIDs.map { id in
            [
                "id": id,
                "name": id,
                "shortDescription": ["text": sarifRuleTitles[id] ?? id],
                "fullDescription": ["text": sarifRuleDescriptions[id] ?? (sarifRuleTitles[id] ?? id)],
                "properties": ["tags": ["security", "mcp"]],
            ]
        }
        let artifactPaths = Array(NSOrderedSet(array: result.scannedFiles + result.findings.map(\.file))) as? [String] ?? result.scannedFiles
        let artifactIndex = Dictionary(uniqueKeysWithValues: artifactPaths.enumerated().map { ($1, $0) })
        let artifacts: [[String: Any]] = artifactPaths.map {
            ["location": ["uri": AgentSetupAuditor.sarifURI(for: $0)], "roles": ["analysisTarget"]]
        }
        let results: [[String: Any]] = result.findings.map { f in
            let title = sarifRuleTitles[f.id] ?? f.id
            let server = f.server.map { " Server: \($0)." } ?? ""
            let fingerprintSource = "\(f.id)\n\(f.file)\n\(f.server ?? "")\n\(f.detail)"
            let fingerprint = SHA256.hash(data: Data(fingerprintSource.utf8)).map { String(format: "%02x", $0) }.joined()
            var r: [String: Any] = [
                "ruleId": f.id,
                "level": AgentSetupAuditor.sarifLevel(f.severity),
                "message": ["text": "\(title).\(server) \(f.detail)"],
                "locations": [[
                    "physicalLocation": ["artifactLocation": ["uri": AgentSetupAuditor.sarifURI(for: f.file), "index": artifactIndex[f.file] ?? 0] as [String: Any]],
                ] as [String: Any]],
                "partialFingerprints": ["roamSwitchMcpConfig/v1": fingerprint],
                "properties": ["severity": f.severity, "server": f.server ?? ""] as [String: Any],
            ]
            if let i = ruleIDs.firstIndex(of: f.id) { r["ruleIndex"] = i }
            return r
        }
        let notifications: [[String: Any]] = result.unreadableFiles.map {
            [
                "level": "warning",
                "message": ["text": "This file exists but could not be read or parsed, so it was not audited."],
                "descriptor": ["id": "unreadable-file"],
                "locations": [["physicalLocation": ["artifactLocation": ["uri": AgentSetupAuditor.sarifURI(for: $0)]]]],
            ]
        }
        return [
            "$schema": AgentSetupAuditor.sarifSchemaURI,
            "version": "2.1.0",
            "runs": [[
                "tool": ["driver": [
                    "name": "RoamSwitch MCP config audit",
                    "version": toolVersion,
                    "semanticVersion": toolVersion,
                    "rules": rules,
                ] as [String: Any]],
                "artifacts": artifacts,
                "invocations": [["executionSuccessful": true, "toolExecutionNotifications": notifications] as [String: Any]],
                "results": results,
                "properties": ["scannedFileCount": result.scannedFiles.count, "serverCount": result.serverCount,
                               "complete": result.unreadableFiles.isEmpty] as [String: Any],
            ] as [String: Any]],
        ]
    }

    /// The strings of a result that come from the audited files, for the injection scan.
    static func sarifDataStrings(_ result: Result) -> [String] {
        result.findings.flatMap { [$0.detail, $0.file, $0.server ?? ""] } + result.scannedFiles + result.unreadableFiles
    }

    static func sarifJSON(_ result: Result, toolVersion: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: sarifLog(result, toolVersion: toolVersion),
                                                     options: [.sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
