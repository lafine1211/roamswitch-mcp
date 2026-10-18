// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.12.6 (build 168).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// What `SSHGuard` (the app side of the SSH brute-force guard) leaves in the shared preferences for
/// `RoamSwitchMCPServer`, which runs as the user and cannot talk to the root helper. Mirrors
/// `PortAnomalyStatusReader`: dependency-free, `defaults` must be the app's real preferences domain.
///
/// The records are copies of what the helper kept (incidents and logins, newest 200 / 50): the MCP tool
/// only reads, and nothing here can change a ban.
enum SSHGuardStatusReader {
    static let enabledKey = "RoamSwitch.SSHGuardEnabled"
    static let incidentsKey = "RoamSwitch.SSHGuard.IncidentsV1"
    static let sessionsKey = "RoamSwitch.SSHGuard.SessionsV1"
    static let statusKey = "RoamSwitch.SSHGuard.StatusV1"
    static let statusUpdatedKey = "RoamSwitch.SSHGuard.StatusUpdatedAt"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    /// Oldest first, as the helper keeps them.
    static func incidents(defaults: UserDefaults = .standard) -> [SSHGuardIncident] {
        guard let data = defaults.data(forKey: incidentsKey) else { return [] }
        return (try? JSONDecoder().decode([SSHGuardIncident].self, from: data)) ?? []
    }

    /// Newest first.
    static func sessions(defaults: UserDefaults = .standard) -> [SSHSession] {
        guard let data = defaults.data(forKey: sessionsKey) else { return [] }
        return (try? JSONDecoder().decode([SSHSession].self, from: data)) ?? []
    }

    /// The last status the app saw, with when it saw it; nil if the app has never reached the helper.
    static func status(defaults: UserDefaults = .standard) -> (status: SSHGuardStatus, updatedAt: Date)? {
        guard let data = defaults.data(forKey: statusKey),
              let status = try? JSONDecoder().decode(SSHGuardStatus.self, from: data),
              defaults.object(forKey: statusUpdatedKey) != nil else { return nil }
        return (status, Date(timeIntervalSince1970: defaults.double(forKey: statusUpdatedKey)))
    }
}
