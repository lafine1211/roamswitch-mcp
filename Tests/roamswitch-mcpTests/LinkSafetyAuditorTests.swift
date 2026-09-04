// Mirrored from RoamSwitchTests/ — RoamSwitch 1.8.2 (build 49). Do not edit here; see SYNC.md.

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

    func testLinkGuardMode_persistsAndReads() {
        // The enum used by LinkGuardManager / the menu picker.
        XCTAssertEqual(LinkGuardMode(rawValue: "block"), .block)
        XCTAssertEqual(LinkGuardMode.allCases.count, 3)
    }
}
