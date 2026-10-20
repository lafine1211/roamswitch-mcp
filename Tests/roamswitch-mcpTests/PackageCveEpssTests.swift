// Mirrored from RoamSwitchTests/ — RoamSwitch 1.14.0 (build 173). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// EPSS on the package CVE scans: optional in the signed feed, shown as a hint, used only to order findings of
/// equal severity. A feed without EPSS (every feed before this change) must decode and scan exactly as before.
final class PackageCveEpssTests: XCTestCase {

    // MARK: value and label

    func testOnlyAFiniteNumberFromZeroToOneIsAccepted() {
        XCTAssertEqual(PackageCveEpss.validated(0), 0)
        XCTAssertEqual(PackageCveEpss.validated(1), 1)
        XCTAssertEqual(PackageCveEpss.validated(0.123), 0.123)
        for bad in [-0.01, 1.01, Double.nan, Double.infinity, 12.0] {
            XCTAssertNil(PackageCveEpss.validated(bad), "\(bad)")
        }
        XCTAssertNil(PackageCveEpss.validated(nil))
    }

    func testOnlyAnIsoShapedDateIsAccepted() {
        XCTAssertEqual(PackageCveEpss.validatedDate("2026-10-18"), "2026-10-18")
        for bad in ["", "2026/10/18", "18-10-2026", "2026-10-1", "2026-10-18T00:00:00Z", "２０２６-10-18", "abcd-ef-gh"] {
            XCTAssertNil(PackageCveEpss.validatedDate(bad), bad)
        }
        XCTAssertNil(PackageCveEpss.validatedDate(nil))
    }

    func testTheLabelShowsAPercentAndTheDay() {
        XCTAssertEqual(PackageCveEpss.label(epss: 0.12, date: "2026-10-18"), "EPSS 12% (2026-10-18)")
        XCTAssertEqual(PackageCveEpss.label(epss: 0.974, date: "2026-10-18"), "EPSS 97% (2026-10-18)")
        XCTAssertEqual(PackageCveEpss.label(epss: 0.001, date: "2026-10-18"), "EPSS <1% (2026-10-18)")
        XCTAssertEqual(PackageCveEpss.label(epss: 1.0, date: nil), "EPSS 100%")
        XCTAssertNil(PackageCveEpss.label(epss: nil, date: "2026-10-18"), "no value, nothing shown, nothing guessed")
        XCTAssertNil(PackageCveEpss.label(epss: 4, date: "2026-10-18"))
    }

    // MARK: ordering

    func testBandsFollowTheCvssRatings() {
        XCTAssertEqual([10.0, 9.0, 8.9, 7.0, 6.9, 4.0, 3.9, 0.0].map(PackageCveEpss.band(cvss:)), [3, 3, 2, 2, 1, 1, 0, 0])
    }

    func testEpssOrdersInsideABandAndNeverAcrossBands() {
        func before(_ a: (Double, Double?, String), _ b: (Double, Double?, String)) -> Bool {
            PackageCveEpss.precedes(cvssA: a.0, epssA: a.1, idA: a.2, cvssB: b.0, epssB: b.1, idB: b.2)
        }
        // Same band: higher EPSS first even with a lower CVSS.
        XCTAssertTrue(before((7.5, 0.9, "A"), (8.8, 0.1, "B")))
        XCTAssertFalse(before((8.8, 0.1, "B"), (7.5, 0.9, "A")))
        // Different bands: the band wins over a huge EPSS.
        XCTAssertTrue(before((9.8, 0.0, "A"), (7.5, 0.99, "B")))
        // A value beats no value; two without a value fall back to CVSS, then to the id.
        XCTAssertTrue(before((7.5, 0.0, "A"), (7.9, nil, "B")))
        XCTAssertTrue(before((7.9, nil, "B"), (7.5, nil, "A")))
        XCTAssertTrue(before((7.5, nil, "A"), (7.5, nil, "B")))
        XCTAssertFalse(before((7.5, nil, "B"), (7.5, nil, "A")))
    }

    func testAnInvalidValueOrdersLikeNoValue() {
        XCTAssertFalse(PackageCveEpss.precedes(cvssA: 7.5, epssA: 5.0, idA: "A", cvssB: 7.5, epssB: 0.2, idB: "B"))
    }

    // MARK: feed decoding (Homebrew)

    private func homebrewMap(_ json: String) throws -> PackageCveScan.CveMap {
        try JSONDecoder().decode(PackageCveScan.CveMap.self, from: Data(json.utf8))
    }

    func testAnOldFeedWithoutEpssDecodesAsBefore() throws {
        let map = try homebrewMap(#"{"mapVersion":"2026-09-01","ecosystem":"Homebrew","entries":[{"cveId":"CVE-1","package":"curl","cvssScore":7.5,"ranges":[{"introduced":"1.0","fixed":"2.0"}],"summary":"s","confidence":"confirmed"}]}"#)
        XCTAssertNil(map.epssDate)
        XCTAssertNil(map.entries[0].epss)
        XCTAssertEqual(map.entries[0].confidence, "confirmed")
    }

    func testEpssAndItsDateAreReadWhenPresent() throws {
        let map = try homebrewMap(#"{"mapVersion":"2026-10-18","ecosystem":"Homebrew","epssDate":"2026-10-18","entries":[{"cveId":"CVE-1","package":"curl","cvssScore":7.5,"ranges":[],"summary":"s","confidence":"gray","epss":0.42}]}"#)
        XCTAssertEqual(map.epssDate, "2026-10-18")
        XCTAssertEqual(map.entries[0].epss, 0.42)
    }

    func testABadEpssDoesNotBreakTheFeed() throws {
        let map = try homebrewMap(#"{"mapVersion":"v","ecosystem":"Homebrew","epssDate":"yesterday","entries":[{"cveId":"CVE-1","package":"a","cvssScore":7.5,"ranges":[],"summary":"","confidence":"gray","epss":"high"},{"cveId":"CVE-2","package":"b","cvssScore":7.5,"ranges":[],"summary":"","confidence":"gray","epss":7.5}]}"#)
        XCTAssertEqual(map.entries.count, 2, "a malformed value costs the value, never the entry")
        XCTAssertNil(map.entries[0].epss)
        XCTAssertNil(map.entries[1].epss)
        XCTAssertNil(map.epssDate)
    }

    func testHomebrewFindingsCarryEpssAndAreOrdered() throws {
        let map = try homebrewMap(#"""
        {"mapVersion":"v","ecosystem":"Homebrew","epssDate":"2026-10-18","entries":[
         {"cveId":"CVE-LOW-EPSS","package":"curl","cvssScore":8.8,"ranges":[{"introduced":"1.0","fixed":"9.0"}],"summary":"","confidence":"confirmed","epss":0.01},
         {"cveId":"CVE-HIGH-EPSS","package":"curl","cvssScore":7.5,"ranges":[{"introduced":"1.0","fixed":"9.0"}],"summary":"","confidence":"confirmed","epss":0.9},
         {"cveId":"CVE-CRIT","package":"curl","cvssScore":9.8,"ranges":[{"introduced":"1.0","fixed":"9.0"}],"summary":"","confidence":"confirmed"},
         {"cveId":"CVE-NONE","package":"curl","cvssScore":7.9,"ranges":[{"introduced":"1.0","fixed":"9.0"}],"summary":"","confidence":"confirmed"}]}
        """#)
        let findings = PackageCveScan.scan(installed: [.init(name: "curl", version: "2.0")], map: map)
        XCTAssertEqual(findings.map(\.cveId), ["CVE-CRIT", "CVE-HIGH-EPSS", "CVE-LOW-EPSS", "CVE-NONE"])
        XCTAssertEqual(findings[1].epss, 0.9)
        XCTAssertEqual(findings[1].epssDate, "2026-10-18")
        XCTAssertNil(findings[0].epss)
        XCTAssertNil(findings[0].epssDate, "no value, no date")
    }

    // MARK: feed decoding and scan (language ecosystems)

    func testLanguageMapsDecodeWithAndWithoutEpss() throws {
        let old = try JSONDecoder().decode(PackageCveScanLanguages.CveMap.self, from: Data(#"{"mapVersion":"v","ecosystem":"npm","entries":[{"cveId":"CVE-1","package":"lodash","cvssScore":7.5,"ranges":[]}]}"#.utf8))
        XCTAssertNil(old.epssDate)
        XCTAssertNil(old.entries[0].epss)
        let new = try JSONDecoder().decode(PackageCveScanLanguages.CveMap.self, from: Data(#"{"mapVersion":"v","ecosystem":"npm","epssDate":"2026-10-18","entries":[{"cveId":"CVE-1","package":"lodash","cvssScore":7.5,"ranges":[],"epss":0.5}]}"#.utf8))
        XCTAssertEqual(new.epssDate, "2026-10-18")
        XCTAssertEqual(new.entries[0].epss, 0.5)
    }

    func testLanguageFindingsKeepProjectGroupsAndOrderByEpssInside() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("roamswitch-epss-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        for project in ["a", "b"] {
            let dir = tmp.appendingPathComponent(project)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try #"{"packages":{"":{},"node_modules/lodash":{"version":"4.17.20"},"node_modules/minimist":{"version":"1.2.0"}}}"#
                .write(to: dir.appendingPathComponent("package-lock.json"), atomically: true, encoding: .utf8)
        }
        let map = try JSONDecoder().decode(PackageCveScanLanguages.CveMap.self, from: Data(#"""
        {"mapVersion":"v","ecosystem":"npm","epssDate":"2026-10-18","entries":[
         {"cveId":"CVE-A","package":"lodash","cvssScore":8.1,"ranges":[{"introduced":"0","fixed":"4.17.21"}],"epss":0.02},
         {"cveId":"CVE-B","package":"minimist","cvssScore":7.5,"ranges":[{"introduced":"0","fixed":"1.2.6"}],"epss":0.8}]}
        """#.utf8))
        let findings = PackageCveScanLanguages.runScan(watchedFolders: [tmp.path], maps: ["npm": map])
        XCTAssertEqual(findings.count, 4)
        XCTAssertEqual(findings.map { ($0.lockfile as NSString).deletingLastPathComponent.hasSuffix("/a") }, [true, true, false, false],
                       "findings of one project stay together")
        XCTAssertEqual(findings.map(\.cveId), ["CVE-B", "CVE-A", "CVE-B", "CVE-A"], "inside a band, higher EPSS first")
        XCTAssertEqual(findings[0].epssDate, "2026-10-18")
    }

    func testTheAcceptanceSubjectOfAFindingIsItsPackageCveAndVersion() {
        let f = PackageCveScanLanguages.Finding(ecosystem: "PyPI", package: "requests", installedVersion: "2.0", cveId: "CVE-9",
                                                cvssScore: 7.5, fixedVersion: "2.1", summary: "", lockfile: "/p/requirements.txt")
        XCTAssertEqual(f.acceptanceSubject, VulnerabilityAcceptance.Subject(ecosystem: "PyPI", package: "requests", cveId: "CVE-9", version: "2.0"))
        let h = PackageCveScan.Finding(cveId: "CVE-1", package: "curl", installedVersion: "8", cvssScore: 7.5, fixedVersion: "9", summary: "", confidence: "confirmed")
        XCTAssertEqual(h.acceptanceSubject.ecosystem, "Homebrew")
    }
}
