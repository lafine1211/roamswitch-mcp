// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.1 (build 58).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `RansomwareCanaryGuard`'s on-disk
/// state — used by `RoamSwitchMCPServer`, which can't reuse the full
/// `@MainActor`-isolated `RansomwareCanaryGuard` class directly (it depends
/// on `LicenseManager`, itself `@MainActor` and requiring app-level Keychain/
/// NSAlert context the bare MCP server process doesn't have). Recomputes
/// `isEnabled` and `monitoredFilesCount` fresh from UserDefaults/disk on
/// every call, so it always reflects the main app's real current state —
/// but cannot report incident history, which only ever lives in the main
/// app process's memory (`RansomwareCanaryGuard.recentIncidents`, never
/// persisted to disk).
enum CanaryStatusReader {
    private static let enabledKey = "RoamSwitch.RansomwareCanaryGuardEnabled"

    /// The exact bait file set `RansomwareCanaryGuard.setupCanaryBait`
    /// creates — 4 inside the dedicated Application Support directory, 4
    /// scattered (dot-prefixed) into the real folders ransomware actually
    /// walks. Kept in sync with that function by hand; if the bait file set
    /// there changes, update here too.
    private static func expectedCanaryPaths() -> [String] {
        let fm = FileManager.default
        var paths: [String] = []
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("RoamSwitch/CanaryGuard", isDirectory: true)
            for name in [
                "financial_statement_2026.xlsx", "personal_vault_backup.kdbx",
                "customer_database_export.csv", "project_source_archive.zip",
            ] {
                paths.append(dir.appendingPathComponent(name).path)
            }
        }
        let scattered: [(FileManager.SearchPathDirectory, String)] = [
            (.documentDirectory, ".roamswitch_security_canary_do_not_delete.xlsx"),
            (.desktopDirectory, ".roamswitch_security_canary_do_not_delete.pdf"),
            (.downloadsDirectory, ".roamswitch_security_canary_do_not_delete.zip"),
            (.picturesDirectory, ".roamswitch_security_canary_do_not_delete.zip"),
        ]
        for (dir, name) in scattered {
            if let url = fm.urls(for: dir, in: .userDomainMask).first {
                paths.append(url.appendingPathComponent(name).path)
            }
        }
        return paths
    }

    /// `defaults` must be the app's real shared preferences domain — in
    /// `RoamSwitchMCPServer`, `UserDefaults.standard` resolves to that
    /// separate process's own (different, empty) bundle identifier, not the
    /// main app's, so callers there must pass the shared-suite instance.
    static func currentStatus(defaults: UserDefaults = .standard) -> (isEnabled: Bool, monitoredFilesCount: Int, expectedFilesCount: Int) {
        let isEnabled = defaults.bool(forKey: enabledKey)
        let expected = expectedCanaryPaths()
        let existing = expected.filter { FileManager.default.fileExists(atPath: $0) }
        return (isEnabled, existing.count, expected.count)
    }
}
