// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.7.6 (build 46).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public enum LinkRiskLevel: String, Codable, Equatable {
    case safe = "safe"
    case caution = "caution"
    case dangerous = "dangerous"

    public var label: String {
        switch self {
        case .safe: return loc("安全 (Low Risk)")
        case .caution: return loc("注意 (Suspicious)")
        case .dangerous: return loc("危険 (High Risk)")
        }
    }
}

public struct LinkRiskFactor: Identifiable, Codable, Equatable {
    public var id: String { title }
    public let title: String
    public let detail: String
    public let isSevere: Bool

    public init(title: String, detail: String, isSevere: Bool) {
        self.title = title
        self.detail = detail
        self.isSevere = isSevere
    }
}

public struct LinkAuditReport: Equatable {
    public let originalURLString: String
    public let finalURLString: String
    public let redirectChain: [String]
    public let domain: String
    public let score: Int
    public let riskLevel: LinkRiskLevel
    public let riskFactors: [LinkRiskFactor]
    public let isHTTPS: Bool
}

/// Enforcement decision for the passive link guard — mirrors
/// `roamswitch-core::link_guard::Verdict` on Linux. `riskLevel` is for display;
/// this is what an interception layer would actually do.
public enum LinkGuardVerdict: String, Codable, Equatable {
    case allow, warn, block

    public var label: String {
        switch self {
        case .allow: return loc("リンク保護では問題として扱いません")
        case .warn: return loc("リンク保護なら警告を表示します")
        case .block: return loc("リンク保護ならこのサイトへの接続を遮断します")
        }
    }

    public var icon: String {
        switch self {
        case .allow: return "✓"
        case .warn: return "⚠️"
        case .block: return "🚫"
        }
    }
}

/// The user-selectable link-guard mode (menu picker + `LinkGuardManager`).
/// Lives here, not in `LinkGuardManager.swift`, so the roamswitch-mcp mirror and
/// its tests compile without that file's AppKit/Combine dependencies.
/// `off` removes the managed `/etc/hosts` section; `warn` loads the feed but
/// does not sinkhole; `block` sinkholes (Linux parity, the 1.7.2 default).
public enum LinkGuardMode: String, CaseIterable, Codable {
    case off, warn, block

    public var displayName: String {
        switch self {
        case .off: return loc("オフ")
        case .warn: return loc("警告のみ (遮断しない)")
        case .block: return loc("明らかな詐欺サイトは自動でブロック (推奨)")
        }
    }
}

public extension LinkAuditReport {
    /// Only a Unicode/Punycode **homograph** host is ever `.block` from
    /// heuristics alone (matching Linux: feed hit OR brand homograph).
    /// Brand-in-subdomain impersonation, high-risk TLDs, etc. are `.warn`.
    var verdict: LinkGuardVerdict {
        let homograph = riskFactors.contains {
            $0.isSevere && ($0.title.contains("ホモグラフ") || $0.title.lowercased().contains("homograph"))
        }
        if homograph { return .block }
        if riskLevel == .dangerous || riskLevel == .caution || score < 60 { return .warn }
        return .allow
    }
}

public final class LinkSafetyAuditor {
    public static let shared = LinkSafetyAuditor()

    private let highRiskTLDs: Set<String> = [
        "xyz", "top", "work", "click", "tk", "ml", "ga", "cf", "gq",
        "buzz", "fit", "rest", "surf", "casa", "bar", "icu", "cam"
    ]

    private let targetBrandKeywords: [String] = [
        "apple", "icloud", "google", "microsoft", "paypal", "amazon",
        "netflix", "line", "yahoo", "rakuten", "smbc", "mufg", "mizuho",
        "chase", "wellsfargo", "bankofamerica", "binance", "coinbase"
    ]

    private let suspiciousPathKeywords: [String] = [
        "verify", "login", "signin", "account-update", "secure-login",
        "confirm-identity", "password-reset", "auth-check", "billing-update"
    ]

    // MARK: - Synchronous Analysis (Offline / Fast)

    public func analyzeURL(_ urlString: String) -> LinkAuditReport {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed

        guard let url = URL(string: normalized), let host = url.host?.lowercased() else {
            return LinkAuditReport(
                originalURLString: urlString,
                finalURLString: urlString,
                redirectChain: [],
                domain: loc("無効なURL"),
                score: 0,
                riskLevel: .dangerous,
                riskFactors: [LinkRiskFactor(title: loc("不正なURL形式"), detail: loc("URLの構造が無効または解析不能です。"), isSevere: true)],
                isHTTPS: false
            )
        }

        var riskFactors: [LinkRiskFactor] = []
        var penaltyScore = 0

        // 1. Check Protocol (HTTPS vs HTTP)
        let isHTTPS = url.scheme?.lowercased() == "https"
        if !isHTTPS {
            penaltyScore += 25
            riskFactors.append(LinkRiskFactor(
                title: loc("暗号化なし (HTTP通信)"),
                detail: loc("通信が暗号化されていないため、盗聴や改ざんのリスクがあります。"),
                isSevere: false
            ))
        }

        // 2. Check for IP address instead of domain name
        if isIPAddress(host) {
            penaltyScore += 45
            riskFactors.append(LinkRiskFactor(
                title: loc("IPアドレス直打ちURL"),
                detail: loc("ドメイン名ではなくIPアドレス（例: http://45.33.x.x）を直接指定している不審な接続先です。"),
                isSevere: true
            ))
        }

        // 3. Check for Homograph / Punycode Attacks (e.g. xn--...)
        if host.hasPrefix("xn--") || containsNonASCII(host) {
            penaltyScore += 50
            riskFactors.append(LinkRiskFactor(
                title: loc("ホモグラフ攻撃の疑い (Unicode偽装ドメイン)"),
                detail: loc("見た目が正規ドメインに酷似したキリル文字やPunycode（xn--）が使用されている詐欺ドメインの疑いがあります。"),
                isSevere: true
            ))
        }

        // 4. Check for Subdomain Spoofing (e.g. apple.com.secure-auth.xyz)
        if let spoofedBrand = detectSubdomainSpoofing(host: host) {
            penaltyScore += 50
            riskFactors.append(LinkRiskFactor(
                title: String(format: loc("ブランド名偽装の疑い (%@)"), spoofedBrand),
                detail: String(format: loc("「%@」の正規ドメインではなく、サブドメインにブランド名を含めたフィッシングドメインです。"), spoofedBrand),
                isSevere: true
            ))
        }

        // 5. Check High-Risk TLDs (.xyz, .top, etc.)
        let tld = (host as NSString).pathExtension.lowercased()
        if highRiskTLDs.contains(tld) {
            penaltyScore += 30
            riskFactors.append(LinkRiskFactor(
                title: String(format: loc("高リスクTLD (.%@)"), tld),
                detail: String(format: loc("フィッシング詐欺やスパムメールで頻繁に悪用されるドメイン末尾（.%@）です。"), tld),
                isSevere: false
            ))
        }

        // 6. Check for Non-standard Ports (e.g. :8080, :4444)
        if let port = url.port, port != 80, port != 443, port != 8080, port != 8443 {
            penaltyScore += 25
            riskFactors.append(LinkRiskFactor(
                title: String(format: loc("非標準ポート指定 (Port %d)"), port),
                detail: loc("Web標準（80/443）以外の特殊ポートへの通信を要求しています。"),
                isSevere: false
            ))
        }

        // 7. Check for Phishing Path Keywords
        let pathAndQuery = (url.path + (url.query ?? "")).lowercased()
        for kw in suspiciousPathKeywords {
            if pathAndQuery.contains(kw) && (tld.isEmpty || highRiskTLDs.contains(tld) || isIPAddress(host)) {
                penaltyScore += 20
                riskFactors.append(LinkRiskFactor(
                    title: String(format: loc("認証・アカウント詐取キーワード (%@)"), kw),
                    detail: loc("アカウント認証や決済情報を詐取するためのページURL構造が見られます。"),
                    isSevere: true
                ))
                break
            }
        }

        let calculatedScore = max(0, 100 - penaltyScore)
        let hasSevere = riskFactors.contains { $0.isSevere }
        let riskLevel: LinkRiskLevel
        if calculatedScore >= 80 && riskFactors.isEmpty {
            riskLevel = .safe
        } else if hasSevere || calculatedScore < 50 {
            riskLevel = .dangerous
        } else {
            riskLevel = .caution
        }

        return LinkAuditReport(
            originalURLString: urlString,
            finalURLString: normalized,
            redirectChain: [],
            domain: host,
            score: calculatedScore,
            riskLevel: riskLevel,
            riskFactors: riskFactors,
            isHTTPS: isHTTPS
        )
    }

    // MARK: - Asynchronous Analysis with Safe Redirect Expansion

    public func analyzeURLWithRedirects(_ urlString: String) async -> LinkAuditReport {
        let baseReport = analyzeURL(urlString)
        guard let url = URL(string: baseReport.finalURLString) else {
            return baseReport
        }

        // Safely trace redirects without executing page content or downloading full payload
        let (chain, finalURL) = await traceRedirectChain(from: url)
        if chain.count > 1, let lastURL = chain.last {
            let finalReport = analyzeURL(lastURL)
            var mergedFactors = baseReport.riskFactors
            for factor in finalReport.riskFactors {
                if !mergedFactors.contains(where: { $0.title == factor.title }) {
                    mergedFactors.append(factor)
                }
            }

            let finalScore = min(baseReport.score, finalReport.score)
            let hasSevere = mergedFactors.contains { $0.isSevere }
            let riskLevel: LinkRiskLevel
            if finalScore >= 80 && mergedFactors.isEmpty {
                riskLevel = .safe
            } else if hasSevere || finalScore < 50 {
                riskLevel = .dangerous
            } else {
                riskLevel = .caution
            }

            return LinkAuditReport(
                originalURLString: urlString,
                finalURLString: lastURL,
                redirectChain: chain,
                domain: URL(string: lastURL)?.host ?? finalReport.domain,
                score: finalScore,
                riskLevel: riskLevel,
                riskFactors: mergedFactors,
                isHTTPS: URL(string: lastURL)?.scheme?.lowercased() == "https"
            )
        }

        return baseReport
    }

    // MARK: - Helper Algorithms

    private func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                guard let n = Int(part) else { return false }
                return (0...255).contains(n)
            }
        }
        return host.contains(":") // IPv6
    }

    private func containsNonASCII(_ str: String) -> Bool {
        str.unicodeScalars.contains { !$0.isASCII }
    }

    private func detectSubdomainSpoofing(host: String) -> String? {
        let parts = host.split(separator: ".")
        guard parts.count >= 3 else { return nil }

        let actualDomainAndTLD = parts.suffix(2).joined(separator: ".")
        let subdomains = parts.dropLast(2).joined(separator: ".")

        for brand in targetBrandKeywords {
            if subdomains.contains(brand) && !actualDomainAndTLD.contains(brand) {
                return brand
            }
        }
        return nil
    }

    private func isPrivateOrLocalHost(_ host: String) -> Bool {
        let lowered = host.lowercased()
        if lowered == "localhost" || lowered.hasSuffix(".localhost") || lowered.hasSuffix(".local") {
            return true
        }
        if lowered == "127.0.0.1" || lowered == "::1" || lowered == "0.0.0.0" {
            return true
        }
        let parts = host.split(separator: ".")
        if parts.count == 4, let p0 = Int(parts[0]), let p1 = Int(parts[1]) {
            if p0 == 10 { return true }                                // 10.0.0.0/8
            if p0 == 127 { return true }                               // 127.0.0.0/8
            if p0 == 169 && p1 == 254 { return true }                  // 169.254.0.0/16 (Link Local / Cloud Metadata)
            if p0 == 172 && (16...31).contains(p1) { return true }     // 172.16.0.0/12
            if p0 == 192 && p1 == 168 { return true }                  // 192.168.0.0/16
        }
        return false
    }

    private final class NonRedirectingSessionDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            // Stop automatic redirect following so each hop is inspected safely
            completionHandler(nil)
        }
    }

    private func traceRedirectChain(from initialURL: URL) async -> ([String], URL) {
        var chain: [String] = [initialURL.absoluteString]
        var currentURL = initialURL

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3.0
        config.timeoutIntervalForResource = 3.0
        let delegate = NonRedirectingSessionDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

        for _ in 0..<5 {
            guard let host = currentURL.host, !isPrivateOrLocalHost(host) else {
                // Stop trace on private/local destinations to prevent SSRF
                break
            }

            var request = URLRequest(url: currentURL)
            request.httpMethod = "HEAD"

            guard let (_, response) = try? await session.data(for: request),
                  let httpResponse = response as? HTTPURLResponse else {
                break
            }

            if (301...308).contains(httpResponse.statusCode),
               let location = httpResponse.value(forHTTPHeaderField: "Location"),
               let nextURL = URL(string: location, relativeTo: currentURL)?.absoluteURL {
                currentURL = nextURL
                chain.append(nextURL.absoluteString)
            } else {
                break
            }
        }

        return (chain, currentURL)
    }
}
