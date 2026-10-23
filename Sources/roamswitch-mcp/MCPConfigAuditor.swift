// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.5 (build 184).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static audit of the MCP client configuration files on this Mac (Claude Desktop,
/// Claude Code, Cursor, Windsurf, VS Code, Cline, Gemini CLI, plus `.mcp.json` in the
/// project folders registered in RoamSwitch).
///
/// Why: an MCP server is a door through which a model runs tools, so a bad entry in one
/// of these files is a standing way to execute code. HexStrike AI (an MCP backend that
/// hands a model 150+ attack tools and runs whatever string it is sent through a shell,
/// with no authentication) is the extreme case, but the same mistakes show up in ordinary
/// setups: tools auto-approved so no human ever sees the call, a plaintext http:// server
/// on another host, a launch command that is itself a shell one-liner, a settings file
/// anyone can rewrite.
///
/// Read-only and local: it opens a fixed list of well-known files, never the network, and
/// never reports a secret. `env` and `headers` values, and any argument, are not copied
/// into the result (they routinely hold API keys); only the server name, a command's
/// basename, a URL's host and (when it is a plain registry name) the package or image
/// name a launcher fetches are. Everything read from those files is untrusted data (a
/// server name can say anything), so names are trimmed to printable text and the MCP tool
/// marks the whole result as untrusted.
enum MCPConfigAuditor {

    struct Finding: Codable, Equatable {
        /// Stable id: `auto_approve`, `remote_plain_http`, `shell_wrapper`, `hexstrike`,
        /// `world_writable_config`, `auto_trust_project_servers`, `unpinned_package_launcher`,
        /// `container_host_access`, `code_loading_env`, `traffic_interception_env`, `injection_exposure`.
        let id: String
        /// `high` or `medium`.
        let severity: String
        let file: String
        let server: String?
        /// Short technical fact, never a secret (see the type's doc comment).
        let detail: String
        /// Localized explanation and what to do about it.
        let message: String
    }

    struct Result: Equatable {
        var scannedFiles: [String] = []
        var serverCount = 0
        var findings: [Finding] = []
        /// Files that exist but could not be read or parsed. Reported so "nothing found"
        /// is never mistaken for "everything was checked".
        var unreadableFiles: [String] = []
    }

    /// One file as read from disk: its bytes and POSIX permission bits (nil if unknown).
    struct FileInput {
        let path: String
        let data: Data
        let mode: UInt16?
    }

    private static let maxFileBytes = 8 * 1024 * 1024
    private static let maxServersPerFile = 500

    // MARK: - Candidate files

    /// Per-user config files whose `mcpServers` / `servers` object is audited.
    static func serverConfigPaths(home: String) -> [String] {
        [
            "\(home)/Library/Application Support/Claude/claude_desktop_config.json",
            "\(home)/.claude.json",
            "\(home)/.cursor/mcp.json",
            "\(home)/.codeium/windsurf/mcp_config.json",
            "\(home)/Library/Application Support/Code/User/mcp.json",
            "\(home)/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json",
            "\(home)/.gemini/settings.json",
        ]
    }

    /// Claude Code settings files, checked only for the "trust every project .mcp.json" switch.
    static func settingsPaths(home: String) -> [String] {
        ["\(home)/.claude/settings.json", "\(home)/.claude/settings.local.json"]
    }

    static func projectConfigPaths(folders: [String]) -> [String] {
        folders.flatMap { ["\($0)/.mcp.json", "\($0)/.cursor/mcp.json", "\($0)/.vscode/mcp.json"] }
    }

    // MARK: - Run

    static func run(home: String = NSHomeDirectory(), projectFolders: [String]) -> Result {
        let fm = FileManager.default
        var inputs: [FileInput] = []
        var unreadable: [String] = []
        let paths = serverConfigPaths(home: home) + settingsPaths(home: home) + projectConfigPaths(folders: projectFolders)
        for path in paths {
            guard let attrs = try? fm.attributesOfItem(atPath: path) else { continue } // absent: nothing to audit
            guard (attrs[.type] as? FileAttributeType) == .typeRegular || (attrs[.type] as? FileAttributeType) == .typeSymbolicLink,
                  let size = attrs[.size] as? NSNumber, size.intValue <= maxFileBytes,
                  let data = fm.contents(atPath: path) else {
                unreadable.append(path)
                continue
            }
            let mode = (attrs[.posixPermissions] as? NSNumber).map { UInt16($0.intValue & 0o7777) }
            inputs.append(FileInput(path: path, data: data, mode: mode))
        }
        var result = audit(files: inputs)
        result.unreadableFiles += unreadable
        return result
    }

    /// Digest of every MCP server definition in the same config files `run` reads, for change
    /// detection (see `AgentSetupBaseline`). Config path -> server name -> digest. Only digests
    /// leave this function: a server's arguments and environment can hold a token.
    static func serverSnapshot(home: String = NSHomeDirectory(), projectFolders: [String]) -> [String: [String: AgentSetupBaseline.Entry]] {
        let fm = FileManager.default
        var out: [String: [String: AgentSetupBaseline.Entry]] = [:]
        for path in serverConfigPaths(home: home) + projectConfigPaths(folders: projectFolders) {
            guard let attrs = try? fm.attributesOfItem(atPath: path),
                  let size = attrs[.size] as? NSNumber, size.intValue <= maxFileBytes,
                  let data = fm.contents(atPath: path),
                  let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }
            var entries: [String: AgentSetupBaseline.Entry] = [:]
            for (name, config) in servers(in: root).prefix(maxServersPerFile) {
                if let entry = AgentSetupBaseline.serverEntry(config) { entries[name] = entry }
            }
            if !entries.isEmpty { out[path] = entries }
        }
        return out
    }

    // MARK: - Pure audit

    static func audit(files: [FileInput]) -> Result {
        var result = Result()
        for file in files {
            guard let root = (try? JSONSerialization.jsonObject(with: file.data)) as? [String: Any] else {
                result.unreadableFiles.append(file.path)
                continue
            }
            result.scannedFiles.append(file.path)
            var fileHasMCPContent = false

            if (root["enableAllProjectMcpServers"] as? Bool) == true {
                fileHasMCPContent = true
                result.findings.append(Finding(
                    id: "auto_trust_project_servers", severity: "high", file: file.path, server: nil,
                    detail: "enableAllProjectMcpServers is true",
                    message: loc("Claude Code が、リポジトリ内の .mcp.json に書かれた MCP サーバーを確認なしですべて有効にする設定（enableAllProjectMcpServers）です。悪意のあるリポジトリを開いただけで、そこに書かれたコマンドが実行されます。この設定をオフにして、サーバーごとに確認してください。")
                ))
            }

            let fileServers = Array(servers(in: root).prefix(maxServersPerFile))
            for (serverName, config) in fileServers {
                fileHasMCPContent = true
                result.serverCount += 1
                result.findings += audit(server: serverName, config: config, file: file.path)
            }
            if let exposure = injectionExposure(servers: fileServers, file: file.path) {
                result.findings.append(exposure)
            }

            if fileHasMCPContent, let mode = file.mode, mode & 0o022 != 0 {
                result.findings.append(Finding(
                    id: "world_writable_config", severity: "medium", file: file.path, server: nil,
                    detail: "mode \(String(mode, radix: 8)) is writable by group or others",
                    message: loc("この設定ファイルは、所有者以外も書き込める権限になっています。他のユーザーやプロセスが MCP サーバーの起動コマンドを差し替えれば、次回の起動時に任意のコードが実行されます。chmod go-w で書き込み権限を外してください。")
                ))
            }
        }
        return result
    }

    /// Every server object in a file: top-level `mcpServers` (or VS Code's `servers`) and,
    /// for `~/.claude.json`, the per-project `projects.<path>.mcpServers`.
    private static func servers(in root: [String: Any]) -> [(String, [String: Any])] {
        var out: [(String, [String: Any])] = []
        func collect(_ object: Any?, prefix: String = "") {
            guard let dict = object as? [String: Any] else { return }
            for (name, value) in dict.sorted(by: { $0.key < $1.key }) {
                if let config = value as? [String: Any] { out.append((prefix + name, config)) }
            }
        }
        collect(root["mcpServers"])
        collect(root["servers"])
        if let projects = root["projects"] as? [String: Any] {
            for (projectPath, value) in projects.sorted(by: { $0.key < $1.key }) {
                collect((value as? [String: Any])?["mcpServers"], prefix: "[\((projectPath as NSString).lastPathComponent)] ")
            }
        }
        return out
    }

    private static let shellCommands: Set<String> = ["sh", "bash", "zsh", "dash", "fish", "ksh", "csh", "tcsh", "cmd", "cmd.exe", "powershell", "powershell.exe", "pwsh", "pwsh.exe"]
    private static let shellInlineFlags: Set<String> = ["-c", "/c", "-command", "-encodedcommand", "-enc"]
    private static let interpreterInlineFlags: Set<String> = ["-c", "-e", "-p", "--eval", "--print"]

    private static func isInterpreter(_ name: String) -> Bool {
        name.hasPrefix("python") || ["node", "bun", "deno", "perl", "ruby", "php"].contains(name)
    }

    static func isLoopbackHost(_ host: String) -> Bool {
        let h = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if h == "localhost" || h.hasSuffix(".localhost") || h == "::1" { return true }
        let parts = h.split(separator: ".")
        return parts.count == 4 && parts[0] == "127" && parts.allSatisfy { Int($0) != nil }
    }

    /// Host of the first non-loopback `http://` address among a server's launch arguments, either
    /// a whole argument (`--server http://host:8888`) or the value of a flag (`--url=http://host/mcp`).
    /// Only the host is returned: a URL in an argument can carry credentials.
    private static func plainHTTPRemoteHost(inArguments args: [String]) -> String? {
        for arg in args {
            var candidate = arg
            if arg.hasPrefix("-"), let equals = arg.firstIndex(of: "=") {
                candidate = String(arg[arg.index(after: equals)...])
            }
            guard let components = URLComponents(string: candidate), components.scheme?.lowercased() == "http",
                  let host = components.host, !host.isEmpty, !isLoopbackHost(host) else { continue }
            return host
        }
        return nil
    }

    private static func audit(server rawName: String, config: [String: Any], file: String) -> [Finding] {
        let name = sanitized(rawName)
        var findings: [Finding] = []

        let command = (config["command"] as? String) ?? ""
        let args = (config["args"] as? [Any])?.compactMap { $0 as? String } ?? []
        let urlString = (config["url"] as? String) ?? (config["serverUrl"] as? String) ?? ""
        let commandBase = (command as NSString).lastPathComponent.lowercased()

        // Tools that run without a per-call confirmation.
        var autoApprovedCount = 0
        var everyToolAutoApproved = false
        for key in ["alwaysAllow", "autoApprove"] {
            if let list = config[key] as? [Any] { autoApprovedCount = max(autoApprovedCount, list.count) }
            if (config[key] as? Bool) == true { everyToolAutoApproved = true }
        }
        if everyToolAutoApproved || autoApprovedCount > 0 {
            findings.append(Finding(
                id: "auto_approve", severity: "high", file: file, server: name,
                detail: everyToolAutoApproved ? "every tool is auto-approved" : "\(autoApprovedCount) tool(s) are auto-approved",
                message: loc("この MCP サーバーのツールが、毎回の確認なしに自動承認される設定です。プロンプトインジェクションで AI が誘導されると、ユーザーの目に触れないままツールが実行されます。自動承認は読み取り専用で影響の小さいツールだけに絞ってください。")
            ))
        }

        let lowerArgs = args.map { $0.lowercased() }
        let isShellOneLiner = shellCommands.contains(commandBase) && lowerArgs.contains { shellInlineFlags.contains($0) }
        let isInterpreterOneLiner = isInterpreter(commandBase) && lowerArgs.first.map { interpreterInlineFlags.contains($0) } == true

        // Plaintext remote server: the `url` field, or (HexStrike's own sample does this) an
        // `http://` address handed to the launched client as an argument. A shell or interpreter
        // one-liner is reported as such instead; a URL inside inline code is not a server address.
        var plainHTTPHost: String?
        var plainHTTPFromArgument = false
        if let components = URLComponents(string: urlString), components.scheme?.lowercased() == "http",
           let host = components.host, !isLoopbackHost(host) {
            plainHTTPHost = host
        } else if !isShellOneLiner && !isInterpreterOneLiner, let host = plainHTTPRemoteHost(inArguments: args) {
            plainHTTPHost = host
            plainHTTPFromArgument = true
        }
        if let host = plainHTTPHost {
            findings.append(Finding(
                id: "remote_plain_http", severity: "high", file: file, server: name,
                detail: "http:// to non-loopback host \(sanitized(host))" + (plainHTTPFromArgument ? " (launch argument)" : ""),
                message: loc("暗号化されていない http:// で、ループバック以外のホストに接続する MCP サーバーです。通信内容を同じネットワークの第三者に読まれたり書き換えられたりします。MCP サーバーはツール実行の窓口なので、https とクライアント認証を使ってください。")
            ))
        }

        // Launch command that is a shell/interpreter one-liner.
        if isShellOneLiner || isInterpreterOneLiner {
            findings.append(Finding(
                id: "shell_wrapper", severity: "medium", file: file, server: name,
                detail: "command is \(sanitized(commandBase)) with an inline script",
                message: loc("MCP サーバーの起動コマンドが、シェルやインタープリタのインラインコード（sh -c など）になっています。設定ファイルを書き換えられるだけで、AI クライアントの起動のたびに任意のコマンドが実行されます。実行ファイルと引数を直接指定してください。")
            ))
        }

        // Launcher that fetches code at start-up (npx/uvx/docker run ...) without a pin.
        if let launch = PackageLauncher.parse(command: command, args: args), !launch.unpinned.isEmpty {
            let names = launch.unpinned.joined(separator: ", ")
            findings.append(Finding(
                id: "unpinned_package_launcher", severity: "medium", file: file, server: name,
                detail: "\(launch.runner) fetches unpinned \(names)" + (launch.autoYes ? " (auto-confirmed)" : ""),
                message: loc("この MCP サーバーは、起動のたびにレジストリからコードを取得して実行します。バージョンが固定されていないため、パッケージが乗っ取られたり、名前を似せた別パッケージに解決されたりすると、AI クライアントと同じ権限で攻撃者のコードが動きます。「パッケージ名@x.y.z」のようにバージョンを固定し（Docker はイメージのダイジェストまたは固定タグ）、公開元を確認してください。")
            ))
        }

        // Container launcher that hands the server the host.
        if let risks = PackageLauncher.containerHostAccess(command: command, args: args), !risks.isEmpty {
            findings.append(Finding(
                id: "container_host_access", severity: "high", file: file, server: name,
                detail: "container runs with " + risks.joined(separator: ", "),
                message: loc("この MCP サーバーのコンテナは、ホストの管理権限に近いアクセス（--privileged、Docker ソケットやルートディレクトリのマウント、ホストの PID 名前空間）付きで起動します。サーバーやその依存先が侵害されると、コンテナを越えてこの Mac 側の Docker 環境全体を操作されます。必要なディレクトリだけを読み取り専用でマウントし、特権オプションは外してください。")
            ))
        }

        // `env` that makes the launched process load extra code at start-up.
        if let env = config["env"] as? [String: Any] {
            let keys = codeLoadingEnvKeys(env)
            if !keys.isEmpty {
                findings.append(Finding(
                    id: "code_loading_env", severity: "high", file: file, server: name,
                    detail: "env sets " + keys.joined(separator: ", "),
                    message: loc("この MCP サーバーの環境変数に、起動したプロセスが自分のコードより先に追加のライブラリやスクリプトを読み込む設定（LD_PRELOAD、DYLD_INSERT_LIBRARIES、NODE_OPTIONS の --require など）があります。ふつうの MCP サーバーには要らない設定で、設定ファイルを書き換えられる人がコードを紛れ込ませる手口です。心当たりがなければこの項目を削除し、設定ファイルを書き換えられる人がほかにいないか確認してください。")
                ))
            }
        }

        // `env` that sends the server's traffic through a proxy, trusts an extra certificate authority, or turns
        // certificate checking off: whoever runs the proxy or holds the CA can read what the server sends.
        if let env = config["env"] as? [String: Any] {
            let items = trafficInterceptionEnv(env)
            if !items.isEmpty {
                findings.append(Finding(
                    id: "traffic_interception_env", severity: "medium", file: file, server: name,
                    detail: "env sets " + items.joined(separator: ", "),
                    message: loc("この MCP サーバーの環境変数に、通信をプロキシ経由にする設定(HTTP_PROXY・HTTPS_PROXY・ALL_PROXY)、追加の認証局を信頼させる設定(NODE_EXTRA_CA_CERTS・SSL_CERT_FILE・REQUESTS_CA_BUNDLE など)、または証明書の検証を切る設定(NODE_TLS_REJECT_UNAUTHORIZED=0)があります。社内のプロキシを使うための正しい設定のこともありますが、心当たりがなければ、このサーバーの通信(API キーやトークンを含みます)をプロキシの運営者や認証局を持つ人に読まれるおそれがあります。この項目を確認し、設定ファイルを書き換えられる人がほかにいないか確かめてください。")
                ))
            }
        }

        // HexStrike AI.
        let haystack = ([rawName, command, urlString] + args).joined(separator: " ").lowercased()
        if haystack.contains("hexstrike") {
            findings.append(Finding(
                id: "hexstrike", severity: "high", file: file, server: name,
                detail: "entry references HexStrike AI",
                message: loc("HexStrike AI（AI にペネトレーションテスト用ツールを自律実行させる MCP バックエンド）に接続する設定です。接続先のサーバーは認証なしで、受け取った文字列をそのままシェルで実行します。自分で検証用に運用しているものでなければ、この設定を削除してください。")
            ))
        }
        return findings
    }

    /// Launch-line fragments (package or image names) of well-known servers whose job is to bring text
    /// that other people wrote into the model's context: web fetch, headless browsers, web search,
    /// chat, mail, and the GitHub server (issues and pull requests are open to anyone for a public repo).
    private static let untrustedContentReaders: [String] = [
        "mcp-server-fetch", "server-fetch", "server-puppeteer", "@playwright/mcp", "playwright-mcp",
        "server-brave-search", "firecrawl-mcp", "tavily-mcp", "exa-mcp-server", "chrome-devtools-mcp",
        "@browsermcp/mcp", "server-slack", "server-github", "github-mcp-server", "server-gmail", "gmail-mcp",
    ]

    /// The same for well-known servers that run commands or write files on this Mac.
    private static let machineActors: [String] = [
        "desktop-commander", "mcp-shell", "shell-mcp", "mcp-server-commands", "server-shell",
        "terminal-controller", "iterm-mcp", "mcp-server-docker", "mcp-server-kubernetes", "server-filesystem",
    ]

    private static func launchText(_ config: [String: Any]) -> String {
        let command = (config["command"] as? String) ?? ""
        let args = (config["args"] as? [Any])?.compactMap { $0 as? String } ?? []
        let url = (config["url"] as? String) ?? (config["serverUrl"] as? String) ?? ""
        return ([command, url] + args).joined(separator: " ").lowercased()
    }

    /// Indirect prompt injection (ATT&CK T1698) needs two things in one setup: a server that reads text
    /// an attacker can write (a web page, an issue, a mail) and a different server that can run commands
    /// or change files here. A page can then carry the instruction and the model carries it out. This
    /// cannot see what a server's tools say or whether the model obeys them; it only reports that the
    /// combination is configured, by recognising well-known package and image names in the launch line.
    /// One finding per file; server names come from the file and are sanitized.
    static func injectionExposure(servers: [(String, [String: Any])], file: String) -> Finding? {
        var readers: [String] = []
        var actors: [String] = []
        for (rawName, config) in servers {
            let text = launchText(config)
            if untrustedContentReaders.contains(where: { text.contains($0) }) { readers.append(sanitized(rawName)) }
            else if machineActors.contains(where: { text.contains($0) }) { actors.append(sanitized(rawName)) }
        }
        guard !readers.isEmpty, !actors.isEmpty else { return nil }
        func list(_ names: [String]) -> String {
            names.prefix(3).joined(separator: ", ") + (names.count > 3 ? " (+\(names.count - 3))" : "")
        }
        return Finding(
            id: "injection_exposure", severity: "medium", file: file, server: nil,
            detail: "reads outside content: \(list(readers)); acts on this Mac: \(list(actors))",
            message: loc("この設定には、Web ページ・メール・チャット・Issue など第三者が書いた文章を AI に読ませる MCP サーバーと、このマシンでコマンドを実行したりファイルを書き換えたりできる MCP サーバーが、同時に入っています。読み込んだ文章に紛れた命令（間接プロンプトインジェクション）を AI が実行すると、手元の操作をしていなくてもコマンドやファイル変更が走ります。実行系のツールは毎回の確認を残し、読み取り用のサーバーとは別のクライアントやプロファイルに分けてください。")
        )
    }

    /// Variables that make the process load a library or script of the caller's choosing before its
    /// own code runs, whatever the value is (an empty value only clears the variable).
    private static let alwaysCodeLoadingEnv: Set<String> = ["LD_PRELOAD", "LD_AUDIT", "DYLD_INSERT_LIBRARIES", "BASH_ENV", "PYTHONSTARTUP"]

    /// Everyday settings (`NODE_OPTIONS=--max-old-space-size=4096`) that load code only when the value
    /// carries one of these flags.
    private static let conditionalCodeLoadingEnv: [String: [String]] = [
        "NODE_OPTIONS": ["--require", "--import", "--loader", "--experimental-loader"],
        "JAVA_TOOL_OPTIONS": ["-javaagent", "-agentlib", "-agentpath", "-Xbootclasspath"],
        "_JAVA_OPTIONS": ["-javaagent", "-agentlib", "-agentpath", "-Xbootclasspath"],
        "JDK_JAVA_OPTIONS": ["-javaagent", "-agentlib", "-agentpath", "-Xbootclasspath"],
    ]

    /// Names (as written in the file, sanitized) of the `env` entries that load code at start-up.
    ///
    /// Names are matched without regard to case: Windows treats `node_options` and `NODE_OPTIONS` as
    /// one variable, and Flowise's exact-case deny list was bypassed with the lower-case spelling (a
    /// published Windows proof of concept). On macOS a lower-case name does nothing, but a config file
    /// is often shared between machines and the spelling is a sign of someone trying to get past a
    /// check. Values are read to decide and never copied out.
    static func codeLoadingEnvKeys(_ env: [String: Any]) -> [String] {
        var found: [String] = []
        for (key, value) in env {
            guard let text = value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let upper = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            var hit = alwaysCodeLoadingEnv.contains(upper)
            if !hit, let flags = conditionalCodeLoadingEnv[upper] {
                hit = text.split(whereSeparator: { $0.isWhitespace }).contains { raw in
                    let token = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    return (upper == "NODE_OPTIONS" && token == "-r") || flags.contains { token.hasPrefix($0) }
                }
            }
            if hit { found.append(sanitized(key)) }
        }
        return found.sorted()
    }

    private static let proxyEnv: Set<String> = ["HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"]
    private static let caEnv: Set<String> = ["NODE_EXTRA_CA_CERTS", "SSL_CERT_FILE", "SSL_CERT_DIR", "REQUESTS_CA_BUNDLE", "CURL_CA_BUNDLE", "GIT_SSL_CAINFO"]

    /// The host of a proxy URL, without a scheme, a user name or password, a port or a path. A value that is not a
    /// URL at all (`proxy.example.com:3128`) is read the same way.
    static func proxyHost(_ value: String) -> String {
        var v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let r = v.range(of: "://") { v = String(v[r.upperBound...]) }
        let authority = v.split(whereSeparator: { "/?#".contains($0) }).first.map(String.init) ?? ""
        let hostPort = authority.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? authority
        let host: String
        if hostPort.hasPrefix("[") {
            host = String(hostPort.dropFirst().prefix(while: { $0 != "]" }))
        } else {
            host = hostPort.split(separator: ":", omittingEmptySubsequences: false).first.map(String.init) ?? ""
        }
        return sanitized(host)
    }

    /// The `env` entries that route traffic through a proxy (shown with the proxy's host only), name an extra
    /// certificate authority file, or switch certificate checking off (`NODE_TLS_REJECT_UNAUTHORIZED=0`). Names are
    /// matched without regard to case, as for `codeLoadingEnvKeys`. Paths, credentials and every other value are
    /// read to decide and never copied out; `NO_PROXY` is ignored (it only narrows a proxy).
    static func trafficInterceptionEnv(_ env: [String: Any]) -> [String] {
        var found: [String] = []
        for (key, value) in env {
            guard let text = value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let upper = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if proxyEnv.contains(upper) {
                let host = proxyHost(text)
                found.append(host.isEmpty ? sanitized(key) : "\(sanitized(key)) (host \(host))")
            } else if upper == "NODE_TLS_REJECT_UNAUTHORIZED" {
                if text.trimmingCharacters(in: .whitespacesAndNewlines) == "0" { found.append("\(sanitized(key))=0") }
            } else if caEnv.contains(upper) {
                found.append(sanitized(key))
            }
        }
        return found.sorted()
    }

    /// Printable, bounded text for anything that came from a config file.
    private static func sanitized(_ text: String) -> String {
        let cleaned = String(text.unicodeScalars.filter { $0.value >= 0x20 && $0.value != 0x7F }.map(Character.init))
        return cleaned.count > 80 ? String(cleaned.prefix(80)) + "…" : cleaned
    }
}

/// Reads what a package-runner launch line (`npx -y foo`, `uvx foo`, `docker run image`, ...)
/// will fetch and whether that is pinned. Pure and argument-only: it never resolves a
/// name, never touches the network and never copies anything that is not a plain registry
/// name (a spec can carry a token, e.g. `git+https://TOKEN@host/repo`).
enum PackageLauncher {

    struct Launch: Equatable {
        /// `npx`, `uvx`, `docker`, ...
        let runner: String
        /// Registry names (or "(non-registry spec)") that are fetched without a pin.
        let unpinned: [String]
        /// `-y` / `--yes`: no confirmation before the fetched code runs.
        let autoYes: Bool
    }

    private enum Ecosystem { case npm, python, container }

    /// Flags of the npm-style runners that consume the next token as their value.
    private static let npmValueFlags: Set<String> = [
        "-c", "--call", "--registry", "--cache", "--prefix", "--userconfig", "--node-options", "--workspace", "-w",
        "--loglevel", "--fetch-timeout",
    ]
    private static let uvxValueFlags: Set<String> = [
        "--with", "--with-requirements", "--with-editable", "-p", "--python", "--index", "--index-url", "-i",
        "--extra-index-url", "--default-index", "--constraints", "-c", "--env-file", "--directory", "--project",
        "--config-file", "--python-preference", "--resolution", "--prerelease", "--refresh-package", "--reinstall-package",
    ]
    private static let dockerValueFlags: Set<String> = [
        "-e", "--env", "-v", "--volume", "--mount", "-p", "--publish", "--name", "-w", "--workdir", "-u", "--user",
        "--network", "--net", "--entrypoint", "--env-file", "-l", "--label", "--platform", "--add-host", "--cap-add",
        "--cap-drop", "--device", "-m", "--memory", "--cpus", "--restart", "--pull", "--pid", "--ipc", "--hostname", "-h",
        "--security-opt", "--tmpfs", "--log-driver", "--ulimit", "--group-add", "--cidfile", "--label-file", "--expose",
    ]

    static func parse(command: String, args: [String]) -> Launch? {
        let base = (command as NSString).lastPathComponent.lowercased()
        switch base {
        case "npx", "bunx", "pnpx", "pnx":
            return npmLaunch(runner: base, args: args)
        case "npm":
            guard let first = args.first, ["exec", "x"].contains(first.lowercased()) else { return nil }
            return npmLaunch(runner: "npm exec", args: Array(args.dropFirst()))
        case "pnpm", "yarn":
            guard let first = args.first, first.lowercased() == "dlx" else { return nil }
            return npmLaunch(runner: "\(base) dlx", args: Array(args.dropFirst()))
        case "deno":
            let specs = args.filter { $0.hasPrefix("npm:") }.map { String($0.dropFirst(4)) }
            guard !specs.isEmpty else { return nil }
            return Launch(runner: "deno npm:", unpinned: specs.compactMap { unpinnedName(npmSpec: $0) }, autoYes: false)
        case "uvx":
            return uvxLaunch(runner: "uvx", args: args)
        case "uv":
            guard let first = args.first, first.lowercased() == "tool", args.dropFirst().first?.lowercased() == "run" else { return nil }
            return uvxLaunch(runner: "uv tool run", args: Array(args.dropFirst(2)))
        case "pipx":
            guard let first = args.first, first.lowercased() == "run" else { return nil }
            return uvxLaunch(runner: "pipx run", args: Array(args.dropFirst()))
        case "docker", "podman":
            return dockerLaunch(runner: base, args: args)
        default:
            return nil
        }
    }

    // MARK: npm family

    private static func npmLaunch(runner: String, args: [String]) -> Launch? {
        var autoYes = false
        var bound: [String] = []       // from -p / --package
        var positional: String?
        var endOfFlags = false
        var i = 0
        while i < args.count {
            let a = args[i]
            i += 1
            if !endOfFlags, a == "--" { endOfFlags = true; continue }
            if !endOfFlags, a.hasPrefix("-") {
                let lower = a.lowercased()
                if lower == "-y" || lower == "--yes" { autoYes = true; continue }
                if lower == "-p" || lower == "--package" {
                    if i < args.count { bound.append(args[i]); i += 1 }
                    continue
                }
                if lower.hasPrefix("--package=") { bound.append(String(a.dropFirst("--package=".count))); continue }
                if npmValueFlags.contains(lower) { i += 1 }
                continue
            }
            positional = a
            break // everything after the first operand belongs to the launched program
        }
        // With --package the positional is only the executable name; the bound spec is what is fetched.
        let specs = bound.isEmpty ? (positional.map { [$0] } ?? []) : bound
        let unpinned = specs.compactMap { unpinnedName(npmSpec: $0) }
        guard !specs.isEmpty else { return nil }
        return Launch(runner: runner, unpinned: unpinned, autoYes: autoYes)
    }

    private static func isLocalSpec(_ spec: String) -> Bool {
        spec.hasPrefix(".") || spec.hasPrefix("/") || spec.hasPrefix("~") || spec.hasPrefix("file:")
    }

    /// nil when the spec is pinned (or is a local path); otherwise a printable name for the report.
    static func unpinnedName(npmSpec spec: String) -> String? {
        if spec.isEmpty || isLocalSpec(spec) { return nil }
        // Scoped packages (`@org/name`) are not reported: the scope ties the name to one
        // publisher, which is the part of the risk this check can judge. A scoped package can
        // still change between runs, and pinning it is still the better setup.
        if spec.hasPrefix("@") { return nil }
        if spec.contains("://") || spec.hasPrefix("git+") || spec.hasPrefix("github:") || spec.hasPrefix("gitlab:") {
            let pinnedRef = spec.range(of: #"#[0-9a-f]{7,40}$"#, options: .regularExpression) != nil
            return pinnedRef ? nil : "(non-registry spec)"
        }
        let versionStart = spec.firstIndex(of: "@")
        let name = versionStart.map { String(spec[..<$0]) } ?? spec
        let version = versionStart.map { String(spec[spec.index(after: $0)...]) } ?? ""
        if version.range(of: #"^v?\d+\.\d+\.\d+([-+][0-9A-Za-z.\-+]*)?$"#, options: .regularExpression) != nil { return nil }
        return registryName(name, pattern: #"^[A-Za-z0-9._\-]+$"#)
    }

    // MARK: Python family

    private static func uvxLaunch(runner: String, args: [String]) -> Launch? {
        var from: String?
        var positional: String?
        var i = 0
        while i < args.count {
            let a = args[i]
            i += 1
            if a == "--from" { if i < args.count { from = args[i]; i += 1 }; continue }
            if a.hasPrefix("--from=") { from = String(a.dropFirst("--from=".count)); continue }
            if a.hasPrefix("-") {
                if a.contains("=") { continue }
                if uvxValueFlags.contains(a) { i += 1 }
                continue
            }
            positional = a
            break
        }
        guard let spec = from ?? positional else { return nil }
        let unpinned = unpinnedName(pythonSpec: spec).map { [$0] } ?? []
        return Launch(runner: runner, unpinned: unpinned, autoYes: false)
    }

    static func unpinnedName(pythonSpec spec: String) -> String? {
        if spec.isEmpty || isLocalSpec(spec) { return nil }
        if spec.contains("://") || spec.hasPrefix("git+") {
            let pinnedRef = spec.range(of: #"@[0-9a-f]{7,40}$"#, options: .regularExpression) != nil
            return pinnedRef ? nil : "(non-registry spec)"
        }
        // `pkg==1.2.3` and uvx's `pkg@1.2.3` are exact; ranges, `@latest` and a bare name are not.
        if spec.range(of: #"^[A-Za-z0-9._\-\[\],]+(==|@)v?\d[0-9A-Za-z.\-+!]*$"#, options: .regularExpression) != nil { return nil }
        let nameEnd = spec.firstIndex(where: { "=<>!~@; ".contains($0) }) ?? spec.endIndex
        return registryName(String(spec[..<nameEnd]), pattern: #"^[A-Za-z0-9._\-\[\],]+$"#)
    }

    // MARK: Containers

    private static func dockerLaunch(runner: String, args: [String]) -> Launch? {
        guard let runIndex = args.firstIndex(where: { $0 == "run" || $0 == "create" }) else { return nil }
        var image: String?
        var i = runIndex + 1
        while i < args.count {
            let a = args[i]
            i += 1
            if a.hasPrefix("-") {
                if a.contains("=") { continue }
                if dockerValueFlags.contains(a) { i += 1 }
                continue
            }
            image = a
            break
        }
        guard let image else { return nil }
        let unpinned = unpinnedName(image: image).map { [$0] } ?? []
        return Launch(runner: runner, unpinned: unpinned, autoYes: false)
    }

    static func unpinnedName(image: String) -> String? {
        if image.contains("@sha256:") { return nil }
        var name = image
        // A ":" after the last "/" is a tag; one before it is a registry port (`host:5000/img`).
        if let colon = image.range(of: ":", options: .backwards), !image[colon.upperBound...].contains("/") {
            let tag = image[colon.upperBound...]
            if !tag.isEmpty, tag != "latest" { return nil }
            name = String(image[..<colon.lowerBound])
        }
        return registryName(name, pattern: #"^[A-Za-z0-9._\-/:]+$"#)
    }

    /// Host-level access a `docker run` line grants. Only fixed labels are returned.
    static func containerHostAccess(command: String, args: [String]) -> [String]? {
        let base = (command as NSString).lastPathComponent.lowercased()
        guard base == "docker" || base == "podman", args.contains(where: { $0 == "run" || $0 == "create" }) else { return nil }
        var risks: [String] = []
        func add(_ r: String) { if !risks.contains(r) { risks.append(r) } }
        var i = 0
        while i < args.count {
            let a = args[i]
            i += 1
            let lower = a.lowercased()
            if lower == "--privileged" || lower == "--privileged=true" { add("--privileged") }
            if lower == "--pid=host" || (lower == "--pid" && args.indices.contains(i) && args[i].lowercased() == "host") { add("--pid=host") }
            var volumeValue: String?
            if ["-v", "--volume", "--mount"].contains(lower), args.indices.contains(i) { volumeValue = args[i] }
            else if lower.hasPrefix("--volume=") || lower.hasPrefix("--mount=") { volumeValue = String(a.drop(while: { $0 != "=" }).dropFirst()) }
            else if lower.hasPrefix("-v"), lower.count > 2, !lower.hasPrefix("--") { volumeValue = String(a.dropFirst(2)) }
            if let v = volumeValue?.lowercased() {
                if v.contains("docker.sock") { add("docker.sock mount") }
                else if v.hasPrefix("/:") || v.hasPrefix("source=/,") || v.contains("src=/,") || v.hasPrefix("type=bind,source=/,") || v.hasPrefix("type=bind,src=/,") { add("root filesystem mount") }
            }
        }
        return risks
    }

    private static func registryName(_ name: String, pattern: String) -> String? {
        guard !name.isEmpty, name.count <= 100, name.range(of: pattern, options: .regularExpression) != nil else {
            return "(non-registry spec)"
        }
        return name
    }
}

/// Result payload for `audit_mcp_configs`.
public struct MCPConfigAuditResultPayload: Codable, Equatable {
    public struct FindingPayload: Codable, Equatable {
        public let id: String
        public let severity: String
        public let file: String
        public let server: String?
        public let detail: String
        public let message: String
    }
    public let scannedFileCount: Int
    public let scannedFiles: [String]
    public let serverCount: Int
    /// Files that exist but could not be read or parsed (so they were NOT audited).
    public let unreadableFiles: [String]
    public let findings: [FindingPayload]
}
