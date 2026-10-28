// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.10 (build 189).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Where the link guard is enforced right now, and the notice when the better enforcement point waits for the person
/// (audit B-F8). Dependency-free: the MCP server reads the record the app writes.
///
/// The content-filter system extension sees every connection after name resolution, so it also covers browsers that
/// encrypt their DNS (DoH). Until the person approves it in System Settings, the guard falls back to a block list in
/// `/etc/hosts`, which those browsers bypass. The fallback is not shown anywhere but the menu, so a Mac could stay on it
/// for good while the guard read "on".
enum LinkGuardEnforcement: String, Codable, Equatable {
    /// The system extension is filtering.
    case systemExtension
    /// Waiting for the person to approve it in System Settings.
    case waitingForApproval
    /// The request failed.
    case failed
    /// Not active (not requested yet, or the guard is off): the /etc/hosts list is the only enforcement.
    case hostsOnly

    /// The better enforcement point is not in place although the guard is on.
    var isDegraded: Bool { self != .systemExtension }

    static let defaultsKey = "RoamSwitch.LinkGuardEnforcementV1"
    static let freshSecs: Double = 180

    static func write(_ value: LinkGuardEnforcement, now: Double, defaults: UserDefaults = .standard) {
        defaults.set(["state": value.rawValue, "at": now] as [String: Any], forKey: defaultsKey)
    }

    /// As the app last wrote it; nil when there is none or it is stale (the app is probably not running).
    static func read(defaults: UserDefaults, now: Double) -> LinkGuardEnforcement? {
        guard let record = defaults.dictionary(forKey: defaultsKey), let raw = record["state"] as? String,
              let value = LinkGuardEnforcement(rawValue: raw), let at = record["at"] as? Double,
              now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return value
    }
}

/// When to tell the person that the approval is still missing.
enum LinkFilterApprovalPolicy {
    /// The approval dialog is easy to dismiss and forget; this long after the request is "too long".
    static let graceSecs: TimeInterval = 600
    /// Not told again within this time (the app asks for the extension again at every launch).
    static let repeatSecs: TimeInterval = 3 * 24 * 3600

    static func shouldNotify(pendingSince: Date?, lastNoticeAt: Date?, now: Date, linkGuardOn: Bool) -> Bool {
        guard linkGuardOn, let pendingSince, now.timeIntervalSince(pendingSince) >= graceSecs else { return false }
        if let lastNoticeAt, now.timeIntervalSince(lastNoticeAt) < repeatSecs { return false }
        return true
    }

    static func noticeTitle() -> String { "⚠️ " + loc("リンク保護のシステム拡張が、承認待ちです") }

    static func noticeBody() -> String {
        loc("承認するまで、リンク保護は /etc/hosts の一覧だけで動き、DNSを暗号化するブラウザー(DoH)の接続は止められません。メニューの「リンク保護」→「システム拡張を承認 (システム設定を開く)…」から開き、RoamSwitchを許可してください。")
    }
}
