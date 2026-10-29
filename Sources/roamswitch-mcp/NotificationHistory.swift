// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.13 (build 192).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Persisted, time-bounded log of every notification RoamSwitch has sent —
/// so a user (or an AI agent, via MCP) can review "what fired in the last
/// week" instead of having to catch and read each alert live. Entries older
/// than `retention` are pruned on every write, so storage stays small and
/// bounded without a separate cleanup job. Mirrors
/// `roamswitch_core::notification_history` in the Linux edition.
public struct NotificationHistoryEntry: Codable, Identifiable, Equatable {
    public var id: String { timestamp + title }
    /// ISO 8601, so entries sort lexicographically in the same order as
    /// chronologically.
    public let timestamp: String
    public let title: String
    public let body: String
}

public enum NotificationHistory {
    private static let key = "RoamSwitch.NotificationHistoryV1"
    static let retention: TimeInterval = 7 * 24 * 3600
    private static let formatter = ISO8601DateFormatter()

    /// The app's own preferences domain, read and written alike by the app and by the MCP server (a separate
    /// process whose `.standard` is another, empty domain). Tests pass a scratch suite instead.
    private static func store(_ defaults: UserDefaults?) -> UserDefaults { defaults ?? AppLanguage.sharedDefaults }

    private static func loadRaw(_ defaults: UserDefaults?) -> [NotificationHistoryEntry] {
        guard let data = store(defaults).data(forKey: key),
              let decoded = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func save(_ entries: [NotificationHistoryEntry], _ defaults: UserDefaults?) {
        if let data = try? JSONEncoder().encode(entries) {
            store(defaults).set(data, forKey: key)
        }
    }

    static func isWithinRetention(_ entry: NotificationHistoryEntry, now: Date) -> Bool {
        guard let t = formatter.date(from: entry.timestamp) else {
            // An unparseable timestamp shouldn't silently vanish from the
            // log — keep it and let a human notice the malformed entry.
            return true
        }
        return now.timeIntervalSince(t) <= retention
    }

    /// Called with every recorded notification. The app sets it to hand the text to the opt-in forwarder
    /// (`EventForwarder`); it stays `nil` in the targets that only read the history.
    public static var recordObserver: ((String, String) -> Void)?

    /// Records one notification and prunes anything older than `retention`.
    public static func record(title: String, body: String, defaults: UserDefaults? = nil) {
        let now = Date()
        var entries = loadRaw(defaults).filter { isWithinRetention($0, now: now) }
        entries.append(NotificationHistoryEntry(timestamp: formatter.string(from: now), title: title, body: body))
        save(entries, defaults)
        recordObserver?(title, body)
    }

    /// Returns entries within `retention`, most recent first.
    public static func load(defaults: UserDefaults? = nil) -> [NotificationHistoryEntry] {
        let now = Date()
        return Array(loadRaw(defaults).filter { isWithinRetention($0, now: now) }.reversed())
    }
}
