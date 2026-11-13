// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.35 (build 214). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The package CVE results: the triage tier and the SARIF form of both scans.
final class PackageCveSarifTests: XCTestCase {

    func testTier() {
        XCTAssertEqual(PackageCveEpss.tier(kev: true, epss: nil), "kev")
        XCTAssertEqual(PackageCveEpss.tier(kev: true, epss: 0.1), "kev", "KEV wins over EPSS")
        XCTAssertEqual(PackageCveEpss.tier(kev: false, epss: 0.9), "epss_high")
        XCTAssertEqual(PackageCveEpss.tier(kev: false, epss: 0.97), "epss_high")
        XCTAssertEqual(PackageCveEpss.tier(kev: false, epss: 0.89), "info")
        XCTAssertEqual(PackageCveEpss.tier(kev: false, epss: nil), "info")
        XCTAssertEqual(PackageCveEpss.tier(kev: false, epss: 1.5), "info", "an invalid value from a feed is not trusted")
        XCTAssertEqual(PackageCveExposure.epssThreshold, 0.9, "the tier uses the bar the diagnosis fails on")
    }

    func testTheMcpPayloadsCarryTheTier() throws {
        var p = MCPPackageCveLanguageFindingPayload(lockfile: "/a", ecosystem: "npm", cveId: "CVE-1", package: "p", installedVersion: "1",
                                                    cvssScore: 8, fixedVersion: "2", summary: "")
        p.tier = PackageCveEpss.tier(kev: false, epss: 0.95)
        XCTAssertTrue(String(decoding: try JSONEncoder().encode(p), as: UTF8.self).contains("\"tier\":\"epss_high\""))
        let h = MCPPackageCveFindingPayload(cveId: "CVE-1", package: "p", installedVersion: "1", cvssScore: 8, fixedVersion: "2", summary: "", confidence: "confirmed")
        XCTAssertTrue(String(decoding: try JSONEncoder().encode(h), as: UTF8.self).contains("\"tier\":\"info\""))
    }

    private func run(_ log: [String: Any]) throws -> [String: Any] {
        let data = try XCTUnwrap(PackageCveSarif.json(log).data(using: .utf8))
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(parsed["version"] as? String, "2.1.0")
        return try XCTUnwrap((parsed["runs"] as? [[String: Any]])?.first)
    }

    func testLanguagesSarifUsesTheCveAsTheRuleAndTheLockfileAsTheLocation() throws {
        let findings = [
            PackageCveScanLanguages.Finding(ecosystem: "npm", package: "lodash", installedVersion: "4.17.20", cveId: "CVE-2021-23337",
                                            cvssScore: 7.2, fixedVersion: "4.17.21", summary: "Command injection in template", lockfile: "/p/package-lock.json",
                                            epss: 0.95),
            PackageCveScanLanguages.Finding(ecosystem: "npm", package: "lodash", installedVersion: "4.17.20", cveId: "CVE-2021-23337",
                                            cvssScore: 7.2, fixedVersion: "4.17.21", summary: "Command injection in template", lockfile: "/q/package-lock.json"),
            PackageCveScanLanguages.Finding(ecosystem: "PyPI", package: "x", installedVersion: "1.0", cveId: "CVE-2024-1",
                                            cvssScore: 5.0, fixedVersion: "", summary: "", lockfile: "/p/requirements.txt", unfixed: true),
        ]
        let items = PackageCveSarif.items(languages: findings)
        let r = try run(PackageCveSarif.sarifLog(items, driverName: "d", toolVersion: "1", notifications: [], properties: [:]))
        let rules = try XCTUnwrap(((r["tool"] as? [String: Any])?["driver"] as? [String: Any])?["rules"] as? [[String: Any]])
        XCTAssertEqual(rules.compactMap { $0["id"] as? String }, ["CVE-2021-23337", "CVE-2024-1"], "one rule per CVE")
        XCTAssertEqual((rules[0]["properties"] as? [String: Any])?["security-severity"] as? String, "7.2")
        let results = try XCTUnwrap(r["results"] as? [[String: Any]])
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0]["level"] as? String, "error", "epss_high is an error")
        XCTAssertEqual(results[1]["level"] as? String, "warning")
        XCTAssertEqual((results[0]["properties"] as? [String: Any])?["tier"] as? String, "epss_high")
        XCTAssertEqual((results[2]["properties"] as? [String: Any])?["unfixed"] as? Bool, true)
        let loc = try XCTUnwrap((results[0]["locations"] as? [[String: Any]])?.first)
        XCTAssertEqual(((loc["physicalLocation"] as? [String: Any])?["artifactLocation"] as? [String: Any])?["uri"] as? String, "file:///p/package-lock.json")
        XCTAssertEqual(((loc["logicalLocations"] as? [[String: Any]])?.first)?["fullyQualifiedName"] as? String, "npm:lodash@4.17.20")
        let fp0 = (results[0]["partialFingerprints"] as? [String: String])?["roamSwitchPackageCve/v1"]
        let fp1 = (results[1]["partialFingerprints"] as? [String: String])?["roamSwitchPackageCve/v1"]
        XCTAssertNotEqual(fp0, fp1, "the same CVE in two projects is two alerts")
        XCTAssertEqual((r["properties"] as? [String: Any])?["complete"] as? Bool, true)
    }

    func testHomebrewSarifHasNoFileAndSaysWhatWasNotChecked() throws {
        var f = PackageCveScan.Finding(cveId: "CVE-2023-38545", package: "curl", installedVersion: "8.3.0", cvssScore: 9.8,
                                       fixedVersion: "8.4.0", summary: "SOCKS5 heap overflow", confidence: "confirmed")
        f.kev = true
        let r = try run(PackageCveSarif.sarifLog(PackageCveSarif.items(homebrew: [f]), driverName: "d", toolVersion: "1",
                                                 notifications: ["No Homebrew CVE map is installed on this Mac yet, so no package was checked."],
                                                 properties: ["mapVersion": "x"]))
        let result = try XCTUnwrap((r["results"] as? [[String: Any]])?.first)
        XCTAssertEqual(result["level"] as? String, "error")
        let loc = try XCTUnwrap((result["locations"] as? [[String: Any]])?.first)
        XCTAssertNil(loc["physicalLocation"])
        XCTAssertEqual(((loc["logicalLocations"] as? [[String: Any]])?.first)?["fullyQualifiedName"] as? String, "homebrew:curl@8.3.0")
        XCTAssertEqual((r["properties"] as? [String: Any])?["complete"] as? Bool, false)
        let notes = ((r["invocations"] as? [[String: Any]])?.first?["toolExecutionNotifications"] as? [[String: Any]]) ?? []
        XCTAssertEqual(notes.count, 1)
    }
}
