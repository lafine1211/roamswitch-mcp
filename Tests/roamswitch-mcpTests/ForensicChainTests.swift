// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.0 (build 179). Do not edit here; see SYNC.md.

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
    private func makeBundle(_ name: String, in root: URL, content: String = "pid 1 launchd", capturedAt: String = "2026-10-20T00:00:00Z") throws -> URL {
        let dir = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try content.write(to: dir.appendingPathComponent("process_list.txt"), atomically: true, encoding: .utf8)
        let manifest = ForensicManifest(capturedAt: capturedAt, reason: "test", suspectedPID: nil, artifacts: [
            ForensicArtifactRecord(name: "process_list", status: "captured", detail: "x", relativePath: "process_list.txt", sha256: ForensicChain.sha256Hex(Data(content.utf8))),
        ])
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: dir.appendingPathComponent("manifest.json"))
        XCTAssertTrue(ForensicChain.record(root: root, bundleName: name, capturedAt: capturedAt, manifestData: data))
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
        XCTAssertFalse(ForensicChain.record(root: root, bundleName: "x", capturedAt: "t", manifestData: Data("{}".utf8)))
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
}
