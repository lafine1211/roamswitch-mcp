// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.5 (build 184).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// When a signed data feed (the package CVE map, the active-scan CVE map, the link guard's list) last updated, and
/// why the last attempt failed (audit C-F7).
///
/// An updater that fails keeps the old data and writes one line to the log. The data then ages without anyone
/// knowing: a CVE scan reports "nothing found" against a map that is months old. The record is kept in the
/// preferences so the CVE windows, the menu and the MCP tool (a separate process) can say it. A feed that was checked
/// and is already current counts as a success. Dependency-free: it is also built into the MCP server.
struct FeedUpdateRecord: Codable, Equatable {
    /// Unix seconds of the last time the feed was checked or installed without an error.
    var lastSuccessAt: Double?
    /// Unix seconds of the last failure, and what it was.
    var lastErrorAt: Double?
    var lastError: String?

    /// The last attempt failed (a later success clears it).
    var isFailing: Bool {
        guard let errorAt = lastErrorAt else { return false }
        return errorAt >= (lastSuccessAt ?? 0)
    }
}

enum FeedUpdateStatusStore {
    static let packageCveMap = "packageCveMap"
    static let activeVulnCveMap = "activeVulnCveMap"
    static let linkGuardFeed = "linkGuardFeed"
    static let all = [packageCveMap, activeVulnCveMap, linkGuardFeed]

    static func key(_ feed: String) -> String { "RoamSwitch.FeedUpdateStatusV1." + feed }
    static let maxMessageLength = 200

    static func read(_ feed: String, defaults: UserDefaults = .standard) -> FeedUpdateRecord {
        guard let data = defaults.data(forKey: key(feed)), let record = try? JSONDecoder().decode(FeedUpdateRecord.self, from: data) else {
            return FeedUpdateRecord()
        }
        return record
    }

    private static func write(_ record: FeedUpdateRecord, _ feed: String, _ defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: key(feed)) }
    }

    static func recordSuccess(_ feed: String, now: Date = Date(), defaults: UserDefaults = .standard) {
        var record = read(feed, defaults: defaults)
        record.lastSuccessAt = now.timeIntervalSince1970
        write(record, feed, defaults)
    }

    static func recordFailure(_ feed: String, message: String, now: Date = Date(), defaults: UserDefaults = .standard) {
        var record = read(feed, defaults: defaults)
        record.lastErrorAt = now.timeIntervalSince1970
        let flat = message.unicodeScalars.map { $0.value < 0x20 || $0.value == 0x7F ? " " : String($0) }.joined()
        record.lastError = String(flat.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ").prefix(maxMessageLength))
        write(record, feed, defaults)
    }

    // MARK: Text

    private static func day(_ t: Double) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: Date(timeIntervalSince1970: t))
    }

    /// One line for a window or a menu: when it last updated, and the failure if the last attempt failed.
    static func line(_ record: FeedUpdateRecord) -> String {
        let when = record.lastSuccessAt.map { String(format: loc("最後に更新できた日時: %@"), day($0)) } ?? loc("まだ更新できていません")
        guard record.isFailing, let message = record.lastError else { return when }
        return when + " / " + String(format: loc("直近の更新は失敗しました: %@"), message)
    }

    /// Nothing to say when the feed is fine and nothing was ever tried.
    static func lineIfKnown(_ record: FeedUpdateRecord) -> String? {
        (record.lastSuccessAt == nil && record.lastErrorAt == nil) ? nil : line(record)
    }
}
