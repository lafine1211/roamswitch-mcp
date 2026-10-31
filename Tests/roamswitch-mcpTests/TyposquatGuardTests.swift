// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.17 (build 196). Do not edit here; see SYNC.md.

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

    func testAJsTailDoesNotHideTheRealName() {
        let list = ["nodemon", "react-router-dom", "zustand", "discord.js", "ethers", "chart.js", "core-js", "postcss"]
        for (squat, target) in [
            ("nodemonjs", "nodemon"), ("react-router-dom.js", "react-router-dom"), ("zustand.js", "zustand"),
            ("etherdjs", "ethers"), ("ethesjs", "ethers"), ("ethetsjs", "ethers"),
            ("dizcordjs", "discord.js"), ("dezcord.js", "discord.js"),
        ] {
            XCTAssertEqual(TyposquatGuard.checkName(squat, against: list)?.suspectedTarget, target, squat)
        }
        // `-js` is a normal way to name a real package, and a real `chart` or `core` is not a look-alike of `chart.js` or `core-js`.
        XCTAssertNil(TyposquatGuard.checkName("postcss-js", against: list))
        XCTAssertNil(TyposquatGuard.checkName("chart", against: list))
        XCTAssertNil(TyposquatGuard.checkName("core", against: list))
        XCTAssertNil(TyposquatGuard.checkName("deezcord.js", against: list))
    }

    func testAScopedNameDoesNotGetTheJsTailSecondChance() {
        let list = ["web3", "discord.js", "ethers"]
        // The real Solana client lives in its owner's scope: not a copy of `web3`.
        XCTAssertNil(TyposquatGuard.checkName("@solana/web3.js", against: list))
        XCTAssertNil(TyposquatGuard.checkName("@scope/discord.js", against: list))
        // The same names unscoped are still caught.
        XCTAssertNotNil(TyposquatGuard.checkName("web3.js", against: list))
        XCTAssertNotNil(TyposquatGuard.checkName("dizcordjs", against: list))
    }

    /// A hand-added name matches at two edits (8+ letters), a name taken from a ranking at one edit only; the `js` tail
    /// second chance follows the same limit; a list of the old shape (no ranked part) reads every name as hand-added.
    func testARankedNameMatchesAtOneEditAHandAddedNameAtTwo() {
        let hand = ["react-router-dom", "discord.js", "zustand"]
        let ranked = ["react-query-devtools", "vitest", "web3"]
        let index = TyposquatGuard.PopularIndex(hand, ranked: ranked)
        XCTAssertEqual(TyposquatGuard.checkName("react-routr-do", against: index)?.distance, 2)
        XCTAssertEqual(TyposquatGuard.checkName("react-query-devtool", against: index)?.suspectedTarget, "react-query-devtools")
        XCTAssertNil(TyposquatGuard.checkName("react-quey-devtool", against: index))
        XCTAssertNotNil(TyposquatGuard.checkName("react-quey-devtool", against: ["react-query-devtools"]))
        // the js tail: one edit from the stem of a ranked name, or two from a hand-added one
        XCTAssertEqual(TyposquatGuard.checkName("dizcrdjs", against: index)?.suspectedTarget, "discord.js")
        XCTAssertEqual(TyposquatGuard.checkName("web33.js", against: index)?.suspectedTarget, "web3")
        XCTAssertNotNil(TyposquatGuard.checkName("dizcord.js", against: TyposquatGuard.PopularIndex([], ranked: ["discord.js"])))
        XCTAssertNil(TyposquatGuard.checkName("dizcrdjs", against: TyposquatGuard.PopularIndex([], ranked: ["discord.js"])))
        XCTAssertNotNil(TyposquatGuard.checkName("dizcrdjs", against: ["discord.js"]))
        // scoped names get no second chance; the names themselves are never look-alikes
        XCTAssertNil(TyposquatGuard.checkName("@solana/web3.js", against: index))
        XCTAssertNil(TyposquatGuard.checkName("vitest", against: index))
        XCTAssertNil(TyposquatGuard.checkName("react-router-dom", against: index))
    }

    /// A ranked name matches a swap of two neighbouring letters; typing-like edits only with install-time code.
    func testASwapMatchesARankedNameAndTypingEditsNeedInstallCode() {
        let index = TyposquatGuard.PopularIndex(["react-router-dom"], ranked: ["eslint-plugin-promise", "gatsby-source-filesystem", "vitest", "lodash.isobject"])
        func check(_ name: String, install: Bool) -> (String, Int)? {
            TyposquatGuard.checkName(name, against: index, hasInstallCode: { install }).map { ($0.suspectedTarget, $0.distance) }
        }
        XCTAssertEqual(check("eslint-plguin-promise", install: false)?.0, "eslint-plugin-promise")
        XCTAssertEqual(check("eslint-plguin-promise", install: false)?.1, 2)
        XCTAssertEqual(check("vitset", install: false)?.0, "vitest")
        for (name, target) in [("eslint-plugn-promse", "eslint-plugin-promise"), ("gatsbysourc-filesystem", "gatsby-source-filesystem")] {
            XCTAssertNil(check(name, install: false), name)
            XCTAssertEqual(check(name, install: true)?.0, target, name)
        }
        XCTAssertNil(check("lodash.zipobject", install: true))
        XCTAssertNil(check("lodash.isnumber", install: true))
        XCTAssertNil(check("@scope/vitestjs", install: true))
        XCTAssertTrue(TyposquatGuard.isSwap("ab", "ba"))
        XCTAssertFalse(TyposquatGuard.isSwap("abc", "cba"))
        XCTAssertTrue(TyposquatGuard.typingLikeWithinTwo("plugn", "plugin"))
        XCTAssertFalse(TyposquatGuard.typingLikeWithinTwo("zipobject", "isobject"))
        // the install-code question is asked only when the answer matters, and at most once
        var asked = 0
        let counting: () -> Bool = { asked += 1; return true }
        _ = TyposquatGuard.checkName("some-other-package", against: index, hasInstallCode: counting)
        _ = TyposquatGuard.checkName("eslint-plugin-promis", against: index, hasInstallCode: counting)
        _ = TyposquatGuard.checkName("eslint-plguin-promise", against: index, hasInstallCode: counting)
        XCTAssertEqual(asked, 0)
        _ = TyposquatGuard.checkName("eslint-plugn-promse", against: index, hasInstallCode: counting)
        XCTAssertEqual(asked, 1)
    }

    /// A scan asks `node_modules` for install-time code only for a ranked name two typing edits away.
    func testAScanAsksNodeModulesForInstallTimeCode() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let project = root.appendingPathComponent("app", isDirectory: true)
        try fm.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        try Data(#"{"dependencies":{"eslint-plugn-promse":"1.0.0","vite-plugn-inspct":"1.0.0","vite-plgin-inspct":"1.0.0"}}"#.utf8).write(to: project.appendingPathComponent("package.json"))
        let index = TyposquatGuard.PopularIndex(["react"], ranked: ["eslint-plugin-promise", "vite-plugin-inspect"])
        func found() -> [String] {
            TyposquatGuard.scanWatchedFolder(root, maxDepth: 3, against: index).map(\.dependencyName).sorted()
        }
        func install(_ dir: URL, _ name: String, _ manifest: String, gyp: Bool = false) throws {
            let d = dir.appendingPathComponent("node_modules/\(name)", isDirectory: true)
            try fm.createDirectory(at: d, withIntermediateDirectories: true)
            try Data(manifest.utf8).write(to: d.appendingPathComponent("package.json"))
            if gyp { try Data("{}".utf8).write(to: d.appendingPathComponent("binding.gyp")) }
        }
        XCTAssertEqual(found(), [])  // declared only
        try install(project, "eslint-plugn-promse", #"{"name":"x","scripts":{"postinstall":"node install.js"}}"#)
        try install(project, "vite-plugn-inspct", #"{"name":"x","scripts":{"test":"jest","prepare":"tsc"}}"#)
        XCTAssertEqual(found(), ["eslint-plugn-promse"])
        try install(root, "vite-plgin-inspct", #"{"name":"x"}"#, gyp: true)  // hoisted, binding.gyp
        XCTAssertEqual(found(), ["eslint-plugn-promse", "vite-plgin-inspct"])
        // a node_modules above the folder the walk started from is not read
        XCTAssertEqual(TyposquatGuard.scanWatchedFolder(project, maxDepth: 3, against: index).map(\.dependencyName), ["eslint-plugn-promse"])
    }

    /// The installed list keeps `rankedPackages` apart; a list of the old shape, and unknown keys, still load.
    func testTheInstalledListKeepsTheRankedNamesApartAndAnOldShapedListStillLoads() throws {
        let fm = FileManager.default
        let url = TyposquatGuard.updatedListURL
        let backup = try? Data(contentsOf: url)
        defer {
            if let backup { try? backup.write(to: url) } else { try? fm.removeItem(at: url) }
        }
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"mapVersion":"2099-01-01","packages":["hand-one"],"rankedPackages":["ranked-one"],"somethingNew":1}"#.utf8).write(to: url)
        var lists = TyposquatGuard.popularLists()
        XCTAssertEqual(lists.hand, ["hand-one"])
        XCTAssertEqual(lists.ranked, ["ranked-one"])
        XCTAssertEqual(TyposquatGuard.popularPackageNames(), ["hand-one"])
        try Data(#"{"mapVersion":"2099-01-01","packages":["only-hand"]}"#.utf8).write(to: url)
        lists = TyposquatGuard.popularLists()
        XCTAssertEqual(lists.hand, ["only-hand"])
        XCTAssertEqual(lists.ranked, [])
    }

    /// The vectors Rust and Python also run (roamswitch-linux/scripts/testdata/typosquat_parity.json). Skipped when the
    /// Linux repository is not next to this one; `TEST_RUNNER_TYPO_VECTORS=<file>` points elsewhere.
    func testTheSharedParityVectors() throws {
        let path = ProcessInfo.processInfo.environment["TYPO_VECTORS"]
            ?? NSString(string: "~/Dev/roamswitch-linux/scripts/testdata/typosquat_parity.json").expandingTildeInPath
        guard let data = FileManager.default.contents(atPath: path) else { throw XCTSkip("no parity vectors at \(path)") }
        struct Case: Decodable { let name: String; let expect: [JSONValue]?; let installCode: Bool? }
        struct Group: Decodable { let popular: [String]; let ranked: [String]?; let cases: [Case] }
        struct Vectors: Decodable { let groups: [Group] }
        enum JSONValue: Decodable {
            case s(String), i(Int)
            init(from d: Decoder) throws {
                let c = try d.singleValueContainer()
                if let i = try? c.decode(Int.self) { self = .i(i) } else { self = .s(try c.decode(String.self)) }
            }
        }
        let vectors = try JSONDecoder().decode(Vectors.self, from: data)
        var checked = 0, flagged = 0
        for group in vectors.groups {
            let index = TyposquatGuard.PopularIndex(group.popular, ranked: group.ranked ?? [])
            for c in group.cases {
                let installCode = c.installCode ?? false
                let got = TyposquatGuard.checkName(c.name, against: index, hasInstallCode: { installCode })
                if let expect = c.expect, case .s(let target) = expect[0], case .i(let distance) = expect[1] {
                    XCTAssertEqual(got?.suspectedTarget, target, c.name)
                    XCTAssertEqual(got?.distance, distance, c.name)
                    flagged += 1
                } else {
                    XCTAssertNil(got, c.name)
                }
                checked += 1
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 300)
        XCTAssertGreaterThanOrEqual(flagged, 100)
    }

    /// A list prepared once (`PopularIndex`) answers exactly as the plain array does, for a list far larger than the seed.
    func testAPreparedListGivesTheSameAnswersAsTheArrayOnALargeList() {
        var list = ["nodemon", "react-router-dom", "zustand", "discord.js", "ethers", "chart.js", "core-js", "lodash", "express"]
        for i in 0..<12_000 { list.append("pkg-\(String(i, radix: 36))-\(i % 97)") }
        let index = TyposquatGuard.PopularIndex(list)
        let names = ["nodemonjs", "zustand.js", "lodsh", "expres", "chart", "postcss-js", "@solana/web3.js", "react", "pkg-a1-3x",
                     "pkg-zz-1", "some-unrelated-name", "etherdjs", "dizcordjs", "@scope/lodsh", "abc"]
        for name in names {
            let a = TyposquatGuard.checkName(name, against: list)
            let b = TyposquatGuard.checkName(name, against: index)
            XCTAssertEqual(a?.suspectedTarget, b?.suspectedTarget, name)
            XCTAssertEqual(a?.distance, b?.distance, name)
        }
        XCTAssertEqual(TyposquatGuard.checkName("nodemonjs", against: index)?.suspectedTarget, "nodemon")
        XCTAssertEqual(TyposquatGuard.checkName("lodsh", against: index)?.suspectedTarget, "lodash")
        XCTAssertNil(TyposquatGuard.checkName("@solana/web3.js", against: index))
    }

    /// Timing on a real list: `TEST_RUNNER_TYPO_BENCH_LIST=<list.json> TEST_RUNNER_TYPO_BENCH_NAMES=<names.txt>`.
    /// Skipped when the variables are not set.
    func testTimingOnAGivenList() throws {
        let env = ProcessInfo.processInfo.environment
        guard let listPath = env["TYPO_BENCH_LIST"], let namesPath = env["TYPO_BENCH_NAMES"] else {
            throw XCTSkip("no benchmark list given")
        }
        struct List: Decodable { let packages: [String] }
        let list = try JSONDecoder().decode(List.self, from: Data(contentsOf: URL(fileURLWithPath: listPath))).packages
        let names = try String(contentsOfFile: namesPath, encoding: .utf8).split(separator: "\n").map(String.init)
        var t0 = Date()
        let index = TyposquatGuard.PopularIndex(list)
        let build = Date().timeIntervalSince(t0)
        t0 = Date()
        var flagged = 0
        for n in names where TyposquatGuard.checkName(n, against: index) != nil { flagged += 1 }
        let elapsed = Date().timeIntervalSince(t0)
        print("TYPO_BENCH list=\(list.count) names=\(names.count) flagged=\(flagged) build_ms=\(build * 1000) us_per_check=\(elapsed * 1e6 / Double(max(names.count, 1)))")
    }

    func testAllowlistSuppressesKnownLookalikes() {
        XCTAssertNil(TyposquatGuard.checkName("preact", against: popular))
        XCTAssertNil(TyposquatGuard.checkName("is-array", against: popular))
    }

    func testUnrelatedNameIsNotFlagged() {
        XCTAssertNil(TyposquatGuard.checkName("some-totally-unrelated-package-name", against: popular))
    }

    func testShortNamesAreNotComparedByEditDistance() {
        // `@eslint/js` unscopes to `js`, one edit from `ws`.
        XCTAssertNil(TyposquatGuard.checkName("@eslint/js", against: ["ws", "react"]))
        XCTAssertNil(TyposquatGuard.checkName("js", against: ["ws"]))
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
        XCTAssertTrue(findings.first?.projectDir.hasSuffix("packages/app") ?? false)
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
