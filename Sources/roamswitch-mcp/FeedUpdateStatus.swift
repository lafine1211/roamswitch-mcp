// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.14 (build 193).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// When a signed data feed (the package CVE map, the active-scan CVE map, the link guard's list, the web rules) last updated, and
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
    static let webRules = "webRules"
    static let all = [packageCveMap, activeVulnCveMap, linkGuardFeed, webRules]

    // MARK: Updates that stopped running

    /// A feed that has not been checked for this long is stale. It is the Linux build's `UPDATES_STALE_SECS` (a week
    /// without a run of the daily update timer): the link list and the web rules are checked every day.
    static let staleAfterDaily: TimeInterval = 7 * 24 * 3600
    /// The two CVE maps are fetched at most once a week (`autoCheckInterval`), and the record is written when a
    /// check happens, not at every daily tick of the timer. A week more than the interval is allowed, which is what
    /// "a week without a run" comes to for them.
    static let weeklyChecked: Set<String> = [packageCveMap, activeVulnCveMap]

    static func staleAfter(_ feed: String) -> TimeInterval {
        weeklyChecked.contains(feed) ? 2 * staleAfterDaily : staleAfterDaily
    }

    /// The last time the feed was checked, whether it worked or not.
    static func lastRun(_ record: FeedUpdateRecord) -> Double? {
        [record.lastSuccessAt, record.lastErrorAt].compactMap { $0 }.max()
    }

    /// The updater has not checked this feed for longer than `staleAfter`. A feed that was never checked is not
    /// stale by this test: nothing says when it should have run (the windows say "まだ更新できていません"), and a failed
    /// check counts as a run, because a failure is shown on its own (`isFailing`).
    static func isStale(_ record: FeedUpdateRecord, feed: String, now: Date) -> Bool {
        guard let run = lastRun(record) else { return false }
        return now.timeIntervalSince1970 - run > staleAfter(feed)
    }

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

    static func displayName(_ feed: String) -> String {
        switch feed {
        case packageCveMap: return loc("パッケージCVEの地図")
        case activeVulnCveMap: return loc("アクティブ脆弱性スキャンのCVE地図")
        case linkGuardFeed: return loc("リンク保護の一覧")
        case webRules: return loc("Webルール")
        default: return feed
        }
    }

    /// The menu line for feeds whose updates stopped: which ones, nothing else.
    static func staleTitle(_ stale: [(feed: String, lastRun: Double)]) -> String {
        String(format: loc("⚠️ 検知用データの更新が止まっています: %@"), stale.map { displayName($0.feed) }.joined(separator: "、"))
    }

    /// The tooltip of that line: when each feed was last checked, and what brings the check back.
    static func staleTooltip(_ stale: [(feed: String, lastRun: Double)]) -> String {
        let lines = stale.map { String(format: loc("%@ (最後の確認: %@)"), displayName($0.feed), day($0.lastRun)) }.joined(separator: "\n")
        return String(format: loc("次のデータを、1週間以上確認できていません。\n%@\n\nRoamSwitchを再起動すると、すぐに更新を確認します。"), lines)
    }

    static func day(_ t: Double) -> String {
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
