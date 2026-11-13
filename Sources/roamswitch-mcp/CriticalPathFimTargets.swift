// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.33 (build 212).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Which files the root helper hashes for the Critical Path FIM, and how the app re-trusts files that a
/// newer version started to cover. Pure (no file access of its own) so it can be tested without root.
enum CriticalPathFimTargets {
    /// Directories whose every entry is hashed, so a file that appears later is noticed as new.
    static let watchedDirectories = ["/etc/ssh/sshd_config.d", "/etc/sudoers.d", "/etc/pam.d"]

    /// Directories added after the first release of this guard. A baseline saved before that holds none of their
    /// files, so each of them would be reported as new on the first scan after the update.
    static let laterAddedDirectories = ["/etc/sudoers.d", "/etc/pam.d"]

    /// The fixed list plus every entry of the watched directories (`listDirectory` returns names, or nil when the
    /// directory cannot be read). Directories inside them are not hashed. Order is stable and without duplicates.
    static func expand(
        fixed: [String],
        listDirectory: (String) -> [String]?,
        isDirectory: (String) -> Bool
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        func add(_ path: String) {
            if seen.insert(path).inserted { result.append(path) }
        }
        fixed.forEach(add)
        for dir in watchedDirectories {
            for name in (listDirectory(dir) ?? []).sorted() {
                let path = dir + "/" + name
                if !isDirectory(path) { add(path) }
            }
        }
        return result
    }

    /// One-time step after an update that widened the coverage: files in `laterAddedDirectories` that the
    /// stored baseline has never seen are taken as they are now. Files the baseline already holds are not touched.
    static func adoptNewlyCoveredPaths(stored: [String: String], current: [String: String]) -> [String: String] {
        var result = stored
        for (path, hash) in current where result[path] == nil && isInLaterAddedDirectory(path) {
            result[path] = hash
        }
        return result
    }

    /// Files a person adds and removes on purpose, so taking one away is not the kind of change that must stay
    /// unresolved: drop-ins in `/etc/sudoers.d` and `/etc/ssh/sshd_config.d`, and `/etc/pam.d/sudo_local` (Touch ID
    /// for sudo). The system's own pam.d files and the fixed core files are not add-ons.
    static func isUserAddOn(_ path: String) -> Bool {
        path.hasPrefix("/etc/sudoers.d/") || path.hasPrefix("/etc/ssh/sshd_config.d/") || path == "/etc/pam.d/sudo_local"
    }

    private static func isInLaterAddedDirectory(_ path: String) -> Bool {
        laterAddedDirectories.contains { path.hasPrefix($0 + "/") }
    }
}
