// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.2 (build 218). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// The anchor chain of the evidence bundles: a manifest rewritten after the fact, an edited or truncated log and a
/// deleted bundle all show up when the bundles are listed.
final class ForensicChainTests: XCTestCase {

    private func makeRoot() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rs-chain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A bundle in the format `captureSnapshot` writes: one artifact and a manifest holding its hash, anchored in the chain.
    @discardableResult
    /// `startMark: false` writes the older kind of log (no start mark), which the tests that were written for it still use.
    private func makeBundle(_ name: String, in root: URL, content: String = "pid 1 launchd", capturedAt: String = "2026-10-20T00:00:00Z",
                            startMark: Bool = false) throws -> URL {
        let dir = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try content.write(to: dir.appendingPathComponent("process_list.txt"), atomically: true, encoding: .utf8)
        let manifest = ForensicManifest(capturedAt: capturedAt, reason: "test", suspectedPID: nil, artifacts: [
            ForensicArtifactRecord(name: "process_list", status: "captured", detail: "x", relativePath: "process_list.txt", sha256: ForensicChain.sha256Hex(Data(content.utf8))),
        ])
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: dir.appendingPathComponent("manifest.json"))
        XCTAssertTrue(ForensicChain.record(root: root, bundleName: name, capturedAt: capturedAt, manifestData: data, startMark: startMark, logToSystem: false))
        return dir
    }

    private func integrity(_ root: URL) -> [String: String] {
        Dictionary(uniqueKeysWithValues: ForensicCaptureManager.listBundles(root: root).map { (($0.bundleDir as NSString).lastPathComponent, $0.integrity) })
    }

    func testAnUntouchedChainVerifiesEveryBundle() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root)
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        XCTAssertEqual(integrity(root), ["20261020T000000Z-a": "verified", "20261020T000100Z-b": "verified"])
        let payload = ForensicCaptureManager.bundlesPayload(root: root)
        XCTAssertTrue(payload.chainOk)
        XCTAssertNil(payload.chainBrokenAt)
        XCTAssertTrue(payload.missingBundles.isEmpty)
        let mode = try FileManager.default.attributesOfItem(atPath: root.appendingPathComponent("chain.log").path)[.posixPermissions] as? Int
        XCTAssertEqual(mode, 0o600)
    }

    func testARewrittenManifestAnAlteredArtifactAndAMissingOneAreEachNamed() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        let b = try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        let c = try makeBundle("20261020T000200Z-c", in: root, capturedAt: "2026-10-20T00:02:00Z")
        // a: the manifest is rewritten so that it matches a changed artifact (the attacker's tidy edit)
        let forged = ForensicManifest(capturedAt: "2026-10-20T00:00:00Z", reason: "nothing happened", suspectedPID: nil, artifacts: [])
        try JSONEncoder().encode(forged).write(to: a.appendingPathComponent("manifest.json"))
        // b: an artifact changed, manifest untouched
        try "pid 1 launchd\npid 666 evil".write(to: b.appendingPathComponent("process_list.txt"), atomically: true, encoding: .utf8)
        // c: an artifact removed
        try FileManager.default.removeItem(at: c.appendingPathComponent("process_list.txt"))
        let got = integrity(root)
        XCTAssertEqual(got["20261020T000000Z-a"], "manifest_altered")
        XCTAssertEqual(got["20261020T000100Z-b"], "artifact_altered:process_list")
        XCTAssertEqual(got["20261020T000200Z-c"], "artifact_missing:process_list")
    }

    func testADeletedBundleAndAnEditedLogAreDetected() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        try FileManager.default.removeItem(at: a)
        XCTAssertEqual(ForensicCaptureManager.bundlesPayload(root: root).missingBundles, ["20261020T000000Z-a"])
        // The first line of the log is removed to hide it: the second no longer follows from the genesis.
        let log = root.appendingPathComponent("chain.log")
        let lines = try String(contentsOf: log, encoding: .utf8).split(separator: "\n")
        try (String(lines[1]) + "\n").write(to: log, atomically: true, encoding: .utf8)
        let payload = ForensicCaptureManager.bundlesPayload(root: root)
        XCTAssertFalse(payload.chainOk)
        XCTAssertEqual(payload.chainBrokenAt, "20261020T000100Z-b")
        // A broken chain is not extended: a new bundle would hide where it broke.
        XCTAssertFalse(ForensicChain.record(root: root, bundleName: "x", capturedAt: "t", manifestData: Data("{}".utf8), logToSystem: false))
    }

    func testABundleWithNoLineIsNotAnchoredAndAnOldBundleStaysReadable() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let dir = root.appendingPathComponent("20261019T000000Z-old")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let manifest = ForensicManifest(capturedAt: "2026-10-19T00:00:00Z", reason: "old", suspectedPID: nil, artifacts: [])
        try JSONEncoder().encode(manifest).write(to: dir.appendingPathComponent("manifest.json"))
        XCTAssertEqual(integrity(root), ["20261019T000000Z-old": "not_anchored"])
        XCTAssertTrue(ForensicCaptureManager.bundlesPayload(root: root).chainOk, "no log is not a broken log")
    }

    // MARK: - timeline references against the chain

    private func refs(for dir: URL, manifestSHA: String? = nil) throws -> [ContainmentEvidenceRef] {
        let data = try Data(contentsOf: dir.appendingPathComponent("manifest.json"))
        return [ContainmentEvidenceRef(bundle: dir.lastPathComponent, artifact: "manifest.json", sha256: manifestSHA ?? ForensicChain.sha256Hex(data))]
    }

    private func status(_ refs: [ContainmentEvidenceRef], _ root: URL) -> [MCPEvidenceCheckPayload] {
        ForensicChain.check(refs: refs, root: root, chain: ForensicChain.load(root: root))
    }

    func testAnUntouchedBundleMatchesTheTimelineReference() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        let got = status(try refs(for: a), root)
        XCTAssertEqual(got, [MCPEvidenceCheckPayload(bundle: "20261020T000000Z-a", status: "matches", stale: false)])
    }

    func testAPrunedBundleARewrittenManifestAndAChangedReferenceAreStale() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        let b = try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        let c = try makeBundle("20261020T000200Z-c", in: root, capturedAt: "2026-10-20T00:02:00Z")
        let all = try refs(for: a) + refs(for: b) + refs(for: c, manifestSHA: ForensicChain.sha256Hex(Data("other".utf8)))
        try FileManager.default.removeItem(at: a)
        try JSONEncoder().encode(ForensicManifest(capturedAt: "x", reason: "forged", suspectedPID: nil, artifacts: [])).write(to: b.appendingPathComponent("manifest.json"))
        let got = Dictionary(uniqueKeysWithValues: status(all, root).map { ($0.bundle, $0) })
        XCTAssertEqual(got["20261020T000000Z-a"]?.status, "bundle_missing")
        XCTAssertEqual(got["20261020T000100Z-b"]?.status, "manifest_altered")
        XCTAssertEqual(got["20261020T000200Z-c"]?.status, "ref_changed")
        XCTAssertTrue(got.values.allSatisfy(\.stale))
    }

    func testABrokenChainAndABundleWithNoLineAreStaleAndNamed() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        let b = try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        let both = try refs(for: a) + refs(for: b)
        let stranger = [ContainmentEvidenceRef(bundle: "20261019T000000Z-none", artifact: "manifest.json", sha256: "00")]
        XCTAssertEqual(status(stranger, root).first?.status, "not_anchored")
        XCTAssertEqual(status(stranger, root).first?.stale, true)
        let log = root.appendingPathComponent("chain.log")
        let lines = try String(contentsOf: log, encoding: .utf8).split(separator: "\n")
        try (String(lines[1]) + "\n").write(to: log, atomically: true, encoding: .utf8)
        let got = status(both, root)
        XCTAssertEqual(got.map(\.status), ["chain_broken", "chain_broken"])
        XCTAssertEqual(got.first?.chainBrokenAt, "20261020T000100Z-b")
    }

    func testAnUnreadableLogIsUncheckedNotStale() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: root.appendingPathComponent("chain.log").path); try? FileManager.default.removeItem(at: root) }
        let a = try makeBundle("20261020T000000Z-a", in: root)
        let r = try refs(for: a)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: root.appendingPathComponent("chain.log").path)
        try XCTSkipIf(getuid() == 0, "root can read it")
        let got = status(r, root)
        XCTAssertEqual(got.first?.status, "unchecked")
        XCTAssertEqual(got.first?.stale, false)
    }

    func testTheTimelinePayloadCarriesTheChecksOnlyWhenThereAreSome() {
        let none = MCPResponseFormatting.makeIncidentTimelinePayload(events: [])
        XCTAssertNil(none.evidenceChecks)
        XCTAssertNil(none.evidenceChecksNote)
        let check = MCPEvidenceCheckPayload(bundle: "b", status: "bundle_missing", stale: true)
        let some = MCPResponseFormatting.makeIncidentTimelinePayload(events: [], evidenceChecks: [check])
        XCTAssertEqual(some.evidenceChecks, [check])
        XCTAssertTrue(some.evidenceChecksNote?.contains("stale") == true)
    }

    // MARK: - start mark, head, witness

    private func lines(_ root: URL) throws -> [String] {
        try String(contentsOf: root.appendingPathComponent("chain.log"), encoding: .utf8).split(separator: "\n").map(String.init)
    }

    private func writeLines(_ lines: [String], _ root: URL) throws {
        try (lines.joined(separator: "\n") + "\n").write(to: root.appendingPathComponent("chain.log"), atomically: true, encoding: .utf8)
    }

    /// The chain hash of line `seq` (from 1), read from the file.
    private func chainHash(_ seq: Int, _ root: URL) throws -> String {
        try lines(root)[seq - 1].split(separator: " ").map(String.init)[4]
    }

    func testANewChainStartsWithAStartMarkThatIsNotABundle() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        var got = try lines(root)
        XCTAssertEqual(got.count, 2)
        let mark = got[0].split(separator: " ").map(String.init)
        XCTAssertEqual(mark[0], "2026-10-20T00:00:00Z", "the start mark is dated like the first bundle, so that bundle counts as made after it")
        XCTAssertEqual(mark[1], "@genesis")
        XCTAssertEqual(mark[2], String(repeating: "0", count: 64))
        XCTAssertEqual(mark[3], "GENESIS")
        XCTAssertEqual(mark[4], ForensicChain.chainHash(time: mark[0], bundle: mark[1], manifestSHA: mark[2], prev: mark[3]))
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z", startMark: true)
        got = try lines(root)
        XCTAssertEqual(got.count, 3, "the mark is written once")
        XCTAssertEqual(integrity(root), ["20261020T000000Z-a": "verified", "20261020T000100Z-b": "verified"])
        let payload = ForensicCaptureManager.bundlesPayload(root: root)
        XCTAssertTrue(payload.chainOk)
        XCTAssertTrue(payload.missingBundles.isEmpty, "the start mark is not a bundle that went missing")
        XCTAssertEqual(ForensicChain.load(root: root).bundleEntries.map(\.bundle), ["20261020T000000Z-a", "20261020T000100Z-b"])
    }

    func testAnEmptyLogFileStartsWithTheMarkAndAnOlderLogIsNotGivenOne() throws {
        let empty = try makeRoot()
        let old = try makeRoot()
        defer { try? FileManager.default.removeItem(at: empty); try? FileManager.default.removeItem(at: old) }
        FileManager.default.createFile(atPath: empty.appendingPathComponent("chain.log").path, contents: nil)
        try makeBundle("20261020T000000Z-a", in: empty, startMark: true)
        XCTAssertEqual(try lines(empty).count, 2)
        // An older log (no mark) is extended as it was, and its bundles verify.
        try makeBundle("20261020T000000Z-a", in: old, startMark: false)
        try makeBundle("20261020T000100Z-b", in: old, capturedAt: "2026-10-20T00:01:00Z", startMark: true)
        XCTAssertEqual(try lines(old).count, 2, "a log that already has lines never gets a mark added")
        XCTAssertNil(ForensicChain.load(root: old).startMarkTime)
        XCTAssertEqual(integrity(old), ["20261020T000000Z-a": "verified", "20261020T000100Z-b": "verified"])
    }

    func testACutOffTailLineIsAnchorRemovedAndABundleFromBeforeTheLogIsNotAnchored() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        let b = try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z", startMark: true)
        // a bundle from before the log began, which never had a line
        let old = root.appendingPathComponent("20261019T000000Z-old")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try JSONEncoder().encode(ForensicManifest(capturedAt: "2026-10-19T00:00:00Z", reason: "old", suspectedPID: nil, artifacts: [])).write(to: old.appendingPathComponent("manifest.json"))
        // the attacker rewrites b and cuts b's line off the end: the rest of the chain still checks out
        try writeLines(Array(try lines(root).dropLast()), root)
        XCTAssertEqual(integrity(root), ["20261020T000000Z-a": "verified", "20261020T000100Z-b": "anchor_removed", "20261019T000000Z-old": "not_anchored"])
        XCTAssertTrue(ForensicCaptureManager.bundlesPayload(root: root).chainOk)
        let all = try refs(for: b) + [ContainmentEvidenceRef(bundle: "20261019T000000Z-old", artifact: "manifest.json", sha256: "00")]
        let got = Dictionary(uniqueKeysWithValues: status(all, root).map { ($0.bundle, $0) })
        XCTAssertEqual(got["20261020T000100Z-b"]?.status, "anchor_removed")
        XCTAssertEqual(got["20261020T000100Z-b"]?.stale, true)
        XCTAssertEqual(got["20261019T000000Z-old"]?.status, "not_anchored")
        // with the manifest gone too, the time in the bundle's name decides
        try FileManager.default.removeItem(at: b.appendingPathComponent("manifest.json"))
        XCTAssertEqual(status(try refsByName("20261020T000100Z-b"), root).first?.status, "anchor_removed")
        XCTAssertEqual(status(try refsByName("not-a-time"), root).first?.status, "not_anchored")
    }

    func testWithoutAStartMarkACutOffTailLineStaysNotAnchored() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root)
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z")
        try writeLines(Array(try lines(root).dropLast()), root)
        XCTAssertEqual(integrity(root), ["20261020T000000Z-a": "verified", "20261020T000100Z-b": "not_anchored"])
    }

    private func refsByName(_ bundle: String) throws -> [ContainmentEvidenceRef] {
        [ContainmentEvidenceRef(bundle: bundle, artifact: "manifest.json", sha256: "00")]
    }

    func testTheHeadIsTheLineCountAndTheLastHash() throws {
        let root = try makeRoot()
        let legacy = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: legacy) }
        XCTAssertNil(ForensicChain.head(chain: ForensicChain.load(root: root)), "no log, no head")
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z", startMark: true)
        let head = try XCTUnwrap(ForensicChain.head(chain: ForensicChain.load(root: root)))
        XCTAssertEqual(head.seq, 3, "the start mark counts")
        XCTAssertEqual(head.chain, try chainHash(3, root))
        try makeBundle("20261020T000000Z-a", in: legacy)
        XCTAssertEqual(ForensicChain.head(chain: ForensicChain.load(root: legacy))?.seq, 1)
        // a log that does not check out has no head
        var broken = try lines(root)
        broken[1] = broken[1].replacingOccurrences(of: "20261020T000000Z-a", with: "20261020T000000Z-x")
        try writeLines(broken, root)
        XCTAssertNil(ForensicChain.head(chain: ForensicChain.load(root: root)))
    }

    func testAWitnessIsConsistentTruncatedDivergedInvalidOrChainBroken() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        try makeBundle("20261020T000100Z-b", in: root, capturedAt: "2026-10-20T00:01:00Z", startMark: true)
        try makeBundle("20261020T000200Z-c", in: root, capturedAt: "2026-10-20T00:02:00Z", startMark: true)
        let h2 = try chainHash(2, root), h4 = try chainHash(4, root)
        func witness(_ w: String) -> String { ForensicChain.checkWitness(w, chain: ForensicChain.load(root: root)) }
        XCTAssertEqual(witness("4:\(h4)"), "consistent")
        XCTAssertEqual(witness("2:\(h2)"), "consistent", "an earlier head is still in the history")
        XCTAssertEqual(witness(" 4:\(h4.uppercased()) \n"), "consistent", "case and surrounding space do not matter")
        for bad in ["", "4", "4:", ":\(h4)", "0:\(h4)", "-1:\(h4)", "x:\(h4)", "4:\(h4.dropLast())", "4:\(String(repeating: "z", count: 64))", "4:\(h4):5"] {
            XCTAssertEqual(witness(bad), "invalid", "\(bad)")
        }
        let original = try lines(root)
        // the newest line is cut off: the chain still checks out, but it is shorter than the witness says
        try writeLines(Array(original.dropLast()), root)
        XCTAssertEqual(witness("4:\(h4)"), "truncated")
        XCTAssertEqual(witness("2:\(h2)"), "consistent")
        XCTAssertEqual(witness("999:\(h4)"), "truncated")
        // the attacker rewrites line 2 and recomputes every hash after it: the log checks out but the history differs
        var entries = ForensicChain.load(root: root).entries
        _ = entries.removeLast()
        var rebuilt: [String] = []
        var prev = ForensicChain.genesis
        for (i, e) in (try lines(root)).enumerated() {
            let f = e.split(separator: " ").map(String.init)
            let sha = i == 1 ? String(repeating: "a", count: 64) : f[2]
            let c = ForensicChain.chainHash(time: f[0], bundle: f[1], manifestSHA: sha, prev: prev)
            rebuilt.append("\(f[0]) \(f[1]) \(sha) \(prev) \(c)")
            prev = c
        }
        try writeLines(rebuilt, root)
        XCTAssertTrue(ForensicChain.load(root: root).chainOK)
        XCTAssertEqual(witness("2:\(h2)"), "diverged")
        // a line edited in place without recomputing breaks the chain, and that is what is reported
        var edited = original
        edited[1] = edited[1].replacingOccurrences(of: "20261020T000000Z-a", with: "20261020T000000Z-x")
        try writeLines(edited, root)
        XCTAssertEqual(witness("4:\(h4)"), "chain_broken")
        XCTAssertEqual(witness("nonsense"), "invalid", "the form is checked first")
        // no log at all: nothing is left of what the witness names
        try FileManager.default.removeItem(at: root.appendingPathComponent("chain.log"))
        XCTAssertEqual(witness("1:\(h2)"), "truncated")
    }

    func testThePayloadsCarryTheHeadAndTheWitnessOnlyWhenAsked() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        let h2 = try chainHash(2, root)
        let plain = ForensicCaptureManager.bundlesPayload(root: root)
        XCTAssertEqual(plain.chainHead, MCPChainHeadPayload(seq: 2, chain: h2))
        XCTAssertNil(plain.chainWitness)
        let asked = ForensicCaptureManager.bundlesPayload(root: root, witness: "2:\(h2)")
        XCTAssertEqual(asked.chainWitness, "consistent")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(asked)) as? [String: Any])
        XCTAssertEqual((json["chainHead"] as? [String: Any])?["seq"] as? Int, 2)
        XCTAssertEqual((json["chainHead"] as? [String: Any])?["chain"] as? String, h2)
        XCTAssertEqual(json["chainWitness"] as? String, "consistent")
        let plainJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(plain)) as? [String: Any])
        XCTAssertNil(plainJSON["chainWitness"])
        XCTAssertEqual(ForensicCaptureManager.bundlesPayload(root: root, witness: "junk").chainWitness, "invalid")
        // an empty folder: no head, and a given witness names lines that are not there
        let none = try makeRoot()
        defer { try? FileManager.default.removeItem(at: none) }
        XCTAssertNil(ForensicCaptureManager.bundlesPayload(root: none).chainHead)
        XCTAssertEqual(ForensicCaptureManager.chainEnd(root: none, witness: "1:\(h2)").witness, "truncated")
        // the timeline carries the same two fields
        let end = ForensicCaptureManager.chainEnd(root: root, witness: "2:\(h2)")
        let timeline = MCPResponseFormatting.makeIncidentTimelinePayload(events: [], chainHead: end.head, chainWitness: end.witness)
        XCTAssertEqual(timeline.chainHead, MCPChainHeadPayload(seq: 2, chain: h2))
        XCTAssertEqual(timeline.chainWitness, "consistent")
        XCTAssertNil(MCPResponseFormatting.makeIncidentTimelinePayload(events: []).chainHead)
        XCTAssertTrue(MCPResponseFormatting.evidenceChecksNote.contains("anchor_removed"))
        XCTAssertTrue(MCPResponseFormatting.evidenceChecksNote.contains("chainHead"))
    }

    func testTheSystemLogLineCarriesTheBundleTheManifestHashAndTheHead() {
        XCTAssertEqual(
            ForensicChain.systemLogMessage(bundle: "20261020T000000Z-a", manifestSHA: "ab", seq: 3, chain: "cd"),
            "bundle=20261020T000000Z-a manifest_sha256=ab seq=3 chain=cd")
    }

    // MARK: - capture times in the manifest

    func testAManifestWithoutCaptureTimesStillDecodesAndOneWithThemKeepsThem() throws {
        let old = """
        {"capturedAt":"2026-10-20T00:00:00Z","reason":"r","artifacts":[{"name":"process_list","status":"captured","detail":"d","relativePath":"process_list.txt","sha256":"ab"}]}
        """
        let decoded = try JSONDecoder().decode(ForensicManifest.self, from: Data(old.utf8))
        XCTAssertNil(decoded.durationMs)
        XCTAssertNil(decoded.artifacts[0].elapsedMs)
        var record = ForensicArtifactRecord(name: "n", status: "captured", detail: "d", relativePath: "p", sha256: "ab")
        record.elapsedMs = 12
        let now = ForensicManifest(capturedAt: "2026-10-20T00:00:00Z", reason: "r", suspectedPID: nil, artifacts: [record], durationMs: 34)
        let back = try JSONDecoder().decode(ForensicManifest.self, from: JSONEncoder().encode(now))
        XCTAssertEqual(back.durationMs, 34)
        XCTAssertEqual(back.artifacts[0].elapsedMs, 12)
        // an old bundle on disk is still listed and verified
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try makeBundle("20261020T000000Z-a", in: root, startMark: true)
        XCTAssertEqual(integrity(root), ["20261020T000000Z-a": "verified"])
    }
}
