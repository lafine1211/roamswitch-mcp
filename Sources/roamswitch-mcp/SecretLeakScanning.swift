// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.13 (build 70).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
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
        (#"\b(sk-[a-zA-Z0-9]{20,60}|sk-proj-[a-zA-Z0-9_\-]{40,})\b"#, .openAI),
        (#"\bsk-ant-[a-zA-Z0-9_\-]{30,}\b"#, .anthropic),
        (#"\b(ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{40,})\b"#, .gitHub),
        (#"\bAKIA[0-9A-Z]{16}\b"#, .aws),
        (#"\bhf_[a-zA-Z0-9]{34}\b"#, .huggingFace),
        (#"\bAIza[0-9A-Za-z\-_]{30,45}\b"#, .googleGemini),
        (#"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"#, .privateKey),
        (#"\bxox[baprs]-[0-9a-zA-Z\-]{10,}\b"#, .slack),
        (#"\b(?:sk|rk)_(?:live|test)_[0-9a-zA-Z]{24,}\b"#, .stripe),
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
        return results
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
        }
        return findings
    }

    /// Directory/build-dependency names skipped during a recursive folder scan,
    /// mirroring the Linux CLI's `roamswitch audit-secrets <directory>` behavior.
    private static let scanSkipDirs: Set<String> = [
        ".git", "node_modules", "target", "vendor", "dist", "build", "__pycache__", ".venv", "venv",
    ]
    private static let scanMaxFileBytes = 2 * 1024 * 1024

    /// Recursively audits every text file under `root`, skipping VCS/build/dependency
    /// directories and files that are too large or look binary (a NUL byte in the
    /// first 8KB). Purely local — never touches the network. Intended to run off the
    /// main thread since a large repository can take a while to walk.
    public static func auditDirectory(at root: URL) -> [SecretFinding] {
        var results: [SecretFinding] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        ) else { return results }

        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            if values?.isDirectory == true {
                if scanSkipDirs.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard let size = values?.fileSize, size > 0, size <= scanMaxFileBytes else { continue }
            guard let data = try? Data(contentsOf: url) else { continue }
            let sniffLen = min(data.count, 8192)
            if data.prefix(sniffLen).contains(0) { continue }
            guard let text = String(data: data, encoding: .utf8) else { continue }
            results.append(contentsOf: auditText(text, filePath: url.path))
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
        return result
    }

    private static func maskSecret(_ secret: String) -> String {
        guard secret.count > 8 else { return "****" }
        let prefixLen = secret.count > 16 ? 6 : 3
        let suffixLen = secret.count > 16 ? 4 : 2
        return "\(secret.prefix(prefixLen))...\(secret.suffix(suffixLen))"
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
