// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.1 (build 180). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Static dependency-confusion check: pip `extra-index-url` and npm scopes resolved from a registry no `.npmrc`
/// pins. It reads files only; it never asks a registry anything.
final class DependencySourceScanTests: XCTestCase {

    private typealias Scan = DependencySourceScan

    // MARK: URL handling

    func testHostDropsCredentialsAndRejectsNonHttp() {
        XCTAssertEqual(Scan.host(ofURL: "https://user:s3cret@pypi.example.com/simple"), "pypi.example.com")
        XCTAssertEqual(Scan.host(ofURL: "HTTPS://Pypi.Example.COM:8443/simple/"), "pypi.example.com")
        XCTAssertEqual(Scan.host(ofURL: "\"https://x.example/simple\","), "x.example")
        for bad in ["", "/srv/wheels", "file:///srv/wheels", "git+ssh://git@github.com/a/b", "ftp://x.example", "https://"] {
            XCTAssertNil(Scan.host(ofURL: bad), bad)
        }
    }

    // MARK: pip

    func testRequirementsExtraIndexUrl() {
        let text = """
        # --extra-index-url https://commented.example/simple
        requests==2.31.0
        --index-url https://primary.example/simple
        --extra-index-url https://private.example/simple   # internal
        --extra-index-url=https://token:abc@other.example/simple
        --extra-index-urls https://typo.example
        """
        let hits = Scan.pipExtraIndexInRequirements(text)
        XCTAssertEqual(hits.map(\.line), [4, 5])
        XCTAssertEqual(hits.map(\.host), ["private.example", "other.example"])
        XCTAssertFalse(hits.map(\.host).contains("primary.example"), "--index-url replaces PyPI, so it is not a finding")
    }

    func testPipConfExtraIndexUrlWithContinuationLines() {
        let text = """
        [global]
        index-url = https://primary.example/simple
        extra-index-url = https://one.example/simple
            https://two.example/simple
            https://three.example/simple
        timeout = 60
        ; extra-index-url = https://commented.example
        [install]
        extra_index_url=https://four.example/simple
        """
        let hits = Scan.pipExtraIndexInPipConf(text)
        XCTAssertEqual(hits.map(\.host), ["one.example", "two.example", "three.example", "four.example"])
        XCTAssertEqual(hits.map(\.line), [3, 4, 5, 9])
    }

    func testTomlExtraIndexUrlAsStringAndArray() {
        let text = """
        [tool.uv.pip]
        extra-index-url = "https://one.example/simple"
        [tool.other]
        # extra-index-url = "https://commented.example/simple"
        extra-index-url = [
          "https://two.example/simple",
          "https://three.example/simple",
        ]
        extra-index-url = ["https://four.example/simple", "https://five.example/simple"]
        """
        let hits = Scan.pipExtraIndexInToml(text)
        XCTAssertEqual(hits.map(\.host), ["one.example", "two.example", "three.example", "four.example", "five.example"])
        XCTAssertEqual(hits.map(\.line), [2, 5, 5, 9, 9])
    }

    // MARK: npm lockfiles

    func testPackageLockV3AndV1() {
        let v3 = #"""
        {"lockfileVersion":3,"packages":{"":{"name":"app"},
         "node_modules/lodash":{"version":"4.17.21","resolved":"https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"},
         "node_modules/@acme/core":{"version":"1.0.0","resolved":"https://npm.acme.example/@acme/core/-/core-1.0.0.tgz"},
         "node_modules/a/node_modules/@acme/util":{"version":"2.0.0","resolved":"https://npm.acme.example/@acme/util/-/util-2.0.0.tgz"},
         "node_modules/local":{"resolved":"../local","link":true}}}
        """#
        let entries = Scan.resolvedEntries(packageLock: v3)
        XCTAssertEqual(Set(entries.map(\.name)), ["lodash", "@acme/core", "@acme/util"])
        let v1 = #"{"lockfileVersion":1,"dependencies":{"@acme/core":{"version":"1.0.0","resolved":"https://npm.acme.example/c.tgz","dependencies":{"@acme/util":{"version":"2.0.0","resolved":"https://npm.acme.example/u.tgz"}}}}}"#
        XCTAssertEqual(Set(Scan.resolvedEntries(packageLock: v1).map(\.name)), ["@acme/core", "@acme/util"])
        XCTAssertTrue(Scan.resolvedEntries(packageLock: "not json").isEmpty)
    }

    func testYarnLockV1AndBerry() {
        let v1 = """
        # yarn lockfile v1


        "@acme/core@^1.0.0", "@acme/core@^1.1.0":
          version "1.1.0"
          resolved "https://npm.acme.example/@acme/core/-/core-1.1.0.tgz#abc123"
          integrity sha512-x

        left-pad@^1.3.0:
          version "1.3.0"
          resolved "https://registry.yarnpkg.com/left-pad/-/left-pad-1.3.0.tgz#def"
        """
        let entries = Scan.resolvedEntries(yarnLock: v1)
        XCTAssertEqual(entries.map(\.name), ["@acme/core", "left-pad"])
        XCTAssertEqual(Scan.host(ofURL: entries[0].url), "npm.acme.example")
        XCTAssertTrue(Scan.resolvedEntries(yarnLock: "__metadata:\n  version: 6\n\n\"@acme/core@npm:^1.0.0\":\n  resolution: \"@acme/core@npm:1.0.0\"\n").isEmpty,
                      "Berry does not record the source, so nothing is claimed")
    }

    func testPnpmLockTarballs() {
        let text = """
        lockfileVersion: '9.0'

        packages:

          '@acme/core@1.0.0':
            resolution: {integrity: sha512-aaa, tarball: https://npm.acme.example/@acme/core/-/core-1.0.0.tgz}

          lodash@4.17.21:
            resolution: {integrity: sha512-bbb}

          /@acme/util@2.0.0(react@18.0.0):
            resolution: {tarball: 'https://npm.acme.example/@acme/util/-/util-2.0.0.tgz'}
        """
        let entries = Scan.resolvedEntries(pnpmLock: text)
        XCTAssertEqual(entries.map(\.name), ["@acme/core", "@acme/util"])
        XCTAssertEqual(entries.compactMap { Scan.host(ofURL: $0.url) }, ["npm.acme.example", "npm.acme.example"])
    }

    func testNpmrcScopeRegistries() {
        let text = """
        # @commented:registry=https://commented.example/
        registry=https://registry.npmjs.org/
        @acme:registry=https://npm.acme.example/
        @Other:registry="https://Other.Example/npm"
        @env:registry=${INTERNAL_REGISTRY}
        //npm.acme.example/:_authToken=${TOKEN}
        """
        XCTAssertEqual(Scan.npmrcScopeRegistries(text), ["@acme": "npm.acme.example", "@other": "other.example", "@env": "*"])
    }

    func testOnlyAnUnpinnedScopeFromANonDefaultHostIsAFinding() {
        let entries: [Scan.ResolvedEntry] = [
            ("@acme/core", "https://npm.acme.example/c.tgz"),
            ("@acme/util", "https://npm.acme.example/u.tgz"),
            ("@acme/util", "https://npm.acme.example/u2.tgz"),          // same package twice counts once
            ("@types/node", "https://registry.npmjs.org/@types/node/-/n.tgz"),   // default registry
            ("@pinned/x", "https://npm.pinned.example/x.tgz"),
            ("@wrong/y", "https://npm.wrong.example/y.tgz"),
            ("@env/z", "https://anything.example/z.tgz"),
            ("unscoped", "https://npm.acme.example/unscoped.tgz"),      // cannot be pinned by .npmrc: not evaluated
            ("@git/dep", "git+ssh://git@github.com/a/b.git"),
        ]
        let pinned: [String: Set<String>] = ["@pinned": ["npm.pinned.example"], "@wrong": ["elsewhere.example"], "@env": ["*"]]
        let findings = Scan.npmFindings(entries: entries, pinned: pinned, file: "/p/package-lock.json")
        XCTAssertEqual(findings.map(\.scope), ["@acme", "@wrong"])
        XCTAssertEqual(findings[0].packageCount, 2)
        XCTAssertEqual(findings[0].host, "npm.acme.example")
        XCTAssertEqual(findings[1].host, "npm.wrong.example", "pinned to another host is still not pinned to this one")
        XCTAssertTrue(findings.allSatisfy { $0.kind == .npmScopeNotPinned && $0.line == nil })
    }

    // MARK: walking real folders

    private func makeProject() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("roamswitch-depsrc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return URL(fileURLWithPath: SafeScanFS.canonicalPath(root.path) ?? root.path)
    }

    func testScanFindsBothKindsAndHonoursNpmrcAboveTheLockfile() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        let fm = FileManager.default
        let api = root.appendingPathComponent("services/api"), web = root.appendingPathComponent("services/web")
        try fm.createDirectory(at: api, withIntermediateDirectories: true)
        try fm.createDirectory(at: web, withIntermediateDirectories: true)
        let lock = #"{"lockfileVersion":3,"packages":{"node_modules/@acme/core":{"resolved":"https://npm.acme.example/c.tgz"}}}"#
        try lock.write(to: api.appendingPathComponent("package-lock.json"), atomically: true, encoding: .utf8)
        try lock.write(to: web.appendingPathComponent("package-lock.json"), atomically: true, encoding: .utf8)
        // One .npmrc above both lockfiles pins @acme to the host the lockfiles use.
        try "@acme:registry=https://npm.acme.example/\n".write(to: root.appendingPathComponent("services/.npmrc"), atomically: true, encoding: .utf8)
        // web has its own .npmrc that does not mention @acme; the one above it still applies (pins accumulate).
        try "registry=https://registry.npmjs.org/\n".write(to: web.appendingPathComponent(".npmrc"), atomically: true, encoding: .utf8)
        try "requests\n--extra-index-url https://private.example/simple\n".write(to: api.appendingPathComponent("requirements-dev.txt"), atomically: true, encoding: .utf8)

        let findings = Scan.runScan(watchedFolders: [root.path], home: nil)
        XCTAssertEqual(findings.map(\.kind), [.pipExtraIndexUrl])
        XCTAssertEqual(findings.first?.line, 2)
        XCTAssertEqual(findings.first?.host, "private.example")
        XCTAssertEqual(findings.first?.fileName, "requirements-dev.txt")
    }

    func testAMissingPinIsReportedAndAHomeNpmrcCanSupplyIt() throws {
        let root = try makeProject(), home = try makeProject()
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: home) }
        try #"{"lockfileVersion":3,"packages":{"node_modules/@acme/core":{"resolved":"https://npm.acme.example/c.tgz"}}}"#
            .write(to: root.appendingPathComponent("package-lock.json"), atomically: true, encoding: .utf8)
        let without = Scan.runScan(watchedFolders: [root.path], home: nil)
        XCTAssertEqual(without.map(\.kind), [.npmScopeNotPinned])
        XCTAssertEqual(without.first?.scope, "@acme")
        try "@acme:registry=https://npm.acme.example/\n".write(to: home.appendingPathComponent(".npmrc"), atomically: true, encoding: .utf8)
        XCTAssertTrue(Scan.runScan(watchedFolders: [root.path], home: home.path).isEmpty)
    }

    func testPyPIItselfAsAnExtraIndexIsNotAFinding() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try "--extra-index-url https://pypi.org/simple\n".write(to: root.appendingPathComponent("requirements.txt"), atomically: true, encoding: .utf8)
        XCTAssertTrue(Scan.runScan(watchedFolders: [root.path], home: nil).isEmpty)
    }

    func testNodeModulesAndOtherDependencyFoldersAreNotWalked() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        for dir in ["node_modules/pkg", ".venv/lib", "vendor/x"] {
            let url = root.appendingPathComponent(dir)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try "--extra-index-url https://planted.example/simple\n".write(to: url.appendingPathComponent("requirements.txt"), atomically: true, encoding: .utf8)
        }
        XCTAssertTrue(Scan.runScan(watchedFolders: [root.path], home: nil).isEmpty)
    }

    func testAFindingNeverCarriesACredential() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try "--extra-index-url https://deploy:hunter2@private.example/simple\n".write(to: root.appendingPathComponent("requirements.txt"), atomically: true, encoding: .utf8)
        let findings = Scan.runScan(watchedFolders: [root.path], home: nil)
        XCTAssertEqual(findings.count, 1)
        let description = String(describing: findings[0])
        XCTAssertFalse(description.contains("hunter2") || description.contains("deploy:"))
    }

    // MARK: MCP

    func testToolIsListedWithTheWatchedFoldersArgumentAndIsProOnly() throws {
        let tools = MCPServer.toolDefinitionsForTesting()
        let tool = try XCTUnwrap(tools.first { $0["name"] as? String == "run_dependency_source_scan" })
        let description = try XCTUnwrap(tool["description"] as? String)
        XCTAssertTrue(description.contains("NO NETWORK REQUESTS"))
        XCTAssertTrue(description.contains("never asks a registry"))
        XCTAssertTrue(description.contains("Pro only"))
        let schema = try XCTUnwrap(tool["inputSchema"] as? [String: Any])
        XCTAssertNotNil((schema["properties"] as? [String: Any])?["watchedFolders"])
    }

    func testEveryKnowledgeBaseLanguageDocumentsTheToolAndTheNewCount() {
        for code in RoamSwitchKnowledgeBase.supportedLanguageCodes {
            let entries = RoamSwitchKnowledgeBase.localizedEntries(for: code)
            XCTAssertTrue(entries.contains { $0.id == "feat_dependency_source_scan" && $0.details.contains("run_dependency_source_scan") }, code)
            XCTAssertFalse(entries.contains { $0.details.contains("34") && $0.details.contains("get_detection_coverage") && $0.details.contains("get_security_report") },
                           "\(code): the tool count in the main-tools sentence was not bumped")
        }
    }
}
