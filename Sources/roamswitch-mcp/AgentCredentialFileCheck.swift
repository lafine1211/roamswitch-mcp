// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.18 (build 197).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// Audit check `agent_credential_files`: are the files in which AI coding tools keep their sign-in tokens private?
///
/// For each known file that EXISTS this looks at the file's metadata only (never its content):
/// - the mode: any group or other permission bit is a problem (the files are written 0600 by the tools that own them);
/// - the owner: it must be the current user;
/// - where it really lives: the path with symbolic links resolved (a dotfiles setup often links `~/.codex` into a
///   repository or a Dropbox folder) must not be inside a cloud-synced folder (iCloud Drive, `~/Library/CloudStorage`
///   providers such as Dropbox, OneDrive, Google Drive and Box, or a `~/Dropbox`-style folder) or inside a git work tree
///   (a work tree whose root is the home folder itself is not counted: a dotfiles repository that way is common and
///   says nothing about whether this file is tracked).
///
/// Honest limits, stated in the item and in the detection coverage:
/// - Claude Code keeps its sign-in in the macOS Keychain on a Mac (the file below is its fallback), so most Macs have
///   no `~/.claude/.credentials.json` and nothing is checked for it.
/// - These are the default locations. A tool moved with an environment variable (`CODEX_HOME`, `XDG_CONFIG_HOME`,
///   `XDG_DATA_HOME`) is not found.
/// - Whether a file inside a git work tree is actually tracked or ignored is not asked of git.
/// - A READ of these files is not detected. Without Endpoint Security a Mac cannot see which process opened a file, and
///   RoamSwitch deliberately does not plant decoys at these paths: the tools read them on every start, so a decoy would
///   fire all the time.
enum AgentCredentialFileCheck {

    struct Target: Equatable {
        /// Path below the home folder.
        let relativePath: String
        let tool: String
    }

    static let targets: [Target] = [
        Target(relativePath: ".claude/.credentials.json", tool: "Claude Code"),
        Target(relativePath: ".codex/auth.json", tool: "Codex"),
        Target(relativePath: ".gemini/oauth_creds.json", tool: "Gemini CLI"),
        Target(relativePath: ".config/github-copilot/hosts.json", tool: "GitHub Copilot"),
        Target(relativePath: ".config/github-copilot/apps.json", tool: "GitHub Copilot"),
        Target(relativePath: ".local/share/opencode/auth.json", tool: "opencode"),
        Target(relativePath: ".local/share/opencode/mcp-auth.json", tool: "opencode"),
    ]

    /// What `lstat`/`stat`/`realpath` say about one existing file.
    struct Facts: Equatable {
        var path: String
        var realPath: String
        var mode: UInt16
        var ownerUID: UInt32
    }

    enum Problem: Equatable {
        case accessibleByOthers(mode: UInt16)
        case notOwnedByUser
        case syncedFolder(provider: String)
        case insideGitWorkTree(root: String)
    }

    struct Result: Equatable {
        var target: Target
        var path: String
        var problems: [Problem]
    }

    /// The scan the audit uses; the tests replace it.
    static var scan: () -> [Result]? = liveScan

    // MARK: Pure judgement

    /// `home` and, when the home folder sits under a link (`/tmp` -> `/private/tmp`), its resolved spelling.
    /// A real path from `realpath(3)` is spelled the resolved way.
    static func homeSpellings(_ home: String) -> [String] {
        var spellings = [home]
        if let resolved = realpath(home, nil) {
            defer { free(resolved) }
            let text = String(cString: resolved)
            if text != home { spellings.append(text) }
        }
        return spellings
    }

    /// The cloud provider whose folder holds `realPath`, if any. `home` has no trailing slash.
    static func syncProvider(realPath: String, home: String) -> String? {
        guard let prefix = homeSpellings(home).map({ $0 + "/" }).first(where: { realPath.hasPrefix($0) }) else { return nil }
        let rest = String(realPath.dropFirst(prefix.count))
        if rest.hasPrefix("Library/Mobile Documents/") { return "iCloud Drive" }
        if rest.hasPrefix("Library/CloudStorage/") {
            // "Dropbox", "OneDrive-Personal", "GoogleDrive-name@example.com", "Box-Box": the provider is the part before the dash.
            let folder = rest.dropFirst("Library/CloudStorage/".count).split(separator: "/").first.map(String.init) ?? ""
            let provider = folder.split(separator: "-").first.map(String.init) ?? folder
            return provider.isEmpty ? "cloud storage" : provider
        }
        for (folder, provider) in [("Dropbox", "Dropbox"), ("Google Drive", "Google Drive"), ("OneDrive", "OneDrive"), ("Box", "Box"),
                                   ("iCloud Drive", "iCloud Drive"), ("pCloud Drive", "pCloud")] where rest == folder || rest.hasPrefix(folder + "/") {
            return provider
        }
        return nil
    }

    /// Problems of one file. `gitRoot` gives the root of the git work tree that holds a directory, if any.
    static func problems(for facts: Facts, home: String, uid: UInt32, gitRoot: (String) -> String?) -> [Problem] {
        var out: [Problem] = []
        if facts.mode & 0o077 != 0 { out.append(.accessibleByOthers(mode: facts.mode & 0o777)) }
        if facts.ownerUID != uid { out.append(.notOwnedByUser) }
        if let provider = syncProvider(realPath: facts.realPath, home: home) { out.append(.syncedFolder(provider: provider)) }
        let directory = (facts.realPath as NSString).deletingLastPathComponent
        if let root = gitRoot(directory), !homeSpellings(home).contains(root) { out.append(.insideGitWorkTree(root: root)) }
        return out
    }

    // MARK: Reading

    static func liveScan() -> [Result]? {
        let home = NSHomeDirectory()
        let uid = getuid()
        var results: [Result] = []
        for target in targets {
            let path = home + "/" + target.relativePath
            var st = stat()
            guard stat(path, &st) == 0 else { continue }        // follows a link; a missing file is simply not checked
            guard let resolved = realpath(path, nil) else { continue }
            defer { free(resolved) }
            let facts = Facts(path: path, realPath: String(cString: resolved), mode: st.st_mode & 0o7777, ownerUID: st.st_uid)
            results.append(Result(target: target, path: path, problems: problems(for: facts, home: home, uid: uid, gitRoot: liveGitRoot)))
        }
        return results
    }

    /// The nearest ancestor (or the directory itself) that holds a `.git` directory or file (a work tree or a linked one).
    static func liveGitRoot(of directory: String) -> String? {
        var current = directory
        for _ in 0..<40 {
            if FileManager.default.fileExists(atPath: current + "/.git") { return current }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current || parent.isEmpty || parent == "/" { return nil }
            current = parent
        }
        return nil
    }

    // MARK: Audit item

    static func displayPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    static func lines(for result: Result) -> [String] {
        let shown = MCPUntrustedText.sanitize(displayPath(result.path), maxLength: 120)
        return result.problems.map { problem -> String in
            switch problem {
            case .accessibleByOthers(let mode):
                return String(format: loc("%1$@: 所有者以外も読める権限です(現在 %2$@)。chmod 600 で所有者だけにしてください。"), shown, String(mode, radix: 8))
            case .notOwnedByUser:
                return String(format: loc("%@: 所有者が今のユーザーではありません。"), shown)
            case .syncedFolder(let provider):
                return String(format: loc("%1$@: %2$@ の同期フォルダの中にあります。同期の対象から外すか、別の場所に移してください。"), shown, MCPUntrustedText.sanitize(provider, maxLength: 40))
            case .insideGitWorkTree(let root):
                return String(format: loc("%1$@: git管理下のフォルダ(%2$@)の中にあります。コミットされないよう、.gitignore に入れるか、別の場所に移してください。"),
                              shown, MCPUntrustedText.sanitize(displayPath(root), maxLength: 120))
            }
        }
    }

    static func item(_ results: [Result]?) -> SecurityAuditItem {
        var isPassed = false
        var isApplicable = true
        var inconclusiveReason: String?
        let statusText: String
        var recommendation = loc("設定は万全です。")
        switch results {
        case .none:
            statusText = loc("状態を確認できませんでした")
            inconclusiveReason = "not_verifiable"
            recommendation = loc("もう一度確認してください。")
        case .some(let found) where found.isEmpty:
            isApplicable = false
            isPassed = true
            statusText = loc("対象のファイルがありません")
        case .some(let found):
            let bad = found.filter { !$0.problems.isEmpty }
            if bad.isEmpty {
                isPassed = true
                statusText = String(format: loc("%d件のファイルは、所有者だけが読め、同期フォルダやgit管理下にもありません"), found.count)
            } else {
                statusText = String(format: loc("⚠️ %d件のファイルに問題があります"), bad.count)
                recommendation = bad.flatMap(lines(for:)).prefix(6).joined(separator: "\n")
            }
        }
        return SecurityAuditItem(
            category: loc("認証・アクセス制御"),
            title: loc("AIエージェントの認証情報ファイル"),
            isPassed: isPassed,
            statusText: statusText,
            detail: loc("Claude Code、Codex、Gemini CLI、GitHub Copilot、opencodeがサインイン情報を保存するファイルの権限と置き場所を確認します。中身は読みません。所有者以外が読める、iCloud DriveやDropboxなどの同期フォルダの中、git管理下のフォルダの中にあると、トークンが漏れる原因になります。MacのClaude Codeは通常キーチェーンに保存するため、ファイルがなければ対象外です。標準の場所だけを調べます。これらのファイルが読まれたことの検知はできません。"),
            recommendation: recommendation,
            settingsURL: nil,
            isApplicable: isApplicable,
            checkId: "agent_credential_files",
            inconclusiveReason: inconclusiveReason
        )
    }
}
