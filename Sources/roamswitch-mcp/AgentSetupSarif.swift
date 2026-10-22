// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.16.1 (build 177).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

/// Classification tags for the agent-setup audit's finding ids, and the SARIF 2.1.0 form of an audit run.
///
/// The tags are our own judgement of which public category a rule belongs to, so a CI dashboard or a
/// report can group findings; they are not a certification and a rule can be a fit for more than one.
/// Only identifiers that exist are used: OWASP Top 10 for LLM Applications (2025 edition) ids, and
/// MITRE ATT&CK technique ids where one technique plainly describes the rule. Where no ATT&CK
/// technique fits without stretching, the list is empty rather than guessed.
///
/// The ids, the mapping and the SARIF shape are the same on the Linux edition.
extension AgentSetupAuditor {

    /// OWASP Top 10 for LLM Applications 2025: names of the ids used below (for rule descriptions).
    static let owaspLLMNames: [String: String] = [
        "LLM01": "Prompt Injection",
        "LLM02": "Sensitive Information Disclosure",
        "LLM03": "Supply Chain",
        "LLM06": "Excessive Agency",
    ]

    /// MITRE ATT&CK technique names for the ids used below.
    static let attackNames: [String: String] = [
        "T1027": "Obfuscated Files or Information",
        "T1036": "Masquerading",
        "T1105": "Ingress Tool Transfer",
        "T1140": "Deobfuscate/Decode Files or Information",
        "T1552.001": "Unsecured Credentials: Credentials In Files",
    ]

    struct Tags: Equatable {
        let owaspLLM: [String]
        let attack: [String]
    }

    static func tags(for id: String) -> Tags {
        switch id {
        // Text that steers the agent without the user seeing it, or tells it to disobey.
        case "hidden_tag_characters", "invisible_characters", "override_instruction", "whitespace_padding",
             "agent_file_writable":
            return Tags(owaspLLM: ["LLM01"], attack: [])
        case "hidden_encoded_text":
            return Tags(owaspLLM: ["LLM01"], attack: ["T1027"])
        case "encoded_payload_exec":
            return Tags(owaspLLM: ["LLM01"], attack: ["T1140"])
        case "remote_script_exec":
            return Tags(owaspLLM: ["LLM03"], attack: ["T1105"])
        // Reading or sending secrets. A reference to a credential file is the plainest "credentials in files".
        case "credential_access":
            return Tags(owaspLLM: ["LLM02"], attack: ["T1552.001"])
        case "credential_exfil_shape", "exfil_endpoint", "openclaw_mdns_full",
             "openclaw_loose_permissions", "agent_settings_endpoint_override":
            return Tags(owaspLLM: ["LLM02"], attack: [])
        // What a skill or the agent may do without asking.
        case "persistence_instruction", "skill_broad_tool_grant", "openclaw_auth_disabled", "openclaw_wide_bind",
             "openclaw_weak_token", "openclaw_origin_wildcard", "openclaw_dangerous_flag",
             "openclaw_broad_trusted_proxy", "openclaw_proxy_trust_loosened", "openclaw_audit_suppressed",
             "agent_settings_hook", "agent_settings_bypass", "agent_settings_broad_allow", "agent_settings_weakened",
             "agent_settings_writable":
            return Tags(owaspLLM: ["LLM06"], attack: [])
        case "openclaw_open_dm":
            return Tags(owaspLLM: ["LLM01", "LLM06"], attack: [])
        // Third-party code or definitions that arrived or changed.
        case "skill_precompiled_code", "agent_file_changed", "agent_file_added", "mcp_server_changed", "mcp_server_added":
            return Tags(owaspLLM: ["LLM03"], attack: [])
        case "homoglyph_name":
            return Tags(owaspLLM: ["LLM03"], attack: ["T1036"])
        default:
            return Tags(owaspLLM: [], attack: [])
        }
    }

    // MARK: SARIF

    static let sarifSchemaURI = "https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/schemas/sarif-schema-2.1.0.json"

    /// One-line English titles for the SARIF rule table (SARIF consumers are English-first). The
    /// localized explanation of each rule goes into `fullDescription`.
    static let sarifRuleTitles: [String: String] = [
        "hidden_tag_characters": "Unicode tag characters hide text",
        "invisible_characters": "Zero-width or bidirectional control characters",
        "override_instruction": "Wording that overrides earlier instructions or hides something from the user",
        "remote_script_exec": "Downloads and runs a script",
        "encoded_payload_exec": "Decodes text and runs it",
        "credential_access": "Refers to a credential file or store",
        "credential_exfil_shape": "Credential reference next to an upload or drop site",
        "exfil_endpoint": "Mentions an upload or drop-site host",
        "persistence_instruction": "Sets up something that survives a restart",
        "skill_precompiled_code": "Compiled code inside a skill",
        "agent_file_writable": "Agent instruction file writable by others",
        "homoglyph_name": "Name mixes lookalike letters of different alphabets",
        "whitespace_padding": "Blank padding pushes text out of view",
        "hidden_encoded_text": "Encoded text that decodes to readable text",
        "skill_broad_tool_grant": "allowed-tools grants any shell command",
        "agent_file_changed": "Agent file changed since the accepted state",
        "agent_file_added": "Agent file added since the accepted state",
        "mcp_server_changed": "MCP server definition changed since the accepted state",
        "mcp_server_added": "MCP server definition added since the accepted state",
        "openclaw_auth_disabled": "OpenClaw gateway authentication is off",
        "openclaw_wide_bind": "OpenClaw gateway reachable from the network",
        "openclaw_weak_token": "OpenClaw gateway token is short",
        "openclaw_origin_wildcard": "OpenClaw control UI allows any origin",
        "openclaw_dangerous_flag": "OpenClaw dangerously... switch is on",
        "openclaw_broad_trusted_proxy": "OpenClaw trusts every proxy",
        "openclaw_proxy_trust_loosened": "OpenClaw proxy trust loosened",
        "openclaw_open_dm": "OpenClaw accepts DM or group messages from anyone",
        "openclaw_mdns_full": "OpenClaw advertises full details over mDNS",
        "openclaw_audit_suppressed": "OpenClaw self-audit findings are suppressed",
        "openclaw_loose_permissions": "OpenClaw config readable by other users",
        "editor_auto_run_task": "Editor task runs when the folder is opened",
        "workflow_pwn_request": "Workflow checks out pull-request code where secrets exist",
        "workflow_expression_injection": "Workflow pastes untrusted text into a script",
        "workflow_unpinned_action": "Workflow uses a third-party action that is not pinned to a commit",
        "agent_settings_hook": "Claude Code settings run a hook command on agent events",
        "agent_settings_bypass": "Claude Code settings skip every permission prompt",
        "agent_settings_broad_allow": "Claude Code settings allow any shell command without asking",
        "agent_settings_endpoint_override": "Claude Code settings send API traffic to another host",
        "agent_settings_weakened": "Claude Code settings are looser than the accepted state",
        "agent_settings_writable": "Settings, tasks or workflow file writable by every user",
    ]

    /// `artifactLocation.uri`: absolute paths as `file://`, every byte outside the unreserved set
    /// (and `/`, `:`) percent-encoded.
    static func sarifURI(for path: String) -> String {
        var out = path.hasPrefix("/") ? "file://" : ""
        for byte in path.utf8 {
            let c = Character(UnicodeScalar(byte))
            if byte < 0x80, c.isASCII, c.isLetter || c.isNumber || "-._~/:".contains(c) { out.append(c) }
            else { out += String(format: "%%%02X", byte) }
        }
        return out
    }

    static func sarifLevel(_ severity: String) -> String {
        switch severity {
        case "high": return "error"
        case "medium": return "warning"
        default: return "note"
        }
    }

    /// The first `line N` in a finding's detail, if any.
    static func sarifStartLine(_ detail: String) -> Int? {
        guard let r = detail.range(of: #"\bline (\d{1,9})"#, options: .regularExpression) else { return nil }
        return Int(detail[r].dropFirst(5))
    }

    /// The detail text with decoded hidden text removed: SARIF never carries it.
    static func sarifDetail(_ detail: String) -> String {
        guard let r = detail.range(of: #", hidden text ".*"$"#, options: .regularExpression) else { return detail }
        return String(detail[..<r.lowerBound])
    }

    /// SARIF 2.1.0 log of one audit run, as a JSON-compatible dictionary.
    static func sarifLog(_ result: Result, toolVersion: String) -> [String: Any] {
        var ruleIDs = findingIDs
        for f in result.findings where !ruleIDs.contains(f.id) { ruleIDs.append(f.id) }

        let rules: [[String: Any]] = ruleIDs.map { id in
            let t = tags(for: id)
            var tagList = ["security"] + t.owaspLLM.map { "owasp-llm:\($0)" } + t.attack.map { "attack:\($0)" }
            tagList = Array(NSOrderedSet(array: tagList)) as? [String] ?? tagList
            return [
                "id": id,
                "name": id,
                "shortDescription": ["text": sarifRuleTitles[id] ?? id],
                "fullDescription": ["text": message(id)],
                "properties": [
                    "tags": tagList,
                    "owaspLlm": t.owaspLLM,
                    "attackId": t.attack,
                ] as [String: Any],
            ]
        }

        let artifactPaths = Array(NSOrderedSet(array: result.scannedFiles + result.findings.map(\.file))) as? [String] ?? result.scannedFiles
        let artifactIndex = Dictionary(uniqueKeysWithValues: artifactPaths.enumerated().map { ($1, $0) })
        let artifacts: [[String: Any]] = artifactPaths.map {
            ["location": ["uri": sarifURI(for: $0)], "roles": ["analysisTarget"]]
        }

        // Drift findings exist only when a state was accepted. Added files and servers are `new`, changed ones `updated`.
        let baselineStates: [String: String] = ["agent_file_added": "new", "mcp_server_added": "new",
                                                "agent_file_changed": "updated", "mcp_server_changed": "updated"]
        let results: [[String: Any]] = result.findings.map { f in
            let t = tags(for: f.id)
            let detail = sarifDetail(f.detail)
            var physical: [String: Any] = ["artifactLocation": ["uri": sarifURI(for: f.file), "index": artifactIndex[f.file] ?? 0] as [String: Any]]
            if let line = sarifStartLine(detail), line >= 1 { physical["region"] = ["startLine": line] }
            let title = sarifRuleTitles[f.id] ?? f.id
            let fingerprintSource = "\(f.id)\n\(f.file)\n\(detail)"
            let fingerprint = SHA256.hash(data: Data(fingerprintSource.utf8)).map { String(format: "%02x", $0) }.joined()
            var r: [String: Any] = [
                "ruleId": f.id,
                "level": sarifLevel(f.severity),
                "message": ["text": "\(title). \(detail)"],
                "locations": [["physicalLocation": physical]],
                "partialFingerprints": ["roamSwitchAgentSetup/v1": fingerprint],
                "properties": [
                    "severity": f.severity,
                    "area": f.area,
                    "owaspLlm": t.owaspLLM,
                    "attackId": t.attack,
                ] as [String: Any],
            ]
            if let i = ruleIDs.firstIndex(of: f.id) { r["ruleIndex"] = i }
            if let state = baselineStates[f.id] { r["baselineState"] = state }
            return r
        }

        // Files that exist but could not be read were NOT audited; say so in the log.
        let notifications: [[String: Any]] = result.unreadableFiles.map {
            [
                "level": "warning",
                "message": ["text": "This file exists but could not be read, so it was not audited."],
                "descriptor": ["id": "unreadable-file"],
                "locations": [["physicalLocation": ["artifactLocation": ["uri": sarifURI(for: $0)]]]],
            ]
        }

        var runProps: [String: Any] = [
            "skillCount": result.skillCount,
            "openClawConfigFound": result.openClawConfigFound,
            "scannedFileCount": result.scannedFiles.count,
        ]
        if let at = result.baselineAcceptedAt { runProps["baselineAcceptedAt"] = at }

        return [
            "$schema": sarifSchemaURI,
            "version": "2.1.0",
            "runs": [[
                "tool": ["driver": [
                    "name": "RoamSwitch agent setup audit",
                    "version": toolVersion,
                    "semanticVersion": toolVersion,
                    "rules": rules,
                ] as [String: Any]],
                "artifacts": artifacts,
                "invocations": [[
                    "executionSuccessful": true,
                    "toolExecutionNotifications": notifications,
                ] as [String: Any]],
                "results": results,
                "properties": runProps,
            ] as [String: Any]],
        ]
    }

    /// The strings of a result that come from outside RoamSwitch (file paths, names and details taken
    /// from the audited files), for the injection scan. The localized explanations are RoamSwitch's own.
    static func dataStrings(_ result: Result) -> [String] {
        result.findings.flatMap { [$0.detail, $0.file] } + result.scannedFiles + result.unreadableFiles
    }

    static func sarifJSON(_ result: Result, toolVersion: String) -> String {
        let log = sarifLog(result, toolVersion: toolVersion)
        guard let data = try? JSONSerialization.data(withJSONObject: log, options: [.sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
