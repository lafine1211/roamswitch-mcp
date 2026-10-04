// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.25 (build 143).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import CryptoKit
import Foundation

/// Pure, dependency-free secret-detection logic — split out of
/// `SecretLeakAuditor.swift` (which stays `@MainActor` and owns the
/// pasteboard watcher + notification side effects) so this half can be
/// compiled into `RoamSwitchMCPServer` without pulling in
/// `SecurityNotifier`/AppKit/UserNotifications. Never touches the network.
public enum SecretLeakScanning {

    /// Types of API keys and confidential tokens detected locally.
    public enum DetectedSecretType: String, CaseIterable, Codable, Sendable {
        case openAI = "OpenAI API Key"
        case anthropic = "Anthropic API Key"
        case gitHub = "GitHub Token"
        case aws = "AWS Access Key"
        case huggingFace = "HuggingFace Token"
        case googleGemini = "Google AI / Gemini API Key"
        case privateKey = "Private Key (RSA/SSH)"
        case slack = "Slack Token"
        case stripe = "Stripe API Key"
        /// GitLab personal access tokens, npm tokens, Google OAuth access tokens.
        case accessToken = "Access Token (GitLab / npm / Google OAuth)"
        /// A checksum-verified BIP39 mnemonic seed phrase (12/15/18/21/24 words).
        case cryptoSeedPhrase = "Crypto Seed Phrase (BIP39)"
        /// A checksum-verified Bitcoin Wallet Import Format private key.
        case cryptoBitcoinWIF = "Bitcoin Private Key (WIF)"
        /// A checksum-verified BIP32 extended private key (xprv/yprv/zprv/tprv).
        case cryptoExtendedKey = "Crypto Extended Private Key (BIP32)"

        public var localizedName: String {
            switch self {
            case .openAI: return loc("OpenAI APIキー")
            case .anthropic: return loc("Anthropic APIキー")
            case .gitHub: return loc("GitHubアクセストークン")
            case .aws: return loc("AWSアクセスキー")
            case .huggingFace: return loc("HuggingFaceトークン")
            case .googleGemini: return loc("Google AI / Gemini APIキー")
            case .privateKey: return loc("秘密鍵 (RSA/SSH)")
            case .slack: return loc("Slackトークン")
            case .stripe: return loc("Stripe APIキー")
            case .accessToken: return loc("アクセストークン (GitLab / npm / Google OAuth)")
            case .cryptoSeedPhrase: return loc("暗号資産ウォレットのシードフレーズ (BIP39)")
            case .cryptoBitcoinWIF: return loc("Bitcoin秘密鍵 (WIF形式)")
            case .cryptoExtendedKey: return loc("暗号資産ウォレットの拡張秘密鍵 (BIP32)")
            }
        }

        /// Where/how to revoke or rotate a leaked secret of this type.
        public var recommendation: String {
            switch self {
            case .openAI: return loc("OpenAIダッシュボードからキーを失効・再発行してください。")
            case .anthropic: return loc("Anthropic ConsoleからAPIキーを直ちにRevokeしてください。")
            case .gitHub: return loc("GitHub Settings → Developer settingsからトークンを削除してください。")
            case .aws: return loc("AWS IAMコンソールからアクセスキーを非アクティブ化してください。")
            case .huggingFace: return loc("HuggingFaceの設定ページからAccess Tokenを無効化してください。")
            case .googleGemini: return loc("GCP Cloud Console / Google AI StudioからAPIキーを再生成してください。")
            case .privateKey: return loc("秘密鍵が漏洩している可能性があります。直ちに鍵を再生成し、authorized_keysを更新してください。")
            case .slack: return loc("Slack API管理画面からトークンをRevokeしてください。")
            case .stripe: return loc("StripeダッシュボードからAPIキーをロールしてください。")
            case .accessToken: return loc("発行元(GitLab / npm / Google)の管理画面からトークンを失効させ、再発行してください。")
            case .cryptoSeedPhrase: return loc("これは暗号資産ウォレットを復元できる可能性があります。APIキーと違い「失効」はできません。直ちに新しいウォレットを作成し、資産を移動してください。このフレーズを入力したウォレットは今後一切使用しないでください。")
            case .cryptoBitcoinWIF: return loc("暗号資産ウォレットの秘密鍵です。APIキーと違い「失効」はできません。直ちに新しいウォレットを作成し、資産を移動してください。この鍵に対応するウォレットは今後一切使用しないでください。")
            case .cryptoExtendedKey: return loc("暗号資産ウォレットの拡張秘密鍵です。この鍵から配下の全アドレスの秘密鍵を導出できます。APIキーと違い「失効」はできません。直ちに新しいウォレットを作成し、資産を移動してください。")
            }
        }
    }

    public struct DetectedSecretItem: Identifiable, Equatable, Sendable {
        public var id: String { type.rawValue }
        public let type: DetectedSecretType
        public let detectedAt: Date

        public init(type: DetectedSecretType, detectedAt: Date = Date()) {
            self.type = type
            self.detectedAt = detectedAt
        }
    }

    /// A single occurrence found by `auditText`, one per match (not deduped
    /// by type, unlike `scanTextForSecrets`) so the caller can see exactly
    /// which lines are affected.
    public struct SecretFinding: Identifiable, Sendable {
        public let id = UUID()
        public let type: DetectedSecretType
        public let lineNumber: Int
        public let masked: String
        public let entropy: Double
        /// Set when the finding came from `auditDirectory`; nil for pasted-text audits.
        public let filePath: String?

        public init(type: DetectedSecretType, lineNumber: Int, masked: String, entropy: Double, filePath: String? = nil) {
            self.type = type
            self.lineNumber = lineNumber
            self.masked = masked
            self.entropy = entropy
            self.filePath = filePath
        }
    }

    /// Single source of truth for every secret pattern, shared by the passive
    /// pasteboard watcher (`scanTextForSecrets`) and the manual line-by-line
    /// audit (`auditText`).
    private static let patterns: [(regex: String, type: DetectedSecretType)] = [
        (#"\b(sk-[a-zA-Z0-9]{20,}|sk-(?:proj|svcacct|admin)-[a-zA-Z0-9_\-]{20,})"#, .openAI),
        (#"\bsk-ant-[a-zA-Z0-9_\-]{30,}"#, .anthropic),
        (#"\b(gh[pousr]_[a-zA-Z0-9]{36,}|github_pat_[a-zA-Z0-9_]{40,})"#, .gitHub),
        (#"\bAKIA[0-9A-Z]{16}\b"#, .aws),
        (#"\bhf_[a-zA-Z0-9]{34}\b"#, .huggingFace),
        // Two live Google key formats: the long-standing `AIzaSy...` format
        // (Cloud/Maps/Firebase and older Gemini keys) and the newer
        // `AQ.<token>` format issued by Google AI Studio — confirmed live
        // (2026-09-16, ported from the Linux fix) that a real AI Studio key
        // in this second format produced zero findings, since this pattern
        // previously only matched the `AIza` prefix. Length is a wide, open
        // bound (not an exact count) since only one real example was
        // observed and its precise length wasn't confirmed.
        (#"\b(AIza[0-9A-Za-z\-_]{30,45}|AQ\.[0-9A-Za-z\-_]{30,100})\b"#, .googleGemini),
        (#"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"#, .privateKey),
        (#"\b(?:xox[baprs]|xapp)-[0-9a-zA-Z\-]{10,}"#, .slack),
        (#"\b(?:sk|rk)_(?:live|test)_[0-9a-zA-Z]{24,}\b"#, .stripe),
        (#"\bglpat-[0-9A-Za-z_\-]{20,}"#, .accessToken),
        (#"\bnpm_[A-Za-z0-9]{36}\b"#, .accessToken),
        (#"\bya29\.[0-9A-Za-z\-_]{20,}"#, .accessToken),
    ]

    public static func scanTextForSecrets(_ text: String) -> [DetectedSecretItem] {
        let now = Date()
        var seen: Set<DetectedSecretType> = []
        var results: [DetectedSecretItem] = []
        for (regex, type) in patterns where !seen.contains(type) {
            if matchesRegex(pattern: regex, in: text) {
                seen.insert(type)
                results.append(DetectedSecretItem(type: type, detectedAt: now))
            }
        }
        for line in text.components(separatedBy: .newlines) {
            if !seen.contains(.cryptoSeedPhrase), !CryptoSecretDetection.findMnemonicSpans(CryptoSecretDetection.tokenizeWords(line)).isEmpty {
                seen.insert(.cryptoSeedPhrase)
                results.append(DetectedSecretItem(type: .cryptoSeedPhrase, detectedAt: now))
            }
            if !seen.contains(.cryptoBitcoinWIF) || !seen.contains(.cryptoExtendedKey) {
                for (pattern, type) in cryptoKeyPatterns where !seen.contains(type) {
                    if matchesRegex(pattern: pattern, in: line), lineContainsVerifiedCryptoKey(line, pattern: pattern, expecting: type) {
                        seen.insert(type)
                        results.append(DetectedSecretItem(type: type, detectedAt: now))
                    }
                }
            }
        }
        return results
    }

    /// `(candidate regex, secret type)` pairs for the checksum-verified
    /// crypto key detectors — parallel to `patterns`, but each candidate
    /// match still has to pass `CryptoSecretDetection.classifyCryptoKeyCandidate`
    /// before being reported (see that type's documentation for why a plain
    /// regex alone isn't trustworthy here).
    private static let cryptoKeyPatterns: [(regex: String, type: DetectedSecretType)] = [
        (CryptoSecretDetection.wifCandidatePattern, .cryptoBitcoinWIF),
        (CryptoSecretDetection.extendedKeyCandidatePattern, .cryptoExtendedKey),
    ]

    private static func lineContainsVerifiedCryptoKey(_ line: String, pattern: String, expecting type: DetectedSecretType) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        var found = false
        regex.enumerateMatches(in: line, options: [], range: range) { match, _, stop in
            guard let match, let matchRange = Range(match.range, in: line) else { return }
            let candidate = String(line[matchRange])
            let wantKind: CryptoSecretDetection.CryptoKeyKind = type == .cryptoBitcoinWIF ? .wif : .extendedPrivateKey
            if CryptoSecretDetection.classifyCryptoKeyCandidate(candidate) == wantKind {
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    private static func matchesRegex(pattern: String, in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    /// Line-by-line audit of pasted text for the manual "Secret Leak Audit"
    /// tool. Purely local — never touches the network.
    public static func auditText(_ text: String, filePath: String? = nil) -> [SecretFinding] {
        var findings: [SecretFinding] = []
        let lines = text.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            let lineRange = NSRange(line.startIndex..<line.endIndex, in: line)
            for (pattern, type) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                regex.enumerateMatches(in: line, options: [], range: lineRange) { match, _, _ in
                    guard let match, let matchRange = Range(match.range, in: line) else { return }
                    let matched = String(line[matchRange])
                    findings.append(SecretFinding(
                        type: type,
                        lineNumber: idx + 1,
                        masked: maskSecret(matched),
                        entropy: shannonEntropy(matched),
                        filePath: filePath
                    ))
                }
            }

            // BIP39 mnemonic seed phrase: word-run + checksum, not a regex.
            let tokens = CryptoSecretDetection.tokenizeWords(line)
            for span in CryptoSecretDetection.findMnemonicSpans(tokens) {
                let phrase = tokens[span.start..<span.end].joined(separator: " ")
                findings.append(SecretFinding(
                    type: .cryptoSeedPhrase,
                    lineNumber: idx + 1,
                    masked: cryptoSecretPlaceholder(),
                    entropy: shannonEntropy(phrase),
                    filePath: filePath
                ))
            }

            // Bitcoin WIF / BIP32 extended private key: regex pre-filter,
            // then a real Base58Check + version-byte verification before
            // ever reporting a finding (see `CryptoSecretDetection`'s docs).
            for (pattern, type) in cryptoKeyPatterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                regex.enumerateMatches(in: line, options: [], range: lineRange) { match, _, _ in
                    guard let match, let matchRange = Range(match.range, in: line) else { return }
                    let candidate = String(line[matchRange])
                    let wantKind: CryptoSecretDetection.CryptoKeyKind = type == .cryptoBitcoinWIF ? .wif : .extendedPrivateKey
                    guard CryptoSecretDetection.classifyCryptoKeyCandidate(candidate) == wantKind else { return }
                    findings.append(SecretFinding(
                        type: type,
                        lineNumber: idx + 1,
                        masked: cryptoSecretPlaceholder(),
                        entropy: shannonEntropy(candidate),
                        filePath: filePath
                    ))
                }
            }
        }
        return findings
    }

    /// Fixed, fully-redacted display value for a crypto secret finding —
    /// unlike API keys (where showing a few boundary characters is low
    /// risk), even one or two words of a BIP39 phrase, or any base58
    /// characters of a WIF/extended key, meaningfully narrows a brute-force
    /// search, so nothing of the actual value is ever shown.
    private static func cryptoSecretPlaceholder() -> String {
        loc("[値は完全に非表示]")
    }

    /// Directory/build-dependency names skipped during a recursive folder scan,
    /// mirroring the Linux CLI's `roamswitch audit-secrets <directory>` behavior.
    private static let scanSkipDirs: Set<String> = [
        ".git", "node_modules", "target", "vendor", "dist", "build", "__pycache__", ".venv", "venv",
    ]
    private static let scanMaxFileBytes = 2 * 1024 * 1024
    /// Directory nesting cap for `auditDirectory` (defence in depth next to the visited-set).
    private static let scanMaxDepth = 40

    /// 2026-09-24: `CredentialHoneytokenGuard` が設置する囮ファイルの(ホーム相対パス → バイト数)。
    /// 内容を読まずに判別するため(読むこと自体が検知を誘発する)サイズで照合する。内容変更時は同ガードと揃えること。
    /// 旧版が設置済みの囮(`[default]`のAWS、Docker Hub宛のDocker、`.ssh/id_rsa`)も、移行されるまで読まない。
    static let honeytokenDecoySizes: [String: [Int]] = [
        ".aws/credentials": [135, 130],
        ".ssh/id_rsa_backup": [192],
        ".ssh/id_rsa": [192],
        ".docker/config.json": [146, 131],
    ]

    /// 2026-09-24: 本物の同名ファイル(サイズが異なる)は従来どおり監査対象に残す。
    static func isHoneytokenDecoy(path: String, size: Int, home: String) -> Bool {
        let prefix = home.hasSuffix("/") ? home : home + "/"
        guard path.hasPrefix(prefix) else { return false }
        return honeytokenDecoySizes[String(path.dropFirst(prefix.count))]?.contains(size) ?? false
    }

    /// Recursively audits every text file under `root`, skipping VCS/build/dependency
    /// directories and files that are too large or look binary (a NUL byte in the
    /// first 8KB). Purely local — never touches the network. Intended to run off the
    /// main thread since a large repository can take a while to walk.
    /// Symlinks are never followed out of `root` (`SafeScanFS`: a link is skipped unless
    /// its real path is still inside `root`), only regular files are read (O_NOFOLLOW,
    /// size-capped), and each directory is visited once (no link loops).
    public static func auditDirectory(at root: URL) -> [SecretFinding] {
        var results: [SecretFinding] = []
        guard let rootPath = SafeScanFS.canonicalPath(root.path) else { return results }
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let home = SafeScanFS.canonicalPath(homePath) ?? homePath

        var visited: Set<String> = [rootPath]
        var stack: [(path: String, depth: Int)] = [(rootPath, 0)]
        while let item = stack.popLast() {
            for entry in SafeScanFS.children(ofDirectory: item.path, root: rootPath) {
                switch entry.kind {
                case .directory:
                    guard item.depth < scanMaxDepth, !scanSkipDirs.contains(entry.name),
                          visited.insert(entry.path).inserted else { continue }
                    stack.append((entry.path, item.depth + 1))
                case .regularFile:
                    let size = Int(clamping: entry.size)
                    guard size > 0, size <= scanMaxFileBytes else { continue }
                    // 2026-09-24: 自前のハニートークン囮を読むと、読み取り検知(atime)が自分自身を誤報するため除外する。
                    if isHoneytokenDecoy(path: entry.path, size: size, home: home) { continue }
                    guard let data = SafeScanFS.readRegularFile(atPath: entry.path, maxBytes: scanMaxFileBytes) else { continue }
                    let sniffLen = min(data.count, 8192)
                    if data.prefix(sniffLen).contains(0) { continue }
                    guard let text = String(data: data, encoding: .utf8) else { continue }
                    results.append(contentsOf: auditText(text, filePath: entry.path))
                }
            }
        }
        return results
    }

    /// Scans arbitrary text and returns a copy with every detected secret
    /// replaced by its masked form (`maskSecret`). Unlike `auditText`, this
    /// returns the redacted text itself rather than a findings list, for
    /// callers that hand raw text to an external party — e.g. copying a log
    /// audit report to the clipboard for the user to paste into an AI chat.
    public static func redact(_ text: String) -> String {
        var result = text
        for (pattern, _) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, options: [], range: range)
            // Replace back-to-front so earlier matches' ranges stay valid
            // against `result` as later ones are rewritten.
            for match in matches.reversed() {
                guard let matchRange = Range(match.range, in: result) else { continue }
                let matched = String(result[matchRange])
                result.replaceSubrange(matchRange, with: maskSecret(matched))
            }
        }
        for (pattern, type) in cryptoKeyPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, options: [], range: range)
            let wantKind: CryptoSecretDetection.CryptoKeyKind = type == .cryptoBitcoinWIF ? .wif : .extendedPrivateKey
            for match in matches.reversed() {
                guard let matchRange = Range(match.range, in: result) else { continue }
                let candidate = String(result[matchRange])
                guard CryptoSecretDetection.classifyCryptoKeyCandidate(candidate) == wantKind else { continue }
                result.replaceSubrange(matchRange, with: cryptoRedactionMarker)
            }
        }
        result = redactMnemonics(in: result)
        return result
    }

    /// Fixed, non-localized redaction marker for a verified crypto secret —
    /// same convention as `maskSecret`'s `"****"`, which also isn't
    /// translated (it's a technical marker, not user-facing prose).
    private static let cryptoRedactionMarker = "[REDACTED-CRYPTO-SECRET]"

    /// Replaces every checksum-verified BIP39 mnemonic phrase in `text` with
    /// `cryptoRedactionMarker`, line by line (mnemonic detection is
    /// word-based, not a single regex — see `CryptoSecretDetection`).
    private static func redactMnemonics(in text: String) -> String {
        text.components(separatedBy: "\n")
            .map(redactMnemonics(inLine:))
            .joined(separator: "\n")
    }

    private static func redactMnemonics(inLine line: String) -> String {
        guard let wordRegex = try? NSRegularExpression(pattern: "[A-Za-z]+") else { return line }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let nsMatches = wordRegex.matches(in: line, options: [], range: range)
        guard !nsMatches.isEmpty else { return line }
        let wordRanges: [Range<String.Index>] = nsMatches.compactMap { Range($0.range, in: line) }
        guard wordRanges.count == nsMatches.count else { return line }
        let tokens = wordRanges.map { line[$0].lowercased() }
        let spans = CryptoSecretDetection.findMnemonicSpans(tokens)
        guard !spans.isEmpty else { return line }

        var result = line
        // Replace back-to-front so earlier ranges stay valid as later ones
        // are rewritten (same pattern as the regex-based redactions above).
        for span in spans.sorted(by: { $0.start > $1.start }) {
            let start = wordRanges[span.start].lowerBound
            let end = wordRanges[span.end - 1].upperBound
            result.replaceSubrange(start..<end, with: cryptoRedactionMarker)
        }
        return result
    }

    /// Reveals as little of a secret as possible: at most the first 4 characters
    /// (enough to recognise the key family, e.g. `AKIA`) plus the length. The
    /// tail is never shown — MCP clients (LLMs) and logs receive this string,
    /// and a prefix+suffix of a high-entropy token materially narrows brute force.
    private static func maskSecret(_ secret: String) -> String {
        guard secret.count > 8 else { return "****" }
        return "\(secret.prefix(4))...[\(secret.count) chars]"
    }

    private static func shannonEntropy(_ s: String) -> Double {
        guard !s.isEmpty else { return 0 }
        var counts: [Character: Int] = [:]
        for ch in s { counts[ch, default: 0] += 1 }
        let len = Double(s.count)
        var entropy = 0.0
        for count in counts.values {
            let p = Double(count) / len
            entropy -= p * log2(p)
        }
        return (entropy * 100).rounded() / 100
    }
}
