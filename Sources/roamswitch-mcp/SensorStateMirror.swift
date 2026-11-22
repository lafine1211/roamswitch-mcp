// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The paired Sensors and the Sensor audit results, as the app keeps them for the MCP server.
///
/// The helper (root) writes both lists to files in `/Library/Application Support/RoamSwitch` (`trusted_sensors.json`,
/// `sensor_audit_results.json`). They name the Sensors' public keys, last addresses and the findings of a scan of the network, and were
/// world-readable (0644): the MCP server read them straight off the disk. They are 0600 now, like the helper's other state (see
/// docs/output_channel_audit L5). The app asks the helper for them over XPC, as it does for the Sensor screen, and keeps the answer in
/// the preferences of the account that runs it (`SensorStateMirrorRefresher`); the MCP server reads that copy. This is the same way
/// `HelperHealthMirror` reaches the MCP server.
public struct SensorStateMirrorRecord: Codable, Equatable {
    /// The app's clock when it asked.
    public var fetchedAt: Double
    /// The helper's trusted-Sensor list as JSON, nil when the helper has not answered yet.
    public var trusted: Data?
    /// The helper's audit-result list as JSON, nil when the helper has not answered yet.
    public var audit: Data?
    /// The helper answered that it could not read the file (damaged): not "nothing paired".
    public var trustedUnreadable: Bool
    public var auditUnreadable: Bool

    public init(fetchedAt: Double, trusted: Data? = nil, audit: Data? = nil, trustedUnreadable: Bool = false, auditUnreadable: Bool = false) {
        self.fetchedAt = fetchedAt; self.trusted = trusted; self.audit = audit
        self.trustedUnreadable = trustedUnreadable; self.auditUnreadable = auditUnreadable
    }
}

public enum SensorStateMirror {
    public static let defaultsKey = "RoamSwitch.SensorStateMirrorV1"
    /// Older than this (the app is not running, or the helper does not answer), the copy is not what the helper holds.
    public static let freshSecs: Double = 30 * 60

    public static func store(_ record: SensorStateMirrorRecord, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: defaultsKey) }
    }

    /// The last record, nil when there is none or it is too old to be believed.
    public static func read(defaults: UserDefaults, now: Double = Date().timeIntervalSince1970) -> SensorStateMirrorRecord? {
        guard let data = defaults.data(forKey: defaultsKey),
              let r = try? JSONDecoder().decode(SensorStateMirrorRecord.self, from: data),
              now - r.fetchedAt <= freshSecs, r.fetchedAt - now <= freshSecs else { return nil }
        return r
    }
}
