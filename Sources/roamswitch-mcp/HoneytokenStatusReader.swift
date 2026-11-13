// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.35 (build 214).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `CredentialHoneytokenGuard`'s
/// on-disk state — same rationale as `CanaryStatusReader`/
/// `RansomwareEntropyStatusReader`: the bare MCP server process can't
/// reuse the full `@MainActor`-isolated guard class (it depends on
/// `LicenseManager`, itself requiring app-level context this process
/// lacks).
enum HoneytokenStatusReader {
    private static let enabledKey = "RoamSwitch.CredentialHoneytokenGuardEnabled"
    private static let persistedEventsKey = "RoamSwitch.HoneytokenAccessEventsV1"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    static func persistedEvents(defaults: UserDefaults = .standard) -> [PersistedHoneytokenEvent] {
        persistedEventsRead(defaults: defaults).value(or: [])
    }

    /// The same, telling a stored log that cannot be read from one that is empty.
    static func persistedEventsRead(defaults: UserDefaults = .standard) -> StoredRecordRead<[PersistedHoneytokenEvent]> {
        StoredRecordDefaults.peek([PersistedHoneytokenEvent].self, key: persistedEventsKey, defaults: defaults)
    }
}

/// Field-for-field mirror of `HoneytokenAccessEvent`'s `Codable` shape —
/// duplicated per this codebase's established convention (see
/// `PersistedCanaryIncident`).
struct PersistedHoneytokenEvent: Codable {
    let timestamp: Date
    let path: String
    let kind: String
    let suspectedProcess: String
}

/// `HoneytokenAccessEvent.suspectedProcess` holds a program label (`name (PID n)`, from `AlertEvidence.programLabel`)
/// or, when nobody could be identified, a sentence. That sentence is stored as its catalog key (the source language),
/// not in the language of the moment, and written in the reader's language when it is shown (the MCP answer keeps
/// its `suspectedProcess` string, in the language the server answers in). Records written before this held the
/// sentence in the language of that moment; any of the ten is recognised and rewritten the same way.
enum HoneytokenSuspectText {
    static let unidentifiedKey = "特定できませんでした（検知時点で該当プロセスは終了済みの可能性）"

    /// What to store when the reader of the decoy was not identified.
    static var unidentifiedStored: String { unidentifiedKey }

    static func isUnidentified(_ stored: String) -> Bool {
        stored == unidentifiedKey || AppLanguage.allCases.contains { $0 != .system && loc(unidentifiedKey, localeCode: $0.rawValue) == stored }
    }

    /// `stored` as the reader should see it: the "could not be identified" sentence in `localeCode`, a label as it is.
    static func display(_ stored: String, localeCode: String = AppLanguage.activeLocaleCode) -> String {
        isUnidentified(stored) ? loc(unidentifiedKey, localeCode: localeCode) : stored
    }
}
