// Mirrored from RoamSwitchTests/ — RoamSwitch 2.2.2 (build 226). Do not edit here; see SYNC.md.

import XCTest

/// The tests that read the app's own source files, the string catalog or the other repositories' vectors.
///
/// In a source checkout (a `project.yml` next to the test folder) those files are there, and a test that cannot find them has
/// found a defect (a moved file, a catalog that no longer parses, a folder listing that came back empty): it FAILS. A skip would
/// hide it. In a tree that has only the tests (the public mirror), the sources do not exist and there is nothing to read:
/// only there the test is skipped.
enum SourceTree {
    /// The folder that holds `RoamSwitchTests`, `RoamSwitch`, `Shared` and `project.yml`.
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    /// This is a source checkout: the project file is next to the tests.
    static var isCheckout: Bool { FileManager.default.fileExists(atPath: root.appendingPathComponent("project.yml").path) }

    struct Missing: Error, CustomStringConvertible {
        let what: String
        var description: String { "missing in a source checkout: \(what)" }
    }

    /// `present` is whether what the test needs was found. In a checkout, not found is a failure; elsewhere the test is skipped.
    static func require(_ present: Bool, _ what: String, file: StaticString = #filePath, line: UInt = #line) throws {
        guard !present else { return }
        guard isCheckout else { throw XCTSkip("\(what) (this tree has no sources: a mirror)") }
        XCTFail("\(what): a source checkout must have it", file: file, line: line)
        throw Missing(what: what)
    }
}
