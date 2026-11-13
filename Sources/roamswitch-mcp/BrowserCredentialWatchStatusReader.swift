// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.34 (build 213).
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
        persistedEventsRead(defaults: defaults).value(or: [])
    }

    /// The same, telling a stored log that cannot be read from one that is empty.
    static func persistedEventsRead(defaults: UserDefaults = .standard) -> StoredRecordRead<[PersistedBrowserCredentialEvent]> {
        StoredRecordDefaults.peek([PersistedBrowserCredentialEvent].self, key: persistedEventsKey, defaults: defaults)
    }
}

struct PersistedBrowserCredentialEvent: Codable {
    let timestamp: Date
    let path: String
    let suspectedProcess: String
}
