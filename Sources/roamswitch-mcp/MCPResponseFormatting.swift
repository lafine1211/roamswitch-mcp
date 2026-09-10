// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.16 (build 73).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// MARK: - Payload DTOs (serialized as JSON tool responses by RoamSwitchMCPServer)

public struct MCPSecurityAuditItemPayload: Codable, Equatable {
    public let category: String
    public let title: String
    public let isPassed: Bool
    public let statusText: String
    public let detail: String
    public let recommendation: String
    public let settingsURL: String?
    public let isApplicable: Bool
}

public struct MCPSecurityReportPayload: Codable, Equatable {
    public let score: Int
    public let grade: String
    public let totalChecks: Int
    public let passedChecks: Int
    public let items: [MCPSecurityAuditItemPayload]
    public let caveats: [String]
    public let timestamp: String
}

public struct MCPPortFindingPayload: Codable, Equatable {
    public let title: String
    public let riskLevel: String
    public let description: String
    public let recommendation: String
}

public struct MCPPortPayload: Codable, Equatable {
    public let processName: String
    public let pid: Int
    public let port: Int
    public let isGloballyExposed: Bool
    public let executablePath: String?
    public let auditPerformed: Bool
    public let overallRisk: String?
    public let findings: [MCPPortFindingPayload]
    public let httpHeaders: [String: String]?
}

public struct MCPActiveVulnScanFindingPayload: Codable, Equatable {
    public let port: Int
    public let processName: String
    public let title: String
    public let description: String
    public let recommendation: String
}

public struct MCPActiveVulnScanResultPayload: Codable, Equatable {
    public let enabled: Bool
    public let scannedTargetCount: Int
    public let findings: [MCPActiveVulnScanFindingPayload]
    public let message: String
}

public struct MCPPackageCveFindingPayload: Codable, Equatable {
    public let cveId: String
    public let package: String
    public let installedVersion: String
    public let cvssScore: Double
    public let fixedVersion: String
    public let summary: String
    public let confidence: String
}

public struct MCPPackageCveScanResultPayload: Codable, Equatable {
    public let mapInstalled: Bool
    public let mapVersion: String
    public let findings: [MCPPackageCveFindingPayload]
}

public struct MCPPackageCveLanguageFindingPayload: Codable, Equatable {
    public let ecosystem: String
    public let cveId: String
    public let package: String
    public let installedVersion: String
    public let cvssScore: Double
    public let fixedVersion: String
    public let summary: String
}

public struct MCPPackageCveScanLanguagesResultPayload: Codable, Equatable {
    public let scannedFolderCount: Int
    public let findings: [MCPPackageCveLanguageFindingPayload]
}

public struct MCPExposedPortsPayload: Codable, Equatable {
    public let isFirewallShielded: Bool
    public let ports: [MCPPortPayload]
}

public struct MCPSecretFindingPayload: Codable, Equatable {
    public let type: String
    public let lineNumber: Int
    public let masked: String
    public let entropy: Double
    public let filePath: String?
}

public struct MCPAuditSecretsResultPayload: Codable, Equatable {
    public let findings: [MCPSecretFindingPayload]
}

public struct MCPSecurityLogEventPayload: Codable, Equatable {
    public let timestamp: String
    public let process: String
    public let category: String
    public let severity: String
    public let message: String
}

public struct MCPTemplateAnomalyPayload: Codable, Equatable {
    public let template: String
    public let example: String
    public let count: Int
    public let zScore: Double
    public let isNew: Bool
}

public struct MCPSecurityLogAuditPayload: Codable, Equatable {
    public let timeWindowHours: Int
    public let totalEvents: Int
    public let sudoFailures: Int
    public let sshAttempts: Int
    public let gatekeeperBlocks: Int
    public let xprotectDetections: Int
    public let isClean: Bool
    public let events: [MCPSecurityLogEventPayload]
    public let templateAnomalies: [MCPTemplateAnomalyPayload]
}

public struct MCPQuarantinedFilePayload: Codable, Equatable {
    public let originalPath: String
    public let quarantinedPath: String
    public let threatName: String
    public let quarantinedAt: String
    public let fileSize: Int64
}

public struct MCPQuarantineStatusPayload: Codable, Equatable {
    public let quarantineDirectory: String
    public let files: [MCPQuarantinedFilePayload]
}

public struct MCPCanaryIncidentPayload: Codable, Equatable {
    public let timestamp: String
    public let fileName: String
    public let detectedAction: String
    public let suspectedProcess: String?
    public let affectedFilePaths: [String]
}

/// `recentIncidentsAvailable` used to be hardcoded `false`: incident history
/// (`RansomwareCanaryGuard.recentIncidents`) only ever lived in the running
/// main app's memory, never persisted to disk, so a separate MCP server
/// process couldn't read it. `RansomwareCanaryGuard` now also persists a
/// capped incident log to the shared UserDefaults suite
/// (`CanaryStatusReader.persistedIncidents(defaults:)`), so this is `true`
/// whenever the guard has ever run, and `recentIncidents` carries the
/// actual history.
public struct MCPCanaryStatusPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let monitoredFilesCount: Int
    public let expectedFilesCount: Int
    public let recentIncidentsAvailable: Bool
    public let recentIncidents: [MCPCanaryIncidentPayload]
}

/// The history of notifications RoamSwitch has sent over the past 7 days,
/// most recent first — `NotificationHistoryEntry` mirrors
/// `roamswitch_core::notification_history::NotificationHistoryEntry` in the
/// Linux edition, and this wrapper matches that edition's MCP tool response
/// shape (`{"notifications": [...]}`).
public struct MCPNotificationHistoryPayload: Codable, Equatable {
    public let notifications: [NotificationHistoryEntry]
}

public struct MCPPortAnomalyIncidentPayload: Codable, Equatable {
    public let timestamp: String
    public let port: Int
    public let processName: String
    public let pid: Int
    public let executablePath: String?
}

public struct MCPPortAnomalyIncidentsPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let baselineCaptured: Bool
    public let autoIsolatedPorts: [Int]
    public let incidents: [MCPPortAnomalyIncidentPayload]
}

public struct MCPRuntimeThreatIncidentPayload: Codable, Equatable {
    public let timestamp: String
    public let process: String
    public let category: String
    public let severity: String
    public let message: String
}

/// Mac equivalent of the Linux eBPF Runtime Guard's status/incident MCP
/// tool — scoped to a single latest incident, not a history array, matching
/// `RuntimeThreatContainmentManager`'s own single-`lastIncident` design.
public struct MCPRuntimeThreatStatusPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let isIsolated: Bool
    public let lastContainmentDate: String?
    public let lastIncident: MCPRuntimeThreatIncidentPayload?
}

public struct MCPGuardEntryPayload: Codable, Equatable {
    public let key: String
    public let enabledInSettings: Bool
}

public struct MCPGuardStatusPayload: Codable, Equatable {
    public let activeSecurityLevel: String
    public let activeSecurityLevelLabel: String
    public let isCurrentNetworkTrusted: Bool
    public let guards: [MCPGuardEntryPayload]
    public let caveats: [String]
}

// MARK: - Pure formatting / decision functions

/// Reused by RoamSwitchMCPServer and, indirectly, tested here via
/// `@testable import RoamSwitch` (a separate `type: tool` target isn't a
/// practical XCTest target, so this file lives in the main app module and
/// is compiled into both targets — see project.yml).
public enum MCPResponseFormatting {
    private static let trustedNetworksKey = "RoamSwitch.trustedNetworks"
    private static let manualOverrideKey = "RoamSwitch.manualOverrideLevel"
    private static let awaySecurityLevelKey = "RoamSwitch.awaySecurityLevel"

    static let portAnomalyGuardKey = "RoamSwitch.PortAnomalyGuardEnabled"
    static let arpSpoofAutoContainmentKey = "RoamSwitch.ARPSpoofAutoContainmentEnabled"
    static let usbKeyboardGuardKey = "RoamSwitch.USBKeyboardGuardEnabled"
    static let usbStorageGuardKey = "RoamSwitch.USBStorageGuardEnabled"
    static let bluetoothGuardKey = "RoamSwitch.BluetoothGuardEnabled"
    static let webMailDownloadGuardKey = "RoamSwitch.WebMailDownloadGuardEnabled"
    static let dnsThreatGuardKey = "RoamSwitch.DNSThreatGuardEnabled"
    static let runtimeThreatContainmentKey = "RoamSwitch.RuntimeThreatContainmentEnabled"

    // MARK: get_security_report

    public static func makeSecurityReportPayload(
        report: ComprehensiveSecurityReport,
        wifiInterfacePresent: Bool,
        wifiSSIDResolved: Bool
    ) -> MCPSecurityReportPayload {
        var caveats: [String] = []
        // An interface exists but no SSID came back: ambiguous between
        // "genuinely not connected" and "no Location Services permission" —
        // a bare command-line tool can't be granted that permission the way
        // the app bundle can, so this reading can't be trusted either way.
        if wifiInterfacePresent, !wifiSSIDResolved {
            caveats.append(loc("Wi-Fi暗号化強度の判定は、位置情報の権限を持たないためこのツールからは行えない場合があります。「未接続」と表示されていても、実際にはOpen Wi-Fi等に接続している可能性があります。RoamSwitchアプリ本体の表示もあわせてご確認ください。"))
        }

        return MCPSecurityReportPayload(
            score: report.score,
            grade: report.grade,
            totalChecks: report.totalChecks,
            passedChecks: report.passedChecks,
            items: report.items.map {
                MCPSecurityAuditItemPayload(
                    category: $0.category,
                    title: $0.title,
                    isPassed: $0.isPassed,
                    statusText: $0.statusText,
                    detail: $0.detail,
                    recommendation: $0.recommendation,
                    settingsURL: $0.settingsURL,
                    isApplicable: $0.isApplicable
                )
            },
            caveats: caveats,
            timestamp: ISO8601DateFormatter().string(from: report.timestamp)
        )
    }

    // MARK: get_exposed_ports

    public static func makePortPayload(
        portInfo: ListeningPortInfo,
        auditResult: PortSecurityAuditResult?
    ) -> MCPPortPayload {
        MCPPortPayload(
            processName: portInfo.processName,
            pid: portInfo.pid,
            port: portInfo.port,
            isGloballyExposed: portInfo.isGloballyExposed,
            executablePath: portInfo.executablePath,
            auditPerformed: auditResult != nil,
            overallRisk: auditResult?.overallRisk.rawValue,
            findings: (auditResult?.findings ?? []).map {
                MCPPortFindingPayload(
                    title: $0.title,
                    riskLevel: $0.riskLevel.rawValue,
                    description: $0.description,
                    recommendation: $0.recommendation
                )
            },
            httpHeaders: auditResult?.httpHeaders
        )
    }

    // MARK: get_guard_status / activeSecurityLevel

    /// Replicates `AppState.activeSecurityLevel`'s UserDefaults-backed
    /// precedence (manual override > matched trusted network > away-level
    /// default) without touching `AppState` itself, which pulls in
    /// AppKit/Combine and isn't safe to compile into a headless CLI target.
    public static func resolveActiveSecurityLevel(
        gatewayMAC: String?,
        defaults: UserDefaults = .standard
    ) -> SecurityLevel {
        if let savedOverride = defaults.string(forKey: manualOverrideKey),
           let override = SecurityLevel(rawValue: savedOverride) {
            return override
        }

        if let gatewayMAC,
           let data = defaults.data(forKey: trustedNetworksKey),
           let networks = try? JSONDecoder().decode([TrustedNetwork].self, from: data),
           let matched = networks.first(where: { $0.macAddress.caseInsensitiveCompare(gatewayMAC) == .orderedSame }) {
            return matched.securityLevel
        }

        if let savedAway = defaults.string(forKey: awaySecurityLevelKey),
           let level = SecurityLevel(rawValue: savedAway) {
            return level
        }

        return .lockdown
    }

    public static func isCurrentNetworkTrusted(
        gatewayMAC: String?,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard let gatewayMAC,
              let data = defaults.data(forKey: trustedNetworksKey),
              let networks = try? JSONDecoder().decode([TrustedNetwork].self, from: data) else {
            return false
        }
        return networks.contains { $0.macAddress.caseInsensitiveCompare(gatewayMAC) == .orderedSame }
    }

    public static func makeGuardStatusPayload(
        gatewayMAC: String?,
        defaults: UserDefaults = .standard
    ) -> MCPGuardStatusPayload {
        let level = resolveActiveSecurityLevel(gatewayMAC: gatewayMAC, defaults: defaults)
        return MCPGuardStatusPayload(
            activeSecurityLevel: level.rawValue,
            activeSecurityLevelLabel: level.displayName,
            isCurrentNetworkTrusted: isCurrentNetworkTrusted(gatewayMAC: gatewayMAC, defaults: defaults),
            guards: [
                MCPGuardEntryPayload(key: "portAnomalyGuard", enabledInSettings: defaults.bool(forKey: portAnomalyGuardKey)),
                MCPGuardEntryPayload(key: "arpSpoofAutoContainment", enabledInSettings: defaults.bool(forKey: arpSpoofAutoContainmentKey)),
                MCPGuardEntryPayload(key: "usbKeyboardGuard", enabledInSettings: defaults.bool(forKey: usbKeyboardGuardKey)),
                MCPGuardEntryPayload(key: "usbStorageGuard", enabledInSettings: defaults.bool(forKey: usbStorageGuardKey)),
                MCPGuardEntryPayload(key: "bluetoothGuard", enabledInSettings: defaults.bool(forKey: bluetoothGuardKey)),
                MCPGuardEntryPayload(key: "webMailDownloadGuard", enabledInSettings: defaults.object(forKey: webMailDownloadGuardKey) == nil ? true : defaults.bool(forKey: webMailDownloadGuardKey)),
                MCPGuardEntryPayload(key: "dnsThreatGuard", enabledInSettings: defaults.object(forKey: dnsThreatGuardKey) == nil ? true : defaults.bool(forKey: dnsThreatGuardKey)),
                MCPGuardEntryPayload(key: "runtimeThreatContainment", enabledInSettings: defaults.bool(forKey: runtimeThreatContainmentKey)),
            ],
            caveats: [
                loc("各ガードの実際の有効性はRoamSwitch Pro版のライセンス状態にも依存しますが、このツールは別プロセスのためライセンス状態を正確に確認できません。上記はSettingsのトグル状態のみを示しています。")
            ]
        )
    }

    // MARK: audit_url_safety

    public static func makeLinkAuditPayload(report: LinkAuditReport) -> MCPLinkAuditPayload {
        MCPLinkAuditPayload(
            originalURL: report.originalURLString,
            finalURL: report.finalURLString,
            redirectChain: report.redirectChain,
            domain: report.domain,
            score: report.score,
            riskLevel: report.riskLevel.rawValue,
            isHTTPS: report.isHTTPS,
            riskFactors: report.riskFactors.map {
                MCPLinkRiskFactorPayload(
                    title: $0.title,
                    detail: $0.detail,
                    isSevere: $0.isSevere
                )
            }
        )
    }
}

public struct MCPLinkRiskFactorPayload: Codable, Equatable {
    public let title: String
    public let detail: String
    public let isSevere: Bool
}

public struct MCPLinkAuditPayload: Codable, Equatable {
    public let originalURL: String
    public let finalURL: String
    public let redirectChain: [String]
    public let domain: String
    public let score: Int
    public let riskLevel: String
    public let isHTTPS: Bool
    public let riskFactors: [MCPLinkRiskFactorPayload]
}
