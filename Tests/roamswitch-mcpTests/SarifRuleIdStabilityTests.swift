// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.16 (build 195). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// SARIF rule ids are the unit a dashboard groups alerts by. Renaming or removing one detaches every alert filed
/// under it (docs/sarif_rule_id_policy.md). These lists are the ids that have been published; an id may be
/// added to the code freely (and then added here), but never taken out of it.
final class SarifRuleIdStabilityTests: XCTestCase {

    private static let publishedAgentSetupIDs: [String] = [
        "hidden_tag_characters", "invisible_characters", "override_instruction", "remote_script_exec",
        "encoded_payload_exec", "credential_access", "credential_exfil_shape", "exfil_endpoint",
        "persistence_instruction", "skill_precompiled_code", "agent_file_writable",
        "homoglyph_name", "whitespace_padding", "hidden_encoded_text", "skill_broad_tool_grant",
        "agent_file_changed", "agent_file_added", "mcp_server_changed", "mcp_server_added",
        "openclaw_auth_disabled", "openclaw_wide_bind", "openclaw_weak_token", "openclaw_origin_wildcard",
        "openclaw_dangerous_flag", "openclaw_broad_trusted_proxy", "openclaw_proxy_trust_loosened",
        "openclaw_open_dm", "openclaw_mdns_full", "openclaw_audit_suppressed", "openclaw_loose_permissions",
        "editor_auto_run_task", "workflow_pwn_request", "workflow_expression_injection", "workflow_unpinned_action",
        "agent_settings_hook", "agent_settings_bypass", "agent_settings_broad_allow", "agent_settings_endpoint_override",
        "agent_settings_weakened", "agent_settings_writable",
    ]

    private static let publishedActiveProbeIDs: [String] = [
        "redis-default-noauth", "mongod-default-noauth", "dockerd-tcp-noauth", "memcached-noauth", "etcd-noauth",
        "elasticsearch-noauth", "couchdb-noauth", "jenkins-noauth", "vnc-noauth", "smb1-enabled",
        "smb-signing-not-required", "caido-network-exposed", "hexstrike-noauth", "ollama-exposed",
        "jupyter-noauth", "mlflow-noauth", "gradio-noauth",
        "webvuln-cors", "webvuln-traversal", "webvuln-redirect", "webvuln-ssrf", "webvuln-unauth-admin", "webvuln-xss",
        "nmap-nse", "unclassified",
    ]

    func testNoPublishedAgentSetupIdWasRemovedOrRenamed() {
        let current = Set(AgentSetupAuditor.findingIDs)
        let missing = Self.publishedAgentSetupIDs.filter { !current.contains($0) }
        XCTAssertTrue(missing.isEmpty, "rule ids removed or renamed: \(missing). See docs/sarif_rule_id_policy.md")
    }

    func testNoPublishedActiveProbeIdWasRemovedOrRenamed() {
        let current = Set(ActiveVulnScan.sarifRuleIDs)
        let missing = Self.publishedActiveProbeIDs.filter { !current.contains($0) }
        XCTAssertTrue(missing.isEmpty, "rule ids removed or renamed: \(missing). See docs/sarif_rule_id_policy.md")
    }

    func testTheAgentSetupSarifLogKeepsEveryPublishedRule() throws {
        let log = AgentSetupAuditor.sarifLog(AgentSetupAuditor.Result(), toolVersion: "0")
        let run = try XCTUnwrap((log["runs"] as? [[String: Any]])?.first)
        let driver = try XCTUnwrap((run["tool"] as? [String: Any])?["driver"] as? [String: Any])
        let ids = Set((driver["rules"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String })
        XCTAssertTrue(Set(Self.publishedAgentSetupIDs).isSubset(of: ids))
    }

    func testTheActiveScanSarifLogKeepsEveryPublishedRule() throws {
        let json = ActiveVulnScan.sarifJSON(ActiveVulnScan.ScanRunResult(), scannedTargetCount: 0, toolVersion: "0")
        let log = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let run = try XCTUnwrap((log["runs"] as? [[String: Any]])?.first)
        let driver = try XCTUnwrap((run["tool"] as? [String: Any])?["driver"] as? [String: Any])
        let ids = Set((driver["rules"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String })
        XCTAssertTrue(Set(Self.publishedActiveProbeIDs).isSubset(of: ids))
    }

    /// An id stays unique and plain: a dashboard keys on it as text.
    func testIdsAreUniqueAndPlain() {
        for list in [AgentSetupAuditor.findingIDs, ActiveVulnScan.sarifRuleIDs] {
            XCTAssertEqual(Set(list).count, list.count)
            for id in list { XCTAssertNotNil(id.range(of: #"^[a-z0-9][a-z0-9_-]*$"#, options: .regularExpression), id) }
        }
    }
}
