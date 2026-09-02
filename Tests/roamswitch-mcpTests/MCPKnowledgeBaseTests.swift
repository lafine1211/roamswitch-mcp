// Mirrored from RoamSwitchTests/ — RoamSwitch 1.7.3 (build 43). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class MCPKnowledgeBaseTests: XCTestCase {
    private let kb = RoamSwitchKnowledgeBase.shared

    func testKnowledgeBase_hasItems() {
        XCTAssertGreaterThan(kb.allItems.count, 20)
    }

    func testSearch_topicFiltering() {
        let features = kb.search(topic: "feature")
        XCTAssertGreaterThanOrEqual(features.totalResults, 12)
        XCTAssertTrue(features.items.allSatisfy { $0.topic == "feature" })

        let alerts = kb.search(topic: "alert_message")
        XCTAssertGreaterThanOrEqual(alerts.totalResults, 8)
        XCTAssertTrue(alerts.items.allSatisfy { $0.topic == "alert_message" })

        let settings = kb.search(topic: "setting")
        XCTAssertGreaterThanOrEqual(settings.totalResults, 5)
        XCTAssertTrue(settings.items.allSatisfy { $0.topic == "setting" })

        let troubleshooting = kb.search(topic: "troubleshooting")
        XCTAssertGreaterThanOrEqual(troubleshooting.totalResults, 5)
        XCTAssertTrue(troubleshooting.items.allSatisfy { $0.topic == "troubleshooting" })
    }

    func testSearch_queryKeywords() {
        let arpResult = kb.search(query: "ARP")
        XCTAssertGreaterThanOrEqual(arpResult.totalResults, 2)
        XCTAssertTrue(arpResult.items.contains { $0.id == "feat_arp_spoof_guard" || $0.id == "alert_arp_spoofing" })

        let usbResult = kb.search(query: "USB")
        XCTAssertGreaterThanOrEqual(usbResult.totalResults, 3)

        let helperResult = kb.search(query: "ヘルパー")
        XCTAssertGreaterThanOrEqual(helperResult.totalResults, 2)

        let clamavResult = kb.search(query: "ClamAV")
        XCTAssertGreaterThanOrEqual(clamavResult.totalResults, 4)

        let ransomwareResult = kb.search(query: "ランサムウェア")
        XCTAssertGreaterThanOrEqual(ransomwareResult.totalResults, 2)
    }

    func testResources_allValidURIs() {
        let uris = [
            "roamswitch://docs/features",
            "roamswitch://docs/alerts-and-messages",
            "roamswitch://docs/settings-guide",
            "roamswitch://docs/troubleshooting",
        ]

        for uri in uris {
            guard let content = kb.resource(for: uri) else {
                XCTFail("Resource \(uri) returned nil")
                continue
            }
            XCTAssertFalse(content.isEmpty, "Resource \(uri) should not be empty")
            XCTAssertTrue(content.contains("# "), "Resource \(uri) should contain markdown header")
        }

        XCTAssertNil(kb.resource(for: "roamswitch://docs/nonexistent"))
    }
}
