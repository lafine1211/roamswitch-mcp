// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.9 (build 188).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The state of the watchdog: the small program that starts RoamSwitch again after it quit unexpectedly (audit C-F1).
///
/// The program ships inside the app, but nothing started it: its LaunchAgent plist was left out of the bundle and no
/// code registered it, so a normal install never ran it while the catalog and the coverage called it "on". The plist is
/// now in the bundle (`Contents/Library/LaunchAgents`) and the app registers it as a login item (`SMAppService.agent`)
/// after the person agrees. This type is the pure part: how the OS answer and the old script's file become one state,
/// what each state is called, and the record the app keeps for the MCP tool (a separate process that cannot ask the OS).
enum WatchdogAgentState: String, Codable, Equatable {
    /// Never registered, or switched off.
    case notRegistered
    /// Registered and allowed: the watchdog runs and restarts the app after a crash.
    case enabled
    /// Registered, waiting for the person to allow it in System Settings (Login Items).
    case requiresApproval
    /// The app does not contain the agent's plist or its program (a build that left it out).
    case notFound
    /// Started by `scripts/manage_watchdog.sh` (a plist in ~/Library/LaunchAgents) instead of by the app.
    case legacyScript

    /// What the system says about the registered agent. Mirrors `SMAppService.Status`, which the app converts.
    enum Registration: Equatable { case notRegistered, enabled, requiresApproval, notFound }

    /// `agentInBundle`: the plist and the program it names are really inside the running app (`bundleHasAgent`).
    ///
    /// macOS answers `notFound` for an agent that was never registered, even when its plist is in the app: the system
    /// only knows the item once `register()` has run (seen on a signed, notarized build, where the plist and program
    /// are in the bundle and the status is still `notFound`). So `notFound` means "left out of the app" only when the
    /// bundle check agrees. Otherwise it is "not registered yet".
    static func resolve(registration: Registration, legacyScriptInstalled: Bool, agentInBundle: Bool) -> WatchdogAgentState {
        switch registration {
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notFound:
            if legacyScriptInstalled { return .legacyScript }
            return agentInBundle ? .notRegistered : .notFound
        case .notRegistered: return legacyScriptInstalled ? .legacyScript : .notRegistered
        }
    }

    /// The agent's plist is in `<app>/Contents/Library/LaunchAgents` and the program it names (`BundleProgram`,
    /// relative to the app) exists there.
    static func bundleHasAgent(bundleURL: URL, plistName: String, fileManager: FileManager = .default) -> Bool {
        let plistURL = bundleURL.appendingPathComponent("Contents/Library/LaunchAgents").appendingPathComponent(plistName)
        guard let data = try? Data(contentsOf: plistURL),
              let plist = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any],
              let program = plist["BundleProgram"] as? String, !program.isEmpty, !program.hasPrefix("/"), !program.contains("..")
        else { return false }
        return fileManager.isExecutableFile(atPath: bundleURL.appendingPathComponent(program).path)
    }

    /// The watchdog is running. Waiting for approval is not running.
    var isRunning: Bool { self == .enabled || self == .legacyScript }

    /// The liveState word of `get_detection_coverage` for the watchdog.
    var liveState: String {
        switch self {
        case .enabled, .legacyScript: return "on"
        case .notRegistered, .requiresApproval, .notFound: return "off"
        }
    }

    /// Why it is off, in the codes the coverage uses for `reason`.
    var reasonCode: String? {
        switch self {
        case .enabled, .legacyScript: return nil
        case .notRegistered: return "watchdog_not_registered"
        case .requiresApproval: return "watchdog_requires_approval"
        case .notFound: return "watchdog_not_in_bundle"
        }
    }
}

/// What the app tells the MCP tool about the watchdog. Written by the app (at launch and every minute), read by the
/// MCP server. A record older than `freshSecs` is not trusted (the app is probably not running).
enum WatchdogAgentSnapshot {
    static let defaultsKey = "RoamSwitch.WatchdogAgentStateV1"
    static let freshSecs: Double = 180

    static func write(_ state: WatchdogAgentState, now: Double, defaults: UserDefaults = .standard) {
        defaults.set(["state": state.rawValue, "at": now] as [String: Any], forKey: defaultsKey)
    }

    static func read(defaults: UserDefaults, now: Double) -> WatchdogAgentState? {
        guard let record = defaults.dictionary(forKey: defaultsKey), let raw = record["state"] as? String,
              let state = WatchdogAgentState(rawValue: raw), let at = record["at"] as? Double,
              now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return state
    }
}
