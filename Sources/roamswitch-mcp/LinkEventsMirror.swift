// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.0 (build 224).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The link-guard filter's event log (`linkfilter/events.log`), for the MCP server.
///
/// The file is root-only (mode 0600): it lists the hosts that were blocked or held and the apps that asked for them. The app gets the lines from
/// the helper (`HelperLogRelays`, stream `linkevents`) and keeps the last ones in its preferences (`~/Library/Preferences/com.tetsuharu.RoamSwitch.plist`,
/// 0600 inside `~/Library`, 0700), where the MCP server (the same account) reads them. Nothing reads the file itself.
///
/// Older than `freshSecs` (the app is not running), the mirror counts for nothing: the MCP server says the log could not be read.
public enum LinkEventsMirror {
    public static let defaultsKey = "RoamSwitch.LinkEventsMirrorV1"
    public static let freshSecs: Double = 600
    public static let maxLines = 400

    /// `history`: the whole log as the helper holds it (replaces what was kept); otherwise the new lines (appended).
    public static func store(lines: [String], isHistory: Bool, defaults: UserDefaults = .standard, now: Double = Date().timeIntervalSince1970) {
        let prior = defaults.dictionary(forKey: defaultsKey)
        let priorLines = prior?["lines"] as? [String] ?? []
        let priorAt = prior?["at"] as? Double ?? 0
        var kept = isHistory ? lines : priorLines + lines
        if kept.count > maxLines { kept.removeFirst(kept.count - maxLines) }
        // Written when something changed, or when the last write is getting old (the preferences file is large).
        if kept == priorLines, prior != nil, now >= priorAt, now - priorAt < freshSecs / 4 { return }
        defaults.set(["lines": kept, "at": now] as [String: Any], forKey: defaultsKey)
    }

    /// The log as text (one line per event, newline at the end); nil when there is no mirror or it is stale.
    public static func text(defaults: UserDefaults, now: Double = Date().timeIntervalSince1970) -> String? {
        guard let r = defaults.dictionary(forKey: defaultsKey), let lines = r["lines"] as? [String], let at = r["at"] as? Double,
              now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }
}
