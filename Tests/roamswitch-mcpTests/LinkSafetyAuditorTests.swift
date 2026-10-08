// Mirrored from RoamSwitchTests/ — RoamSwitch 1.11.2 (build 149). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class LinkSafetyAuditorTests: XCTestCase {

    func testSafeLegitimateURL() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("https://www.apple.com")

        XCTAssertEqual(report.domain, "www.apple.com")
        XCTAssertTrue(report.isHTTPS)
        XCTAssertEqual(report.riskLevel, .safe)
        XCTAssertGreaterThanOrEqual(report.score, 80)
        XCTAssertTrue(report.riskFactors.isEmpty)
    }

    func testPlainHTTP_penalty() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("http://example.org")

        XCTAssertFalse(report.isHTTPS)
        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("暗号化なし") })
        XCTAssertLessThan(report.score, 100)
    }

    func testIPAddressURL_flaggedAsDangerous() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("http://192.168.1.100/admin")

        XCTAssertEqual(report.riskLevel, .dangerous)
        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("IPアドレス直打ち") })
    }

    // MARK: - Numeric hosts and credentials in the authority

    func testObfuscatedNumericHostsAreIPAddressHosts() {
        let auditor = LinkSafetyAuditor.shared
        for url in ["http://2130706433/", "http://0x7f.1/", "http://0x7f000001/login", "http://0177.0.0.1/", "http://127.1/", "https://3232235777/x"] {
            let report = auditor.analyzeURL(url)
            XCTAssertTrue(report.riskFactors.contains { $0.kind == .ipAddressHost }, url)
            XCTAssertEqual(report.riskLevel, .dangerous, url)
            XCTAssertTrue(report.riskFactors.first { $0.kind == .ipAddressHost }?.title.contains("数値表記") == true, "\(url) should say the number was disguised")
        }
        let plain = auditor.analyzeURL("http://192.168.1.100/admin")
        XCTAssertFalse(plain.riskFactors.first { $0.kind == .ipAddressHost }?.title.contains("数値表記") == true)
    }

    func testNumericHostHelpersDoNotTouchRealDomains() {
        for host in ["example.com", "1password.com", "123.example.com", "a.1", "0xg.com", "x.0x7f", "1.2.3.4.5", ""] {
            XCTAssertFalse(LinkSafetyAuditor.isNumericIPv4Host(host), host)
        }
        XCTAssertTrue(LinkSafetyAuditor.isNumericIPv4Host("1.2.3.4"))
        XCTAssertFalse(LinkSafetyAuditor.isObfuscatedIPv4Host("1.2.3.4"))
        XCTAssertFalse(LinkSafetyAuditor.isObfuscatedIPv4Host("192.168.0.1"))
        XCTAssertTrue(LinkSafetyAuditor.isObfuscatedIPv4Host("192.168.0.01"))
        XCTAssertTrue(LinkSafetyAuditor.isObfuscatedIPv4Host("1.2.3.999"))
    }

    func testDomainLookalikeBeforeAtSignIsSevere() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://apple.com@evil.example/signin")
        XCTAssertEqual(report.domain, "evil.example")
        let factor = report.riskFactors.first { $0.kind == .urlUserInfo }
        XCTAssertNotNil(factor)
        XCTAssertEqual(factor?.isSevere, true)
        XCTAssertEqual(report.riskLevel, .dangerous)
    }

    func testPlainUserInfoIsFlaggedButNotSevereAlone() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://bob:pw@example.org/")
        let factor = report.riskFactors.first { $0.kind == .urlUserInfo }
        XCTAssertEqual(factor?.isSevere, false)
        XCTAssertEqual(report.riskLevel, .caution)
    }

    func testNoUserInfoFactorForOrdinaryURLs() {
        XCTAssertFalse(LinkSafetyAuditor.shared.analyzeURL("https://www.apple.com/jp/").riskFactors.contains { $0.kind == .urlUserInfo })
        XCTAssertFalse(LinkSafetyAuditor.shared.analyzeURL("https://example.org/a@b").riskFactors.contains { $0.kind == .urlUserInfo }, "an @ in the path is not credentials")
    }

    func testSubdomainSpoofing_detected() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("https://apple.com.account-verify.xyz/login")

        XCTAssertEqual(report.riskLevel, .dangerous)
        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("ブランド名偽装") })
        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("高リスクTLD") })
    }

    func testHomographPunycode_detected() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("https://xn--pple-43d.com")

        XCTAssertEqual(report.riskLevel, .dangerous)
        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("ホモグラフ攻撃") })
    }

    func testHighRiskTLD_detected() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("https://free-prizes.click")

        XCTAssertTrue(report.riskFactors.contains { $0.title.contains("高リスクTLD") })
    }

    func testInvalidURL_returnsDangerous() {
        let auditor = LinkSafetyAuditor.shared
        let report = auditor.analyzeURL("   ")

        XCTAssertEqual(report.riskLevel, .dangerous)
        XCTAssertEqual(report.score, 0)
    }

    // MARK: - LinkGuardVerdict (mirrors roamswitch-core::link_guard::Verdict)

    func testVerdict_brandHomograph_isBlock() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://xn--pple-43d.com")
        XCTAssertEqual(report.verdict, .block)
    }

    func testVerdict_brandImpersonation_isWarnNotBlock() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://apple.com.account-verify.xyz/login")
        XCTAssertEqual(report.verdict, .warn)
    }

    func testVerdict_cleanURL_isAllow() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://www.google.com/search?q=test")
        XCTAssertEqual(report.verdict, .allow)
    }

    func testHomograph_factorCarriesLanguageIndependentKind() {
        let report = LinkSafetyAuditor.shared.analyzeURL("https://xn--pple-43d.com")
        XCTAssertTrue(report.riskFactors.contains { $0.kind == .homograph && $0.isSevere })
    }

    /// Regression: `verdict` used to match the *translated* title
    /// ("ホモグラフ"/"homograph"), so in de/es/it/ko/pt-PT/zh a homograph was
    /// downgraded from block to warn. It must key off `kind` only.
    func testVerdict_homographIsBlockRegardlessOfTitleLanguage() {
        for title in ["Verdacht auf Homographen-Angriff", "호모그래프 공격 의심", "疑似同形异义字攻击", "Suspeita de ataque homógrafo"] {
            let report = LinkAuditReport(
                originalURLString: "https://xn--pple-43d.com",
                finalURLString: "https://xn--pple-43d.com",
                redirectChain: [],
                domain: "xn--pple-43d.com",
                score: 50,
                riskLevel: .dangerous,
                riskFactors: [LinkRiskFactor(title: title, detail: "", isSevere: true, kind: .homograph)],
                isHTTPS: true
            )
            XCTAssertEqual(report.verdict, .block, title)
        }
    }

    func testVerdict_kindWinsOverMisleadingTitle() {
        let report = LinkAuditReport(
            originalURLString: "https://apple.com.x.xyz",
            finalURLString: "https://apple.com.x.xyz",
            redirectChain: [],
            domain: "apple.com.x.xyz",
            score: 20,
            riskLevel: .dangerous,
            riskFactors: [LinkRiskFactor(title: "homograph-looking brand text", detail: "", isSevere: true, kind: .brandSubdomainSpoofing)],
            isHTTPS: true
        )
        XCTAssertEqual(report.verdict, .warn)
    }

    func testLinkRiskFactor_decodesLegacyJSONWithoutKind() throws {
        let data = Data(#"{"title":"ホモグラフ攻撃の疑い","detail":"d","isSevere":true}"#.utf8)
        let factor = try JSONDecoder().decode(LinkRiskFactor.self, from: data)
        XCTAssertNil(factor.kind)
    }

    func testLinkGuardMode_persistsAndReads() {
        // The enum used by LinkGuardManager / the menu picker.
        XCTAssertEqual(LinkGuardMode(rawValue: "block"), .block)
        XCTAssertEqual(LinkGuardMode.allCases.count, 3)
    }
}
