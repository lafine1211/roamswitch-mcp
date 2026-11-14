// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.0 (build 216). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

/// `AtomicFile`: the one way a state file is replaced. Fixed here: a symbolic link at the destination is refused and
/// what it points to is untouched, the mode the file had is kept, a failure in the middle leaves the old file whole and
/// no temporary file behind, and the lock serialises a read-modify-write.
final class AtomicFileTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("rs-atomic-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        AtomicFile.beforeRenameHook = nil
        try? FileManager.default.removeItem(at: dir)
    }

    private func path(_ name: String) -> String { dir.appendingPathComponent(name).path }
    private func mode(_ p: String) throws -> Int {
        (try FileManager.default.attributesOfItem(atPath: p)[.posixPermissions] as? NSNumber)?.intValue ?? -1
    }
    private func leftovers() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.contains(".tmp-") }
    }

    func testWritesANewFileWithTheDefaultModeOrTheGivenOne() throws {
        try AtomicFile.write(Data("a".utf8), toPath: path("plain"))
        XCTAssertEqual(try String(contentsOfFile: path("plain"), encoding: .utf8), "a")
        XCTAssertEqual(try mode(path("plain")), 0o644)
        try AtomicFile.write("b", toPath: path("private"), newFileMode: 0o600)
        XCTAssertEqual(try mode(path("private")), 0o600)
        XCTAssertEqual(try leftovers(), [])
    }

    func testAReplacedFileKeepsItsMode() throws {
        let p = path("state.json")
        try Data("old".utf8).write(to: URL(fileURLWithPath: p))
        chmod(p, 0o600)
        try AtomicFile.write(Data("new".utf8), toPath: p)
        XCTAssertEqual(try String(contentsOfFile: p, encoding: .utf8), "new")
        XCTAssertEqual(try mode(p), 0o600, "the old Data.write(.atomic) gave the new file 0644")
        chmod(p, 0o640)
        try AtomicFile.write(Data("newer".utf8), toPath: p)
        XCTAssertEqual(try mode(p), 0o640)
    }

    func testAnExplicitModeWins() throws {
        let p = path("wide")
        try Data("old".utf8).write(to: URL(fileURLWithPath: p))
        chmod(p, 0o666)
        try AtomicFile.write(Data("new".utf8), toPath: p, mode: 0o600)
        XCTAssertEqual(try mode(p), 0o600)
    }

    func testASymbolicLinkAtTheDestinationIsRefusedAndItsTargetIsUntouched() throws {
        let target = path("target")
        try Data("keep".utf8).write(to: URL(fileURLWithPath: target))
        let link = path("link")
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: target)
        XCTAssertThrowsError(try AtomicFile.write(Data("evil".utf8), toPath: link)) { error in
            XCTAssertEqual(error as? AtomicFile.WriteError, .destinationIsSymlink(link))
        }
        XCTAssertEqual(try String(contentsOfFile: target, encoding: .utf8), "keep")
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link), target, "the link is still a link")
        XCTAssertEqual(try leftovers(), [])
    }

    func testADanglingSymbolicLinkIsRefusedToo() throws {
        let link = path("dangling")
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: path("nowhere"))
        XCTAssertThrowsError(try AtomicFile.write(Data("x".utf8), toPath: link))
        XCTAssertFalse(FileManager.default.fileExists(atPath: path("nowhere")))
    }

    func testADirectoryAtTheDestinationIsRefused() throws {
        let d = path("adir")
        try FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: false)
        XCTAssertThrowsError(try AtomicFile.write(Data("x".utf8), toPath: d)) { error in
            XCTAssertEqual(error as? AtomicFile.WriteError, .destinationNotRegular(d))
        }
    }

    func testAFailureInTheMiddleLeavesTheOriginalAndNoTemporaryFile() throws {
        let p = path("ledger.json")
        try Data("original".utf8).write(to: URL(fileURLWithPath: p))
        chmod(p, 0o600)
        var sawTemporary: String?
        AtomicFile.beforeRenameHook = { tmp in
            sawTemporary = tmp
            XCTAssertEqual(try? String(contentsOfFile: tmp, encoding: .utf8), "replacement", "fully written before the rename")
            throw NSError(domain: "test", code: 1)
        }
        XCTAssertThrowsError(try AtomicFile.write(Data("replacement".utf8), toPath: p))
        XCTAssertEqual(try String(contentsOfFile: p, encoding: .utf8), "original")
        XCTAssertEqual(try mode(p), 0o600)
        XCTAssertNotNil(sawTemporary)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sawTemporary ?? ""))
        XCTAssertEqual(try leftovers(), [])
    }

    func testAMissingDirectoryFailsWithoutCreatingAnything() {
        let p = dir.appendingPathComponent("no/such/dir/file").path
        XCTAssertThrowsError(try AtomicFile.write(Data("x".utf8), toPath: p))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("no").path))
    }

    func testTheLockSerialisesReadModifyWrite() throws {
        let p = path("counter")
        try AtomicFile.write("0", toPath: p)
        let group = DispatchGroup()
        for _ in 0..<40 {
            group.enter()
            DispatchQueue.global().async {
                AtomicFile.withLock(p) {
                    let n = Int((try? String(contentsOfFile: p, encoding: .utf8)) ?? "") ?? -1000
                    try? AtomicFile.write(String(n + 1), toPath: p)
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(try String(contentsOfFile: p, encoding: .utf8), "40")
        XCTAssertEqual(try mode(p + ".lock"), 0o600)
    }
}
