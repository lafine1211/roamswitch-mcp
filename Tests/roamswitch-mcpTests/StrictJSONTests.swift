// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.10 (build 189). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class StrictJSONTests: XCTestCase {

    private func data(_ s: String) -> Data { Data(s.utf8) }

    func testRepeatedKeysAreRefusedAtAnyDepth() {
        XCTAssertNoThrow(try StrictJSON.validate(data(#"{"a":1,"b":{"c":[1,{"d":2}]}}"#)))
        XCTAssertThrowsError(try StrictJSON.validate(data(#"{"a":1,"a":2}"#))) { XCTAssertEqual($0 as? StrictJSON.Failure, .duplicateKey("a")) }
        XCTAssertThrowsError(try StrictJSON.validate(data(#"{"files":{"/x":{"sha":"1"},"/y":{},"/x":{"sha":"2"}}}"#)))
        XCTAssertThrowsError(try StrictJSON.validate(data(#"[{"k":1,"k":1}]"#)))
        // the same key in two different objects is fine
        XCTAssertNoThrow(try StrictJSON.validate(data(#"{"a":{"k":1},"b":{"k":2}}"#)))
    }

    func testEscapedSpellingsOfOneKeyAreTheSameKey() {
        XCTAssertThrowsError(try StrictJSON.validate(data(#"{"a":1,"a":2}"#))) { XCTAssertEqual($0 as? StrictJSON.Failure, .duplicateKey("a")) }
        XCTAssertThrowsError(try StrictJSON.validate(data(#"{"a\/b":1,"a/b":2}"#)))
        XCTAssertNoThrow(try StrictJSON.validate(data(#"{"é":1,"e":2}"#)))
    }

    func testInvalidJSONAndTrailingDataAreRefused() {
        for bad in ["{not json", #"{"a":1} {"b":2}"#, #"{"a":1,}"#, #"{"a" 1}"#, "", #"{"a":"unterminated}"#, #"{"a":tru}"#] {
            XCTAssertThrowsError(try StrictJSON.validate(data(bad)), bad)
        }
        XCTAssertNoThrow(try StrictJSON.validate(data(" \n{\"a\": [ ] , \"b\": { } , \"c\": -1.5e3, \"d\": null, \"e\": true}\n")))
    }

    func testDecodeReturnsTheValueOrFails() throws {
        let ok = try StrictJSON.decode([String: String].self, from: data(#"{"/a":"1","/b":"2"}"#))
        XCTAssertEqual(ok, ["/a": "1", "/b": "2"])
        XCTAssertThrowsError(try StrictJSON.decode([String: String].self, from: data(#"{"/a":"1","/a":"2"}"#)))
    }

    func testABaselineThatListsAPathTwiceIsNotLoaded() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("strict-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        let ok = dir.appendingPathComponent("ok.json"), dup = dir.appendingPathComponent("dup.json")
        try data(#"{"version":1,"acceptedAt":"t","snapshot":{"scopes":[],"files":{"/a":{"sha256":"1"}},"servers":{}}}"#).write(to: ok)
        try data(#"{"version":1,"acceptedAt":"t","snapshot":{"scopes":[],"files":{"/a":{"sha256":"1"},"/a":{"sha256":"2"}},"servers":{}}}"#).write(to: dup)
        XCTAssertNotNil(AgentSetupBaseline.load(from: ok))
        XCTAssertNil(AgentSetupBaseline.load(from: dup), "the later entry for a path must not win silently")
    }
}
