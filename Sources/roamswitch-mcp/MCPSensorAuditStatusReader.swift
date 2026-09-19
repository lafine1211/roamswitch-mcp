// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.43 (build 100).
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
    private static let trustedSensorsFile = stateDir + "/trusted_sensors.json"
    private static let auditResultsFile = stateDir + "/sensor_audit_results.json"

    static func pairedSensorCount() -> Int {
        guard let data = FileManager.default.contents(atPath: trustedSensorsFile),
              let decoded = try? JSONDecoder().decode([PersistedTrustedSensor].self, from: data) else {
            return 0
        }
        return decoded.count
    }

    /// Newest-last, same order `SensorPairingManager` appends in.
    static func auditResults() -> [PersistedSensorAuditResult] {
        guard let data = FileManager.default.contents(atPath: auditResultsFile),
              let decoded = try? JSONDecoder().decode([PersistedSensorAuditResult].self, from: data) else {
            return []
        }
        return decoded
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
