// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.18 (build 197). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `FrontendBundleScan`: the files a web front end publishes, which `SecretLeakScanning.auditDirectory` skips.
final class FrontendBundleScanTests: XCTestCase {

    private let jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1rwW0gMlO6sT3kQc"
    private let awsKey = "AKIAABCDEFGHIJKLMNOP"

    private func makeRoot() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rs-frontend-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return URL(fileURLWithPath: SafeScanFS.canonicalPath(url.path) ?? url.path)
    }

    private func write(_ text: String, _ path: String, in root: URL) throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func testMaskKeepsFourCharactersAndTheLengthOnly() {
        XCTAssertEqual(FrontendBundleScan.mask("sk-live-abcdefghijklmnop"), "sk-l…(24)")
        XCTAssertFalse(FrontendBundleScan.mask(jwt).contains("dBjft"))
    }

    func testAProjectIsScannedThroughItsBuildDirectoriesAndNotNodeModulesOrSource() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("var k=\"\(awsKey)\";var t=\"\(jwt)\";", "dist/assets/app.js", in: root)
        try write("{\"version\":3}", "dist/assets/app.js.map", in: root)
        try write("var k=\"\(awsKey)\";", "node_modules/x/i.js", in: root)
        try write("var k=\"\(awsKey)\";", "src/app.js", in: root)
        let r = FrontendBundleScan.scan(root: root)
        XCTAssertEqual(r.scannedDirs, ["dist"])
        let kinds = r.findings.map { "\($0.kind.rawValue):\($0.file)" }
        XCTAssertTrue(kinds.contains("secret:dist/assets/app.js"), "\(kinds)")
        XCTAssertTrue(kinds.contains("jwt:dist/assets/app.js"), "\(kinds)")
        XCTAssertTrue(kinds.contains("source_map:dist/assets/app.js.map"), "\(kinds)")
        XCTAssertTrue(r.findings.allSatisfy { $0.file.hasPrefix("dist/") }, "only the build output: \(kinds)")
        let shown = r.findings.map { "\($0.detail)\($0.masked)" }.joined()
        XCTAssertFalse(shown.contains(awsKey))
        XCTAssertFalse(shown.contains("dBjftJeZ4"))
    }

    func testAFolderWithNoBuildDirectoryIsScannedAsItIs() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("var k=\"\(awsKey)\";", "main.js", in: root)
        try Data([0, 1, 2]).write(to: root.appendingPathComponent("notes.bin"))
        let r = FrontendBundleScan.scan(root: root)
        XCTAssertEqual(r.scannedDirs, ["."])
        XCTAssertEqual(r.scannedFiles, 1)
        XCTAssertEqual(r.findings.count, 1)
    }

    func testOrdinaryBundlesReportNothing() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("!function(){var a=\"eyJ\";var h='Bearer ';console.log(a+h)}();//# sourceMappingURL=vendor.js.map", "dist/vendor.js", in: root)
        XCTAssertTrue(FrontendBundleScan.scan(root: root).findings.isEmpty)
    }
}
