// Mirrored from RoamSwitchTests/ — RoamSwitch 1.10.18 (build 136). Do not edit here; see SYNC.md.

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

    /// Regression guard: `feat_exec_recorder`'s KB text lists every
    /// `exec.*` correlation rule by id, but nothing enforced that — rules 8
    /// (`interpreter_inline_obfuscated`) and 9 (`dyld_insert_libraries`)
    /// shipped without ever being added to this text, in every language,
    /// and rule 10 (`ransomware_recovery_tampering`) almost repeated it.
    /// This ties the two together mechanically: add a rule to
    /// `ExecRuleID.all` (`Shared/ExecCorrelationRules.swift`) without
    /// mentioning its id here (in all 10 languages), and this test fails
    /// instead of the KB doc silently going stale again.
    ///
    /// The ids are duplicated as string literals rather than referencing
    /// `ExecRuleID.all` directly: this test file is mirrored verbatim into
    /// the `roamswitch-mcp` package (see that repo's `SYNC.md`), whose
    /// smaller module never links `ExecCorrelationRules.swift` (the live
    /// eslogger-driven engine has no place in a read-only log reader) —
    /// syncing that file over just for this one test would pull real-time
    /// detection logic into a context that intentionally never runs it.
    /// Keep this list in sync with `ExecRuleID.all` by hand.
    func testEveryExecRuleIDIsMentionedInTheKnowledgeBaseInEveryLanguage() {
        let allExecRuleIDs = [
            "exec.shell_from_app", "exec.untrusted_location", "exec.pipe_to_shell", "exec.osascript_obfuscated",
            "exec.quarantine_stripped_then_exec", "exec.launchd_untrusted_binary", "exec.keychain_access",
            "exec.interpreter_inline_obfuscated", "exec.dyld_insert_libraries", "exec.ransomware_recovery_tampering",
            "exec.honeytoken_path",
        ]
        for code in RoamSwitchKnowledgeBase.supportedLanguageCodes {
            let entries = RoamSwitchKnowledgeBase.localizedEntries(for: code)
            guard let entry = entries.first(where: { $0.id == "feat_exec_recorder" }) else {
                XCTFail("feat_exec_recorder entry missing for language \(code)")
                continue
            }
            for ruleID in allExecRuleIDs {
                XCTAssertTrue(entry.details.contains(ruleID), "\(code): feat_exec_recorder details is missing \(ruleID)")
            }
        }
    }
}
