// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.13 (build 192).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

/// SARIF 2.1.0 form of one `run_active_vuln_scan` run, for CI and code-scanning tools.
///
/// The rule id is the probe id (`ProbeCatalog`), the same id the probe log and `get_active_vuln_scan_status`
/// use. Ids are the unit an alert dashboard groups by, so they never change (`docs/sarif_rule_id_policy.md`).
/// A rule describes the kind of weakness a probe looks for, never one finding.
///
/// What the log says about completeness: a check that could not connect is NOT a clean check. It appears as a
/// tool execution notification (`inconclusive-check`) and `run.properties.complete` is false, so a CI gate can
/// tell "scanned and found nothing" from "could not scan". `evidenceKind` stays on every result and rule, so a
/// version-range match is never mistaken for a weakness that was shown on the wire.
///
/// The ids, the shape and the wording are the same on the Linux edition.
extension ActiveVulnScan {

    static let sarifUnclassifiedRuleID = "unclassified"

    /// Short English titles of the rules (SARIF consumers are English-first), keyed by probe id.
    static let sarifRuleTitles: [String: String] = [
        "redis-default-noauth": "Redis accepts commands without authentication",
        "mongod-default-noauth": "MongoDB accepts commands without authentication",
        "dockerd-tcp-noauth": "Docker daemon API reachable over TCP without client authentication",
        "memcached-noauth": "Memcached answers without authentication",
        "etcd-noauth": "etcd serves its data without client authentication",
        "elasticsearch-noauth": "Elasticsearch answers without authentication",
        "couchdb-noauth": "CouchDB answers without authentication",
        "jenkins-noauth": "Jenkins is open without a login",
        "vnc-noauth": "VNC server accepts connections without authentication",
        "smb1-enabled": "SMBv1 is enabled",
        "smb-signing-not-required": "SMB signing is not required",
        "caido-network-exposed": "Intercepting proxy reachable from the network",
        "hexstrike-noauth": "Command execution API open without authentication",
        "ollama-exposed": "Local LLM server usable from the network without authentication",
        "jupyter-noauth": "Jupyter Server open without token or password",
        "mlflow-noauth": "MLflow Tracking Server open without authentication",
        "gradio-noauth": "Gradio app open without authentication",
        "webvuln-cors": "CORS policy lets any origin read responses",
        "webvuln-traversal": "Path traversal reads files outside the web root",
        "webvuln-redirect": "Open redirect",
        "webvuln-ssrf": "Server-side request forgery",
        "webvuln-unauth-admin": "Admin or API path returns data without a login",
        "webvuln-xss": "Reflected cross-site scripting",
        ProbeCatalog.nmapNSEProbeName: "nmap NSE script reports an issue",
        sarifUnclassifiedRuleID: "Finding without a probe id",
    ]

    /// What each rule is about: the kind of weakness, never an instance.
    static let sarifRuleDescriptions: [String: String] = [
        "redis-default-noauth": "A Redis server answers commands without AUTH. Anyone who can reach the port can read and change its data.",
        "mongod-default-noauth": "A MongoDB server lists its databases without authentication. Anyone who can reach the port can read and change its data.",
        "dockerd-tcp-noauth": "The Docker daemon listens on TCP. Without mutual TLS, whoever can connect can act with the host's root rights.",
        "memcached-noauth": "A Memcached server answers without authentication. Anyone who can reach it can read and change the cache.",
        "etcd-noauth": "An etcd server serves its key-value data without client authentication.",
        "elasticsearch-noauth": "An Elasticsearch node answers requests without authentication and exposes its indices.",
        "couchdb-noauth": "A CouchDB server answers requests without authentication.",
        "jenkins-noauth": "A Jenkins controller serves its pages without a login.",
        "vnc-noauth": "A VNC server accepts a session without authentication.",
        "smb1-enabled": "The SMB service still offers the obsolete SMBv1 protocol.",
        "smb-signing-not-required": "The SMB service does not require message signing, which allows relay and tampering on the network.",
        "caido-network-exposed": "An intercepting proxy meant for the loopback interface is reachable from the network.",
        "hexstrike-noauth": "An HTTP API that runs commands answers without authentication.",
        "ollama-exposed": "A local LLM server is reachable from the network without authentication.",
        "jupyter-noauth": "A Jupyter Server accepts requests without a token or password, which means code execution for whoever connects.",
        "mlflow-noauth": "An MLflow Tracking Server answers without authentication.",
        "gradio-noauth": "A Gradio app is reachable without authentication.",
        "webvuln-cors": "The server reflects a foreign Origin together with credentials, so a page from another site can read its responses.",
        "webvuln-traversal": "A request containing ../ returns a file from outside the intended directory.",
        "webvuln-redirect": "A parameter lets a request choose the address the server redirects to.",
        "webvuln-ssrf": "A parameter lets a request make the server fetch an address of the requester's choosing.",
        "webvuln-unauth-admin": "A path that looks administrative or an API route returns data to a request that carries no login.",
        "webvuln-xss": "A value sent in a request is written into the HTML page without the encoding its position requires.",
        ProbeCatalog.nmapNSEProbeName: "A script from nmap's safe category reported an issue. RoamSwitch did not verify it.",
        sarifUnclassifiedRuleID: "A finding that carries no probe id.",
    ]

    /// Every rule id the log can hold: all probe ids (never removed or renamed) plus the unclassified bucket.
    static var sarifRuleIDs: [String] {
        let probeIDs = Set(ProbeCatalog.webChecks.keys).union(ServiceSignatures.signatures.map(\.id))
        return probeIDs.sorted() + [sarifUnclassifiedRuleID]
    }

    static func sarifLevel(for kind: EvidenceKind) -> String {
        switch kind {
        case .confirmed: return "error"
        case .versionRangeMatch, .portOpenOnly, .externalToolReport: return "warning"
        }
    }

    static func sarifFingerprint(ruleID: String, port: Int) -> String {
        SHA256.hash(data: Data("\(ruleID)\n\(port)".utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// SARIF 2.1.0 log of one run, as a JSON-compatible dictionary.
    static func sarifLog(_ scan: ScanRunResult, scannedTargetCount: Int, toolVersion: String) -> [String: Any] {
        let ruleIDs = sarifRuleIDs
        let rules: [[String: Any]] = ruleIDs.map { id in
            var props: [String: Any] = ["tags": ["security", "active-probe"]]
            if let declaration = ProbeCatalog.declaration(forProbeName: id) {
                props["sideEffects"] = declaration.sideEffects.map(\.rawValue)
                props["evidenceKind"] = declaration.evidenceKind.rawValue
            }
            return [
                "id": id,
                "name": id,
                "shortDescription": ["text": sarifRuleTitles[id] ?? id],
                "fullDescription": ["text": sarifRuleDescriptions[id] ?? sarifRuleTitles[id] ?? id],
                "properties": props,
            ]
        }

        let results: [[String: Any]] = scan.findings.map { f in
            let ruleID = f.probeName.flatMap { ruleIDs.contains($0) ? $0 : nil } ?? sarifUnclassifiedRuleID
            var props: [String: Any] = [
                "port": f.port,
                "processName": f.processName,
                "evidenceKind": f.evidenceKind.rawValue,
                "recommendation": f.recommendation,
            ]
            if let at = f.previouslySafeAt { props["previouslySafeAt"] = at }
            var result: [String: Any] = [
                "ruleId": ruleID,
                "level": sarifLevel(for: f.evidenceKind),
                "message": ["text": "\(f.title). \(f.description)"],
                "locations": [[
                    "logicalLocations": [[
                        "name": "127.0.0.1:\(f.port)",
                        "kind": "endpoint",
                        "fullyQualifiedName": "tcp://127.0.0.1:\(f.port)",
                    ]],
                ]],
                "partialFingerprints": ["roamSwitchActiveVulnScan/v1": sarifFingerprint(ruleID: ruleID, port: f.port)],
                "properties": props,
            ]
            if let index = ruleIDs.firstIndex(of: ruleID) { result["ruleIndex"] = index }
            return result
        }

        // A check that could not connect was not done. Say so, so an empty `results` is not read as "clean".
        let notifications: [[String: Any]] = scan.inconclusive.map {
            [
                "level": "warning",
                "message": ["text": "Could not connect; this check was not completed."],
                "descriptor": ["id": "inconclusive-check"],
                "properties": ["port": $0.port, "check": $0.check] as [String: Any],
            ]
        }

        let probesRun: [[String: Any]] = scan.probesRun.compactMap { name in
            ProbeCatalog.declaration(forProbeName: name).map {
                ["probeName": name, "sideEffects": $0.sideEffects.map(\.rawValue), "evidenceKind": $0.evidenceKind.rawValue]
            }
        }

        return [
            "$schema": AgentSetupAuditor.sarifSchemaURI,
            "version": "2.1.0",
            "runs": [[
                "tool": ["driver": [
                    "name": "RoamSwitch active vulnerability scan",
                    "version": toolVersion,
                    "semanticVersion": toolVersion,
                    "rules": rules,
                ] as [String: Any]],
                "invocations": [[
                    "executionSuccessful": true,
                    "toolExecutionNotifications": notifications,
                ] as [String: Any]],
                "results": results,
                "properties": [
                    "scannedTargetCount": scannedTargetCount,
                    "probesRun": probesRun,
                    "confirmedSafeCount": scan.confirmedSafe.count,
                    "inconclusiveCount": scan.inconclusive.count,
                    "complete": scan.inconclusive.isEmpty,
                ] as [String: Any],
            ] as [String: Any]],
        ]
    }

    /// The strings of a result that come from outside RoamSwitch, for the injection scan: process names, and the
    /// text of a finding that is another tool's own output (nmap).
    static func sarifDataStrings(_ scan: ScanRunResult) -> [String] {
        let external = scan.findings.filter { $0.evidenceKind == .externalToolReport }.flatMap { [$0.title, $0.description, $0.recommendation] }
        return scan.findings.map(\.processName) + scan.inconclusive.map(\.processName) + scan.confirmedSafe.map(\.processName) + external
    }

    static func sarifJSON(_ scan: ScanRunResult, scannedTargetCount: Int, toolVersion: String) -> String {
        let log = sarifLog(scan, scannedTargetCount: scannedTargetCount, toolVersion: toolVersion)
        guard let data = try? JSONSerialization.data(withJSONObject: log, options: [.sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
