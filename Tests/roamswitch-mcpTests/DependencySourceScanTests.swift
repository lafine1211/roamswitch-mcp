// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.13 (build 192). Do not edit here; see SYNC.md.

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

        let all = Scan.runScan(watchedFolders: [root.path], home: nil)
        // The two npm lockfiles also lack a release age gate; that kind has its own tests below.
        XCTAssertEqual(all.filter { $0.kind == .releaseAgeGateMissing }.count, 2)
        let findings = all.filter { $0.kind != .releaseAgeGateMissing }
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
        let without = Scan.runScan(watchedFolders: [root.path], home: nil).filter { $0.kind != .releaseAgeGateMissing }
        XCTAssertEqual(without.map(\.kind), [.npmScopeNotPinned])
        XCTAssertEqual(without.first?.scope, "@acme")
        try "@acme:registry=https://npm.acme.example/\n".write(to: home.appendingPathComponent(".npmrc"), atomically: true, encoding: .utf8)
        XCTAssertTrue(Scan.runScan(watchedFolders: [root.path], home: home.path).filter { $0.kind != .releaseAgeGateMissing }.isEmpty)
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

    // MARK: release age gate: values and files

    func testGateValueReadsOffAbsentAndOn() {
        for off in ["0", "0d", "0m", "00", "false", "False", "null", "~", "\"0\"", "0.0", "0w   # none"] {
            XCTAssertEqual(Scan.gateValue(off), .disabled, off)
        }
        for on in ["7", "10080", "\"1w\"", "7 days", "P7D", "2026-10-01T00:00:00Z", "${AGE}", "true", "604800"] {
            XCTAssertEqual(Scan.gateValue(on), .active, on)
        }
        XCTAssertEqual(Scan.gateValue(""), .absent)
        XCTAssertEqual(Scan.gateValue("   "), .absent)
    }

    func testNpmrcGateReadsTheKeysAndSkipsComments() {
        XCTAssertEqual(Scan.npmrcGate("min-release-age=3\n", keys: ["min-release-age", "before"]), .active)
        XCTAssertEqual(Scan.npmrcGate("min_release_age = 3\n", keys: ["min-release-age"]), .active, "_ and - are the same key")
        XCTAssertEqual(Scan.npmrcGate("before=2026-10-01\n", keys: ["min-release-age", "before"]), .active)
        XCTAssertEqual(Scan.npmrcGate("min-release-age=0\n", keys: ["min-release-age"]), .disabled)
        XCTAssertEqual(Scan.npmrcGate("# min-release-age=3\n; min-release-age=3\n", keys: ["min-release-age"]), .absent, "comment lines")
        XCTAssertEqual(Scan.npmrcGate("registry=https://registry.npmjs.org/\n", keys: ["min-release-age"]), .absent)
        XCTAssertEqual(Scan.npmrcGate("min-release-age=0\nmin-release-age=7\n", keys: ["min-release-age"]), .active, "the strongest line wins")
        XCTAssertEqual(Scan.npmrcGate("xmin-release-age=3\n", keys: ["min-release-age"]), .absent, "exact key only")
    }

    func testYamlGateReadsOnlyTheTopLevelKey() {
        XCTAssertEqual(Scan.yamlTopLevelGate("packages:\n  - apps/*\nminimumReleaseAge: 1440\n", key: "minimumReleaseAge"), .active)
        XCTAssertEqual(Scan.yamlTopLevelGate("minimumReleaseAge: 0\n", key: "minimumReleaseAge"), .disabled)
        XCTAssertEqual(Scan.yamlTopLevelGate("# minimumReleaseAge: 1440\n", key: "minimumReleaseAge"), .absent, "comment")
        XCTAssertEqual(Scan.yamlTopLevelGate("nested:\n  minimumReleaseAge: 1440\n", key: "minimumReleaseAge"), .absent, "indented belongs to another key")
        XCTAssertEqual(Scan.yamlTopLevelGate("npmMinimalAgeGate: \"1w\"\n", key: "npmMinimalAgeGate"), .active)
        XCTAssertEqual(Scan.yamlTopLevelGate("npmMinimalAgeGate: 0 # off\n", key: "npmMinimalAgeGate"), .disabled)
        XCTAssertEqual(Scan.yamlTopLevelGate("minimumReleaseAgeExclude:\n  - foo\n", key: "minimumReleaseAge"), .absent, "a longer key is another key")
    }

    func testTomlGateReadsTheTableAndTheDottedForm() {
        XCTAssertEqual(Scan.tomlGate("[install]\nminimumReleaseAge = 604800\n", table: "install", key: "minimumReleaseAge"), .active)
        XCTAssertEqual(Scan.tomlGate("[install]\nminimumReleaseAge = 0\n", table: "install", key: "minimumReleaseAge"), .disabled)
        XCTAssertEqual(Scan.tomlGate("install.minimumReleaseAge = 100\n", table: "install", key: "minimumReleaseAge"), .active)
        XCTAssertEqual(Scan.tomlGate("[run]\nminimumReleaseAge = 100\n", table: "install", key: "minimumReleaseAge"), .absent, "another table")
        XCTAssertEqual(Scan.tomlGate("# minimumReleaseAge = 100\n[install]\n", table: "install", key: "minimumReleaseAge"), .absent, "comment")
        XCTAssertEqual(Scan.tomlGate("exclude-newer = \"7 days\"\n", table: nil, key: "exclude-newer"), .active)
        XCTAssertEqual(Scan.tomlGate("exclude-newer = false\n", table: nil, key: "exclude-newer"), .disabled)
        XCTAssertEqual(Scan.tomlGate("[pip]\nexclude-newer = \"7 days\"\n", table: nil, key: "exclude-newer"), .absent, "uv.toml top level only")
        XCTAssertEqual(Scan.tomlGate("[project]\nname = \"x\"\n[tool.uv]\nexclude-newer = \"P7D\"\n", table: "tool.uv", key: "exclude-newer"), .active)
        XCTAssertEqual(Scan.tomlGate("[project]\nexclude-newer = \"P7D\"\n", table: "tool.uv", key: "exclude-newer"), .absent)
        XCTAssertEqual(Scan.tomlGate("[[tool.uv.index]]\nexclude-newer = \"P7D\"\n", table: "tool.uv", key: "exclude-newer"), .absent, "an array table is another table")
    }

    func testPnpmMajorAndTheLockfileToManagerMap() {
        XCTAssertEqual(Scan.pnpmMajor(packageJSON: #"{"packageManager":"pnpm@11.0.2+sha512.abc"}"#), 11)
        XCTAssertEqual(Scan.pnpmMajor(packageJSON: #"{"packageManager":"pnpm@10.16.0"}"#), 10)
        XCTAssertNil(Scan.pnpmMajor(packageJSON: #"{"packageManager":"yarn@4.1.0"}"#))
        XCTAssertNil(Scan.pnpmMajor(packageJSON: "{}"))
        XCTAssertNil(Scan.pnpmMajor(packageJSON: "not json"))
        XCTAssertEqual(Scan.gateManager(lockfile: "package-lock.json", lockfileText: nil), "npm")
        XCTAssertEqual(Scan.gateManager(lockfile: "npm-shrinkwrap.json", lockfileText: nil), "npm")
        XCTAssertEqual(Scan.gateManager(lockfile: "pnpm-lock.yaml", lockfileText: nil), "pnpm")
        XCTAssertEqual(Scan.gateManager(lockfile: "bun.lock", lockfileText: nil), "bun")
        XCTAssertEqual(Scan.gateManager(lockfile: "bun.lockb", lockfileText: nil), "bun")
        XCTAssertEqual(Scan.gateManager(lockfile: "uv.lock", lockfileText: nil), "uv")
        XCTAssertEqual(Scan.gateManager(lockfile: "yarn.lock", lockfileText: "__metadata:\n  version: 8\n"), "yarn")
        XCTAssertNil(Scan.gateManager(lockfile: "yarn.lock", lockfileText: "# yarn lockfile v1\n"), "yarn 1 has no such setting")
        XCTAssertNil(Scan.gateManager(lockfile: "Cargo.lock", lockfileText: nil))
    }

    // MARK: release age gate: walking folders

    private func write(_ text: String, _ root: URL, _ path: String) throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func gateFindings(_ root: URL, home: String? = nil) -> [Scan.Finding] {
        Scan.runScan(watchedFolders: [root.path], home: home).filter { $0.kind == .releaseAgeGateMissing }
    }

    func testEveryManagerIsReportedWithoutASettingOnePerLockfile() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("{}", root, "npm/package-lock.json")
        try write("lockfileVersion: '9.0'\n", root, "pnpm/pnpm-lock.yaml")
        try write("__metadata:\n  version: 8\n", root, "yarn/yarn.lock")
        try write("{}", root, "bun/bun.lock")
        try write("version = 1\n", root, "uv/uv.lock")
        try write("# yarn lockfile v1\n", root, "yarn1/yarn.lock")
        let findings = gateFindings(root)
        XCTAssertEqual(findings.compactMap(\.manager).sorted(), ["bun", "npm", "pnpm", "uv", "yarn"], "yarn 1 is not reported")
        for f in findings {
            XCTAssertEqual(f.host, "")
            XCTAssertNil(f.line)
            XCTAssertFalse(f.explicitlyDisabled)
            XCTAssertTrue(f.file.hasSuffix(f.fileName))
        }
        XCTAssertEqual(Set(findings.map(\.id)).count, 5)
    }

    func testEachManagerIsSatisfiedByItsOwnSetting() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("{}", root, "npm/package-lock.json");           try write("min-release-age=3\n", root, "npm/.npmrc")
        try write("{}", root, "npmbefore/package-lock.json");     try write("before=2026-10-01\n", root, "npmbefore/.npmrc")
        try write("x: 1\n", root, "pnpm/pnpm-lock.yaml");         try write("minimumReleaseAge: 1440\n", root, "pnpm/pnpm-workspace.yaml")
        try write("x: 1\n", root, "pnpmrc/pnpm-lock.yaml");       try write("minimum-release-age=10080\n", root, "pnpmrc/.npmrc")
        try write("__metadata:\n", root, "yarn/yarn.lock");        try write("npmMinimalAgeGate: \"3d\"\n", root, "yarn/.yarnrc.yml")
        try write("", root, "bun/bun.lockb");                      try write("[install]\nminimumReleaseAge = 259200\n", root, "bun/bunfig.toml")
        try write("", root, "uv/uv.lock");                         try write("exclude-newer = \"3 days\"\n", root, "uv/uv.toml")
        try write("", root, "uvpy/uv.lock");                       try write("[tool.uv]\nexclude-newer = \"P3D\"\n", root, "uvpy/pyproject.toml")
        XCTAssertEqual(gateFindings(root).map(\.file), [], "every project sets the wait")
    }

    func testAWaitOfZeroIsReportedAsExplicitlyDisabled() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("{}", root, "package-lock.json"); try write("min-release-age=0\n", root, ".npmrc")
        let findings = gateFindings(root)
        XCTAssertEqual(findings.count, 1)
        XCTAssertTrue(findings[0].explicitlyDisabled)
        XCTAssertEqual(findings[0].manager, "npm")
    }

    func testACommentedSettingDoesNotCount() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("{}", root, "package-lock.json"); try write("# min-release-age=7\n", root, ".npmrc")
        try write("", root, "bun/bun.lock");        try write("# [install]\n# minimumReleaseAge = 604800\n", root, "bun/bunfig.toml")
        XCTAssertEqual(gateFindings(root).compactMap(\.manager).sorted(), ["bun", "npm"])
    }

    func testAFileAboveTheLockfileAndTheHomeFileCountButAnotherManagersDoesNot() throws {
        let root = try makeProject(), home = try makeProject()
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: home) }
        try write("{}", root, "apps/web/package-lock.json")
        XCTAssertEqual(gateFindings(root, home: home.path).count, 1)
        // The folder above the lockfile, inside the watched root.
        try write("min-release-age=5\n", root, "apps/.npmrc")
        XCTAssertTrue(gateFindings(root, home: home.path).isEmpty)
        try FileManager.default.removeItem(at: root.appendingPathComponent("apps/.npmrc"))
        // The user's file.
        try write("min-release-age=5\n", home, ".npmrc")
        XCTAssertTrue(gateFindings(root, home: home.path).isEmpty)
        XCTAssertEqual(gateFindings(root, home: nil).count, 1, "without the home file it is missing again")
        // pnpm's workspace setting does not satisfy npm.
        try FileManager.default.removeItem(at: home.appendingPathComponent(".npmrc"))
        try write("minimumReleaseAge: 1440\n", root, "apps/web/pnpm-workspace.yaml")
        XCTAssertEqual(gateFindings(root, home: home.path).count, 1)
    }

    func testHomeFilesOfEachManagerCount() throws {
        let root = try makeProject(), home = try makeProject()
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: home) }
        try write("x: 1\n", root, "pnpm/pnpm-lock.yaml")
        try write("__metadata:\n", root, "yarn/yarn.lock")
        try write("", root, "bun/bun.lock")
        try write("", root, "uv/uv.lock")
        XCTAssertEqual(gateFindings(root, home: home.path).count, 4)
        try write("minimumReleaseAge: 1440\n", home, "Library/Preferences/pnpm/config.yaml")
        try write("npmMinimalAgeGate: 3d\n", home, ".yarnrc.yml")
        try write("[install]\nminimumReleaseAge = 1\n", home, ".bunfig.toml")
        try write("exclude-newer = \"3 days\"\n", home, ".config/uv/uv.toml")
        XCTAssertTrue(gateFindings(root, home: home.path).isEmpty)
    }

    func testPnpm11WaitsByDefaultUnlessTheWaitIsSetToZero() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("x: 1\n", root, "new/pnpm-lock.yaml");  try write(#"{"packageManager":"pnpm@11.1.0"}"#, root, "new/package.json")
        try write("x: 1\n", root, "old/pnpm-lock.yaml");  try write(#"{"packageManager":"pnpm@10.16.0"}"#, root, "old/package.json")
        try write("x: 1\n", root, "off/pnpm-lock.yaml");  try write(#"{"packageManager":"pnpm@11.0.0"}"#, root, "off/package.json")
        try write("minimumReleaseAge: 0\n", root, "off/pnpm-workspace.yaml")
        let findings = gateFindings(root)
        XCTAssertEqual(findings.map { ($0.file as NSString).deletingLastPathComponent.components(separatedBy: "/").last ?? "" }.sorted(), ["off", "old"])
        XCTAssertEqual(findings.first { $0.file.contains("/off/") }?.explicitlyDisabled, true)
        XCTAssertEqual(findings.first { $0.file.contains("/old/") }?.explicitlyDisabled, false)
    }

    func testLockfilesInDependencyFoldersAreNotWalkedForTheGateEither() throws {
        let root = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("{}", root, "node_modules/pkg/package-lock.json")
        try write("", root, ".venv/uv.lock")
        XCTAssertTrue(gateFindings(root).isEmpty)
    }

    func testTheSettingNamesAreSpelledForEachManager() {
        XCTAssertEqual(Scan.gateSettingName(manager: "npm"), "min-release-age (.npmrc)")
        for m in ["npm", "pnpm", "yarn", "bun", "uv"] { XCTAssertNotEqual(Scan.gateSettingName(manager: m), m) }
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
