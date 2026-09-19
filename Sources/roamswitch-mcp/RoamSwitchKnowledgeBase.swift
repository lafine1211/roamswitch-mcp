// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.45 (build 102).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Comprehensive, authoritative offline knowledge base for RoamSwitch.
/// Exposes full product specifications, internal mechanics, alert message advice,
/// settings guidance, and troubleshooting information to MCP clients and tests.
///
/// Localization: every entry exists in all 10 app languages (ja, en, zh-Hans,
/// zh-Hant, ko, de, fr, es, it, pt-PT). The text is embedded directly in Swift
/// source (`RoamSwitchKnowledgeBaseContent_<lang>.swift`) rather than in
/// `Localizable.xcstrings`, because this file is mirrored verbatim into the
/// standalone `roamswitch-mcp` SwiftPM package, which ships no localization
/// resources at all. Entry ids, topics, and tags are language-independent and
/// live in `entryCatalog()` below — ids are a stable API for MCP clients.
public struct RoamSwitchKnowledgeBase: Sendable {
    public static let shared = RoamSwitchKnowledgeBase()

    // MARK: - Models

    public struct KnowledgeItem: Codable, Sendable, Equatable {
        public let id: String
        public let topic: String
        public let title: String
        public let summary: String
        public let details: String
        public let recommendation: String?
        public let tags: [String]

        public init(
            id: String,
            topic: String,
            title: String,
            summary: String,
            details: String,
            recommendation: String? = nil,
            tags: [String] = []
        ) {
            self.id = id
            self.topic = topic
            self.title = title
            self.summary = summary
            self.details = details
            self.recommendation = recommendation
            self.tags = tags
        }
    }

    public struct KnowledgeSearchResult: Codable, Sendable, Equatable {
        public let query: String?
        public let topic: String?
        public let totalResults: Int
        public let items: [KnowledgeItem]
        /// Language code the returned items are written in (e.g. "ja", "en").
        public let language: String?

        public init(query: String?, topic: String?, totalResults: Int, items: [KnowledgeItem], language: String? = nil) {
            self.query = query
            self.topic = topic
            self.totalResults = totalResults
            self.items = items
            self.language = language
        }
    }

    /// Language-independent part of an entry (stable id, topic, search tags).
    struct EntryMeta: Sendable {
        let id: String
        let topic: String
        let tags: [String]
    }

    /// Language-dependent part of an entry, provided per language by the
    /// `RoamSwitchKnowledgeBaseContent_<lang>.swift` files.
    struct LocalizedEntry: Sendable {
        let id: String
        let title: String
        let summary: String
        let details: String
        let recommendation: String
    }

    /// Localized framing for the `roamswitch://docs/*` Markdown resources.
    struct MarkdownLabels: Sendable {
        let featuresTitle: String
        let featuresIntro: String
        let alertsTitle: String
        let alertsIntro: String
        let settingsTitle: String
        let settingsIntro: String
        let troubleshootingTitle: String
        let troubleshootingIntro: String
        let summary: String
        let overview: String
        let detailsHeading: String
        let adviceHeading: String
        let recommendation: String
        let bestPractice: String
        let advice: String
    }

    // MARK: - Languages

    /// Every language the knowledge base is written in (matches `AppLanguage`).
    public static let supportedLanguageCodes: [String] = ["ja", "en", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es", "it", "pt-PT"]

    /// Used when a requested or system language is not one of the supported ones.
    public static let fallbackLanguageCode = "en"

    /// Maps a free-form language tag ("en-US", "zh_TW", "pt-BR", "JA") to one of
    /// `supportedLanguageCodes`, or nil if it matches none of them.
    public static func normalizeLanguageCode(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        let lower = trimmed.replacingOccurrences(of: "_", with: "-").lowercased()
        for code in supportedLanguageCodes where code.lowercased() == lower {
            return code
        }
        if lower.hasPrefix("zh") {
            let traditionalMarkers = ["hant", "-tw", "-hk", "-mo"]
            if traditionalMarkers.contains(where: { lower.contains($0) }) {
                return "zh-Hant"
            }
            return "zh-Hans"
        }
        if lower == "pt" || lower.hasPrefix("pt-") {
            return "pt-PT"
        }
        let primary = lower.split(separator: "-").first.map(String.init) ?? lower
        for code in supportedLanguageCodes where code.lowercased() == primary {
            return code
        }
        return nil
    }

    /// The language the app is currently set to (`AppLanguage`, shared with the
    /// MCP server process), else the first supported OS preferred language,
    /// else English. Unlike `AppLanguage.activeLocaleCode`, an unsupported
    /// system language falls back to English rather than Japanese.
    public static func activeLanguageCode() -> String {
        let current = AppLanguage.current
        if current != .system, let code = normalizeLanguageCode(current.rawValue) {
            return code
        }
        for preferred in Locale.preferredLanguages {
            if let code = normalizeLanguageCode(preferred) {
                return code
            }
        }
        return fallbackLanguageCode
    }

    /// Resolves an explicitly requested language (if supported) or the active one.
    public static func resolveLanguage(_ requested: String?) -> String {
        if let code = normalizeLanguageCode(requested) {
            return code
        }
        return activeLanguageCode()
    }

    // MARK: - Knowledge Database

    private let itemsByLanguage: [String: [KnowledgeItem]]
    /// Per item index: one lowercased search haystack per language, so a query
    /// written in any language matches regardless of the response language.
    private let searchHaystacks: [[String]]

    /// All items in the currently active language.
    public var allItems: [KnowledgeItem] {
        items(language: nil)
    }

    public init() {
        let metas = Self.entryCatalog()
        var tables: [String: [String: LocalizedEntry]] = [:]
        for code in Self.supportedLanguageCodes {
            var table: [String: LocalizedEntry] = [:]
            for entry in Self.localizedEntries(for: code) where table[entry.id] == nil {
                table[entry.id] = entry
            }
            tables[code] = table
        }

        var byLanguage: [String: [KnowledgeItem]] = [:]
        for code in Self.supportedLanguageCodes {
            var list: [KnowledgeItem] = []
            for meta in metas {
                guard let text = tables[code]?[meta.id]
                        ?? tables[Self.fallbackLanguageCode]?[meta.id]
                        ?? tables["ja"]?[meta.id] else {
                    continue
                }
                list.append(KnowledgeItem(
                    id: meta.id,
                    topic: meta.topic,
                    title: text.title,
                    summary: text.summary,
                    details: text.details,
                    recommendation: text.recommendation.isEmpty ? nil : text.recommendation,
                    tags: meta.tags
                ))
            }
            byLanguage[code] = list
        }
        self.itemsByLanguage = byLanguage

        let reference = byLanguage[Self.fallbackLanguageCode] ?? []
        var haystacks: [[String]] = []
        for index in reference.indices {
            var perLanguage: [String] = []
            for code in Self.supportedLanguageCodes {
                guard let list = byLanguage[code], index < list.count else { continue }
                let item = list[index]
                let text = "\(item.id) \(item.title) \(item.summary) \(item.details) \(item.recommendation ?? "") \(item.tags.joined(separator: " "))"
                perLanguage.append(text.lowercased())
            }
            haystacks.append(perLanguage)
        }
        self.searchHaystacks = haystacks
    }

    /// Items in `language` (any tag `normalizeLanguageCode` accepts), or the
    /// active language when nil / unsupported.
    public func items(language: String?) -> [KnowledgeItem] {
        let code = Self.resolveLanguage(language)
        return itemsByLanguage[code] ?? itemsByLanguage[Self.fallbackLanguageCode] ?? []
    }

    // MARK: - Search API

    public func search(query: String? = nil, topic: String? = nil, language: String? = nil) -> KnowledgeSearchResult {
        let code = Self.resolveLanguage(language)
        let localized = itemsByLanguage[code] ?? itemsByLanguage[Self.fallbackLanguageCode] ?? []
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedTopic = topic?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tokens = (trimmedQuery ?? "").components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let filterTopic: String? = {
            guard let t = trimmedTopic, !t.isEmpty, t != "all" else { return nil }
            return t
        }()

        var filtered: [KnowledgeItem] = []
        for (index, item) in localized.enumerated() {
            if let t = filterTopic, item.topic.lowercased() != t {
                continue
            }
            if !tokens.isEmpty {
                let haystacks = index < searchHaystacks.count ? searchHaystacks[index] : []
                let matched = haystacks.contains { hay in
                    tokens.allSatisfy { hay.contains($0) }
                }
                if !matched {
                    continue
                }
            }
            filtered.append(item)
        }

        return KnowledgeSearchResult(
            query: query,
            topic: topic,
            totalResults: filtered.count,
            items: filtered,
            language: code
        )
    }

    // MARK: - MCP Resource Documents

    public func resource(for uri: String, language: String? = nil) -> String? {
        switch uri {
        case "roamswitch://docs/features":
            return generateFeaturesMarkdown(language: language)
        case "roamswitch://docs/alerts-and-messages":
            return generateAlertsMarkdown(language: language)
        case "roamswitch://docs/settings-guide":
            return generateSettingsMarkdown(language: language)
        case "roamswitch://docs/troubleshooting":
            return generateTroubleshootingMarkdown(language: language)
        default:
            return nil
        }
    }

    // MARK: - Markdown Document Generators

    public func generateFeaturesMarkdown(language: String? = nil) -> String {
        let code = Self.resolveLanguage(language)
        let labels = Self.markdownLabels(for: code)
        var md = "# 🛡️ \(labels.featuresTitle)\n\n"
        md += "\(labels.featuresIntro)\n\n"
        for f in items(language: code) where f.topic == "feature" {
            md += "## \(f.title)\n"
            md += "**\(labels.summary)**: \(f.summary)\n\n"
            md += "\(f.details)\n\n"
            if let rec = f.recommendation {
                md += "> **💡 \(labels.recommendation)**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateAlertsMarkdown(language: String? = nil) -> String {
        let code = Self.resolveLanguage(language)
        let labels = Self.markdownLabels(for: code)
        var md = "# 🚨 \(labels.alertsTitle)\n\n"
        md += "\(labels.alertsIntro)\n\n"
        for a in items(language: code) where a.topic == "alert_message" {
            md += "## \(a.title)\n"
            md += "**\(labels.overview)**: \(a.summary)\n\n"
            md += "### \(labels.detailsHeading)\n\(a.details)\n\n"
            if let rec = a.recommendation {
                md += "### 🛠️ \(labels.adviceHeading)\n\(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateSettingsMarkdown(language: String? = nil) -> String {
        let code = Self.resolveLanguage(language)
        let labels = Self.markdownLabels(for: code)
        var md = "# ⚙️ \(labels.settingsTitle)\n\n"
        md += "\(labels.settingsIntro)\n\n"
        for s in items(language: code) where s.topic == "setting" {
            md += "## \(s.title)\n"
            md += "**\(labels.summary)**: \(s.summary)\n\n"
            md += "\(s.details)\n\n"
            if let rec = s.recommendation {
                md += "> **💡 \(labels.bestPractice)**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateTroubleshootingMarkdown(language: String? = nil) -> String {
        let code = Self.resolveLanguage(language)
        let labels = Self.markdownLabels(for: code)
        var md = "# 🔧 \(labels.troubleshootingTitle)\n\n"
        md += "\(labels.troubleshootingIntro)\n\n"
        for faq in items(language: code) where faq.topic == "troubleshooting" {
            md += "## \(faq.title)\n"
            md += "**\(labels.summary)**: \(faq.summary)\n\n"
            md += "\(faq.details)\n\n"
            if let rec = faq.recommendation {
                md += "> **💡 \(labels.advice)**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    // MARK: - Per-language dispatch

    static func localizedEntries(for code: String) -> [LocalizedEntry] {
        switch code {
        case "ja": return contentJa()
        case "en": return contentEn()
        case "zh-Hans": return contentZhHans()
        case "zh-Hant": return contentZhHant()
        case "ko": return contentKo()
        case "de": return contentDe()
        case "fr": return contentFr()
        case "es": return contentEs()
        case "it": return contentIt()
        case "pt-PT": return contentPtPT()
        default: return contentEn()
        }
    }

    static func markdownLabels(for code: String) -> MarkdownLabels {
        switch code {
        case "ja": return labelsJa()
        case "zh-Hans": return labelsZhHans()
        case "zh-Hant": return labelsZhHant()
        case "ko": return labelsKo()
        case "de": return labelsDe()
        case "fr": return labelsFr()
        case "es": return labelsEs()
        case "it": return labelsIt()
        case "pt-PT": return labelsPtPT()
        default: return labelsEn()
        }
    }

    // MARK: - Entry catalog (stable ids, topics, tags)

    /// Order here is the order items are returned in. Ids are a stable API —
    /// never rename an existing one; add new entries instead.
    static func entryCatalog() -> [EntryMeta] {
        var list: [EntryMeta] = []
        list.append(contentsOf: featureCatalog())
        list.append(contentsOf: alertCatalog())
        list.append(contentsOf: settingCatalog())
        list.append(contentsOf: troubleshootingCatalog())
        return list
    }

    private static func featureCatalog() -> [EntryMeta] {
        let t = "feature"
        return [
            EntryMeta(id: "feat_network_autoswitch", topic: t, tags: ["network", "firewall", "pf", "packet filter", "lockdown", "stealth", "airdrop", "ssh", "smb", "trusted", "balanced", "free"]),
            EntryMeta(id: "feat_network_history_guard", topic: t, tags: ["ssid", "evil-twin", "gateway", "mac", "network-history", "wifi", "impersonation", "levenshtein", "pro"]),
            EntryMeta(id: "feat_arp_spoof_guard", topic: t, tags: ["arp", "spoofing", "mitm", "eavesdropping", "gateway", "mac", "airgap", "pro", "notify-first", "default-on-pro"]),
            EntryMeta(id: "feat_gateway_arp_lock", topic: t, tags: ["arp", "ndp", "mitm", "gateway", "tofu", "neighbor-cache", "untrusted-network", "pro", "preventive"]),
            EntryMeta(id: "feat_vpn_tunnel", topic: t, tags: ["vpn", "wireguard", "tailscale", "exit-node", "mitm", "killswitch", "tunnel", "pf", "untrusted-network", "pro", "homebrew"]),
            EntryMeta(id: "feat_airgap_containment", topic: t, tags: ["airgap", "air-gap", "containment", "pf", "wifi", "radio", "failsafe", "boot-gate", "emergency", "pro"]),
            EntryMeta(id: "feat_port_anomaly_guard", topic: t, tags: ["port", "devserver", "0.0.0.0", "localhost", "redis", "mongodb", "ollama", "lmstudio", "ai", "llm", "lsof", "isolation", "pro", "default-on-pro"]),
            EntryMeta(id: "feat_active_vuln_scan", topic: t, tags: ["vulnerability", "redis", "memcached", "mongodb", "cors", "path-traversal", "open-redirect", "cve", "opt-in", "mcp", "127.0.0.1"]),
            EntryMeta(id: "feat_nmap_nse", topic: t, tags: ["nmap", "nse", "vulnerability", "scripting-engine", "safe", "opt-in", "supplementary"]),
            EntryMeta(id: "feat_usb_keyboard_guard", topic: t, tags: ["badusb", "usb", "keyboard", "hid", "rubberducky", "omgcable", "flipper", "keystroke-timing", "seize", "pro", "injection"]),
            EntryMeta(id: "feat_usb_storage_guard", topic: t, tags: ["usb", "badusb", "diskarbitration", "clamav", "whitelist", "allowlist", "read-only", "pro", "storage"]),
            EntryMeta(id: "feat_bluetooth_guard", topic: t, tags: ["bluetooth", "blueutil", "ble", "blueborne", "pro", "homebrew", "lockdown"]),
            EntryMeta(id: "feat_webmail_download_guard", topic: t, tags: ["download", "mail", "fsevents", "quarantine", "clamav", "malware", "static-signature", "eicar", "pro"]),
            EntryMeta(id: "feat_ai_model_guard", topic: t, tags: ["ai", "model", "pickle", "safetensors", "gguf", "pytorch", "huggingface", "malware", "pro"]),
            EntryMeta(id: "feat_quarantine_manager", topic: t, tags: ["quarantine", "vault", "restore", "delete", "exclusion", "clamav", "false_positive", "mcp"]),
            EntryMeta(id: "feat_xprotect_file_safety", topic: t, tags: ["xprotect", "gatekeeper", "notarization", "codesign", "quarantine", "file-safety", "free"]),
            EntryMeta(id: "feat_dns_threat_guard", topic: t, tags: ["dns", "quad9", "cloudflare", "adguard", "cleanbrowsing", "phishing", "c2", "pro"]),
            EntryMeta(id: "feat_passive_link_guard", topic: t, tags: ["link", "linkguard", "phishing", "homograph", "hosts", "sinkhole", "system-extension", "content-filter", "doh", "sni", "ja3", "warn", "fail-closed", "feed", "pro", "receive-only"]),
            EntryMeta(id: "feat_link_safety_auditor", topic: t, tags: ["link", "url", "phishing", "homograph", "punycode", "zerotelemetry", "audit", "mcp", "free"]),
            EntryMeta(id: "feat_ransomware_canary_guard", topic: t, tags: ["ransomware", "canary", "bait", "airgap", "sigstop", "freeze", "kqueue", "sha256", "pro", "default-on-pro"]),
            EntryMeta(id: "feat_runtime_threat_containment", topic: t, tags: ["xprotect", "runtime-threat", "airgap", "malware", "log-stream", "gatekeeper", "wifi", "pro", "default-on-pro"]),
            EntryMeta(id: "feat_clickfix_guard", topic: t, tags: ["clickfix", "social-engineering", "terminal", "shell-history", "clipboard", "airgap", "pro", "opt-in"]),
            EntryMeta(id: "feat_persistence_monitor_guard", topic: t, tags: ["persistence", "launchagent", "launchdaemon", "fsevents", "malware", "infostealer", "detection-only", "pro"]),
            EntryMeta(id: "feat_docker_event_guard", topic: t, tags: ["docker", "container", "privileged", "docker.sock", "container-escape", "pro", "notify-only"]),
            EntryMeta(id: "feat_critical_path_fim", topic: t, tags: ["fim", "integrity", "tampering", "sudoers", "sshd_config", "pam", "hosts", "sha256", "baseline", "pro", "default-on-pro"]),
            EntryMeta(id: "feat_security_log_audit", topic: t, tags: ["log", "audit", "unified-logging", "sudo", "ssh", "gatekeeper", "xprotect", "template-anomaly", "csv", "mcp", "free"]),
            EntryMeta(id: "feat_scheduled_log_audit", topic: t, tags: ["log", "audit", "scheduled", "template-anomaly", "z-score", "baseline", "learning", "pro", "default-on-pro"]),
            EntryMeta(id: "feat_containment_incident_timeline", topic: t, tags: ["incident", "timeline", "forensics", "mitre", "att&ck", "airgap", "canary", "port-anomaly", "arp", "runtime-threat"]),
            EntryMeta(id: "feat_notification_history", topic: t, tags: ["notification", "history", "7-days", "eicar", "mcp", "free"]),
            EntryMeta(id: "feat_secret_leak_auditor", topic: t, tags: ["secret", "apikey", "clipboard", "openai", "anthropic", "github", "aws", "stripe", "clickfix", "zerotelemetry", "free"]),
            EntryMeta(id: "feat_secret_leak_audit_tool", topic: t, tags: ["secret", "apikey", "folder-scan", "audit", "zerotelemetry", "tcc", "permission", "mcp", "free"]),
            EntryMeta(id: "feat_package_cve_scan", topic: t, tags: ["cve", "homebrew", "npm", "pypi", "crates.io", "rubygems", "packagist", "go", "maven", "zerotelemetry", "mcp", "free"]),
            EntryMeta(id: "feat_lockfile_tamper_guard", topic: t, tags: ["npm", "yarn", "pnpm", "lockfile", "fim", "sha256", "tampering", "supply-chain", "baseline", "cryptokit", "fsevents", "pro"]),
            EntryMeta(id: "feat_package_lifecycle_script_scan", topic: t, tags: ["npm", "node_modules", "package.json", "lifecycle-script", "postinstall", "preinstall", "prepare", "supply-chain", "heuristic", "mcp", "pro"]),
            EntryMeta(id: "feat_npm_audit_signatures", topic: t, tags: ["npm", "audit", "signatures", "provenance", "registry", "npmjs.com", "opt-in", "network", "mcp", "pro"]),
            EntryMeta(id: "feat_npm_sandboxed_install", topic: t, tags: ["npm", "pnpm", "sandbox-exec", "seatbelt", "install", "lifecycle-script", "postinstall", "network-outbound", "supply-chain", "cli", "pro"]),
            EntryMeta(id: "feat_typosquat_guard", topic: t, tags: ["npm", "pnpm", "typosquatting", "package.json", "levenshtein", "supply-chain", "mcp", "pro"]),
            EntryMeta(id: "feat_sensor_pairing", topic: t, tags: ["sensor", "pairing-code", "tcp", "ed25519", "lan", "trust", "audit", "pro"]),
            EntryMeta(id: "feat_port_scan_guard", topic: t, tags: ["port-scan", "reconnaissance", "nmap", "masscan", "pf", "auto-block", "pro"]),
            EntryMeta(id: "feat_security_health_checker", topic: t, tags: ["audit", "score", "filevault", "sip", "gatekeeper", "firewall", "xprotect", "ssh", "sudo", "accessory", "18-items", "free"]),
            EntryMeta(id: "feat_autonomous_sentinel", topic: t, tags: ["autonomous", "sentinel", "background", "freshclam", "clamav", "scheduled-scan", "pro"]),
            EntryMeta(id: "feat_simulation_self_test", topic: t, tags: ["simulation", "self-test", "test", "ransomware", "airgap", "docker", "eicar"]),
            EntryMeta(id: "feat_privileged_helper", topic: t, tags: ["helper", "xpc", "root", "pfctl", "privilege", "security", "smappservice", "launchdaemon"]),
            EntryMeta(id: "feat_mcp_server", topic: t, tags: ["mcp", "ai", "claude", "read-only", "stdio", "tools", "resources", "zerotelemetry"]),
            EntryMeta(id: "feat_license_pro_tier", topic: t, tags: ["license", "pro", "team", "ed25519", "activation", "devices", "lifetime"]),
        ]
    }

    private static func alertCatalog() -> [EntryMeta] {
        let t = "alert_message"
        return [
            EntryMeta(id: "alert_arp_spoofing", topic: t, tags: ["alert", "arp", "spoofing", "mitm", "wifi", "danger"]),
            EntryMeta(id: "alert_evil_twin_ssid", topic: t, tags: ["alert", "ssid", "evil-twin", "wifi", "impersonation"]),
            EntryMeta(id: "alert_unencrypted_wifi", topic: t, tags: ["alert", "wifi", "open", "unencrypted", "wep", "lockdown"]),
            EntryMeta(id: "alert_port_anomaly", topic: t, tags: ["alert", "port", "anomaly", "exposed", "0.0.0.0", "devserver"]),
            EntryMeta(id: "alert_exposed_database", topic: t, tags: ["alert", "port", "database", "redis", "mongodb", "exposed", "danger"]),
            EntryMeta(id: "alert_unapproved_keyboard", topic: t, tags: ["alert", "usb", "keyboard", "badusb", "hid"]),
            EntryMeta(id: "alert_scripted_keyboard", topic: t, tags: ["alert", "usb", "keyboard", "badusb", "keystroke-timing", "danger"]),
            EntryMeta(id: "alert_untrusted_usb", topic: t, tags: ["alert", "usb", "storage", "untrusted", "eject", "read-only", "badusb"]),
            EntryMeta(id: "alert_malware_usb", topic: t, tags: ["alert", "malware", "virus", "usb", "clamav", "danger"]),
            EntryMeta(id: "alert_quarantined_download", topic: t, tags: ["alert", "download", "quarantine", "clamav", "trojan", "malware"]),
            EntryMeta(id: "alert_eicar_test_signature", topic: t, tags: ["alert", "eicar", "test", "clamav", "notification-history"]),
            EntryMeta(id: "alert_pickle_model", topic: t, tags: ["alert", "pickle", "ai", "model", "safetensors", "download"]),
            EntryMeta(id: "alert_link_guard_blocked", topic: t, tags: ["alert", "link", "linkguard", "phishing", "blocked"]),
            EntryMeta(id: "alert_link_guard_warn_hold", topic: t, tags: ["alert", "link", "linkguard", "warn", "hold", "fail-closed"]),
            EntryMeta(id: "alert_dangerous_url", topic: t, tags: ["alert", "url", "link", "phishing", "homograph", "danger"]),
            EntryMeta(id: "alert_ransomware_activity", topic: t, tags: ["alert", "ransomware", "canary", "airgap", "emergency", "danger"]),
            EntryMeta(id: "alert_runtime_threat_airgap", topic: t, tags: ["alert", "xprotect", "malware", "airgap", "emergency", "danger"]),
            EntryMeta(id: "alert_gatekeeper_block", topic: t, tags: ["alert", "gatekeeper", "unsigned", "notify-only"]),
            EntryMeta(id: "alert_clickfix_command", topic: t, tags: ["alert", "clickfix", "terminal", "clipboard", "airgap", "danger"]),
            EntryMeta(id: "alert_new_persistence_item", topic: t, tags: ["alert", "persistence", "launchagent", "launchdaemon", "malware"]),
            EntryMeta(id: "alert_docker_risk", topic: t, tags: ["alert", "docker", "privileged", "docker.sock"]),
            EntryMeta(id: "alert_critical_file_tampering", topic: t, tags: ["alert", "fim", "tampering", "sudoers", "sshd_config", "hosts", "danger"]),
            EntryMeta(id: "alert_log_audit_anomaly", topic: t, tags: ["alert", "log", "audit", "template-anomaly", "z-score"]),
            EntryMeta(id: "alert_secret_in_clipboard", topic: t, tags: ["alert", "secret", "apikey", "clipboard"]),
            EntryMeta(id: "alert_airgap_failed", topic: t, tags: ["alert", "airgap", "failed", "helper", "danger"]),
            EntryMeta(id: "alert_helper_disconnected", topic: t, tags: ["alert", "helper", "xpc", "error", "troubleshooting"]),
            EntryMeta(id: "alert_score_drop", topic: t, tags: ["alert", "score", "audit", "health", "recommendation"]),
        ]
    }

    private static func settingCatalog() -> [EntryMeta] {
        let t = "setting"
        return [
            EntryMeta(id: "set_trusted_networks", topic: t, tags: ["settings", "networks", "trusted", "levels", "register"]),
            EntryMeta(id: "set_away_default_level", topic: t, tags: ["settings", "away", "default", "levels", "untrusted-network"]),
            EntryMeta(id: "set_manual_override", topic: t, tags: ["settings", "override", "timer", "revert", "duration"]),
            EntryMeta(id: "set_pro_default_guards", topic: t, tags: ["settings", "pro", "defaults", "guards", "opt-in", "default-on-pro"]),
            EntryMeta(id: "set_usb_whitelist", topic: t, tags: ["settings", "usb", "whitelist", "allowlist", "readonly", "keyboard", "pro"]),
            EntryMeta(id: "set_watched_folders", topic: t, tags: ["settings", "watched_folders", "downloads", "fsevents", "pro"]),
            EntryMeta(id: "set_dns_policy", topic: t, tags: ["settings", "dns", "quad9", "cloudflare", "adguard", "cleanbrowsing", "policy", "pro"]),
            EntryMeta(id: "set_link_guard_modes", topic: t, tags: ["settings", "link", "linkguard", "warn", "block", "allowlist", "feed", "system-extension", "pro"]),
            EntryMeta(id: "set_vpn_backend", topic: t, tags: ["settings", "vpn", "wireguard", "tailscale", "exit-node", "killswitch", "pro"]),
            EntryMeta(id: "set_language", topic: t, tags: ["settings", "language", "localization", "mcp"]),
        ]
    }

    private static func troubleshootingCatalog() -> [EntryMeta] {
        let t = "troubleshooting"
        return [
            EntryMeta(id: "faq_free_vs_pro", topic: t, tags: ["faq", "free", "pro", "features", "comparison", "license"]),
            EntryMeta(id: "faq_homebrew_clamav", topic: t, tags: ["faq", "clamav", "homebrew", "install", "antivirus", "troubleshooting"]),
            EntryMeta(id: "faq_blueutil_setup", topic: t, tags: ["faq", "bluetooth", "blueutil", "homebrew", "setup"]),
            EntryMeta(id: "faq_helper_troubleshooting", topic: t, tags: ["faq", "helper", "troubleshooting", "xpc", "repair"]),
            EntryMeta(id: "faq_install_location", topic: t, tags: ["faq", "install", "applications", "translocation", "dmg", "helper"]),
            EntryMeta(id: "faq_network_cut_off", topic: t, tags: ["faq", "airgap", "network", "offline", "wifi", "release", "failsafe"]),
            EntryMeta(id: "faq_quarantine_false_positive", topic: t, tags: ["faq", "quarantine", "restore", "false_positive", "clamav", "exclusion"]),
            EntryMeta(id: "faq_eicar_test", topic: t, tags: ["faq", "eicar", "test", "clamav", "notification-history"]),
            EntryMeta(id: "faq_dev_server_blocked", topic: t, tags: ["faq", "port", "devserver", "blocked", "allow", "localsend", "syncthing"]),
            EntryMeta(id: "faq_link_guard_false_block", topic: t, tags: ["faq", "link", "linkguard", "false_positive", "allowlist", "warn"]),
            EntryMeta(id: "faq_system_extension_approval", topic: t, tags: ["faq", "system-extension", "content-filter", "approval", "linkguard"]),
            EntryMeta(id: "faq_keyboard_blocked", topic: t, tags: ["faq", "keyboard", "usb", "badusb", "accessibility", "approve"]),
            EntryMeta(id: "faq_vpn_troubleshooting", topic: t, tags: ["faq", "vpn", "wireguard", "tailscale", "exit-node", "killswitch", "app-store"]),
            EntryMeta(id: "faq_log_audit_repeated_alerts", topic: t, tags: ["faq", "log", "audit", "template-anomaly", "learning", "notification"]),
            EntryMeta(id: "faq_mcp_setup", topic: t, tags: ["faq", "mcp", "claude", "setup", "stdio", "language"]),
            EntryMeta(id: "faq_zero_telemetry", topic: t, tags: ["faq", "privacy", "zero_telemetry", "security", "telemetry", "network"]),
        ]
    }
}
