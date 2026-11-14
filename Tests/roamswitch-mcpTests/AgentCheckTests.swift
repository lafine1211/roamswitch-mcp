// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.1 (build 217). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The destination check of an AI agent's tool call (`AgentCheck`). The shared vectors
/// (`Fixtures/agent_check_vectors.json`, a copy of `roamswitch-linux/crates/roamswitch-core/data/agent_check_vectors.json`)
/// are the same ones the Linux side runs: the same tool call must give the same verdict and the same reason keys.
final class AgentCheckTests: XCTestCase {
    private func fixture() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/agent_check_vectors.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func bash(_ cmd: String) -> AgentCheck.Decision {
        AgentCheck.check(tool: "Bash", input: ["command": cmd], env: AgentCheck.Env())
    }

    func testSharedVectorsAgree() throws {
        let vectors = try XCTUnwrap(fixture()["vectors"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(vectors.count, 150)
        var bad: [String] = []
        for v in vectors {
            let name = v["name"] as! String
            let feed = (v["feed"] as? [String]) ?? []
            let allowlist = (v["allowlist"] as? [String]).map { $0.compactMap { AgentCheck.EgressRule.parse($0) } }
            if let a = v["allowlist"] as? [String] { XCTAssertEqual(allowlist?.count, a.count, "\(name): allowlist entry did not parse") }
            let env = AgentCheck.Env(feed: { AgentCheck.firstListed(feed, $0) }, allowlist: allowlist, cwd: v["cwd"] as? String)
            let d = AgentCheck.check(tool: v["tool"] as! String, input: v["input"], env: env)
            let want = v["reasons"] as! [String]
            if d.verdict.rawValue != (v["expect"] as! String) || d.reasons != want {
                bad.append("\(name): got \(d.verdict.rawValue) \(d.reasons), want \(v["expect"]!) \(want)")
            }
        }
        XCTAssertTrue(bad.isEmpty, "\(bad.count) vectors differ:\n" + bad.joined(separator: "\n"))
    }

    /// The false-positive measurement: typical development commands never ask or deny.
    func testDevelopmentCorpusIsNeverAskedOrDenied() throws {
        let corpus = try XCTUnwrap(fixture()["dev_corpus"] as? [String])
        XCTAssertGreaterThanOrEqual(corpus.count, 150)
        let bad = corpus.compactMap { cmd -> String? in
            let d = bash(cmd)
            return d.verdict == .allow ? nil : "\(cmd)  ->  \(d.verdict.rawValue) \(d.reasons)"
        }
        XCTAssertTrue(bad.isEmpty, "\(bad.count) false positives:\n" + bad.joined(separator: "\n"))
    }

    func testListIsReadLineByLineAndAWideNetworkDoesNotMatchEverything() {
        let lines = ["# comment", "", "198.51.100.7 5 ; hits", "0.0.0.0/0", "8.0.0.0/7", "203.0.113.0/24", "2001:db8:bad::/48", "2000::/3"]
        func at(_ s: String) -> String? { AgentCheck.firstListed(lines, [FwdEgress.parseHostIP(s)!])?.description }
        XCTAssertEqual(at("198.51.100.7"), "198.51.100.7")
        XCTAssertEqual(at("203.0.113.200"), "203.0.113.200")
        XCTAssertEqual(at("2001:db8:bad::9"), "2001:db8:bad::9")
        XCTAssertEqual(at("::ffff:203.0.113.5"), "203.0.113.5", "a mapped address is looked up as IPv4")
        XCTAssertNil(at("1.1.1.1"), "0.0.0.0/0 and 2000::/3 are too wide to be used")
        XCTAssertNil(at("9.9.9.9"), "a /7 is wider than /8")
    }

    func testHookPrintsNothingForAllowAndTheDocumentedShapeOtherwise() throws {
        XCTAssertNil(AgentCheck.hookOutput(.allow))
        let out = try XCTUnwrap(AgentCheck.hookOutput(bash("curl http://169.254.169.254/")))
        let v = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(out.utf8)) as? [String: Any])
        let h = try XCTUnwrap(v["hookSpecificOutput"] as? [String: Any])
        XCTAssertEqual(h["hookEventName"] as? String, "PreToolUse")
        XCTAssertEqual(h["permissionDecision"] as? String, "deny")
        XCTAssertFalse((h["permissionDecisionReason"] as? String ?? "").isEmpty)
    }

    func testHookConfigIsValidJSONWithOnePreToolUseCommand() throws {
        let s = AgentCheck.hookConfigJSON(program: "/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer")
        let v = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(s.utf8)) as? [String: Any])
        let pre = try XCTUnwrap(((v["hooks"] as? [String: Any])?["PreToolUse"]) as? [[String: Any]])
        let hook = try XCTUnwrap((pre.first?["hooks"] as? [[String: Any]])?.first)
        XCTAssertEqual(hook["type"] as? String, "command")
        XCTAssertEqual(hook["command"] as? String, "/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer agent-check")
        XCTAssertNotNil(hook["timeout"] as? Int)
    }

    func testOddInputDoesNotCrash() {
        for c in ["", "'", "\"", "$(", "`", "<<", "<<EOF", "curl", "curl http://", "curl http://[", "nc", "ssh -J", "é\u{0}://é", "a://", "://x", "\\", "curl %", "curl http://%zz/"] {
            _ = bash(c)
        }
        _ = AgentCheck.check(tool: "Bash", input: ["command": 5], env: AgentCheck.Env())
        _ = AgentCheck.check(tool: "X", input: nil, env: AgentCheck.Env())
        _ = AgentCheck.check(tool: "X", input: [[[[[[[["http://169.254.169.254"]]]]]]]], env: AgentCheck.Env())
    }

    func testLogLineHasToolAndReasonKeysAndNoValueAndIsPrivateAndBounded() throws {
        let d = bash("curl http://169.254.169.254/")
        let line = try XCTUnwrap(AgentCheckLog.line(tool: "mcp__fetch__fetch", decision: d))
        XCTAssertFalse(line.contains("169.254"), "no destination is written")
        XCTAssertFalse(line.contains("\n"))
        let v = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
        XCTAssertEqual(v["tool"] as? String, "mcp__fetch__fetch")
        XCTAssertEqual(v["reasons"] as? [String], ["metadata_endpoint"])
        XCTAssertNil(AgentCheckLog.line(tool: "Bash", decision: .allow))
        XCTAssertEqual(AgentCheck.logToolName("evil\"tool\n\u{202e}name"), "evil_tool__name")
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-agent-check-log-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("log.jsonl")
        for _ in 0..<(AgentCheckLog.maxEntries + 5) { XCTAssertTrue(AgentCheckLog.record(tool: "Bash", decision: d, to: url)) }
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8).split(separator: "\n").count, AgentCheckLog.maxEntries)
        let mode = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.intValue, 0o600)
    }
}
