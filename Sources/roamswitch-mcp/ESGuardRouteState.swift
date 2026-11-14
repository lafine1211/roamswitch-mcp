// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.1 (build 217).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Which way a guard sees the change it watches: through the Endpoint Security extension (the program that did it is known
/// at the moment it happened), or by the guard's own older way (a file-system notification, a timer, `lsof`), which stays
/// as the fallback while the extension is not approved, has no Full Disk Access or is not running.
enum ESGuardRouteState: String, Codable, Equatable {
    case endpointSecurity = "es"
    case fallback = "fallback"

    static let defaultsKeyPrefix = "RoamSwitch.ESGuardRouteV1."
    static let freshSecs: Double = 300

    /// The app writes the state for the MCP server (a separate process that cannot read the extension's report through
    /// the system extension manager), one record per guard.
    static func write(_ state: ESGuardRouteState, reason: String?, guardID: String, now: Double, defaults: UserDefaults = .standard) {
        var record: [String: Any] = ["route": state.rawValue, "at": now]
        if let reason { record["reason"] = reason }
        defaults.set(record, forKey: defaultsKeyPrefix + guardID)
    }

    static func read(_ guardID: String, defaults: UserDefaults, now: Double) -> (state: ESGuardRouteState, reason: String?)? {
        guard let r = defaults.dictionary(forKey: defaultsKeyPrefix + guardID), let raw = r["route"] as? String,
              let s = ESGuardRouteState(rawValue: raw), let at = r["at"] as? Double, now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return (s, r["reason"] as? String)
    }
}

extension ESGuardRouteState {
    /// The guard (`get_guard_status` key) each Endpoint Security watch belongs to.
    static let guardKeys: [String: String] = [
        "ransomwareCanaryGuard": "canary", "ransomwareEntropyGuard": "entropy", "credentialHoneytokenGuard": "honeytoken",
        "browserCredentialWatchGuard": "browser", "credentialFileWatchGuard": "credentials", "criticalPathFim": "fim",
        "lockfileTamperGuard": "lockfile", "agentSetupWatch": "agentSetup", "persistenceMonitor": "persistence",
        "webMailDownloadGuard": "downloads", "logTamperWatchGuard": "history",
    ]

    static func guardID(forKey key: String) -> String? { guardKeys[key] }

    /// Guards that exist only through the extension: no older way to fall back to.
    static func hasNoFallback(key: String) -> Bool { key == "credentialFileWatchGuard" || key == "logTamperWatchGuard" }
}

