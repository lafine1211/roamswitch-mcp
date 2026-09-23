// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.2 (build 120).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `BrowserCredentialWatchGuard`'s
/// on-disk state — same rationale as the other guard status readers in
/// this file family (`CanaryStatusReader`, `HoneytokenStatusReader`, ...).
enum BrowserCredentialWatchStatusReader {
    private static let enabledKey = "RoamSwitch.BrowserCredentialWatchGuardEnabled"
    private static let persistedEventsKey = "RoamSwitch.BrowserCredentialAccessEventsV1"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    static func persistedEvents(defaults: UserDefaults = .standard) -> [PersistedBrowserCredentialEvent] {
        guard let data = defaults.data(forKey: persistedEventsKey),
              let decoded = try? JSONDecoder().decode([PersistedBrowserCredentialEvent].self, from: data) else {
            return []
        }
        return decoded
    }
}

struct PersistedBrowserCredentialEvent: Codable {
    let timestamp: Date
    let path: String
    let suspectedProcess: String
}
