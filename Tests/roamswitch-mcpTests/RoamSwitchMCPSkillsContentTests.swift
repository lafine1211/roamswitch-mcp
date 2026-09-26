// Mirrored from RoamSwitchTests/ — RoamSwitch 1.10.5 (build 123). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class RoamSwitchMCPSkillsContentTests: XCTestCase {
    func testCatalogEntriesMatchAvailableContent() {
        let entries = RoamSwitchMCPSkillsContent.catalogEntries
        XCTAssertEqual(entries.count, 4)

        var seenURIs = Set<String>()
        for entry in entries {
            XCTAssertTrue(seenURIs.insert(entry.uri).inserted, "Duplicate skill URI: \(entry.uri)")
            XCTAssertTrue(entry.uri.hasPrefix("roamswitch://skills/"), "Unexpected skill URI shape: \(entry.uri)")
            XCTAssertFalse(entry.name.isEmpty)
            XCTAssertFalse(entry.description.isEmpty)

            guard let content = RoamSwitchMCPSkillsContent.skillsByURI[entry.uri] else {
                XCTFail("No content registered for catalog entry \(entry.uri)")
                continue
            }
            XCTAssertTrue(content.hasPrefix("---\nname:"), "Skill \(entry.uri) should start with YAML frontmatter")
            for section in ["## When to Use", "## Prerequisites", "## Workflow", "## Verification"] {
                XCTAssertTrue(content.contains(section), "Skill \(entry.uri) is missing section \(section)")
            }
        }
    }

    func testSkillsByURIHasNoOrphanContent() {
        let catalogURIs = Set(RoamSwitchMCPSkillsContent.catalogEntries.map { $0.uri })
        XCTAssertEqual(catalogURIs, Set(RoamSwitchMCPSkillsContent.skillsByURI.keys))
    }
}
