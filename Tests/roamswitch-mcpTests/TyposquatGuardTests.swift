// Mirrored from RoamSwitchTests/ — RoamSwitch 1.9.37 (build 94). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class TyposquatGuardTests: XCTestCase {

    private let popular = ["react", "lodash", "express", "preact", "is-array"]

    func testExactMatchIsNotFlagged() {
        XCTAssertNil(TyposquatGuard.checkName("react", against: popular))
        XCTAssertNil(TyposquatGuard.checkName("lodash", against: popular))
    }

    func testDetectsCommonTypos() {
        let reactt = TyposquatGuard.checkName("reactt", against: popular)
        XCTAssertEqual(reactt?.suspectedTarget, "react")
        XCTAssertEqual(reactt?.distance, 1)

        let loadash = TyposquatGuard.checkName("loadash", against: popular)
        XCTAssertEqual(loadash?.suspectedTarget, "lodash")
        XCTAssertEqual(loadash?.distance, 1)

        let expres = TyposquatGuard.checkName("expres", against: popular)
        XCTAssertEqual(expres?.suspectedTarget, "express")
        XCTAssertEqual(expres?.distance, 1)
    }

    func testAllowlistSuppressesKnownLookalikes() {
        XCTAssertNil(TyposquatGuard.checkName("preact", against: popular))
        XCTAssertNil(TyposquatGuard.checkName("is-array", against: popular))
    }

    func testUnrelatedNameIsNotFlagged() {
        XCTAssertNil(TyposquatGuard.checkName("some-totally-unrelated-package-name", against: popular))
    }

    func testScopedPackageComparesByBaseName() {
        let finding = TyposquatGuard.checkName("@myorg/reactt", against: popular)
        XCTAssertEqual(finding?.dependencyName, "@myorg/reactt")
        XCTAssertEqual(finding?.suspectedTarget, "react")
    }

    func testScanPackageJSONFindsTyposAndIgnoresPeerDependencies() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let packageJSON = """
        {
            "dependencies": { "reactt": "^18.0.0", "express": "^4.0.0" },
            "devDependencies": { "loadash": "^4.0.0" },
            "peerDependencies": { "expres": "^4.0.0" }
        }
        """
        try packageJSON.write(
            to: tmpDir.appendingPathComponent("package.json"),
            atomically: true,
            encoding: .utf8
        )

        let findings = TyposquatGuard.scanPackageJSON(tmpDir, against: popular)
        let names = Set(findings.map(\.dependencyName))
        XCTAssertTrue(names.contains("reactt"))
        XCTAssertTrue(names.contains("loadash"))
        XCTAssertFalse(names.contains("express")) // exact match, not a typo
        XCTAssertFalse(names.contains("expres")) // peerDependencies is out of scope
    }

    func testScanWatchedFolderRecursesButSkipsNodeModules() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let nested = root.appendingPathComponent("packages/app", isDirectory: true)
        let nodeModules = root.appendingPathComponent("node_modules/some-dep", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let typoManifest = """
        { "dependencies": { "reactt": "^18.0.0" } }
        """
        try typoManifest.write(
            to: nested.appendingPathComponent("package.json"),
            atomically: true,
            encoding: .utf8
        )
        // A typo inside node_modules must never be reported — it's an
        // already-installed transitive dependency, not something a human
        // just typed into a manifest.
        try typoManifest.write(
            to: nodeModules.appendingPathComponent("package.json"),
            atomically: true,
            encoding: .utf8
        )

        let findings = TyposquatGuard.scanWatchedFolder(root, maxDepth: 6, against: popular)
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.dependencyName, "reactt")
    }

    func testPopularPackageNamesTwoTierLoadingPrefersNewerUpdatedList() throws {
        let updatedURL = TyposquatGuard.updatedListURL
        let originalData = try? Data(contentsOf: updatedURL)
        try? FileManager.default.createDirectory(
            at: updatedURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        defer {
            if let originalData {
                try? originalData.write(to: updatedURL)
            } else {
                try? FileManager.default.removeItem(at: updatedURL)
            }
        }

        let newerOverride = """
        {"mapVersion": "2099-01-01", "packages": ["only-in-override"]}
        """
        try newerOverride.write(to: updatedURL, atomically: true, encoding: .utf8)

        let names = TyposquatGuard.popularPackageNames()
        XCTAssertEqual(names, ["only-in-override"])
    }

    func testPopularPackageNamesIgnoresOlderUpdatedList() throws {
        let updatedURL = TyposquatGuard.updatedListURL
        let originalData = try? Data(contentsOf: updatedURL)
        try? FileManager.default.createDirectory(
            at: updatedURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        defer {
            if let originalData {
                try? originalData.write(to: updatedURL)
            } else {
                try? FileManager.default.removeItem(at: updatedURL)
            }
        }

        let olderOverride = """
        {"mapVersion": "2000-01-01", "packages": ["only-in-override"]}
        """
        try olderOverride.write(to: updatedURL, atomically: true, encoding: .utf8)

        let names = TyposquatGuard.popularPackageNames()
        XCTAssertFalse(names.contains("only-in-override"))
        XCTAssertTrue(names.contains("react"))
    }
}
