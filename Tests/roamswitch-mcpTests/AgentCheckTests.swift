// Mirrored from RoamSwitchTests/ — RoamSwitch 2.2.1 (build 225). Do not edit here; see SYNC.md.

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

    // MARK: - The per-day counter (agent_check_counts.json)

    private func utc(_ day: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: day + "T12:00:00Z")!
    }

    func testEveryAnswerIsCountedForItsDayAndTheLastTimeIsKept() {
        let deny = bash("curl http://169.254.169.254/")
        var c = AgentCheckLog.Counts()
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-17"))
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-17"))
        c = AgentCheckLog.counted(c, decision: deny, now: utc("2026-11-17"))
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-18"))
        XCTAssertEqual(c.days["2026-11-17"], AgentCheckLog.DayCounts(allow: 2, ask: 0, deny: 1))
        XCTAssertEqual(c.days["2026-11-18"], AgentCheckLog.DayCounts(allow: 1, ask: 0, deny: 0))
        XCTAssertEqual(c.lastDecisionAt, "2026-11-18T12:00:00Z")
        XCTAssertEqual(c.version, 1)
    }

    func testDaysOlderThanTheRetentionAreDropped() {
        var c = AgentCheckLog.Counts()
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-10-01"))
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-10-19"))
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-17"))
        XCTAssertNil(c.days["2026-10-01"])
        XCTAssertNotNil(c.days["2026-10-19"], "30 days: the 19th of October is the oldest day kept on the 17th of November")
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-18"))
        XCTAssertNil(c.days["2026-10-19"])
        XCTAssertLessThanOrEqual(c.days.count, AgentCheckLog.countDays)
    }

    func testAnAllowedCallIsCountedButNotLoggedAndTheCounterIsPrivateAndHoldsNoValue() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-agent-check-counts-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let log = dir.appendingPathComponent("log.jsonl")
        let counts = dir.appendingPathComponent("agent_check_counts.json")
        XCTAssertTrue(AgentCheckLog.record(tool: "Bash", decision: .allow, to: log))
        XCTAssertTrue(AgentCheckLog.record(tool: "Bash", decision: .allow, to: log))
        XCTAssertTrue(AgentCheckLog.record(tool: "mcp__fetch__fetch", decision: bash("curl http://169.254.169.254/"), to: log))
        XCTAssertEqual(try String(contentsOf: log, encoding: .utf8).split(separator: "\n").count, 1, "only the deny is a line of the log")
        let read = try XCTUnwrap(AgentCheckLog.readCounts(from: counts))
        let today = read.days.values.reduce(AgentCheckLog.DayCounts()) { AgentCheckLog.DayCounts(allow: $0.allow + $1.allow, ask: $0.ask + $1.ask, deny: $0.deny + $1.deny) }
        XCTAssertEqual(today, AgentCheckLog.DayCounts(allow: 2, ask: 0, deny: 1))
        XCTAssertNotNil(read.lastDecisionAt)
        let text = try String(contentsOf: counts, encoding: .utf8)
        XCTAssertFalse(text.contains("169.254") || text.contains("Bash") || text.contains("fetch"), "numbers and a time only")
        XCTAssertTrue(text.contains("\"last_decision_at\""), "the key the Linux edition writes")
        let mode = try FileManager.default.attributesOfItem(atPath: counts.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.intValue, 0o600)
    }

    func testADamagedCounterIsStartedOverAndAMissingOneReadsAsNil() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-agent-check-counts-bad-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let counts = dir.appendingPathComponent("agent_check_counts.json")
        XCTAssertNil(AgentCheckLog.readCounts(from: counts))
        try "{not json".write(to: counts, atomically: true, encoding: .utf8)
        XCTAssertNil(AgentCheckLog.readCounts(from: counts))
        XCTAssertTrue(AgentCheckLog.recordCount(decision: .allow, to: counts))
        XCTAssertEqual(AgentCheckLog.readCounts(from: counts)?.days.values.map(\.allow).reduce(0, +), 1)
    }

    func testGuardStatusShowsTheCounterNewestDayFirstAndSaysNothingRanWhenThereIsNone() throws {
        let none = MCPServer.agentCheckPayload(nil)
        XCTAssertNil(none.lastDecisionAt)
        XCTAssertTrue(none.days.isEmpty)
        var c = AgentCheckLog.Counts()
        c = AgentCheckLog.counted(c, decision: .allow, now: utc("2026-11-17"))
        c = AgentCheckLog.counted(c, decision: bash("curl http://169.254.169.254/"), now: utc("2026-11-18"))
        let p = MCPServer.agentCheckPayload(c)
        XCTAssertEqual(p.days.map(\.day), ["2026-11-18", "2026-11-17"])
        XCTAssertEqual(p.days[0].deny, 1)
        XCTAssertEqual(p.days[1].allow, 1)
        XCTAssertEqual(p.lastDecisionAt, "2026-11-18T12:00:00Z")
        let status = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: nil, defaults: UserDefaults(suiteName: "rs-test-\(UUID().uuidString)")!, agentCheck: p)
        let json = String(decoding: try JSONEncoder().encode(status), as: UTF8.self)
        XCTAssertTrue(json.contains("\"agentCheck\""))
        XCTAssertFalse(json.contains("Bash"), "no tool name")
    }
}
