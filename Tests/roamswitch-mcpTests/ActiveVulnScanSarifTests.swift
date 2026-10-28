// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.10 (build 189). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The SARIF 2.1.0 form of an active vulnerability scan run.
///
/// Key sets are copied from the official schema (sarif-schema-2.1.0.json, errata01), as in `AgentSetupSarifTests`.
final class ActiveVulnScanSarifTests: XCTestCase {

    private static let resultKeys: Set<String> = ["analysisTarget", "attachments", "baselineState", "codeFlows", "correlationGuid", "fingerprints", "fixes", "graphTraversals", "graphs", "guid", "hostedViewerUri", "kind", "level", "locations", "message", "occurrenceCount", "partialFingerprints", "properties", "provenance", "rank", "relatedLocations", "rule", "ruleId", "ruleIndex", "stacks", "suppressions", "taxa", "webRequest", "webResponse", "workItemUris"]
    private static let ruleKeys: Set<String> = ["defaultConfiguration", "deprecatedGuids", "deprecatedIds", "deprecatedNames", "fullDescription", "guid", "help", "helpUri", "id", "messageStrings", "name", "properties", "relationships", "shortDescription"]
    private static let logicalLocationKeys: Set<String> = ["decoratedName", "fullyQualifiedName", "index", "kind", "name", "parentIndex", "properties"]
    private static let notificationKeys: Set<String> = ["associatedRule", "descriptor", "exception", "level", "locations", "message", "properties", "threadId", "timeUtc"]

    private func finding(_ probe: String?, port: Int = 6379, process: String = "redis-server", kind: EvidenceKind = .confirmed,
                         previouslySafeAt: String? = nil) -> ActiveVulnScan.Finding {
        ActiveVulnScan.Finding(port: port, processName: process, title: "Title \(port)", description: "Description \(port)",
                               recommendation: "Fix \(port)", probeName: probe, evidenceKind: kind, previouslySafeAt: previouslySafeAt)
    }

    private func log(_ scan: ActiveVulnScan.ScanRunResult, targets: Int = 3) throws -> [String: Any] {
        let json = ActiveVulnScan.sarifJSON(scan, scannedTargetCount: targets, toolVersion: "9.9.9")
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try XCTUnwrap(object as? [String: Any])
    }

    private func run(_ log: [String: Any]) throws -> [String: Any] {
        try XCTUnwrap((log["runs"] as? [[String: Any]])?.first)
    }

    private func rules(_ run: [String: Any]) throws -> [[String: Any]] {
        let driver = try XCTUnwrap((run["tool"] as? [String: Any])?["driver"] as? [String: Any])
        return try XCTUnwrap(driver["rules"] as? [[String: Any]])
    }

    // MARK: rules

    func testEveryProbeIsARuleWithATitleAndADescription() throws {
        let ids = ActiveVulnScan.sarifRuleIDs
        XCTAssertEqual(Set(ids).count, ids.count, "rule ids must be unique")
        for signature in ServiceSignatures.signatures { XCTAssertTrue(ids.contains(signature.id), signature.id) }
        for name in ProbeCatalog.webChecks.keys { XCTAssertTrue(ids.contains(name), name) }
        XCTAssertTrue(ids.contains(ActiveVulnScan.sarifUnclassifiedRuleID))
        for id in ids {
            XCTAssertNotNil(ActiveVulnScan.sarifRuleTitles[id], "no English title for \(id)")
            XCTAssertNotNil(ActiveVulnScan.sarifRuleDescriptions[id], "no description for \(id)")
        }
        // No orphan text for an id that is not a rule.
        XCTAssertEqual(Set(ActiveVulnScan.sarifRuleTitles.keys), Set(ids))
        XCTAssertEqual(Set(ActiveVulnScan.sarifRuleDescriptions.keys), Set(ids))
    }

    func testRuleShapeDeclaredSideEffectsAndEvidenceKind() throws {
        let rules = try rules(try run(try log(ActiveVulnScan.ScanRunResult())))
        XCTAssertEqual(rules.count, ActiveVulnScan.sarifRuleIDs.count)
        for rule in rules {
            XCTAssertTrue(Set(rule.keys).isSubset(of: Self.ruleKeys), "\(rule.keys)")
            let id = try XCTUnwrap(rule["id"] as? String)
            XCTAssertEqual(rule["name"] as? String, id)
            let props = try XCTUnwrap(rule["properties"] as? [String: Any])
            XCTAssertEqual(props["tags"] as? [String], ["security", "active-probe"])
            if let declaration = ProbeCatalog.declaration(forProbeName: id) {
                XCTAssertEqual(props["sideEffects"] as? [String], declaration.sideEffects.map(\.rawValue), id)
                XCTAssertEqual(props["evidenceKind"] as? String, declaration.evidenceKind.rawValue, id)
            } else {
                XCTAssertEqual(id, ActiveVulnScan.sarifUnclassifiedRuleID, "\(id) has no declaration")
            }
        }
        let ssrf = try XCTUnwrap(rules.first { $0["id"] as? String == "webvuln-ssrf" })
        XCTAssertEqual((ssrf["properties"] as? [String: Any])?["sideEffects"] as? [String], ["ioc_in_logs", "temporary_listener", "many_requests"])
    }

    func testReflectedXssIsDeclaredLikeTheOtherWebChecks() {
        let declaration = ProbeCatalog.declaration(forProbeName: "webvuln-xss")
        XCTAssertEqual(declaration?.sideEffects, [.iocInLogs, .manyRequests])
        XCTAssertEqual(declaration?.evidenceKind, .confirmed)
    }

    // MARK: results

    func testResultCarriesRuleLevelEvidenceAndEndpoint() throws {
        var scan = ActiveVulnScan.ScanRunResult()
        scan.findings = [
            finding("redis-default-noauth", previouslySafeAt: "2026-10-01T00:00:00Z"),
            finding("redis-default-noauth", port: 6379, kind: .versionRangeMatch),
            finding(ProbeCatalog.nmapNSEProbeName, port: 8080, process: "node", kind: .externalToolReport),
        ]
        let run = try run(try log(scan))
        let ruleIDs = try rules(run).compactMap { $0["id"] as? String }
        let results = try XCTUnwrap(run["results"] as? [[String: Any]])
        XCTAssertEqual(results.count, 3)
        for r in results {
            XCTAssertTrue(Set(r.keys).isSubset(of: Self.resultKeys), "\(r.keys)")
            let id = try XCTUnwrap(r["ruleId"] as? String)
            XCTAssertEqual(ruleIDs[try XCTUnwrap(r["ruleIndex"] as? Int)], id, "ruleIndex must point at its rule")
        }
        XCTAssertEqual(results.map { $0["level"] as? String }, ["error", "warning", "warning"])
        XCTAssertEqual((results[0]["message"] as? [String: Any])?["text"] as? String, "Title 6379. Description 6379")

        let location = try XCTUnwrap(((results[0]["locations"] as? [[String: Any]])?.first?["logicalLocations"] as? [[String: Any]])?.first)
        XCTAssertTrue(Set(location.keys).isSubset(of: Self.logicalLocationKeys))
        XCTAssertEqual(location["name"] as? String, "127.0.0.1:6379")
        XCTAssertEqual(location["kind"] as? String, "endpoint")
        XCTAssertEqual(location["fullyQualifiedName"] as? String, "tcp://127.0.0.1:6379")

        let props = try XCTUnwrap(results[0]["properties"] as? [String: Any])
        XCTAssertEqual(props["port"] as? Int, 6379)
        XCTAssertEqual(props["processName"] as? String, "redis-server")
        XCTAssertEqual(props["evidenceKind"] as? String, "confirmed")
        XCTAssertEqual(props["recommendation"] as? String, "Fix 6379")
        XCTAssertEqual(props["previouslySafeAt"] as? String, "2026-10-01T00:00:00Z")
        XCTAssertNil((results[1]["properties"] as? [String: Any])?["previouslySafeAt"])
        XCTAssertEqual((results[1]["properties"] as? [String: Any])?["evidenceKind"] as? String, "version_range_match")
    }

    func testAFindingWithoutAKnownProbeIdIsUnclassified() throws {
        var scan = ActiveVulnScan.ScanRunResult()
        scan.findings = [finding(nil), finding("a-probe-that-does-not-exist", port: 9000)]
        let results = try XCTUnwrap(try run(try log(scan))["results"] as? [[String: Any]])
        XCTAssertEqual(results.map { $0["ruleId"] as? String }, ["unclassified", "unclassified"])
    }

    func testFingerprintDependsOnProbeAndPortNotOnTheProcessName() throws {
        let a = ActiveVulnScan.sarifFingerprint(ruleID: "redis-default-noauth", port: 6379)
        XCTAssertEqual(a, ActiveVulnScan.sarifFingerprint(ruleID: "redis-default-noauth", port: 6379))
        XCTAssertNotEqual(a, ActiveVulnScan.sarifFingerprint(ruleID: "redis-default-noauth", port: 6380))
        XCTAssertNotEqual(a, ActiveVulnScan.sarifFingerprint(ruleID: "memcached-noauth", port: 6379))
        XCTAssertEqual(a.count, 64)
        var one = ActiveVulnScan.ScanRunResult(), two = ActiveVulnScan.ScanRunResult()
        one.findings = [finding("redis-default-noauth", process: "redis-server")]
        two.findings = [finding("redis-default-noauth", process: "renamed-binary")]
        func fingerprint(_ s: ActiveVulnScan.ScanRunResult) throws -> String? {
            let r = try XCTUnwrap(try run(try log(s))["results"] as? [[String: Any]])
            return (r[0]["partialFingerprints"] as? [String: String])?["roamSwitchActiveVulnScan/v1"]
        }
        XCTAssertEqual(try fingerprint(one), try fingerprint(two))
    }

    // MARK: completeness

    func testACheckThatCouldNotConnectIsANotificationAndTheRunIsIncomplete() throws {
        var scan = ActiveVulnScan.ScanRunResult()
        scan.confirmedSafe = [ActiveVulnScan.CheckOutcome(port: 6379, processName: "redis-server", check: "Redis")]
        scan.inconclusive = [ActiveVulnScan.CheckOutcome(port: 27017, processName: "mongod", check: "MongoDB"),
                             ActiveVulnScan.CheckOutcome(port: 8080, processName: "node", check: "CORS")]
        scan.probesRun = ["redis-default-noauth", "mongod-default-noauth", "webvuln-cors", "an-unknown-probe"]
        let run = try run(try log(scan, targets: 5))
        XCTAssertEqual((run["results"] as? [Any])?.count, 0, "inconclusive is not a finding")

        let invocation = try XCTUnwrap((run["invocations"] as? [[String: Any]])?.first)
        XCTAssertEqual(invocation["executionSuccessful"] as? Bool, true)
        let notes = try XCTUnwrap(invocation["toolExecutionNotifications"] as? [[String: Any]])
        XCTAssertEqual(notes.count, 2)
        for n in notes {
            XCTAssertTrue(Set(n.keys).isSubset(of: Self.notificationKeys))
            XCTAssertEqual(n["level"] as? String, "warning")
            XCTAssertEqual((n["message"] as? [String: Any])?["text"] as? String, "Could not connect; this check was not completed.")
            XCTAssertEqual((n["descriptor"] as? [String: Any])?["id"] as? String, "inconclusive-check")
        }
        XCTAssertEqual((notes[0]["properties"] as? [String: Any])?["port"] as? Int, 27017)
        XCTAssertEqual((notes[0]["properties"] as? [String: Any])?["check"] as? String, "MongoDB")

        let props = try XCTUnwrap(run["properties"] as? [String: Any])
        XCTAssertEqual(props["complete"] as? Bool, false)
        XCTAssertEqual(props["inconclusiveCount"] as? Int, 2)
        XCTAssertEqual(props["confirmedSafeCount"] as? Int, 1)
        XCTAssertEqual(props["scannedTargetCount"] as? Int, 5)
        let probes = try XCTUnwrap(props["probesRun"] as? [[String: Any]])
        XCTAssertEqual(probes.compactMap { $0["probeName"] as? String }, ["redis-default-noauth", "mongod-default-noauth", "webvuln-cors"],
                       "a probe with no declaration is left out, as in the JSON form")
        XCTAssertEqual(probes[2]["sideEffects"] as? [String], ["ioc_in_logs"])
        XCTAssertEqual(probes[2]["evidenceKind"] as? String, "confirmed")
    }

    func testACleanCompleteRunHasNoResultsAndNoNotifications() throws {
        var scan = ActiveVulnScan.ScanRunResult()
        scan.confirmedSafe = [ActiveVulnScan.CheckOutcome(port: 6379, processName: "redis-server", check: "Redis")]
        let log = try log(scan)
        XCTAssertEqual(log["version"] as? String, "2.1.0")
        XCTAssertEqual(log["$schema"] as? String, AgentSetupAuditor.sarifSchemaURI)
        let run = try run(log)
        XCTAssertEqual((run["results"] as? [Any])?.count, 0)
        let invocation = try XCTUnwrap((run["invocations"] as? [[String: Any]])?.first)
        XCTAssertEqual((invocation["toolExecutionNotifications"] as? [Any])?.count, 0)
        XCTAssertEqual((run["properties"] as? [String: Any])?["complete"] as? Bool, true)
        let driver = try XCTUnwrap((run["tool"] as? [String: Any])?["driver"] as? [String: Any])
        XCTAssertEqual(driver["name"] as? String, "RoamSwitch active vulnerability scan")
        XCTAssertEqual(driver["version"] as? String, "9.9.9")
    }

    // MARK: untrusted text

    func testDataStringsHoldProcessNamesAndOnlyAnExternalToolsOwnText() {
        var scan = ActiveVulnScan.ScanRunResult()
        scan.findings = [finding("redis-default-noauth", process: "proc-a"),
                         finding(ProbeCatalog.nmapNSEProbeName, port: 8080, process: "proc-b", kind: .externalToolReport)]
        scan.inconclusive = [ActiveVulnScan.CheckOutcome(port: 1, processName: "proc-c", check: "x")]
        scan.confirmedSafe = [ActiveVulnScan.CheckOutcome(port: 2, processName: "proc-d", check: "y")]
        let strings = ActiveVulnScan.sarifDataStrings(scan)
        for name in ["proc-a", "proc-b", "proc-c", "proc-d", "Title 8080", "Description 8080", "Fix 8080"] { XCTAssertTrue(strings.contains(name), name) }
        XCTAssertFalse(strings.contains("Title 6379"), "RoamSwitch's own text is not scanned")
    }
}
