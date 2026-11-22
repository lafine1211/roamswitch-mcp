// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for the paired Sensors and the audit results that `SensorPairingManager` (`RoamSwitchHelper`) keeps, used
/// by `RoamSwitchMCPServer`. That target is a separate, unprivileged process that cannot connect to the helper (its code signature is not the
/// app's). The helper's files are root-only (0600) since 2.2.1: the running app asks the helper and keeps a copy in the account's preferences
/// (`SensorStateMirror`), and this reads that copy. Without a fresh copy (the app is not running, or the helper does not answer) it reads the
/// files as this account can: the files of an older helper, which has not narrowed them yet, can be read; those of a current helper cannot,
/// and that is reported as unreadable, not as "no Sensor paired".
enum MCPSensorAuditStatusReader {
    private static let stateDir = "/Library/Application Support/RoamSwitch"
    static let trustedSensorsFile = stateDir + "/trusted_sensors.json"
    static let auditResultsFile = stateDir + "/sensor_audit_results.json"

    static func pairedSensorCount(defaults: UserDefaults? = nil) -> Int {
        pairedSensors(defaults: defaults).list.count
    }

    /// Newest-last, same order `SensorPairingManager` appends in.
    static func auditResults(defaults: UserDefaults? = nil) -> [PersistedSensorAuditResult] {
        auditResultsRead(defaults: defaults).list
    }

    /// The paired Sensors, and `unreadable` when the list is there but could not be read or parsed (the count is
    /// then not "0 paired"). With `defaults` (the app's preferences), the app's fresh copy comes first.
    static func pairedSensors(defaults: UserDefaults? = nil, now: Date = Date(),
                              path: String = trustedSensorsFile) -> (list: [PersistedTrustedSensor], unreadable: Bool) {
        if let defaults, let record = SensorStateMirror.read(defaults: defaults, now: now.timeIntervalSince1970) {
            if record.trustedUnreadable { return ([], true) }
            if let data = record.trusted, let list = try? JSONDecoder().decode([PersistedTrustedSensor].self, from: data) { return (list, false) }
        }
        return read([PersistedTrustedSensor].self, path: path)
    }

    static func auditResultsRead(defaults: UserDefaults? = nil, now: Date = Date(),
                                 path: String = auditResultsFile) -> (list: [PersistedSensorAuditResult], unreadable: Bool) {
        if let defaults, let record = SensorStateMirror.read(defaults: defaults, now: now.timeIntervalSince1970) {
            if record.auditUnreadable { return ([], true) }
            if let data = record.audit, let list = try? JSONDecoder().decode([PersistedSensorAuditResult].self, from: data) { return (list, false) }
        }
        return read([PersistedSensorAuditResult].self, path: path)
    }

    /// A file that is not there is an empty list (nothing paired or pulled yet); one that exists but cannot be read
    /// (no permission, damaged) is `unreadable`.
    private static func read<T: Decodable>(_ type: [T].Type, path: String) -> (list: [T], unreadable: Bool) {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            return ([], QuarantineManager.classifyReadError(error) != nil)
        }
        guard let decoded = try? JSONDecoder().decode(type, from: data) else { return ([], true) }
        return (decoded, false)
    }
}

/// Field-for-field mirror of `TrustedSensor`'s `Codable` shape — duplicated
/// rather than shared, same convention as `PersistedCanaryIncident`, to
/// keep this reader dependency-free (`TrustedSensor` lives in
/// `Shared/HelperProtocol.swift`, which isn't compiled into
/// `RoamSwitchMCPServer`).
struct PersistedTrustedSensor: Codable {
    let publicKeyB64: String
    let name: String
    let lastAddr: String?
    let pairedAt: String
}

/// Field-for-field mirror of `SensorAuditFinding`.
struct PersistedSensorAuditFinding: Codable {
    let port: Int
    let title: String
    let recommendation: String
    /// See `SensorAuditFinding.textKeys`: `nil` in older records and for texts no key gives back.
    let textKeys: SensorFindingTextKeys?

    init(port: Int, title: String, recommendation: String, textKeys: SensorFindingTextKeys? = nil) {
        self.port = port
        self.title = title
        self.recommendation = recommendation
        self.textKeys = textKeys
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        port = try c.decode(Int.self, forKey: .port)
        title = try c.decode(String.self, forKey: .title)
        recommendation = try c.decode(String.self, forKey: .recommendation)
        // A key of another shape loses only the translation, not the finding (nor the whole file).
        textKeys = (try? c.decodeIfPresent(SensorFindingTextKeys.self, forKey: .textKeys)) ?? nil
    }
}

/// Field-for-field mirror of `SensorAuditResult`.
struct PersistedSensorAuditResult: Codable {
    let id: String
    let sensorPublicKeyB64: String
    let sensorName: String
    let requestedAt: String
    let status: String
    let findings: [PersistedSensorAuditFinding]
    let pullAttempts: Int
    /// See `SensorAuditResult.failureReason`'s doc comment. Optional, so a
    /// record persisted before this field existed still decodes (`nil`,
    /// not a parse failure).
    let failureReason: String?
}
