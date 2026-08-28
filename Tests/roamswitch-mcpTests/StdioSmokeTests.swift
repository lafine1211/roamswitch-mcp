// End-to-end tests for the built `roamswitch-mcp` binary over stdio.
//
// The mirrored unit tests exercise the pure logic; this drives the actual
// `main.swift` read loop the way an MCP client would, and checks it survives
// obviously-hostile input without hanging or crashing.
//
// This file is NOT mirrored from the app — it is specific to this repo.

import XCTest

final class StdioSmokeTests: XCTestCase {

    /// The built executable, next to this test bundle in `.build/<config>/`.
    private var binaryURL: URL {
        var url = Bundle(for: Self.self).bundleURL
        url.deleteLastPathComponent()
        return url.appendingPathComponent("roamswitch-mcp")
    }

    /// Send newline-delimited JSON-RPC on stdin, return the parsed stdout lines.
    /// Fails the test if the process doesn't exit within a few seconds.
    private func roundTrip(_ requests: [String], timeout: TimeInterval = 15) throws -> [[String: Any]] {
        let process = Process()
        process.executableURL = binaryURL
        let stdin = Pipe(), stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        try process.run()

        let payload = (requests.joined(separator: "\n") + "\n").data(using: .utf8)!
        stdin.fileHandleForWriting.write(payload)
        try stdin.fileHandleForWriting.close()

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if process.isRunning {
            process.terminate()
            XCTFail("roamswitch-mcp did not exit after stdin closed (possible hang)")
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
            .compactMap { (try? JSONSerialization.jsonObject(with: Data($0.utf8))) as? [String: Any] }
    }

    func testInitializeAndToolsList() throws {
        let out = try roundTrip([
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#,
            #"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#,
        ])
        XCTAssertEqual(out.count, 2)
        XCTAssertNotNil((out[0]["result"] as? [String: Any])?["protocolVersion"])
        let tools = ((out[1]["result"] as? [String: Any])?["tools"] as? [[String: Any]])?
            .compactMap { $0["name"] as? String } ?? []
        XCTAssertEqual(Set(tools),
                       ["get_security_report", "get_exposed_ports", "get_guard_status",
                        "audit_url_safety", "get_app_help"])
    }

    func testAuditURLSafety_flagsPhishing_offline() throws {
        let out = try roundTrip([
            #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":"http://apple.com.secure-login.xyz/verify"}}}"#,
        ])
        let text = ((out.first?["result"] as? [String: Any])?["content"] as? [[String: Any]])?
            .first?["text"] as? String ?? "{}"
        let payload = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any]
        XCTAssertEqual(payload?["riskLevel"] as? String, "dangerous")
    }

    /// Garbage, wrong types, unknown methods/tools, empty args — the read loop
    /// must keep going and the process must still exit cleanly.
    func testHostileInput_doesNotHangOrCrash() throws {
        let out = try roundTrip([
            "{ this is not json",
            "",
            #"[]"#,
            #"{"jsonrpc":"2.0","id":1,"method":12345}"#,
            #"{"jsonrpc":"2.0","id":2,"method":"nonsense/method"}"#,
            #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":""}}}"#,
            #"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"unknown_tool"}}"#,
            #"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"get_app_help","arguments":{"query":"((((((((((a"}}}"#,
        ])
        let ids = Set(out.compactMap { $0["id"] as? Int })
        // The well-formed requests after the garbage must still be answered.
        XCTAssertTrue(ids.isSuperset(of: [2, 3, 4, 5]), "answered ids: \(ids.sorted())")
    }
}
