// Mirrored from RoamSwitchTests/ — RoamSwitch 1.9.47 (build 104). Do not edit here; see SYNC.md.

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
