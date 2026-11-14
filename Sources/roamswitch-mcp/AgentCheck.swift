// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The destination check an AI coding agent's tool call goes through before it runs (`RoamSwitchMCPServer agent-check`,
/// used as a Claude Code `PreToolUse` hook). Pure logic: the tool call comes in as parsed JSON, the decision comes out.
/// The macOS port of `crates/roamswitch-core/src/agent_check.rs` on Linux: the same rules, run against the same
/// vectors (`RoamSwitchTests/Fixtures/agent_check_vectors.json`, a copy of `data/agent_check_vectors.json`).
///
/// An aid for detection, not a gate that holds. It sees the text of one tool call: a URL, an address, a `host:port` or a
/// credential file named in a `Bash` command line, a `WebFetch` URL, or a string in the arguments of an MCP tool. It does
/// not see the inside of a script file, a value a variable or a command substitution produces at run time, an address
/// split over several commands, base64 that is decoded later, or what an agent does with its own sockets. It does not
/// resolve names: a name is judged as written (the hook runs before every call and has to be quick).
///
/// Decisions, from the strongest: `deny` a cloud metadata address (169.254.169.254, fd00:ec2::254, 100.100.100.200, ...)
/// or a well-known metadata name; `ask` an address on the local malicious-IP list (macOS has no such list yet: the
/// command passes none); `ask` a credential file together with a destination outside this Mac's network in the same
/// call; `ask` an address the agent account's allowlist does not list (Linux Server only: macOS passes none).
/// Loopback and private addresses are allowed.
enum AgentCheck {
    enum Verdict: String { case allow, ask, deny }

    static let reasonMetadata = "metadata_endpoint"
    static let reasonMalicious = "malicious_ip"
    static let reasonCredential = "credential_to_external"
    static let reasonAllowlist = "not_in_agent_allowlist"

    struct Decision: Equatable {
        var verdict: Verdict
        /// Reason keys, strongest first. Nothing else is kept in the audit log.
        var reasons: [String]
        /// One short English sentence for the agent and the person. Empty for `allow`.
        var message: String
        static let allow = Decision(verdict: .allow, reasons: [], message: "")
    }

    /// One entry of an agent account's allowlist: `ADDR`, `ADDR/PREFIX`, `ADDR:PORT`, `[ADDR]:PORT`.
    struct EgressRule: Equatable {
        let cidr: FwdEgress.Cidr
        let port: UInt16?

        static func parse(_ raw: String) -> EgressRule? {
            var text = raw.trimmingCharacters(in: .whitespaces)
            var port: UInt16?
            if text.hasPrefix("[") {
                guard let close = text.firstIndex(of: "]") else { return nil }
                let after = text[text.index(after: close)...]
                if !after.isEmpty {
                    guard after.hasPrefix(":"), let p = UInt16(after.dropFirst()), p != 0 else { return nil }
                    port = p
                }
                text = String(text[text.index(after: text.startIndex)..<close])
            } else if text.filter({ $0 == ":" }).count == 1, let colon = text.firstIndex(of: ":") {
                guard let p = UInt16(text[text.index(after: colon)...]), p != 0 else { return nil }
                port = p
                text = String(text[..<colon])
            }
            guard let cidr = FwdEgress.Cidr.parse(text) else { return nil }
            return EgressRule(cidr: cidr, port: port)
        }
    }

    struct Env {
        /// Which of these public addresses is on the malicious-IP list, if any. Asked only when a call names a public
        /// address, and with those addresses only (`firstListed`). macOS has no such list yet: the command passes none.
        var feed: ([FwdEgress.IP]) -> FwdEgress.IP? = { _ in nil }
        /// `agent_egress_allow` of this agent account, when it is known.
        var allowlist: [EgressRule]? = nil
        /// The working directory of the call (a relative `.env` is judged against it).
        var cwd: String? = nil
    }

    struct Dest: Equatable {
        var host: String
        var port: UInt16?
        /// Outside this Mac's network whatever the text says (a storage bucket, an `rclone` remote).
        var external: Bool
    }

    private struct Found {
        var dests: [Dest] = []
        var creds: [String] = []
        mutating func push(_ d: Dest) { if !dests.contains(d) { dests.append(d) } }
        mutating func push(cred: String) { if !creds.contains(cred) { creds.append(cred) } }
    }

    private static let maxText = 256 * 1024
    private static let maxStrings = 600
    private static let maxDepth = 4

    /// Tools that name a file or take text but never open a connection. Everything else is scanned.
    private static let noDestination: Set<String> = [
        "read", "write", "edit", "multiedit", "notebookedit", "glob", "grep", "ls", "todowrite", "task", "agent",
        "exitplanmode", "enterplanmode", "askuserquestion", "skill", "toolsearch", "slashcommand", "killshell",
        "killbash", "bashoutput", "taskoutput", "taskstop",
    ]

    /// Decides one tool call. `input` is the parsed `tool_input` of the hook's JSON.
    static func check(tool: String, input: Any?, env: Env) -> Decision {
        let lname = tool.lowercased()
        if noDestination.contains(lname) { return .allow }
        var found = Found()
        scanTool(lname, input, env.cwd, &found)
        return decide(found, env)
    }

    // MARK: - Walking the input

    private static func scanTool(_ lname: String, _ input: Any?, _ cwd: String?, _ f: inout Found) {
        guard let obj = input as? [String: Any] else {
            if let s = input as? String { scanString(s, hinted: true, cwd, &f) }
            return
        }
        if let s = obj["command"] as? String {
            scanBash(s, depth: 0, cwd, &f)
            return
        }
        if let a = obj["command"] as? [Any] {
            // Already the words of one command (`["bash", "-lc", "curl ..."]`).
            scanCommand(a.compactMap { $0 as? String }, depth: 0, cwd, &f)
            return
        }
        let networkTool = ["fetch", "http", "request", "navigate", "browse", "download", "curl", "web"].contains { lname.contains($0) }
        var budget = maxStrings
        walk(input as Any, key: "", depth: 0, budget: &budget) { key, s in
            scanString(s, hinted: networkTool || keyIsDestination(key), cwd, &f)
        }
    }

    private static func keyIsDestination(_ key: String) -> Bool {
        let k = key.lowercased()
        let long = ["url", "uri", "endpoint", "host", "hostname", "server", "address", "proxy", "registry", "origin", "remote", "domain", "target"]
        let short = ["ip", "addr"]
        return long.contains { k == $0 || k.hasSuffix($0) || k.hasPrefix($0) }
            || short.contains { k == $0 || k.hasSuffix("_" + $0) || k.hasPrefix($0 + "_") }
    }

    private static func walk(_ v: Any, key: String, depth: Int, budget: inout Int, _ visit: (String, String) -> Void) {
        if budget == 0 || depth > maxDepth + 2 { return }
        if let s = v as? String {
            budget -= 1
            visit(key, cut(s, maxText))
        } else if let a = v as? [Any] {
            for x in a { walk(x, key: key, depth: depth + 1, budget: &budget, visit) }
        } else if let m = v as? [String: Any] {
            for k in m.keys.sorted() { walk(m[k] as Any, key: k, depth: depth + 1, budget: &budget, visit) }
        }
    }

    /// `s` cut to at most `max` UTF-8 bytes at a character boundary (the Linux side cuts at bytes too).
    private static func cut(_ s: String, _ max: Int) -> String {
        if s.utf8.count <= max { return s }
        var out = String.UnicodeScalarView()
        var n = 0
        for sc in s.unicodeScalars {
            let l = String(sc).utf8.count
            if n + l > max { break }
            out.append(sc)
            n += l
        }
        return String(out)
    }

    private static func isSpace(_ s: Unicode.Scalar) -> Bool { s.properties.isWhitespace }
    private static func hasSpace(_ s: String) -> Bool { s.unicodeScalars.contains(where: isSpace) }
    private static func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private static func scanString(_ s: String, hinted: Bool, _ cwd: String?, _ f: inout Found) {
        scanEmbeddedURLs(s, &f)
        let t = trimmed(s)
        if t.utf8.count < 300, !t.isEmpty, !hasSpace(t) {
            if hinted, let d = destFromWord(t) { f.push(d) }
            if let label = credLabel(t, cwd) { f.push(cred: label) }
        }
    }

    // MARK: - Credential files

    /// The label of the credential file a word names. The word, and the pieces of it between `= @ , ; < >` and spaces, are
    /// tried the way the Linux side does; a relative path is joined with the working directory, and also looked at as
    /// if it were below `/` (`.ssh/id_rsa`).
    static func credLabel(_ word: String, _ cwd: String?) -> String? {
        var cands = [word]
        let seps = CharacterSet(charactersIn: "=@,; <>")
        cands += word.components(separatedBy: seps).filter { $0.count > 2 }
        for raw in cands {
            let c = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if c.isEmpty { continue }
            if let l = ExecAgentExfil.sensitiveLabel(path: c, cwd: cwd) { return l }
            if !c.hasPrefix("/"), !c.hasPrefix("~"), let l = ExecAgentExfil.sensitiveLabel(path: "/" + c, cwd: nil) { return l }
        }
        return nil
    }

    // MARK: - Shell text

    /// The lines of `cmd` without the bodies of here-documents.
    static func stripHeredocs(_ cmd: String) -> String {
        var out = ""
        var pending: (tag: String, dash: Bool)?
        for line in cmd.components(separatedBy: "\n") {
            if let p = pending {
                var l = Substring(line)
                if p.dash { while l.hasPrefix("\t") { l = l.dropFirst() } }
                if String(l).trimmingTrailingSpaces() == p.tag { pending = nil }
                continue
            }
            out += line + "\n"
            guard let r = line.range(of: "<<") else { continue }
            var rest = Substring(line[r.upperBound...])
            if rest.hasPrefix("<") { continue } // a here-string
            var dash = false
            if rest.hasPrefix("-") { dash = true; rest = rest.dropFirst() }
            while let c = rest.first, c == " " || c == "\t" { rest = rest.dropFirst() }
            while let c = rest.first, c == "'" || c == "\"" { rest = rest.dropFirst() }
            let tag = String(rest.prefix { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") })
            if !tag.isEmpty { pending = (tag, dash) }
        }
        return out
    }

    /// The words of every command: split on `; & | ( ) \`` and newlines outside quotes; quotes and backslashes removed; the
    /// target of a redirection dropped. `$(...)` and backticks in a word are commands of their own, one level down.
    static func splitCommands(_ cmd: String, depth: Int) -> [[String]] {
        var out: [[String]] = []
        var cur: [String] = []
        var word = String.UnicodeScalarView()
        var inWord = false
        var skipNext = false
        var quote: Unicode.Scalar?
        let chars = Array(cmd.unicodeScalars)
        var i = 0

        func endWord() {
            if inWord {
                if skipNext { skipNext = false } else { cur.append(String(word)) }
                word = String.UnicodeScalarView()
                inWord = false
            }
        }
        func endCmd() {
            endWord()
            if !cur.isEmpty { out.append(cur); cur = [] }
        }

        while i < chars.count {
            let c = chars[i]
            i += 1
            if quote == "'" {
                if c == "'" { quote = nil } else { word.append(c) }
            } else if quote == "\"" {
                if c == "\"" {
                    quote = nil
                } else if c == "\\" {
                    if i < chars.count {
                        let n = chars[i]
                        i += 1
                        if !(n == "\"" || n == "\\" || n == "$" || n == "`") { word.append("\\") }
                        word.append(n)
                    }
                } else {
                    word.append(c)
                }
            } else {
                switch c {
                case "'", "\"":
                    quote = c
                    inWord = true
                case "\\":
                    if i < chars.count {
                        let n = chars[i]
                        i += 1
                        if n != "\n" { word.append(n); inWord = true }
                    }
                case "\n", ";", "|", "&", "(", ")", "`":
                    endCmd()
                    skipNext = false
                case "<", ">":
                    endWord()
                    while i < chars.count, chars[i] == "<" || chars[i] == ">" || chars[i] == "&" { i += 1 }
                    skipNext = true
                    inWord = false
                default:
                    if isSpace(c) {
                        endWord()
                    } else {
                        word.append(c)
                        inWord = true
                    }
                }
            }
        }
        endCmd()

        if depth < maxDepth {
            var nested: [String] = []
            for seg in out { for w in seg { collectSubstitutions(w, &nested) } }
            collectSubstitutions(cmd, &nested)
            for n in Array(Set(nested)).sorted() where n != cmd {
                out.append(contentsOf: splitCommands(n, depth: depth + 1))
            }
        }
        return out
    }

    /// The text inside `$( ... )` and backticks in `s` (the outermost level).
    private static func collectSubstitutions(_ s: String, _ out: inout [String]) {
        let b = Array(s.unicodeScalars)
        var i = 0
        func text(_ a: Int, _ z: Int) -> String {
            var v = String.UnicodeScalarView()
            if a < z { v.append(contentsOf: b[a..<z]) }
            return String(v)
        }
        while i < b.count {
            if b[i] == "$", i + 1 < b.count, b[i + 1] == "(" {
                var depth = 0
                var j = i + 1
                let start = j + 1
                while j < b.count {
                    if b[j] == "(" { depth += 1 } else if b[j] == ")" {
                        depth -= 1
                        if depth == 0 { break }
                    }
                    j += 1
                }
                let end = min(j, b.count)
                if start <= end { out.append(text(start, end)) }
                i = end + 1
            } else if b[i] == "`" {
                var j = i + 1
                while j < b.count, b[j] != "`" { j += 1 }
                out.append(text(i + 1, min(j, b.count)))
                i = j + 1
            } else {
                i += 1
            }
        }
    }

    private static let wrappers: Set<String> = [
        "sudo", "doas", "env", "nohup", "time", "exec", "command", "nice", "ionice", "stdbuf", "timeout", "xargs",
        "setsid", "unbuffer", "builtin", "chronic", "torify", "proxychains",
    ]

    private static func wrapperValueOptions(_ name: String) -> Set<String> {
        switch name {
        case "sudo", "doas": return ["-u", "-g", "-C", "-p", "-h", "-r", "-t", "-T", "-U"]
        case "timeout": return ["-s", "-k"]
        case "nice": return ["-n"]
        case "ionice": return ["-c", "-n", "-p"]
        case "stdbuf": return ["-i", "-o", "-e"]
        case "xargs": return ["-n", "-P", "-I", "-L", "-s", "-d", "-E", "-a"]
        case "env": return ["-u", "-C", "-S"]
        default: return []
        }
    }

    private static func baseName(_ p: String) -> String { p.split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? p }

    private static func isAssignment(_ w: String) -> Bool {
        guard let eq = w.firstIndex(of: "="), eq != w.startIndex else { return false }
        let name = w[..<eq]
        return name.unicodeScalars.allSatisfy { $0.isASCII && ($0.properties.isAlphabetic || ("0"..."9").contains($0) || $0 == "_") }
            && !("0"..."9").contains(w.unicodeScalars.first!)
    }

    /// The program and its arguments, with `VAR=value`, `sudo`, `env`, `timeout 5`, ... taken off the front.
    private static func programOf(_ words: [String]) -> (String, [String])? {
        var i = 0
        while i < words.count {
            let w = words[i]
            if isAssignment(w) { i += 1; continue }
            let name = baseName(w).asciiLowercased()
            if wrappers.contains(name) {
                i += 1
                let withValue = wrapperValueOptions(name)
                while i < words.count {
                    let a = words[i]
                    if a.hasPrefix("-") {
                        i += 1
                        if withValue.contains(a) { i += 1 }
                    } else if name == "timeout", let f = a.unicodeScalars.first, ("0"..."9").contains(f) {
                        i += 1
                        break
                    } else if isAssignment(a) {
                        i += 1
                    } else {
                        break
                    }
                }
                continue
            }
            return (name, Array(words[(i + 1)...]))
        }
        return nil
    }

    private static let textOnly: Set<String> = [
        "echo", "printf", "grep", "egrep", "fgrep", "rg", "ag", "ack", "sed", "awk", "gawk", "cat", "head", "tail", "less",
        "more", "man", "wc", "sort", "uniq", "diff", "ls", "jq", "cut", "tr", "xxd", "od", "base64", "cp", "mv", "rm",
        "mkdir", "touch", "cd", "export", "test",
    ]
    private static let gitLocal: Set<String> = [
        "commit", "log", "diff", "show", "grep", "tag", "stash", "add", "status", "blame", "notes", "branch", "checkout",
        "reset", "rebase", "merge", "restore",
    ]
    private static let urlClients: Set<String> = [
        "curl", "wget", "http", "https", "xh", "aria2c", "axel", "lwp-request", "w3m", "lynx", "links", "elinks", "httpie",
    ]
    private static let hostFirst: Set<String> = ["nc", "ncat", "netcat", "telnet", "ping", "ping6", "traceroute", "tracepath", "mtr", "nmap", "dig"]
    private static let hostAny: Set<String> = ["nslookup", "host", "whois"]
    private static let sshLike: Set<String> = ["ssh", "scp", "sftp", "rsync", "mosh", "ssh-copy-id"]

    private static func scanBash(_ cmd: String, depth: Int, _ cwd: String?, _ f: inout Found) {
        let text = stripHeredocs(cut(cmd, maxText))
        for words in splitCommands(text, depth: 0) { scanCommand(words, depth: depth, cwd, &f) }
    }

    private static func scanCommand(_ words: [String], depth: Int, _ cwd: String?, _ f: inout Found) {
        // Credential files named as a word of any command (not after `-i`, an identity file ssh reads and does not send).
        var prevIdentity = false
        for w in words {
            let skip = prevIdentity
            prevIdentity = ["-i", "-I", "--identity", "--identity-file"].contains(w)
            if skip || hasSpace(w) { continue }
            if let label = credLabel(w, cwd) { f.push(cred: label) }
        }
        guard let (prog, args) = programOf(words) else { return }
        if ["bash", "sh", "zsh", "dash", "ksh", "fish", "su"].contains(prog), depth < maxDepth {
            if let i = args.firstIndex(where: { $0.hasPrefix("-") && !$0.hasPrefix("--") && $0.contains("c") }), i + 1 < args.count {
                scanBash(args[i + 1], depth: depth + 1, cwd, &f)
                return
            }
        }
        if prog == "eval", depth < maxDepth {
            scanBash(args.joined(separator: " "), depth: depth + 1, cwd, &f)
            return
        }
        if prog == "git" {
            var sub: String?
            var k = 0
            while k < args.count {
                if ["-C", "-c", "--git-dir", "--work-tree"].contains(args[k]) { k += 2 } else if args[k].hasPrefix("-") { k += 1 } else { sub = args[k]; break }
            }
            if let s = sub, gitLocal.contains(s) { return }
        }
        if textOnly.contains(prog) { return }
        if urlClients.contains(prog) {
            scanURLClient(prog, args, &f)
        } else if hostFirst.contains(prog) {
            scanHostTool(prog, args, &f)
        } else if hostAny.contains(prog) {
            for a in args where !a.hasPrefix("-") {
                if let d = destFromWord(String(a.drop(while: { $0 == "@" }))) { f.push(d) }
            }
        } else if sshLike.contains(prog) {
            scanSSHLike(prog, args, &f)
        } else if prog == "socat" {
            for a in args { scanSocatSpec(a, &f) }
        } else if ["pip", "pip3", "pipx", "uv", "poetry", "pdm", "pipenv", "twine"].contains(prog) {
            scanOptionURLs(args, ["--index-url", "-i", "--extra-index-url", "--trusted-host", "--find-links", "-f", "--repository-url", "--repository"], &f)
        } else if ["npm", "pnpm", "yarn", "bun", "npx", "corepack"].contains(prog) {
            scanOptionURLs(args, ["--registry"], &f)
            if let i = args.firstIndex(where: { $0 == "registry" || $0.hasSuffix(":registry") }), i + 1 < args.count, let d = destFromWord(args[i + 1]) { f.push(d) }
        } else if prog == "rclone" {
            for a in args where !a.hasPrefix("-") {
                if a.contains(":"), !a.hasPrefix("/"), !a.hasPrefix(".") {
                    let name = a.split(separator: ":", omittingEmptySubsequences: false).first.map(String.init) ?? ""
                    f.push(Dest(host: name.asciiLowercased(), port: nil, external: true))
                }
            }
        } else if prog == "git" {
            for a in args { if let d = scpStyle(a) ?? urlDest(a) { f.push(d) } }
        } else {
            for a in args { if let d = scpStyleUserOnly(a) { f.push(d) } }
        }
        // Any command: a URL inside a word.
        for a in words { scanEmbeddedURLs(a, &f) }
    }

    /// `user@host:path` (only with the `@`: `a:b` is too often something else).
    private static func scpStyleUserOnly(_ w: String) -> Dest? {
        if w.hasPrefix("-") || w.contains("://") { return nil }
        guard let colon = w.firstIndex(of: ":") else { return nil }
        let userHost = String(w[..<colon])
        guard userHost.contains("@") else { return nil }
        let host = userHost.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? userHost
        return hostDest(host, nil, false)
    }

    private static func scpStyle(_ w: String) -> Dest? {
        if w.hasPrefix("-") || w.hasPrefix("/") || w.hasPrefix(".") || w.hasPrefix("~") || w.contains("://") { return nil }
        if w.hasPrefix("[") {
            guard let close = w.firstIndex(of: "]") else { return nil }
            return hostDest(String(w[w.index(after: w.startIndex)..<close]), nil, false)
        }
        guard let colon = w.firstIndex(of: ":") else { return nil }
        let left = String(w[..<colon])
        let right = w[w.index(after: colon)...]
        if left.isEmpty || right.hasPrefix("//") { return nil }
        let host = left.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? left
        if host.hasPrefix("["), host.hasSuffix("]") { return hostDest(String(host.dropFirst().dropLast()), nil, false) }
        if host.unicodeScalars.count < 2 || host.contains(where: { "=\\\"'()$".contains($0) }) { return nil }
        return hostDest(host, nil, false)
    }

    private static let curlTakesValue: Set<String> = [
        "-H", "--header", "-d", "--data", "--data-raw", "--data-binary", "--data-urlencode", "--data-ascii", "-o",
        "--output", "-O", "-u", "--user", "-X", "--request", "-A", "--user-agent", "-e", "--referer", "-b", "--cookie",
        "-c", "--cookie-jar", "-F", "--form", "-T", "--upload-file", "-K", "--config", "-w", "--write-out", "--cert",
        "--key", "--cacert", "-m", "--max-time", "--output-dir", "--limit-rate",
    ]

    private static func scanURLClient(_ prog: String, _ args: [String], _ f: inout Found) {
        var i = 0
        while i < args.count {
            let a = args[i]
            if a.hasPrefix("--url=") || a.hasPrefix("--proxy=") {
                let v = String(a[a.index(after: a.firstIndex(of: "=")!)...])
                if let d = destFromWord(v) { f.push(d) }
            } else if a == "--url" || a == "-x" || a == "--proxy" || a == "--socks5" {
                if i + 1 < args.count, let d = destFromWord(args[i + 1]) { f.push(d) }
                i += 1
            } else if a.hasPrefix("-") {
                if curlTakesValue.contains(a), !a.contains("=") { i += 1 }
            } else if let d = destFromWord(a) {
                if !(["http", "https", "xh"].contains(prog) && a.contains("=") && !a.contains("://")) { f.push(d) }
            }
            i += 1
        }
    }

    private static func scanHostTool(_ prog: String, _ args: [String], _ f: inout Found) {
        let takesValue: Set<String> = ["-p", "-s", "-w", "-i", "-q", "-T", "-X", "-x", "-c", "-m", "-I", "-t"]
        let listening = args.contains { $0 == "-l" || ($0.hasPrefix("-") && !$0.hasPrefix("--") && $0.contains("l")) }
        if listening, ["nc", "ncat", "netcat"].contains(prog) { return }
        var host: String?
        var port: UInt16?
        var portSet = false
        var i = 0
        while i < args.count {
            let a = args[i]
            if a.hasPrefix("-") {
                if takesValue.contains(a) { i += 1 }
            } else if host == nil {
                host = a
            } else if !portSet {
                port = UInt16(a)
                portSet = true
            }
            i += 1
        }
        if let h = host, var d = destFromWord(String(h.drop(while: { $0 == "@" }))) {
            if d.port == nil { d.port = port }
            f.push(d)
        }
    }

    private static func scanSSHLike(_ prog: String, _ args: [String], _ f: inout Found) {
        let takesValue: Set<String> = [
            "-p", "-l", "-i", "-o", "-F", "-L", "-R", "-D", "-b", "-c", "-E", "-e", "-I", "-m", "-O", "-Q", "-S", "-W",
            "-w", "-B", "-P", "-J", "--rsh", "--port",
        ]
        var i = 0
        var firstDone = false
        while i < args.count {
            let a = args[i]
            if a == "-J" {
                if i + 1 < args.count {
                    for part in args[i + 1].split(separator: ",", omittingEmptySubsequences: false) {
                        let h = part.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? String(part)
                        if let d = destFromWord(h) { f.push(d) }
                    }
                }
                i += 2
                continue
            }
            if a.hasPrefix("-") {
                if takesValue.contains(a) { i += 2; continue }
            } else if ["ssh", "sftp", "mosh", "ssh-copy-id"].contains(prog) {
                if !firstDone {
                    firstDone = true
                    let w = a.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? a
                    if let d = urlDest(a) ?? destFromWord(w) { f.push(d) }
                }
            } else if let d = urlDest(a) ?? scpStyle(a) {
                f.push(d)
            }
            i += 1
        }
    }

    private static func scanSocatSpec(_ a: String, _ f: inout Found) {
        let lower = a.asciiLowercased()
        for p in ["tcp:", "tcp4:", "tcp6:", "udp:", "udp4:", "udp6:", "ssl:", "openssl:", "openssl-connect:", "tcp-connect:"] where lower.hasPrefix(p) {
            var rest = String(lower.dropFirst(p.count))
            if let comma = rest.firstIndex(of: ",") { rest = String(rest[..<comma]) }
            if let d = destFromWord(rest) { f.push(d) }
        }
    }

    private static func scanOptionURLs(_ args: [String], _ names: [String], _ f: inout Found) {
        for (i, a) in args.enumerated() {
            var value: String?
            for n in names {
                if a.hasPrefix(n + "=") { value = String(a.dropFirst(n.count + 1)) } else if a == n { value = i + 1 < args.count ? args[i + 1] : nil }
            }
            if let v = value, let d = destFromWord(v) { f.push(d) }
            if let d = urlDest(a) { f.push(d) }
        }
    }

    // MARK: - URLs and hosts

    private static func isSchemeChar(_ c: Unicode.Scalar) -> Bool {
        c.isASCII && (c.properties.isAlphabetic || ("0"..."9").contains(c) || c == "+" || c == "." || c == "-")
    }

    /// Every `scheme://authority` inside `s`.
    private static func scanEmbeddedURLs(_ s: String, _ f: inout Found) {
        var rest = Substring(s)
        while let r = rest.range(of: "://") {
            let before = rest[..<r.lowerBound]
            var schemeLen = 0
            for c in before.unicodeScalars.reversed() { if isSchemeChar(c) { schemeLen += 1 } else { break } }
            let after = rest[r.upperBound...]
            if schemeLen > 0 {
                var sv = String.UnicodeScalarView()
                sv.append(contentsOf: Array(before.unicodeScalars).suffix(schemeLen))
                let scheme = String(sv).asciiLowercased()
                let (auth, _) = splitAuthority(after)
                for d in authorityDests(auth, scheme) { f.push(d) }
            }
            rest = after
        }
    }

    private static func isAuthorityChar(_ c: Unicode.Scalar) -> Bool {
        c.isASCII && (c.properties.isAlphabetic || ("0"..."9").contains(c) || ".-_~%:@[]+!$*,;=".unicodeScalars.contains(c))
    }

    private static func splitAuthority(_ after: Substring) -> (String, Substring) {
        let scalars = after.unicodeScalars
        var end = scalars.startIndex
        while end < scalars.endIndex, isAuthorityChar(scalars[end]) { end = scalars.index(after: end) }
        return (String(after[..<end]), after[end...])
    }

    private static func defaultPort(_ scheme: String) -> UInt16? {
        switch scheme {
        case "http", "ws": return 80
        case "https", "wss": return 443
        case "ssh", "sftp", "scp": return 22
        case "git": return 9418
        case "ftp": return 21
        case "rsync": return 873
        default: return nil
        }
    }

    private static let externalSchemes: Set<String> = ["s3", "s3a", "s3n", "gs", "gcs", "az", "azure", "abfs", "abfss", "wasbs", "swift", "oss"]

    private static func authorityDests(_ auth: String, _ scheme: String) -> [Dest] {
        var out: [Dest] = []
        if scheme == "file" || auth.isEmpty { return out }
        var userinfo: String?
        var hostport = auth
        if let at = auth.lastIndex(of: "@") {
            userinfo = String(auth[..<at])
            hostport = String(auth[auth.index(after: at)...])
        }
        let external = externalSchemes.contains(scheme)
        let (host, port) = splitHostPort(hostport)
        if let d = hostDest(host, port ?? defaultPort(scheme), external) { out.append(d) }
        if let u = userinfo {
            let name = u.split(separator: ":", omittingEmptySubsequences: false).first.map(String.init) ?? u
            if !name.isEmpty, decodedIP(name) != nil, let d = hostDest(name, nil, external) { out.append(d) }
        }
        return out
    }

    private static func splitHostPort(_ hostport: String) -> (String, UInt16?) {
        if hostport.hasPrefix("[") {
            let rest = hostport.dropFirst()
            if let close = rest.firstIndex(of: "]") {
                let inner = String(rest[..<close])
                let after = rest[rest.index(after: close)...]
                let port = after.hasPrefix(":") ? UInt16(after.dropFirst()) : nil
                return (inner, port)
            }
            return (String(rest), nil)
        }
        if hostport.filter({ $0 == ":" }).count == 1, let colon = hostport.firstIndex(of: ":") {
            return (String(hostport[..<colon]), UInt16(hostport[hostport.index(after: colon)...]))
        }
        return (hostport, nil)
    }

    private static func urlDest(_ w: String) -> Dest? {
        guard let r = w.range(of: "://") else { return nil }
        var scheme = String(w[..<r.lowerBound]).asciiLowercased()
        if scheme.isEmpty || !scheme.unicodeScalars.allSatisfy(isSchemeChar) { return nil }
        if let plus = scheme.lastIndex(of: "+") { scheme = String(scheme[scheme.index(after: plus)...]) }
        let (auth, _) = splitAuthority(w[r.upperBound...])
        return authorityDests(auth, scheme).first
    }

    private static func destFromWord(_ raw: String) -> Dest? {
        var w = trimmed(raw)
        w = w.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        if w.isEmpty || w.hasPrefix("-") { return nil }
        if w.hasPrefix("/") && !w.hasPrefix("//") { return nil }
        if w.hasPrefix(".") && !w.hasPrefix("..") && w.unicodeScalars.count < 2 { return nil }
        if w.contains("://") { return urlDest(w) }
        if w.hasPrefix("//") { w = String(w.dropFirst(2)) }
        let (auth, _) = splitAuthority(Substring(w))
        if auth.isEmpty || w.hasPrefix("~") { return nil }
        let hostport = auth.split(separator: "@", omittingEmptySubsequences: false).last.map(String.init) ?? auth
        let (host, port) = splitHostPort(hostport)
        return hostDest(host, port, false)
    }

    private static func cleanHost(_ host: String) -> String? {
        var h = trimmed(host)
        while h.hasPrefix("[") { h.removeFirst() }
        while h.hasSuffix("]") { h.removeLast() }
        if h.isEmpty || h.utf8.count > 300 { return nil }
        if !h.contains(":"), h.contains("%") {
            guard let d = percentDecode(h) else { return nil }
            h = d
        }
        while h.hasSuffix(".") { h.removeLast() }
        h = h.asciiLowercased()
        if h.isEmpty { return nil }
        let ok = h.unicodeScalars.allSatisfy { $0.isASCII && ($0.properties.isAlphabetic || ("0"..."9").contains($0) || ".-_:%".unicodeScalars.contains($0)) }
        return ok ? h : nil
    }

    private static func percentDecode(_ s: String) -> String? {
        let b = Array(s.utf8)
        var out: [UInt8] = []
        var i = 0
        while i < b.count {
            if b[i] == UInt8(ascii: "%") {
                guard i + 3 <= b.count, let v = UInt8(String(decoding: b[(i + 1)..<(i + 3)], as: UTF8.self), radix: 16) else { return nil }
                out.append(v)
                i += 3
            } else {
                out.append(b[i])
                i += 1
            }
        }
        guard out.allSatisfy({ $0 < 0x80 }) else { return nil }
        return String(decoding: out, as: UTF8.self)
    }

    private static func hostDest(_ host: String, _ port: UInt16?, _ external: Bool) -> Dest? {
        guard let h = cleanHost(host) else { return nil }
        return Dest(host: h, port: port, external: external)
    }

    private static func decodedIP(_ host: String) -> FwdEgress.IP? {
        guard let h = cleanHost(host) else { return nil }
        return ipOfHost(h)
    }

    /// The address a host text stands for: any notation of an address, or `a.b.c.d.nip.io` and its relatives.
    private static func ipOfHost(_ h: String) -> FwdEgress.IP? {
        if let ip = FwdEgress.parseHostIP(h) { return ip }
        for suffix in [".nip.io", ".sslip.io", ".xip.io"] where h.hasSuffix(suffix) {
            let prefix = String(h.dropLast(suffix.count)).replacingOccurrences(of: "-", with: ".")
            let labels = prefix.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            if labels.count >= 4 {
                let tail = labels.suffix(4)
                let octets = tail.compactMap { l -> UInt8? in
                    // Rust's `Ipv4Addr::from_str`: decimal only, no sign, no leading zero, at most three digits.
                    guard !l.isEmpty, l.count <= 3, l.unicodeScalars.allSatisfy({ ("0"..."9").contains($0) }), !(l.count > 1 && l.hasPrefix("0")) else { return nil }
                    return UInt8(l)
                }
                if octets.count == 4 { return .v4(octets) }
            }
        }
        return nil
    }

    private static let metadataNames: Set<String> = [
        "metadata.google.internal", "metadata.goog", "instance-data", "instance-data.ec2.internal", "metadata.tencentyun.com",
    ]
    private static let internalSuffixes = [".localhost", ".local", ".lan", ".internal", ".home.arpa", ".localdomain", ".test", ".example", ".svc"]

    private enum Kind { case metadata, local, privateNet, publicNet }

    private static func kindOf(_ d: Dest) -> (Kind, FwdEgress.IP?) {
        if let ip = ipOfHost(d.host) {
            switch FwdEgress.classify(ip) {
            case .metadata?: return (.metadata, ip)
            case .loopback?, .unspecified?: return (.local, ip)
            case .some: return (.privateNet, ip)
            case nil: return (.publicNet, ip)
            }
        }
        let h = d.host
        if metadataNames.contains(h) { return (.metadata, nil) }
        if h == "localhost" || h.hasSuffix(".localhost") { return (.local, nil) }
        if d.external { return (.publicNet, nil) }
        if !h.contains(".") || internalSuffixes.contains(where: { h.hasSuffix($0) }) { return (.privateNet, nil) }
        return (.publicNet, nil)
    }

    // MARK: - Decision

    private static func shown(_ s: String) -> String {
        let clean = ExecCommandMasker.stripInvisible(s)
        return clean.count > 80 ? String(clean.prefix(79)) + "…" : clean
    }

    private static func decide(_ f: Found, _ env: Env) -> Decision {
        if f.dests.isEmpty { return .allow }
        let kinds = f.dests.map(kindOf)
        // 1. metadata
        if let i = kinds.firstIndex(where: { $0.0 == .metadata }) {
            return Decision(
                verdict: .deny, reasons: [reasonMetadata],
                message: "Blocked: this call reaches a cloud metadata address (\(shown(f.dests[i].host))). It can return the credentials of this machine's cloud role.")
        }
        // 2. malicious-IP list
        let publicIPs = kinds.compactMap { $0.0 == .publicNet ? $0.1 : nil }
        if !publicIPs.isEmpty {
            if let ip = env.feed(publicIPs) {
                return Decision(verdict: .ask, reasons: [reasonMalicious], message: "\(ip.description) is on the malicious IP list. Confirm that this call should reach it.")
            }
        }
        var reasons: [String] = []
        var message = ""
        // 3. credential + outside destination
        if let label = f.creds.first, let i = kinds.firstIndex(where: { $0.0 == .publicNet }) {
            reasons.append(reasonCredential)
            message = "This call names a credential file (\(label)) and also reaches \(shown(f.dests[i].host)). Confirm that this credential should leave the machine."
        }
        // 4. the agent account's allowlist
        if let rules = env.allowlist {
            for (d, k) in zip(f.dests, kinds) {
                guard k.0 != .local, let ip = k.1 else { continue }
                let allowed = rules.contains { $0.cidr.contains(ip) && ($0.port == nil || $0.port == d.port) }
                if !allowed {
                    reasons.append(reasonAllowlist)
                    if message.isEmpty {
                        message = "\(shown(d.host)) is not in this account's allowed destinations (agent_egress_allow), so the network will drop it."
                    }
                    break
                }
            }
        }
        if reasons.isEmpty { return .allow }
        return Decision(verdict: .ask, reasons: reasons, message: message)
    }

    /// The first of `ips` that one of `lines` lists: an address (`203.0.113.9`) or a network (`203.0.113.0/24`), one per line,
    /// `#` and `;` starting a comment, the first word of a line being the entry (a hit count after it is ignored). A network
    /// wider than /8 (IPv4) or /16 (IPv6) is not used: an unsigned list must not be able to match everything. A line that is
    /// not an address or a network is skipped. The same rules as Linux `first_listed`.
    static func firstListed(_ lines: [String], _ ips: [FwdEgress.IP]) -> FwdEgress.IP? {
        // An IPv4 address written as an IPv6 one is looked up as the IPv4 address.
        let norm: [FwdEgress.IP] = ips.map { ip in
            if case .v6(let o) = ip, o[0..<10].allSatisfy({ $0 == 0 }), o[10] == 0xff, o[11] == 0xff { return .v4(Array(o[12..<16])) }
            return ip
        }
        let text = norm.map { $0.description }
        for raw in lines {
            let body = raw.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "#" || $0 == ";" }).first.map(String.init) ?? ""
            guard let entry = body.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) else { continue }
            if !entry.contains("/"), !entry.contains(":") {
                if let i = text.firstIndex(of: entry) { return norm[i] }
                continue
            }
            if let slash = entry.firstIndex(of: "/") {
                let addr = entry[..<slash]
                guard let p = Int(entry[entry.index(after: slash)...]) else { continue }
                if addr.contains(":") ? p < 16 : p < 8 { continue }
            }
            if let c = FwdEgress.Cidr.parse(entry), let ip = norm.first(where: { c.contains($0) }) { return ip }
        }
        return nil
    }

    /// A tool name made safe to keep in the audit log: at most 80 characters of `A-Za-z0-9_.:-`.
    static func logToolName(_ name: String) -> String {
        String(name.unicodeScalars.prefix(80).map { c in
            (c.isASCII && (c.properties.isAlphabetic || ("0"..."9").contains(c))) || c == "_" || c == "." || c == ":" || c == "-" ? Character(c) : "_"
        })
    }

    /// The `PreToolUse` hook answer for a decision, or nil for `allow` (the hook prints nothing: an explicit `allow` would
    /// skip the permission prompt the person would otherwise see).
    static func hookOutput(_ d: Decision) -> String? {
        if d.verdict == .allow { return nil }
        let obj: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PreToolUse",
                "permissionDecision": d.verdict.rawValue,
                "permissionDecisionReason": d.message,
            ] as [String: Any]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .withoutEscapingSlashes]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The `settings.json` fragment to paste, with `program` as the command.
    static func hookConfigJSON(program: String) -> String {
        let obj: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    [
                        "matcher": "Bash|WebFetch|WebSearch|mcp__.*",
                        "hooks": [["type": "command", "command": "\(program) agent-check", "timeout": 10] as [String: Any]],
                    ] as [String: Any]
                ]
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

private extension String {
    /// ASCII letters to lower case, every other scalar as it is (Rust's `to_ascii_lowercase`).
    func asciiLowercased() -> String {
        var v = String.UnicodeScalarView()
        for c in unicodeScalars {
            if c.value >= 0x41 && c.value <= 0x5A { v.append(Unicode.Scalar(c.value + 32)!) } else { v.append(c) }
        }
        return String(v)
    }

    func trimmingTrailingSpaces() -> String {
        var s = self
        while let l = s.last, l.isWhitespace { s.removeLast() }
        return s
    }
}
