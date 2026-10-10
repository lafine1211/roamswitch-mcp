// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.11.4 (build 151).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Secret masking for exec-recorder command lines, shared by two callers that
// must agree on what counts as a secret:
//   * the MCP output path (`ExecOutputSanitizer`, RoamSwitch / MCP server), which
//     replaces a secret with `****` in what the LLM is shown, and
//   * the helper's `search_exec_events` text match (`ExecLogQuery.matches` with
//     `maskedTextMatch`), which must compare the query against the *masked* command
//     line. Matching against the raw line would let a caller recover a secret one
//     character at a time from "did this query hit?" (an oracle), even though the
//     output itself is masked.
//
// The helper target only compiles `Shared/`, so everything the match side needs
// lives here: the structural rules (URL credentials, bearer/basic, `name=value`,
// `--flag value`, argv flag/value pairs), the known token formats (a copy of
// `SecretLeakScanning`'s patterns -- keep in sync, see below) and the crypto key /
// BIP39 detection (`CryptoSecretDetection`, also in `Shared/`).
//
// Every entry point takes the `marker` that replaces a secret. Output uses
// `****`; matching uses `matchSentinel`, a control character that no query can
// contain (queries are stripped of control characters first), so a query can never
// match "the masked part" either, not even by typing `****`.
public enum ExecCommandMasker {
    /// Replaces a masked span in the haystack. `stripInvisible` removes every
    /// control character, so a (sanitized) query can never contain it.
    public static let matchSentinel = "\u{1}"

    /// Shortest query the MCP path accepts (shorter ones are too cheap a probe).
    public static let minQueryLength = 3

    /// Pre-mask cap per string: above the recorder's own per-string limits so the
    /// masker sees whole values, and a hostile argument can't drive regex cost.
    public static let premaskLimit = 1024

    // MARK: - Sanitizing

    /// Control characters (newline/tab/CR become a single space), bidi controls,
    /// zero-width and other invisible format characters are dropped -- the same
    /// classes `MCPUntrustedText.sanitize` drops, so an invisible character can't
    /// hide a secret from the masker. `maxLength` (characters) cuts without a marker.
    public static func stripInvisible(_ text: String, maxLength: Int? = nil) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.properties.generalCategory {
            case .control:
                if scalar == "\n" || scalar == "\t" || scalar == "\r" { scalars.append(" ") }
            case .format, .lineSeparator, .paragraphSeparator, .privateUse, .unassigned:
                continue
            default:
                scalars.append(scalar)
            }
        }
        let cleaned = String(scalars)
        guard let maxLength, cleaned.count > maxLength else { return cleaned }
        return String(cleaned.prefix(maxLength))
    }

    // MARK: - Flag / argv masking

    private static let sensitiveWords = ["token", "secret", "password", "passwd", "passphrase", "apikey", "api-key", "api_key", "credential", "authorization", "private-key", "private_key"]

    /// `--api-key`, `-token`, `--client-secret` ... (name without the leading dashes).
    /// `--password-stdin` / `--no-password` style flags carry no secret value.
    public static func isSensitiveFlagName(_ rawName: String) -> Bool {
        let name = rawName.lowercased()
        if name.hasSuffix("stdin") || name.hasPrefix("no-") || name.hasSuffix("-file") || name.hasSuffix("-path") { return false }
        if name == "pass" || name == "auth" || name == "passin" || name == "passout" || name == "pwd" { return true }
        return sensitiveWords.contains { name.contains($0) }
    }

    private enum Pending { case none, full, userColon }

    /// `-p` is a password flag only for some programs (`mkdir -p`, `ssh -p 22`, `docker run -p 80:80`
    /// are not), so it is interpreted per command. mysql-family clients take the password attached
    /// (`-pSECRET`; a lone `-p` prompts and the next word is the database name). `sshpass` and
    /// `docker|podman|nerdctl|buildah login` accept both `-p SECRET` and `-pSECRET`.
    private static let attachedPasswordCommands: Set<String> = ["mysql", "mysqldump", "mysqladmin", "mysqlimport", "mysqlcheck", "mysqlpump", "mysqlshow", "mariadb", "mariadb-dump", "mariadb-admin", "mariadb-import", "mariadb-check", "mariadb-show"]
    private static let spacedPasswordCommands: Set<String> = ["sshpass"]
    private static let loginCommands: Set<String> = ["docker", "podman", "nerdctl", "buildah", "skopeo"]

    private enum ShortPassword { case none, attached, attachedOrSpaced }

    /// `args` starts at the effective command (after wrappers / interpreters).
    private static func shortPasswordMode(args: ArraySlice<String>) -> ShortPassword {
        guard let first = args.first else { return .none }
        let cmd = baseName(first)
        if attachedPasswordCommands.contains(cmd) { return .attached }
        if spacedPasswordCommands.contains(cmd) { return .attachedOrSpaced }
        if loginCommands.contains(cmd), args.contains("login") { return .attachedOrSpaced }
        return .none
    }

    private static func baseName(_ s: String) -> String { (s as NSString).lastPathComponent.lowercased() }

    // MARK: - Effective command (wrappers / interpreters)

    /// Wrapper -> options that take a separate value, and how many positionals follow the options.
    private static let wrappers: [String: (valued: Set<String>, positional: Int)] = [
        "sudo": (["-u", "-g", "-h", "-p", "-C", "-D", "-R", "-T", "-U", "-r", "-t", "--user", "--group", "--host", "--prompt", "--chdir", "--role", "--type"], 0),
        "env": (["-u", "-C", "-S", "-P", "--unset", "--chdir"], 0),
        "nohup": ([], 0),
        "nice": (["-n", "--adjustment"], 0),
        "time": (["-f", "-o", "--format", "--output"], 0),
        "timeout": (["-s", "-k", "--signal", "--kill-after"], 1),
        "command": ([], 0),
        "exec": (["-a"], 0),
        "xargs": (["-I", "-n", "-P", "-L", "-s", "-d", "-E", "-a", "-J"], 0),
        "stdbuf": (["-i", "-o", "-e"], 0),
        "caffeinate": (["-t", "-w"], 0),
        "arch": (["-arch"], 0),
    ]
    private static let shells: Set<String> = ["sh", "bash", "zsh", "dash", "ksh", "fish"]
    private static let otherInterpreters: Set<String> = ["ruby", "perl", "node", "php"]
    private static let interpreterValued: Set<String> = ["-W", "-X", "-r", "-I", "-M", "-o", "--require", "-d", "-n", "-E"]

    private static func isInterpreter(_ name: String) -> Bool {
        if shells.contains(name) || otherInterpreters.contains(name) { return true }
        guard name.hasPrefix("python") else { return false }
        return name.dropFirst(6).allSatisfy { $0.isNumber || $0 == "." }
    }

    private static func isAssignment(_ s: String) -> Bool {
        guard let eq = s.firstIndex(of: "="), eq != s.startIndex else { return false }
        let name = s[..<eq]
        guard let f = name.first, f.isLetter || f == "_" else { return false }
        return name.allSatisfy { ($0.isASCII && ($0.isLetter || $0.isNumber)) || $0 == "_" }
    }

    /// Index of the command whose rules apply, skipping known wrappers and interpreters
    /// (`/bin/sh ./mysql -pX` -> `./mysql`; `sudo env A=1 mysql ...` -> `mysql`). `shellString` is the
    /// index of the `-c` body when the effective command is a shell run with `-c`.
    static func effectiveCommand(_ args: [String], allowAssignments: Bool = false) -> (index: Int, shellString: Int?) {
        let n = args.count
        var i = 0
        if allowAssignments { while i < n, isAssignment(args[i]) { i += 1 } }
        while i < n {
            let name = baseName(args[i])
            if let w = wrappers[name] {
                var j = i + 1
                while j < n {
                    let a = args[j]
                    if a == "--" { j += 1; break }
                    if name == "env", isAssignment(a) { j += 1; continue }
                    if a.hasPrefix("-"), a.count > 1 { j += w.valued.contains(a) ? 2 : 1; continue }
                    break
                }
                i = min(j + w.positional, n)
                continue
            }
            if isInterpreter(name) {
                let isShell = shells.contains(name)
                var j = i + 1
                var wantC = false
                var inlineCode = false
                while j < n {
                    let a = args[j]
                    if a == "--" { j += 1; break }
                    if a.hasPrefix("-"), a.count > 1 {
                        if isShell, !a.hasPrefix("--"), a.dropFirst().contains("c") { wantC = true; j += 1; continue }
                        if !isShell, a == "-c" || a == "-e" { inlineCode = true; j += 2; continue }
                        j += interpreterValued.contains(a) ? 2 : 1
                        continue
                    }
                    break
                }
                if inlineCode { return (0, nil) }
                if wantC { return (i, j < n ? j : nil) }
                return j < n ? (j, nil) : (min(i, n - 1), nil)
            }
            return (i, nil)
        }
        return (0, nil)
    }

    // MARK: - Shell string (`sh -c '...'`)

    private struct ShellToken { var range: Range<Int>; var value: String; var isOperator: Bool }

    /// Best-effort split honouring quotes. Operators (`;` `|` `&` newline) are their own tokens.
    /// Returns nil on an unterminated quote.
    private static func tokenizeShell(_ chars: [Character]) -> [ShellToken]? {
        var tokens: [ShellToken] = []
        var i = 0
        let n = chars.count
        while i < n {
            let c = chars[i]
            if c == " " || c == "\t" { i += 1; continue }
            if c == ";" || c == "|" || c == "&" || c == "\n" {
                var j = i + 1
                while j < n, chars[j] == c, c != ";" { j += 1 }
                tokens.append(ShellToken(range: i..<j, value: String(chars[i..<j]), isOperator: true))
                i = j
                continue
            }
            let start = i
            var value = ""
            while i < n {
                let d = chars[i]
                if d == " " || d == "\t" || d == ";" || d == "|" || d == "&" || d == "\n" { break }
                if d == "'" {
                    guard let close = chars[(i + 1)...].firstIndex(of: "'") else { return nil }
                    value += String(chars[(i + 1)..<close])
                    i = close + 1
                } else if d == "\"" {
                    var j = i + 1
                    var closed = false
                    while j < n {
                        if chars[j] == "\\", j + 1 < n { value.append(chars[j + 1]); j += 2; continue }
                        if chars[j] == "\"" { closed = true; break }
                        value.append(chars[j]); j += 1
                    }
                    guard closed else { return nil }
                    i = j + 1
                } else if d == "\\", i + 1 < n {
                    value.append(chars[i + 1]); i += 2
                } else {
                    value.append(d); i += 1
                }
            }
            tokens.append(ShellToken(range: start..<i, value: value, isOperator: false))
        }
        return tokens
    }

    /// Masks the body of `sh -c '<body>'`: each simple command is masked as an argv (so wrappers,
    /// interpreters and per-command rules apply), changed tokens replace their source span, then the
    /// per-string masker runs over the result as a safety net. An untokenizable body only gets the
    /// per-string masker.
    private static func maskShellString(_ body: String, marker: String, text: (String) -> String) -> String {
        let chars = Array(body)
        guard let tokens = tokenizeShell(chars), tokens.contains(where: { !$0.isOperator }) else { return text(body) }
        var replacements: [(Range<Int>, String)] = []
        var segment: [ShellToken] = []
        func flush() {
            guard !segment.isEmpty else { return }
            let masked = maskArgsCore(segment.map(\.value), marker: marker, text: text, allowAssignments: true)
            for (t, m) in zip(segment, masked) where m != t.value {
                let needsQuote = m.contains(where: { " \t;|&\n".contains($0) })
                replacements.append((t.range, needsQuote ? "'" + m.replacingOccurrences(of: "'", with: "") + "'" : m))
            }
            segment.removeAll()
        }
        for t in tokens { if t.isOperator { flush() } else { segment.append(t) } }
        flush()
        var out = ""
        var pos = 0
        for (range, m) in replacements.sorted(by: { $0.0.lowerBound < $1.0.lowerBound }) {
            out += String(chars[pos..<range.lowerBound]) + m
            pos = range.upperBound
        }
        out += String(chars[pos...])
        return text(out)
    }

    /// Masks a whole argv: flag/value pairs are masked across element boundaries;
    /// every other element goes through `text` (the caller's per-string masker).
    /// Wrappers and interpreters (`sudo`, `env`, `/bin/sh script`, `sh -c '...'`) are looked
    /// through, so the real command's rules apply.
    public static func maskArgs(_ args: [String], marker: String, text: (String) -> String) -> [String] {
        maskArgsCore(args, marker: marker, text: text, allowAssignments: false)
    }

    private static func maskArgsCore(_ args: [String], marker: String, text: (String) -> String, allowAssignments: Bool) -> [String] {
        var out: [String] = []
        out.reserveCapacity(args.count)
        var pending = Pending.none
        let effective = effectiveCommand(args, allowAssignments: allowAssignments)
        let shortMode = shortPasswordMode(args: args[effective.index...])
        for (index, arg) in args.enumerated() {
            switch pending {
            case .full:
                pending = .none
                out.append(marker)
                continue
            case .userColon:
                pending = .none
                if let colon = arg.firstIndex(of: ":") {
                    out.append(String(arg[...colon]) + marker)
                } else {
                    out.append(text(arg))
                }
                continue
            case .none:
                break
            }
            if index == effective.shellString {
                out.append(maskShellString(arg, marker: marker, text: text))
                continue
            }
            if shortMode != .none, index >= effective.index, arg.hasPrefix("-p"), !arg.hasPrefix("--") {
                if arg.count > 2 {
                    out.append("-p" + marker)
                    continue
                }
                if shortMode == .attachedOrSpaced {
                    pending = .full
                    out.append(arg)
                    continue
                }
            }
            if arg.hasPrefix("-") {
                let body = String(arg.drop(while: { $0 == "-" }))
                if let eq = body.firstIndex(of: "=") {
                    let name = String(body[..<eq])
                    if isSensitiveFlagName(name) {
                        let prefix = String(arg.prefix(arg.count - body.count + name.count + 1))
                        out.append(prefix + marker)
                        continue
                    }
                } else if isSensitiveFlagName(body) {
                    pending = .full
                    out.append(arg)
                    continue
                } else if arg == "-u" || arg == "--user" {
                    pending = .userColon
                    out.append(arg)
                    continue
                }
            }
            out.append(text(arg))
        }
        return out
    }

    // MARK: - Text masking

    /// Name-side repetitions are bounded ({0,40}) so a hostile 1 KB argument can't drive
    /// quadratic backtracking. (pattern, template; `%M` = marker). Order matters: bearer/basic
    /// first, so the generic `name: value` rule that follows can't strand the token after a
    /// masked scheme word.
    private static let structuralRules: [(NSRegularExpression, String)] = [
        ("://[^/\\s:@]+:[^@\\s/]+@", "://%M@"),
        ("\\b(bearer|basic)\\s+[A-Za-z0-9._~+/=-]{8,}", "$1 %M"),
        ("([A-Za-z0-9_.-]{0,40}(?:token|secret|passw(?:or)?d|api[_-]?key|credential|passphrase|private[_-]?key|authorization)[A-Za-z0-9_.-]{0,40}\\s*[=:]\\s*)(\"[^\"]*\"|'[^']*'|[^\\s\"'&|;]+)", "$1%M"),
        // `DB_PASS=`, `MYSQL_PWD=`, `pass=`: `pass`/`pwd` as a whole name segment (not `bypass=`).
        ("((?<![A-Za-z0-9])(?:[A-Za-z0-9]{1,20}[_.-]){0,5}(?:pass|pwd)(?:[_.-][A-Za-z0-9]{1,20}){0,3}\\s*=\\s*)(\"[^\"]*\"|'[^']*'|[^\\s\"'&|;]+)", "$1%M"),
        ("(--?[A-Za-z0-9_-]{0,40}(?:token|secret|passw(?:or)?d|api[_-]?key|passphrase)[A-Za-z0-9_-]{0,40}\\s+)([^\\s-][^\\s\"';&|]*)", "$1%M"),
    ].compactMap { pattern, template in
        (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])).map { ($0, template) }
    }

    /// URL credentials, bearer/basic tokens, `name=value` / `name: value` /
    /// `--flag value` for secret-looking names (also inside `sh -c '...'` bodies).
    public static func maskStructural(_ s: String, marker: String) -> String {
        var result = s
        for (rule, template) in structuralRules {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = rule.stringByReplacingMatches(in: result, options: [], range: range,
                                                   withTemplate: template.replacingOccurrences(of: "%M", with: marker))
        }
        return result
    }

    /// Known token formats. A copy of `SecretLeakScanning.patterns` (which lives in
    /// the app target, unreachable from the helper): when a format is added there,
    /// add it here too. The output path additionally runs `SecretLeakScanning.redact`,
    /// so a format missing here is still masked in the output -- but would stay
    /// searchable, so keep the two in step.
    private static let tokenFormatRules: [NSRegularExpression] = [
        #"\b(sk-[a-zA-Z0-9]{20,}|sk-(?:proj|svcacct|admin)-[a-zA-Z0-9_\-]{20,})"#,
        #"\bsk-ant-[a-zA-Z0-9_\-]{30,}"#,
        #"\b(gh[pousr]_[a-zA-Z0-9]{36,}|github_pat_[a-zA-Z0-9_]{40,})"#,
        #"\bAKIA[0-9A-Z]{16}\b"#,
        #"\bhf_[a-zA-Z0-9]{34}\b"#,
        #"\b(AIza[0-9A-Za-z\-_]{30,45}|AQ\.[0-9A-Za-z\-_]{30,100})\b"#,
        #"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"#,
        #"\b(?:xox[baprs]|xapp)-[0-9a-zA-Z\-]{10,}"#,
        #"\b(?:sk|rk)_(?:live|test)_[0-9a-zA-Z]{24,}\b"#,
        #"\bglpat-[0-9A-Za-z_\-]{20,}"#,
        #"\bnpm_[A-Za-z0-9]{36}\b"#,
        #"\bya29\.[0-9A-Za-z\-_]{20,}"#,
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    /// Structural rules, then every known token format, verified crypto keys and
    /// BIP39 phrases. The whole span becomes `marker` (no prefix/length hint, unlike the
    /// output-side `SecretLeakScanning.redact`: nothing of a secret may stay searchable).
    public static func maskText(_ s: String, marker: String) -> String {
        var result = maskStructural(s, marker: marker)
        // Cheap guard: no known token format is shorter than 12 characters.
        guard result.count >= 12 else { return result }
        let template = NSRegularExpression.escapedTemplate(for: marker)
        for rule in tokenFormatRules {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = rule.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: template)
        }
        result = maskCryptoKeys(result, marker: marker)
        result = maskMnemonics(result, marker: marker)
        return maskHighEntropy(result, marker: marker)
    }

    // MARK: - Generic high-entropy tokens

    private static let highEntropyCandidate = try? NSRegularExpression(pattern: "(?<![A-Za-z0-9_+=-])[A-Za-z0-9_+=-]{32,}(?![A-Za-z0-9_+=-])")

    /// Fallback for token formats not listed above: a long unbroken run of base64/URL-safe
    /// characters that mixes upper case, lower case and digits and has the entropy of a random
    /// string. Pure hex (hashes, cdhash, UUIDs) and identifier-like words stay readable.
    public static func maskHighEntropy(_ s: String, marker: String) -> String {
        guard s.count >= 32, let highEntropyCandidate else { return s }
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        var result = s
        for match in highEntropyCandidate.matches(in: s, options: [], range: range).reversed() {
            guard let r = Range(match.range, in: result), looksRandom(String(result[r])) else { continue }
            result.replaceSubrange(r, with: marker)
        }
        return result
    }

    static func looksRandom(_ t: String) -> Bool {
        var upper = false, lower = false, digit = false, nonHex = false
        var counts: [Character: Int] = [:]
        for ch in t {
            counts[ch, default: 0] += 1
            if ch.isASCII {
                if ch.isUppercase { upper = true } else if ch.isLowercase { lower = true } else if ch.isNumber { digit = true }
                if !ch.isHexDigit && ch != "-" { nonHex = true }
            }
        }
        guard upper, lower, digit, nonHex else { return false }
        let len = Double(t.count)
        var entropy = 0.0
        for c in counts.values {
            let p = Double(c) / len
            entropy -= p * log2(p)
        }
        return entropy >= 4.2
    }

    private static let cryptoKeyRules: [(NSRegularExpression, CryptoSecretDetection.CryptoKeyKind)] = [
        (CryptoSecretDetection.wifCandidatePattern, CryptoSecretDetection.CryptoKeyKind.wif),
        (CryptoSecretDetection.extendedKeyCandidatePattern, CryptoSecretDetection.CryptoKeyKind.extendedPrivateKey),
    ].compactMap { pattern, kind in
        (try? NSRegularExpression(pattern: pattern)).map { ($0, kind) }
    }

    /// Only checksum-verified candidates are replaced (same test the scanner uses).
    private static func maskCryptoKeys(_ text: String, marker: String) -> String {
        var result = text
        for (regex, want) in cryptoKeyRules {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            // Back-to-front so earlier ranges stay valid while later ones are rewritten.
            for match in regex.matches(in: result, options: [], range: range).reversed() {
                guard let r = Range(match.range, in: result),
                      CryptoSecretDetection.classifyCryptoKeyCandidate(String(result[r])) == want else { continue }
                result.replaceSubrange(r, with: marker)
            }
        }
        return result
    }

    private static let wordRegex = try? NSRegularExpression(pattern: "[A-Za-z]+")

    /// Checksum-verified BIP39 phrases, line by line (detection is word-based).
    private static func maskMnemonics(_ text: String, marker: String) -> String {
        guard let wordRegex else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let nsMatches = wordRegex.matches(in: text, options: [], range: range)
        let wordRanges: [Range<String.Index>] = nsMatches.compactMap { Range($0.range, in: text) }
        // Fewer than 12 words can't hold a mnemonic; a failed range conversion means "leave it".
        guard wordRanges.count == nsMatches.count, wordRanges.count >= 12 else { return text }
        let tokens = wordRanges.map { text[$0].lowercased() }
        let spans = CryptoSecretDetection.findMnemonicSpans(tokens)
        guard !spans.isEmpty else { return text }
        var result = text
        for span in spans.sorted(by: { $0.start > $1.start }) {
            result.replaceSubrange(wordRanges[span.start].lowerBound..<wordRanges[span.end - 1].upperBound, with: marker)
        }
        return result
    }

    // MARK: - Masked matching (helper-side search)

    /// What a text query is matched against: path, argv, signing ID, team ID and
    /// cwd of the record, each stripped of invisible characters and masked, with
    /// every masked span replaced by `matchSentinel`. Lowercased.
    public static func matchHaystack(_ r: ExecEventRecord) -> String {
        var parts: [String] = [maskField(r.path)]
        if let a = r.args {
            let stripped = a.map { stripInvisible($0, maxLength: premaskLimit) }
            parts.append(maskArgs(stripped, marker: matchSentinel, text: { maskText($0, marker: matchSentinel) }).joined(separator: " "))
        }
        if let s = r.signingID { parts.append(maskField(s)) }
        if let s = r.teamID { parts.append(maskField(s)) }
        if let c = r.cwd { parts.append(maskField(c)) }
        return parts.joined(separator: " ").lowercased()
    }

    private static func maskField(_ s: String) -> String {
        maskText(stripInvisible(s, maxLength: premaskLimit), marker: matchSentinel)
    }

    /// The query as it is compared: invisible characters stripped (so it can't
    /// contain `matchSentinel`), trimmed, lowercased.
    /// Surrounding whitespace is dropped too, so padding can't satisfy the minimum length.
    public static func normalizedNeedle(_ query: String) -> String {
        stripInvisible(query).trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// True when the lowercased `needle` occurs in the masked record. The unmasked
    /// text is checked first as a cheap filter: masking only removes characters
    /// (and stripping invisibles is applied to both), so a needle absent from the
    /// unmasked text can't be in the masked one, and the regexes are skipped for
    /// the vast majority of records.
    public static func maskedMatch(_ r: ExecEventRecord, needle: String) -> Bool {
        guard !needle.isEmpty else { return true }
        var raw = stripInvisible(r.path, maxLength: premaskLimit)
        if let a = r.args { raw += " " + a.map { stripInvisible($0, maxLength: premaskLimit) }.joined(separator: " ") }
        if let s = r.signingID { raw += " " + stripInvisible(s, maxLength: premaskLimit) }
        if let s = r.teamID { raw += " " + stripInvisible(s, maxLength: premaskLimit) }
        if let c = r.cwd { raw += " " + stripInvisible(c, maxLength: premaskLimit) }
        guard raw.lowercased().contains(needle) else { return false }
        return matchHaystack(r).contains(needle)
    }
}
