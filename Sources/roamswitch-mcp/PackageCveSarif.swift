// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.32 (build 211).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

/// SARIF 2.1.0 form of the package CVE scans (`run_package_cve_scan` for Homebrew, `run_package_cve_scan_languages`
/// for lockfiles), for CI and code-scanning tools.
///
/// The rule id is the CVE id: it names one published vulnerability and never changes, which is what an alert
/// dashboard needs (`docs/sarif_rule_id_policy.md`). A result is one package version affected by it. The level
/// follows the tier (`PackageCveEpss.tier`): `kev` and `epss_high` are errors, the rest is an error at CVSS 9.0 or
/// more and a warning below. Each rule carries `security-severity` (the CVSS score as text), which GitHub code
/// scanning reads to rank alerts. The feed's summary is data from outside RoamSwitch and goes into the rule's
/// description as it is; the MCP layer marks the whole log as untrusted.
enum PackageCveSarif {

    struct Item {
        let cveId: String
        let ecosystem: String
        let package: String
        let installedVersion: String
        let fixedVersion: String
        let cvssScore: Double
        let summary: String
        let epss: Double?
        let kev: Bool
        let unfixed: Bool
        /// The lockfile, or nil for an installed (Homebrew) package.
        let file: String?
    }

    static func items(homebrew findings: [PackageCveScan.Finding]) -> [Item] {
        findings.map {
            Item(cveId: $0.cveId, ecosystem: "Homebrew", package: $0.package, installedVersion: $0.installedVersion,
                 fixedVersion: $0.fixedVersion, cvssScore: $0.cvssScore, summary: $0.summary, epss: $0.epss, kev: $0.kev,
                 unfixed: false, file: nil)
        }
    }

    static func items(languages findings: [PackageCveScanLanguages.Finding]) -> [Item] {
        findings.map {
            Item(cveId: $0.cveId, ecosystem: $0.ecosystem, package: $0.package, installedVersion: $0.installedVersion,
                 fixedVersion: $0.fixedVersion, cvssScore: $0.cvssScore, summary: $0.summary, epss: $0.epss, kev: $0.kev,
                 unfixed: $0.unfixed, file: $0.lockfile.isEmpty ? nil : $0.lockfile)
        }
    }

    static func level(_ item: Item) -> String {
        let tier = PackageCveEpss.tier(kev: item.kev, epss: item.epss)
        if tier != "info" || item.cvssScore >= 9.0 { return "error" }
        return "warning"
    }

    /// `notifications`: what could not be checked (no map installed, an ecosystem without a map), so an empty
    /// result list is not read as "no vulnerable package".
    static func sarifLog(_ items: [Item], driverName: String, toolVersion: String, notifications: [String],
                         properties: [String: Any]) -> [String: Any] {
        var ruleIDs: [String] = []
        var firstByRule: [String: Item] = [:]
        for i in items where firstByRule[i.cveId] == nil {
            ruleIDs.append(i.cveId)
            firstByRule[i.cveId] = i
        }
        let rules: [[String: Any]] = ruleIDs.map { id in
            let i = firstByRule[id]!
            let summary = i.summary.isEmpty ? "Known vulnerability \(id)" : i.summary
            return [
                "id": id,
                "name": id,
                "shortDescription": ["text": "\(id) in \(i.ecosystem) package \(i.package)"],
                "fullDescription": ["text": summary],
                "helpUri": "https://nvd.nist.gov/vuln/detail/\(id)",
                "properties": [
                    "tags": ["security", "vulnerability", "dependency"],
                    "security-severity": String(format: "%.1f", i.cvssScore),
                ] as [String: Any],
            ]
        }
        let artifactPaths = Array(NSOrderedSet(array: items.compactMap(\.file))) as? [String] ?? []
        let artifactIndex = Dictionary(uniqueKeysWithValues: artifactPaths.enumerated().map { ($1, $0) })
        let results: [[String: Any]] = items.map { i in
            let tier = PackageCveEpss.tier(kev: i.kev, epss: i.epss)
            let fix = i.unfixed || i.fixedVersion.isEmpty ? "no fixed version is published" : "fixed in \(i.fixedVersion)"
            var location: [String: Any] = [
                "logicalLocations": [["fullyQualifiedName": "\(i.ecosystem.lowercased()):\(i.package)@\(i.installedVersion)", "kind": "package"]],
            ]
            if let file = i.file {
                location["physicalLocation"] = ["artifactLocation": ["uri": AgentSetupAuditor.sarifURI(for: file), "index": artifactIndex[file] ?? 0] as [String: Any]]
            }
            let fingerprint = SHA256.hash(data: Data("\(i.cveId)\n\(i.ecosystem)\n\(i.package)\n\(i.installedVersion)\n\(i.file ?? "")".utf8))
                .map { String(format: "%02x", $0) }.joined()
            var props: [String: Any] = [
                "tier": tier, "cvss": i.cvssScore, "kev": i.kev, "ecosystem": i.ecosystem, "package": i.package,
                "installedVersion": i.installedVersion, "fixedVersion": i.fixedVersion, "unfixed": i.unfixed,
            ]
            if let e = PackageCveEpss.validated(i.epss) { props["epss"] = e }
            var r: [String: Any] = [
                "ruleId": i.cveId,
                "level": level(i),
                "message": ["text": "\(i.package) \(i.installedVersion) (\(i.ecosystem)) is affected by \(i.cveId), CVSS \(String(format: "%.1f", i.cvssScore)), \(fix). Tier: \(tier)."],
                "locations": [location],
                "partialFingerprints": ["roamSwitchPackageCve/v1": fingerprint],
                "properties": props,
            ]
            if let idx = ruleIDs.firstIndex(of: i.cveId) { r["ruleIndex"] = idx }
            return r
        }
        let notes: [[String: Any]] = notifications.map {
            ["level": "warning", "message": ["text": $0], "descriptor": ["id": "not-checked"]]
        }
        var runProps = properties
        runProps["complete"] = notifications.isEmpty
        return [
            "$schema": AgentSetupAuditor.sarifSchemaURI,
            "version": "2.1.0",
            "runs": [[
                "tool": ["driver": [
                    "name": driverName,
                    "version": toolVersion,
                    "semanticVersion": toolVersion,
                    "rules": rules,
                ] as [String: Any]],
                "artifacts": artifactPaths.map { ["location": ["uri": AgentSetupAuditor.sarifURI(for: $0)], "roles": ["analysisTarget"]] },
                "invocations": [["executionSuccessful": true, "toolExecutionNotifications": notes] as [String: Any]],
                "results": results,
                "properties": runProps,
            ] as [String: Any]],
        ]
    }

    /// Text that comes from the feeds and the lockfiles, for the injection scan.
    static func dataStrings(_ items: [Item]) -> [String] {
        items.flatMap { [$0.summary, $0.package, $0.installedVersion, $0.fixedVersion, $0.file ?? ""] }
    }

    static func json(_ log: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: log, options: [.sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
