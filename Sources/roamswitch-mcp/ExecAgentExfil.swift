// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The command-line side of `exec.agent_sensitive_send` and `exec.agent_sensitive_then_send`: which
/// ancestor is an AI coding agent, which commands send something out, which arguments name a file that
/// should not leave the Mac, and which arguments carry a secret. Pure, so the rules and the tests share it.
/// Only argv is read. A script runtime (`python -c`, `node -e`), `git push`, a file read by the agent's own
/// tools and arguments that are split or encoded are not seen.
enum ExecAgentExfil {

    // MARK: Agent attribution

    static let agentNames: Set<String> = ["claude", "codex", "gemini", "opencode", "aider", "goose", "cursor-agent", "openclaw", "qwen", "crush"]

    /// The agent an executable is, or nil: the lower-cased file name equals an agent name exactly (`codex2` is not
    /// one). Claude Code's own installer names the file by version only (`~/.local/share/claude/versions/2.1.3`),
    /// so the folder two levels up names it then. `argv0` is the first argument as the process was started
    /// (`claude` through a symlink).
    static func agentName(path: String, argv0: String? = nil) -> String? {
        for candidate in [path, argv0].compactMap({ $0 }) {
            let parts = candidate.split(separator: "/").map(String.init)
            guard let last = parts.last else { continue }
            let base = last.lowercased()
            if agentNames.contains(base) { return base }
            if base.allSatisfy({ $0.isNumber || $0 == "." }), parts.count >= 3, parts[parts.count - 2] == "versions" {
                let owner = parts[parts.count - 3].lowercased()
                if agentNames.contains(owner) { return owner }
            }
        }
        return nil
    }

    // MARK: Commands

    /// The lower-cased file name up to its first dot (`nc.openbsd` is `nc`). Digits stay (`base64`, `s3cmd`).
    static func toolName(_ executable: String) -> String {
        String(executable.lowercased().split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
    }

    /// Programs that open a connection to wherever they are told: any exec of one is a send.
    private static let anySendTools: Set<String> = ["ftp", "tftp", "sftp", "nc", "ncat", "netcat", "socat", "telnet"]
    /// Programs that copy to a remote when the last operand names one (a remote source is a download).
    private static let remoteCopyTools: Set<String> = ["scp", "rsync"]
    private static let readTools: Set<String> = [
        "cat", "head", "tail", "less", "more", "cp", "tar", "zip", "7z", "7za", "7zr", "7zz", "gzip", "bzip2", "xz",
        "base64", "xxd", "od", "strings", "grep", "sed", "awk", "dd",
    ]

    static func isTransferTool(_ tool: String) -> Bool {
        anySendTools.contains(tool) || remoteCopyTools.contains(tool)
            || ["curl", "wget", "rclone", "s3cmd", "mc", "aws", "gsutil", "gcloud", "az"].contains(tool)
    }

    static func isReadCommand(_ tool: String, _ args: [String]) -> Bool {
        if readTools.contains(tool) { return true }
        if tool == "openssl" { return args.dropFirst().contains { $0 == "enc" || $0 == "base64" } }
        return false
    }

    /// Options whose value is authentication, not something sent: `-H "Authorization: ..."`, `-u user:pass`.
    private static let authOptions: Set<String> = [
        "-H", "--header", "-u", "--user", "-U", "--proxy-user", "--oauth2-bearer", "--http-user", "--http-password",
        "--password", "--ftp-user", "--ftp-password", "--proxy-password",
    ]
    /// Options whose value names a login file, a config or an output, not material that is sent. Per tool,
    /// because `-F` is a form field for curl and a config file for scp, and `-i` a key for scp and a flag elsewhere.
    private static func nonPayloadOptions(_ tool: String) -> Set<String> {
        switch tool {
        case "curl", "wget":
            return ["-o", "--output", "--output-dir", "-O", "--cert", "-E", "--key", "--cacert", "--capath", "-c", "--cookie-jar",
                    "-D", "--dump-header", "--trace", "--trace-ascii", "-A", "--user-agent", "-m", "--max-time", "-x", "--proxy",
                    "-w", "--write-out", "--connect-timeout", "--retry", "-K", "--config", "--certificate", "--private-key",
                    "--ca-certificate", "-P", "--directory-prefix"]
        case "scp", "sftp": return ["-i", "-F", "-o", "-P", "-S", "-J", "-c", "-l", "-D", "-B", "-b", "-R", "-s"]
        case "rsync": return ["-e", "--rsh", "--rsync-path", "--exclude", "--include", "--exclude-from", "--include-from", "--filter", "-f", "--port", "--log-file", "--password-file"]
        case "rclone": return ["--config", "--log-file", "--exclude", "--include", "--filter"]
        case "s3cmd": return ["-c", "--config", "--exclude", "--include"]
        case "aws": return ["--profile", "--region", "--endpoint-url", "--bucket", "--key", "--output", "--query", "--ca-bundle"]
        case "gsutil": return ["-o", "-h", "-i", "-u"]
        case "gcloud": return ["--project", "--billing-project", "--account"]
        default: return []
        }
    }

    /// Arguments with the value of an auth option removed (`-H x`, `--header=x`, `-Hx`).
    static func withoutAuthValues(_ args: [String]) -> [String] {
        var out: [String] = []
        var skip = false
        for a in args {
            if skip { skip = false; continue }
            if authOptions.contains(a) { skip = true; continue }
            if a.hasPrefix("--"), let eq = a.firstIndex(of: "="), authOptions.contains(String(a[..<eq])) { continue }
            if a.hasPrefix("-H"), !a.hasPrefix("--"), a.count > 2 { continue }
            out.append(a)
        }
        return out
    }

    // MARK: Send forms

    /// Whether this exec sends something out: an upload or a body (`curl -d`, `-T`, `-F`, `-X POST`),
    /// a copy to a remote, a push to a bucket, or a raw connection.
    static func isSend(tool: String, args: [String]) -> Bool {
        let rest = Array(args.dropFirst())
        switch tool {
        case "curl": return curlSends(rest) && !loopbackOnly(tool: tool, rest)
        case "wget": return wgetSends(rest) && !loopbackOnly(tool: tool, rest)
        case _ where anySendTools.contains(tool): return !loopbackOnly(tool: tool, rest)
        case _ where remoteCopyTools.contains(tool):
            return operands(rest, valued: nonPayloadOptions(tool)).last.map { isRemoteOperand($0) } ?? false
        case "rclone":
            return firstOperand(rest, valued: ["--config", "--log-file", "--transfers", "--checkers", "--bwlimit", "--exclude", "--include", "--filter", "--max-age", "--min-age"])
                .map { ["copy", "copyto", "sync", "move", "moveto", "rcat"].contains($0) } ?? false
        case "s3cmd":
            return firstOperand(rest, valued: ["-c", "--config", "--exclude", "--include", "--acl-public"]).map { $0 == "put" || $0 == "sync" } ?? false
        case "mc":
            return firstOperand(rest, valued: ["--config-dir", "-C"]).map { ["cp", "mirror", "pipe"].contains($0) } ?? false
        case "aws": return awsSends(rest)
        case "gsutil":
            let ops = operands(rest, valued: ["-o", "-h", "-i", "-u"])
            return ops.first.map { ["cp", "mv", "rsync"].contains($0) } == true && ops.count >= 3 && ops.last!.hasPrefix("gs://")
        case "gcloud":
            let ops = operands(rest, valued: ["--project", "--billing-project", "--account", "--content-type", "--cache-control", "--storage-class", "--predefined-acl"])
            return ops.count >= 4 && ops[0] == "storage" && ["cp", "mv", "rsync"].contains(ops[1]) && ops.last!.hasPrefix("gs://")
        case "az":
            guard let i = rest.firstIndex(of: "storage"), i + 2 < rest.count else { return false }
            return rest[i + 1] == "blob" && ["upload", "upload-batch", "sync"].contains(rest[i + 2])
        default: return false
        }
    }

    // MARK: Loopback destinations

    /// Whether every destination the command names is this Mac (a local model server, a dev server). With URL
    /// arguments, all of them must be loopback; with none, the first operand is the host. One other URL makes it a send.
    static func loopbackOnly(tool: String, _ rest: [String]) -> Bool {
        let urls = rest.filter { $0.contains("://") }
        if !urls.isEmpty { return urls.allSatisfy { isLoopbackHost(hostOf($0)) } }
        let valued = nonPayloadOptions(tool).union(authOptions).union(curlDataFlags).union(curlSendFlags).union(["-X", "--request", "-p", "-s", "-w", "-i"])
        guard let first = operands(rest, valued: tool == "curl" || tool == "wget" ? valued : []).first else { return false }
        return isLoopbackHost(hostOf(first))
    }

    /// The host of `scheme://user:pass@host:port/path`, `host:port/path` or `[::1]:port`, lower-cased.
    static func hostOf(_ target: String) -> String {
        var t = target
        if let r = t.range(of: "://") { t = String(t[r.upperBound...]) }
        if let slash = t.firstIndex(of: "/") { t = String(t[..<slash]) }
        if let at = t.lastIndex(of: "@") { t = String(t[t.index(after: at)...]) }
        if t.hasPrefix("["), let close = t.firstIndex(of: "]") { return String(t[t.index(after: t.startIndex)..<close]).lowercased() }
        if t.filter({ $0 == ":" }).count == 1, let colon = t.firstIndex(of: ":") { t = String(t[..<colon]) }
        return t.lowercased()
    }

    static func isLoopbackHost(_ host: String) -> Bool {
        if host == "localhost" || host == "::1" || host == "0.0.0.0" { return true }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts[0] == "127" && parts.allSatisfy { Int($0).map { (0...255).contains($0) } ?? false }
    }

    private static let curlDataFlags: Set<String> = ["-d", "--data", "--data-raw", "--data-binary", "--data-urlencode", "--data-ascii", "--json"]
    private static let curlSendFlags: Set<String> = ["-T", "--upload-file", "-F", "--form", "--form-string"]
    private static let curlValuedShort: Set<Character> = ["o", "H", "u", "A", "e", "b", "c", "m", "w", "x", "K", "E", "D", "Q", "r", "Y", "y", "z", "C", "U", "t"]
    private static let curlValuedLong: Set<String> = [
        "--output", "--header", "--user", "--user-agent", "--referer", "--cookie", "--cookie-jar", "--max-time", "--proxy",
        "--write-out", "--config", "--cert", "--key", "--cacert", "--capath", "--connect-timeout", "--retry", "--resolve",
        "--dump-header", "--proxy-user", "--oauth2-bearer", "--output-dir", "--url-query",
    ]

    private static func curlSends(_ rest: [String]) -> Bool {
        var get = false
        var data = false
        var upload = false
        var i = 0
        while i < rest.count {
            let a = rest[i]
            i += 1
            if a == "--" { break }
            if a.hasPrefix("--") {
                let name = a.split(separator: "=", maxSplits: 1).first.map(String.init) ?? a
                let attached = a.contains("=")
                if name == "--get" { get = true }
                else if curlDataFlags.contains(name) { data = true; if !attached { i += 1 } }
                else if curlSendFlags.contains(name) { upload = true; if !attached { i += 1 } }
                else if name == "--request" {
                    let value = attached ? String(a[a.index(after: a.firstIndex(of: "=")!)...]) : (i < rest.count ? rest[i] : "")
                    if !attached { i += 1 }
                    if isSendingMethod(value) { upload = true }
                } else if curlValuedLong.contains(name), !attached { i += 1 }
                continue
            }
            guard a.hasPrefix("-"), a.count > 1 else { continue }
            // A cluster of short flags (`-sSL`, `-sd`, `-XPOST`): the first flag that takes a value ends it.
            let chars = Array(a.dropFirst())
            var k = 0
            while k < chars.count {
                let c = chars[k]
                if c == "G" { get = true }
                else if c == "d" { data = true; if k == chars.count - 1 { i += 1 }; break }
                else if c == "T" || c == "F" { upload = true; if k == chars.count - 1 { i += 1 }; break }
                else if c == "X" {
                    let attached = String(chars[(k + 1)...])
                    let value = attached.isEmpty ? (i < rest.count ? rest[i] : "") : attached
                    if attached.isEmpty { i += 1 }
                    if isSendingMethod(value) { upload = true }
                    break
                } else if curlValuedShort.contains(c) { if k == chars.count - 1 { i += 1 }; break }
                k += 1
            }
        }
        // `-G` turns `-d` into a query string: nothing is sent in a body.
        return upload || (data && !get)
    }

    private static func isSendingMethod(_ m: String) -> Bool { ["PUT", "POST", "PATCH"].contains(m.uppercased()) }

    private static func wgetSends(_ rest: [String]) -> Bool {
        var i = 0
        while i < rest.count {
            let a = rest[i]
            i += 1
            let name = a.split(separator: "=", maxSplits: 1).first.map(String.init) ?? a
            switch name {
            case "--post-data", "--post-file", "--body-data", "--body-file": return true
            case "--method":
                let value = a.contains("=") ? String(a[a.index(after: a.firstIndex(of: "=")!)...]) : (i < rest.count ? rest[i] : "")
                if isSendingMethod(value) { return true }
            default: break
            }
        }
        return false
    }

    private static func awsSends(_ rest: [String]) -> Bool {
        let ops = operands(rest, valued: ["--profile", "--region", "--endpoint-url", "--output", "--query", "--ca-bundle",
                                          "--cli-read-timeout", "--cli-connect-timeout", "--exclude", "--include", "--acl",
                                          "--storage-class", "--sse", "--sse-kms-key-id", "--content-type", "--cache-control"])
        guard ops.count >= 2 else { return false }
        if ops[0] == "s3api" { return ops[1] == "put-object" || ops[1] == "upload-part" }
        guard ops[0] == "s3", ["cp", "mv", "sync"].contains(ops[1]), ops.count >= 4 else { return false }
        return ops.last!.hasPrefix("s3://")
    }

    /// Words that are not options and not the value of one of `valued`.
    private static func operands(_ rest: [String], valued: Set<String>) -> [String] {
        var out: [String] = []
        var skip = false
        for a in rest {
            if skip { skip = false; continue }
            if valued.contains(a) { skip = true; continue }
            if a.hasPrefix("-"), a != "-" { continue }
            out.append(a)
        }
        return out
    }

    private static func firstOperand(_ rest: [String], valued: Set<String>) -> String? { operands(rest, valued: valued).first }

    /// `host:path`, `user@host:path` and `scheme://`. A path with a colon after a slash is local.
    static func isRemoteOperand(_ a: String) -> Bool {
        guard !a.hasPrefix("-") else { return false }
        if a.contains("://") { return a.hasPrefix("scp://") || a.hasPrefix("sftp://") || a.hasPrefix("rsync://") || a.hasPrefix("ssh://") }
        guard let colon = a.firstIndex(of: ":") else { return false }
        return !a[..<colon].contains("/") && colon != a.startIndex
    }

    // MARK: Sensitive paths

    private static let sensitiveParts: [(needle: String, label: String)] = [
        ("/.ssh/", ".ssh"), ("/.aws/", ".aws"), ("/.config/gcloud", "gcloud"), ("/.azure/", ".azure"),
        ("/.kube/config", "kube config"), ("/.docker/config.json", "docker config"), ("/.npmrc", ".npmrc"),
        ("/.netrc", ".netrc"), ("/.git-credentials", ".git-credentials"), ("/.pgpass", ".pgpass"), ("/.gnupg/", ".gnupg"),
        ("/etc/shadow", "/etc/shadow"), ("/etc/ssh/ssh_host_", "ssh host key"), (".bash_history", "shell history"),
        (".zsh_history", "shell history"),
        ("/.claude/.credentials.json", "agent sign-in file"), ("/.codex/auth.json", "agent sign-in file"),
        ("/.gemini/oauth_creds.json", "agent sign-in file"), ("/.local/share/opencode/auth.json", "agent sign-in file"),
        ("/.config/gh/hosts.yml", "agent sign-in file"), ("/.config/github-copilot/", "agent sign-in file"),
        ("/Library/Keychains/", "keychain"), ("/Library/Application Support/Google/Chrome/", "browser store"),
        ("/Library/Cookies/", "browser store"),
    ]
    private static let browserFiles: Set<String> = ["Login Data", "Cookies", "logins.json", "key4.db", "cookies.sqlite"]
    private static let keyPrefixes = ["id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"]

    /// A short name for what `path` is when it should not leave the Mac, else nil. `path` may be written with a
    /// leading `~` or relative to `cwd`. Public keys (`.pub`), `.pem`, `.key` and `.crt` files are common in
    /// ordinary work and do not count.
    static func sensitiveLabel(path: String, cwd: String?) -> String? {
        var p = path
        if !p.hasPrefix("/"), !p.hasPrefix("~"), let cwd, !cwd.isEmpty { p = cwd + "/" + p }
        while p.count > 1, p.hasSuffix("/") { p.removeLast() }
        let base = (p as NSString).lastPathComponent
        if base.hasSuffix(".pub") { return nil }
        let dirForm = p + "/"
        // Plain files in ~/.ssh that hold no private key.
        if dirForm.contains("/.ssh/"), ["config", "known_hosts", "known_hosts.old", "authorized_keys", "authorized_keys2"].contains(base) { return nil }
        for part in sensitiveParts where dirForm.contains(part.needle) { return part.label }
        if keyPrefixes.contains(where: { base.hasPrefix($0) }) { return base }
        if base == ".env" { return ".env" }
        if base.hasPrefix(".env.") {
            let template = [".example", ".sample", ".template", ".dist"].contains { base.hasSuffix($0) }
            return template ? nil : ".env"
        }
        if base == "credentials.json" { return "credentials.json" }
        if base.hasPrefix("service-account"), base.hasSuffix(".json") { return "service account key" }
        if base.hasSuffix(".kdbx") { return "password database" }
        if base.hasSuffix(".p12") || base.hasSuffix(".pfx") { return "certificate with private key" }
        if browserFiles.contains(base) { return "browser store" }
        return nil
    }

    /// The first sensitive label among the arguments a command works on. Option values that only name a login
    /// file or an output, the remote side of a copy, and URLs are not looked at.
    static func sensitiveLabel(tool: String, args: [String], cwd: String?) -> String? {
        let skipped = nonPayloadOptions(tool).union(isTransferTool(tool) ? authOptions : [])
        let remoteSide = remoteCopyTools.contains(tool) || tool == "sftp" || tool == "rclone"
        var candidates: [(arg: String, isFile: Bool)] = []
        var skip = false
        var nextIsFile = false
        for a in args.dropFirst() {
            if skip { skip = false; continue }
            if skipped.contains(a) { skip = true; continue }
            if tool == "curl", a == "-T" || a == "--upload-file" { nextIsFile = true; continue }
            let isFile = nextIsFile
            nextIsFile = false
            if a.contains("://") { continue }
            if remoteSide, isRemoteOperand(a) { continue }
            candidates.append((a, isFile))
        }
        // `cp SOURCE... DESTINATION`: the destination is written, not read (`cp .env.example .env`).
        if tool == "cp" {
            let files = candidates.indices.filter { !candidates[$0].arg.hasPrefix("-") }
            if files.count >= 2, let last = files.last { candidates.remove(at: last) }
        }
        let bareNamesAreFiles = !isTransferTool(tool) || remoteCopyTools.contains(tool) || tool == "sftp" || tool == "rclone"
        for c in candidates {
            if let label = labelOfArgument(c.arg, cwd: cwd, bareIsFile: bareNamesAreFiles || c.isFile) { return label }
        }
        return nil
    }

    /// An argument may be a path (`~/.ssh/id_rsa`), `@path` (`curl -d @file`), `name=@path`, `if=path` or
    /// `-Tpath`: each piece between `=`, `@`, `;` and `,` is tried. A relative word with no dot and no slash
    /// (`POST`) is joined with the working folder only where such a word is a file (`cat credentials`).
    private static func labelOfArgument(_ arg: String, cwd: String?, bareIsFile: Bool) -> String? {
        guard !arg.isEmpty, arg.count <= 1024 else { return nil }
        func test(_ s: String) -> String? {
            let looksLikeFile = s.contains("/") || s.contains(".") || s.hasPrefix("~")
            guard bareIsFile || looksLikeFile else { return sensitiveLabel(path: s, cwd: nil) }
            return sensitiveLabel(path: s, cwd: cwd)
        }
        if !arg.hasPrefix("-"), let label = test(arg) { return label }
        for piece in arg.split(whereSeparator: { "=@;,".contains($0) }) {
            var s = String(piece)
            if s.hasPrefix("-"), !s.hasPrefix("--"), s.count > 2 { s = String(s.dropFirst(2)) }
            guard s != arg, !s.isEmpty, !s.hasPrefix("-") else { continue }
            if let label = test(s) { return label }
            // `curl -d @credentials`: what follows an `@` is a file.
            if arg.contains("@" + s), let label = sensitiveLabel(path: s, cwd: cwd) { return label }
        }
        return nil
    }

    // MARK: Secrets

    private static let loopbackUserinfo = try! NSRegularExpression(
        pattern: #"://[^/\s:@]+:[^@\s/]+@(localhost|127(?:\.\d{1,3}){3}|\[::1\])"#, options: [.caseInsensitive])

    /// Whether any argument carries a value shaped like a secret (a token format, `password=...`, a private key,
    /// a long random string), by the same detector that masks command lines. The value of `-H`/`--header` and of
    /// the other login options is authentication, and a password inside a loopback URL never leaves the Mac.
    static func carriesSecret(_ args: [String]) -> Bool {
        let marker = ExecCommandMasker.matchSentinel
        let kept = withoutAuthValues(args).map { arg -> String in
            let clean = ExecCommandMasker.stripInvisible(arg, maxLength: ExecCommandMasker.premaskLimit)
            let range = NSRange(clean.startIndex..<clean.endIndex, in: clean)
            return loopbackUserinfo.stringByReplacingMatches(in: clean, options: [], range: range, withTemplate: "://$1")
        }
        let masked = ExecCommandMasker.maskArgs(kept, marker: marker, text: { ExecCommandMasker.maskText($0, marker: marker) })
        return masked != kept
    }

    /// The command line for the log, secrets masked.
    static func maskedCommand(_ args: [String]) -> String {
        let kept = args.map { ExecCommandMasker.stripInvisible($0, maxLength: ExecCommandMasker.premaskLimit) }
        return ExecCommandMasker.maskArgs(kept, marker: "****", text: { ExecCommandMasker.maskText($0, marker: "****") }).joined(separator: " ")
    }
}
