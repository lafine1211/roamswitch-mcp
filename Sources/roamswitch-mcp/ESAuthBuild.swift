// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Whether this build contains the AUTH uses of Endpoint Security: the pre-exec block (`AUTH_EXEC`), the protection of frozen
/// processes (`AUTH_SIGNAL`, `AUTH_PROC_SUSPEND_RESUME`) and the USB mount check (`AUTH_MOUNT`). The switch is the Swift
/// condition `ES_AUTH`, set from the build setting `ES_AUTH_ENABLED` (project.yml; Debug and tests: on, Release: off unless
/// `scripts/release.sh` is run with `ES_AUTH=1`). See docs/ES_CLIENT.md, "AUTH のスイッチ".
///
/// A build without it has **no code** for those uses (the extension subscribes to NOTIFY events only; the app has no guard,
/// menu line or helper call for them). The tables that name guards (the status list, the presets, the Pro defaults) leave the
/// guards of `authGuardKeys` out through `hasGuard`, so a guard that cannot work is never shown.
enum ESAuthBuild {
    #if ES_AUTH
    static let isEnabled = true
    #else
    static let isEnabled = false
    #endif

    /// Guards that exist only in a build with `ES_AUTH`. The protection of frozen processes and the USB mount check are
    /// not guards of their own (they follow the ransomware guards and the USB storage guard), so only the pre-exec block is here.
    static let authGuardKeys: Set<String> = ["preExecBlock"]

    /// `false` for a guard that is compiled out of this build.
    static func hasGuard(_ key: String) -> Bool { isEnabled || !authGuardKeys.contains(key) }
}
