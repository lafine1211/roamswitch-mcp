// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.34 (build 213).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Minimal, dependency-free reader for `SensorPairingManager`'s
/// (`RoamSwitchHelper`) on-disk Sensor pairing/audit-result store — used by
/// `RoamSwitchMCPServer`. That target is a separate, unprivileged process
/// that doesn't link `HelperManager`'s full XPC client (WireGuard/Tailscale/
/// ARP-lock/... — none of which this minimal tool process needs just to
/// read audit findings), so this reads the same on-disk JSON files the
/// helper writes directly off disk instead — the same "minimal
/// dependency-free reader" convention already used for
/// `CanaryStatusReader`/`PortAnomalyStatusReader`, just backed by a plain
/// file rather than shared UserDefaults, since this state originates in a
/// separate root process rather than the main app. Both files are
/// deliberately left world-readable by `SensorPairingManager` (unlike its
/// identity file) since neither trust metadata nor scan findings are
/// secret.
enum MCPSensorAuditStatusReader {
    private static let stateDir = "/Library/Application Support/RoamSwitch"
    static let trustedSensorsFile = stateDir + "/trusted_sensors.json"
    static let auditResultsFile = stateDir + "/sensor_audit_results.json"

    static func pairedSensorCount() -> Int {
        pairedSensors().list.count
    }

    /// Newest-last, same order `SensorPairingManager` appends in.
    static func auditResults() -> [PersistedSensorAuditResult] {
        auditResultsRead().list
    }

    /// The paired Sensors, and `unreadable` when the file is there but could not be read or parsed (the count is
    /// then not "0 paired").
    static func pairedSensors(path: String = trustedSensorsFile) -> (list: [PersistedTrustedSensor], unreadable: Bool) {
        read([PersistedTrustedSensor].self, path: path)
    }

    static func auditResultsRead(path: String = auditResultsFile) -> (list: [PersistedSensorAuditResult], unreadable: Bool) {
        read([PersistedSensorAuditResult].self, path: path)
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
