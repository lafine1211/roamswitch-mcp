// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.15 (build 194). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// Audit check `agent_credential_files`: permissions and location of the AI tools' sign-in files. Pure judgement on
/// fixtures, plus the live helpers on a throw-away directory. Only `testTheLiveScanReturnsOnlyKnownTargets` looks at
/// the real home folder, and only at the metadata of the known paths (never at any content).
final class AgentCredentialFileCheckTests: XCTestCase {
    typealias C = AgentCredentialFileCheck

    private let home = "/Users/tester"
    private let uid: UInt32 = 501

    private func facts(_ path: String = "/Users/tester/.codex/auth.json", real: String? = nil, mode: UInt16 = 0o600, owner: UInt32 = 501) -> C.Facts {
        C.Facts(path: path, realPath: real ?? path, mode: mode, ownerUID: owner)
    }

    private func problems(_ f: C.Facts, git: @escaping (String) -> String? = { _ in nil }) -> [C.Problem] {
        C.problems(for: f, home: home, uid: uid, gitRoot: git)
    }

    func testAnOwnerOnlyFileInAPlainFolderHasNoProblem() {
        XCTAssertTrue(problems(facts()).isEmpty)
        XCTAssertTrue(problems(facts(mode: 0o400)).isEmpty)
        XCTAssertTrue(problems(facts(mode: 0o700)).isEmpty, "owner-only bits, whatever they are")
    }

    func testGroupOrOtherPermissionIsAProblem() {
        for mode: UInt16 in [0o640, 0o644, 0o660, 0o604, 0o666, 0o604, 0o610] {
            XCTAssertEqual(problems(facts(mode: mode)), [.accessibleByOthers(mode: mode)], String(mode, radix: 8))
        }
        // Special bits above the permission bits are not part of the judgement.
        XCTAssertTrue(problems(facts(mode: 0o600)).isEmpty)
    }

    func testAnotherOwnerIsAProblem() {
        XCTAssertEqual(problems(facts(owner: 0)), [.notOwnedByUser])
    }

    func testSyncedFolders() {
        let cases: [(String, String)] = [
            ("/Users/tester/Library/Mobile Documents/com~apple~CloudDocs/dotfiles/codex/auth.json", "iCloud Drive"),
            ("/Users/tester/Library/CloudStorage/Dropbox/dot/auth.json", "Dropbox"),
            ("/Users/tester/Library/CloudStorage/OneDrive-Personal/x/auth.json", "OneDrive"),
            ("/Users/tester/Library/CloudStorage/GoogleDrive-me@example.com/My Drive/auth.json", "GoogleDrive"),
            ("/Users/tester/Library/CloudStorage/Box-Box/auth.json", "Box"),
            ("/Users/tester/Dropbox/dotfiles/auth.json", "Dropbox"),
            ("/Users/tester/Google Drive/auth.json", "Google Drive"),
            ("/Users/tester/OneDrive/auth.json", "OneDrive"),
        ]
        for (real, provider) in cases {
            XCTAssertEqual(C.syncProvider(realPath: real, home: home), provider, real)
            XCTAssertEqual(problems(facts(real: real)), [.syncedFolder(provider: provider)], real)
        }
        for plain in ["/Users/tester/.codex/auth.json", "/Users/tester/Documents/auth.json", "/Users/tester/DropboxBackup/auth.json",
                      "/Users/tester/Library/Preferences/auth.json", "/opt/data/Dropbox/auth.json", "/Users/other/Dropbox/auth.json"] {
            XCTAssertNil(C.syncProvider(realPath: plain, home: home), plain)
        }
    }

    /// A home folder reached through a link (`/tmp` -> `/private/tmp`): `realpath` spells the file the resolved way.
    func testSyncedFolderIsFoundWhenTheHomeFolderIsUnderALink() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("agentcred-\(UUID().uuidString)", isDirectory: true)
        let realHome = root.appendingPathComponent("real/home", isDirectory: true)
        try fm.createDirectory(at: realHome, withIntermediateDirectories: true)
        let link = root.appendingPathComponent("link")
        try fm.createSymbolicLink(atPath: link.path, withDestinationPath: root.appendingPathComponent("real").path)
        addTeardownBlock { try? fm.removeItem(at: root) }
        let linkedHome = link.appendingPathComponent("home").path
        let resolvedHome = String(cString: try XCTUnwrap(realpath(linkedHome, nil)))
        XCTAssertNotEqual(linkedHome, resolvedHome)
        XCTAssertEqual(C.syncProvider(realPath: resolvedHome + "/Dropbox/dot/auth.json", home: linkedHome), "Dropbox")
        XCTAssertEqual(C.syncProvider(realPath: resolvedHome + "/Library/Mobile Documents/x/auth.json", home: linkedHome), "iCloud Drive")
        XCTAssertEqual(C.syncProvider(realPath: linkedHome + "/Dropbox/auth.json", home: linkedHome), "Dropbox")
        XCTAssertNil(C.syncProvider(realPath: resolvedHome + "/.codex/auth.json", home: linkedHome))
        XCTAssertNil(C.syncProvider(realPath: resolvedHome + "Other/Dropbox/auth.json", home: linkedHome))
        // A git work tree that is the home folder (either spelling) is not a finding.
        let f = C.Facts(path: linkedHome + "/.codex/auth.json", realPath: resolvedHome + "/.codex/auth.json", mode: 0o600, ownerUID: uid)
        XCTAssertTrue(C.problems(for: f, home: linkedHome, uid: uid, gitRoot: { _ in resolvedHome }).isEmpty)
        XCTAssertTrue(C.problems(for: f, home: linkedHome, uid: uid, gitRoot: { _ in linkedHome }).isEmpty)
    }

    func testAFileInsideAGitWorkTreeIsAProblemExceptWhenTheTreeIsTheHomeFolder() {
        let repo = "/Users/tester/dotfiles"
        XCTAssertEqual(problems(facts(real: "/Users/tester/dotfiles/codex/auth.json"), git: { $0.hasPrefix(repo) ? repo : nil }),
                       [.insideGitWorkTree(root: repo)])
        // A dotfiles repository that is the home folder itself says nothing about this file.
        XCTAssertTrue(problems(facts(), git: { _ in "/Users/tester" }).isEmpty)
    }

    func testSeveralProblemsAreAllReportedInOrder() {
        let found = problems(facts(real: "/Users/tester/Dropbox/dot/auth.json", mode: 0o644, owner: 0), git: { _ in "/Users/tester/Dropbox/dot" })
        XCTAssertEqual(found, [.accessibleByOthers(mode: 0o644), .notOwnedByUser, .syncedFolder(provider: "Dropbox"),
                               .insideGitWorkTree(root: "/Users/tester/Dropbox/dot")])
    }

    // MARK: the live helpers, on a throw-away directory

    func testLiveGitRootFindsTheNearestAncestorWithADotGit() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("agent-cred-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base) }
        let nested = base.appendingPathComponent("repo/sub/dir")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("repo/.git"), withIntermediateDirectories: true)
        XCTAssertEqual(C.liveGitRoot(of: nested.path).map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().path },
                       base.appendingPathComponent("repo").resolvingSymlinksInPath().path)
        // A linked work tree has a .git file instead of a folder.
        try FileManager.default.createDirectory(at: base.appendingPathComponent("linked/x"), withIntermediateDirectories: true)
        try Data("gitdir: elsewhere".utf8).write(to: base.appendingPathComponent("linked/.git"))
        XCTAssertNotNil(C.liveGitRoot(of: base.appendingPathComponent("linked/x").path))
    }

    // MARK: the audit item

    private func result(_ problems: [C.Problem], tool: String = "Codex", path: String = "/Users/tester/.codex/auth.json") -> C.Result {
        C.Result(target: C.Target(relativePath: ".codex/auth.json", tool: tool), path: path, problems: problems)
    }

    func testNoFilesMeansNotApplicableAndNeverAFailure() {
        let item = C.item([])
        XCTAssertTrue(item.isPassed)
        XCTAssertFalse(item.isApplicable)
        XCTAssertEqual(item.checkId, "agent_credential_files")
        XCTAssertEqual(SecurityCheckVerification.classify(item).verdict, .resolved)
    }

    func testCleanFilesPass() {
        let item = C.item([result([]), result([], tool: "Gemini CLI", path: "/Users/tester/.gemini/oauth_creds.json")])
        XCTAssertTrue(item.isPassed)
        XCTAssertTrue(item.isApplicable)
        XCTAssertTrue(item.statusText.contains("2"))
    }

    func testAProblemFailsAndTheRecommendationNamesTheFileAndTheFix() {
        let item = C.item([result([.accessibleByOthers(mode: 0o644)]), result([])])
        XCTAssertFalse(item.isPassed)
        XCTAssertTrue(item.statusText.contains("1"))
        XCTAssertTrue(item.recommendation.contains("auth.json"))
        XCTAssertTrue(item.recommendation.contains("chmod 600"))
        XCTAssertTrue(item.recommendation.contains("644"))
        let synced = C.item([result([.syncedFolder(provider: "Dropbox")])])
        XCTAssertTrue(synced.recommendation.contains("Dropbox"))
        let git = C.item([result([.insideGitWorkTree(root: "/Users/tester/dotfiles")])])
        XCTAssertTrue(git.recommendation.contains("/Users/tester/dotfiles") || git.recommendation.contains("~/dotfiles"))
        let owner = C.item([result([.notOwnedByUser])])
        XCTAssertFalse(owner.isPassed)
    }

    func testAnUnreadableScanIsInconclusive() {
        let item = C.item(nil)
        XCTAssertEqual(item.inconclusiveReason, "not_verifiable")
        XCTAssertEqual(SecurityCheckVerification.classify(item).verdict, .inconclusive)
    }

    func testTheTargetsAreTheDocumentedFilesAndTheClaudeFileIsOnlyAFallback() {
        let paths = Set(C.targets.map(\.relativePath))
        XCTAssertTrue(paths.isSuperset(of: [".claude/.credentials.json", ".codex/auth.json", ".gemini/oauth_creds.json",
                                            ".config/github-copilot/hosts.json", ".local/share/opencode/auth.json"]))
        XCTAssertEqual(paths.count, C.targets.count, "no path twice")
        for target in C.targets { XCTAssertFalse(target.relativePath.hasPrefix("/"), target.relativePath) }
    }

    func testTheLiveScanReturnsOnlyKnownTargets() throws {
        // The live scan only stats files. In a home folder with none of them it returns an empty list, not nil.
        let live = C.liveScan()
        XCTAssertNotNil(live)
        for r in live ?? [] { XCTAssertTrue(C.targets.contains(r.target)) }
    }

    func testTheCheckIsInTheAuditReportOnceWithTheScanInjected() {
        let original = C.scan
        defer { C.scan = original }
        C.scan = { [self.result([.accessibleByOthers(mode: 0o644)])] }
        let report = SecurityHealthChecker.shared.generateComprehensiveReport(
            wifiInfo: WiFiInfo(ssid: nil, bssid: nil, securityLevel: .notConnected),
            arpStatus: ARPMonitorStatus(isSpoofingDetected: false, message: "", previousMAC: nil, currentMAC: nil, gatewayKnown: true, hadBaseline: true),
            listeningPorts: [], activeSecurityLevel: .balanced)
        let items = report.items.filter { $0.checkId == "agent_credential_files" }
        XCTAssertEqual(items.count, 1)
        XCTAssertFalse(items[0].isPassed)
    }
}
