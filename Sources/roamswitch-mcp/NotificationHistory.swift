// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
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
///
/// In `Shared` so the watchdog, a process of its own, records its restart notices here too.
public struct NotificationHistoryEntry: Codable, Identifiable, Equatable {
    public var id: String { timestamp + title }
    /// ISO 8601, so entries sort lexicographically in the same order as
    /// chronologically.
    public let timestamp: String
    /// The title and body as rendered when the notification was sent, in the language of that moment. Kept for every
    /// reader that knows only these keys (the CSV export, the forwarder, older versions); entries written before
    /// `text` existed have only these.
    public var title: String
    public var body: String
    /// The same title and body without a language (`NotificationText`), so a reader shows the entry in the language
    /// set now. `nil` for older entries and for text no catalog entry matched; those are shown as stored.
    public var text: NotificationTexts? = nil
}

public enum NotificationHistory {
    private static let key = "RoamSwitch.NotificationHistoryV1"
    static let retention: TimeInterval = 7 * 24 * 3600
    private static let formatter = ISO8601DateFormatter()

    /// The app's own preferences domain, read and written alike by the app and by the MCP server (a separate
    /// process whose `.standard` is another, empty domain). Tests pass a scratch suite instead.
    private static func store(_ defaults: UserDefaults?) -> UserDefaults { defaults ?? defaultDomain(underTests: underTests) }

    static func defaultDomain(underTests: Bool) -> UserDefaults { underTests ? testScratch : appDomain }

    /// The app's preferences domain (`AppLanguage.sharedDefaults`), named here so the watchdog can use it too.
    private static let appDomain = UserDefaults(suiteName: "com.tetsuharu.RoamSwitch") ?? .standard

    /// A unit-test run is hosted by the app itself, so its `.sharedDefaults` is the installed app's own domain: every
    /// notification a test raised (clipboard, DYLD, USB ...) landed in the owner's real history. Under XCTest the
    /// history goes to a scratch suite instead, emptied when the run starts.
    private static let underTests = NSClassFromString("XCTestCase") != nil
    private static let testScratch: UserDefaults = {
        let suite = "com.tetsuharu.RoamSwitch.xctest-history"
        let d = UserDefaults(suiteName: suite) ?? .standard
        d.removePersistentDomain(forName: suite)
        return d
    }()

    private static func loadRaw(_ defaults: UserDefaults?) -> [NotificationHistoryEntry] {
        readRaw(defaults).entries
    }

    /// `unreadable`: a value is stored but it is not a history (damaged, another type). The list is then empty because
    /// nothing could be read, not because nothing was sent. No value at all is an empty, readable history.
    private static func readRaw(_ defaults: UserDefaults?) -> (entries: [NotificationHistoryEntry], unreadable: Bool) {
        let d = store(defaults)
        guard d.object(forKey: key) != nil else { return ([], false) }
        guard let data = d.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) else {
            return ([], true)
        }
        return (decoded, false)
    }

    /// The key a history that could not be read is kept under before the next notification starts a new one
    /// (the next save would otherwise replace it with that one notification).
    static func backupKey(existing: (String) -> Bool, now: Date = Date()) -> String {
        let plain = key + ".unreadable"
        guard existing(plain) else { return plain }
        return plain + ".\(Int(now.timeIntervalSince1970))"
    }

    /// How many unreadable histories are kept (the newest; the same as the Linux edition's `json_state`).
    static let backupsKept = 3

    /// `<key>.unreadable` (the first) and `<key>.unreadable.<unix time>`: all but the newest `backupsKept` are removed.
    static func pruneBackups(_ d: UserDefaults) {
        for k in backupKeys(d).dropLast(backupsKept) { d.removeObject(forKey: k) }
    }

    /// The backups kept, oldest first (`<key>.unreadable`, then `<key>.unreadable.<unix time>` by time).
    static func backupKeys(_ d: UserDefaults) -> [String] {
        let plain = key + ".unreadable"
        let stamped = d.dictionaryRepresentation().keys.compactMap { k -> (Int, String)? in
            guard k.hasPrefix(plain + "."), let n = Int(k.dropFirst(plain.count + 1)) else { return nil }
            return (n, k)
        }.sorted { $0.0 < $1.0 }.map(\.1)
        return (d.object(forKey: plain) != nil ? [plain] : []) + stamped
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

    /// Called with every recorded notification: the title and body as shown, and the same without a language (`nil`
    /// when none was found). The app sets it to hand the notification to the opt-in forwarder (`EventForwarder`),
    /// which sends it in English; it stays `nil` in the targets that only read the history.
    public static var recordObserver: ((String, String, NotificationTexts?) -> Void)?

    /// Turns a title and body rendered in the current language into `NotificationTexts` (the app sets it to its
    /// catalog parser, `NotificationTextParser`). `nil` in a process without the catalog: the text is kept as rendered.
    public static var textResolver: ((String, String) -> NotificationTexts?)?

    /// Records one notification and prunes anything older than `retention`. `text` is the same title and body without
    /// a language; when it is not given, `textResolver` finds it from the rendered text.
    public static func record(title: String, body: String, text: NotificationTexts? = nil, defaults: UserDefaults? = nil) {
        let text = text ?? textResolver?(title, body)
        let now = Date()
        // One thread at a time reads, adds and saves: alerts raised together (several detectors reacting to one event)
        // would otherwise all start from the same stored list and keep only the last one's addition.
        recordLock.lock()
        let read = readRaw(defaults)
        if read.unreadable {
            let d = store(defaults)
            // While any backup is kept the next one is stamped, after the newest, so pruning keeps it.
            let kept = backupKeys(d)
            var target = backupKey(existing: { _ in !kept.isEmpty }, now: now)
            let stampedPrefix = key + ".unreadable."
            if let last = kept.last, let n = Int(last.dropFirst(stampedPrefix.count)), Int(now.timeIntervalSince1970) <= n {
                target = stampedPrefix + String(n + 1)
            }
            d.set(d.object(forKey: key), forKey: target)
            pruneBackups(d)
        }
        var entries = read.entries.filter { isWithinRetention($0, now: now) }
        let stamp = formatter.string(from: now)
        // The same notice raised twice in the same second is one entry. A different body is a different event: kept.
        if entries.contains(where: { $0.timestamp == stamp && $0.title == title && $0.body == body }) {
            recordLock.unlock()
            return
        }
        entries.append(NotificationHistoryEntry(timestamp: stamp, title: title, body: body, text: text))
        save(entries, defaults)
        recordLock.unlock()
        recordObserver?(title, body, text)
    }

    private static let recordLock = NSLock()

    /// Returns entries within `retention`, most recent first.
    public static func load(defaults: UserDefaults? = nil) -> [NotificationHistoryEntry] {
        loadWithState(defaults: defaults).entries
    }

    /// `load` and whether the stored history could not be read (then `entries` is empty and does NOT mean that no
    /// notification was sent).
    public static func loadWithState(defaults: UserDefaults? = nil) -> (entries: [NotificationHistoryEntry], unreadable: Bool) {
        let now = Date()
        let read = readRaw(defaults)
        return (Array(read.entries.filter { isWithinRetention($0, now: now) }.reversed()), read.unreadable)
    }
}
