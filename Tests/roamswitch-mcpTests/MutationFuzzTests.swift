// Mutation fuzzing for MCPServer.handleLine.
//
// libFuzzer (`-sanitize=fuzzer`) is not available on the Xcode toolchain for
// this target, so this is coverage-blind mutation fuzzing: take the seed
// corpus, apply random byte-level mutations, and assert every result both
// returns and stays within a wall-clock budget. It won't reach deep states
// the way a coverage-guided fuzzer would, but it reliably catches shallow
// traps and hangs and it runs anywhere `swift test` runs.
//
// This file is specific to this repo (not mirrored from the app).

import XCTest
@testable import roamswitch_mcp

final class MutationFuzzTests: XCTestCase {

    private let seeds: [[UInt8]] = [
        #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}"#,
        #"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#,
        #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#,
        #"{"jsonrpc":"2.0","id":3,"method":"ping"}"#,
        #"{"jsonrpc":"2.0","id":4,"method":"resources/list"}"#,
        #"{"jsonrpc":"2.0","id":5,"method":"resources/read","params":{"uri":"roamswitch://docs/features"}}"#,
        #"{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":"http://a.b.xyz/verify"}}}"#,
        #"{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"get_app_help","arguments":{"query":"ARP"}}}"#,
        #"[{"jsonrpc":"2.0","id":8,"method":"ping"},{"jsonrpc":"2.0","id":9,"method":"tools/list"}]"#,
    ].map { Array($0.utf8) }

    private func mutate(_ input: [UInt8], _ rng: inout SystemRandomNumberGenerator) -> [UInt8] {
        var out = input
        for _ in 0..<Int.random(in: 1...8, using: &rng) {
            guard !out.isEmpty else { out = [UInt8.random(in: 0...255, using: &rng)]; continue }
            switch Int.random(in: 0...5, using: &rng) {
            case 0: out[Int.random(in: 0..<out.count, using: &rng)] = .random(in: 0...255, using: &rng)
            case 1: out.insert(.random(in: 0...255, using: &rng), at: Int.random(in: 0...out.count, using: &rng))
            case 2: out.remove(at: Int.random(in: 0..<out.count, using: &rng))
            case 3: out[Int.random(in: 0..<out.count, using: &rng)] ^= 1 << UInt8.random(in: 0...7, using: &rng)
            case 4: // duplicate a chunk
                let lo = Int.random(in: 0..<out.count, using: &rng)
                let hi = Int.random(in: lo..<out.count, using: &rng)
                out.insert(contentsOf: out[lo...hi], at: lo)
            default: // inject a structural byte
                out.insert([0x7B, 0x5B, 0x22, 0x5C, 0x00][Int.random(in: 0...4, using: &rng)],
                           at: Int.random(in: 0...out.count, using: &rng))
            }
        }
        return out
    }

    func testMutationFuzz_handleLine_neverTrapsOrHangs() {
        let iterations = ProcessInfo.processInfo.environment["FUZZ_ITERATIONS"].flatMap(Int.init) ?? 20_000
        var rng = SystemRandomNumberGenerator()
        for i in 0..<iterations {
            let input = mutate(seeds.randomElement(using: &rng)!, &rng)
            let data = Data(input)

            let done = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                _ = MCPServer.handleLine(data)   // must not trap
                done.signal()
            }
            if done.wait(timeout: .now() + 3) == .timedOut {
                XCTFail("iteration \(i): handleLine hung on input (hex): \(input.map { String(format: "%02x", $0) }.joined())")
                return
            }
        }
    }
}
