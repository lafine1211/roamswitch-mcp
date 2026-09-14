// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.27 (build 84).
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
    /// `true` when no value is stored for this toggle (the user never
    /// changed it), so `enabledInSettings` is the guard's own built-in
    /// default. Optional for wire compatibility with pre-1.9.25 clients.
    public let usingDefault: Bool?
}

/// Every field added after the original five is optional so older
/// RoamSwitchKit / MCP clients decoding the previous shape keep working.
public struct MCPGuardStatusPayload: Codable, Equatable {
    public let activeSecurityLevel: String
    public let activeSecurityLevelLabel: String
    public let isCurrentNetworkTrusted: Bool
    public let guards: [MCPGuardEntryPayload]
    /// "off" | "warn" | "block" (default "block").
    public let linkGuardMode: String?
    /// "wireguard" | "tailscale" (default "wireguard").
    public let vpnBackend: String?
    public let tailscaleExitNodeConfigured: Bool?
    /// "quad9" | "cloudflareSecurity" | "adguard" | "cleanBrowsing" (default "quad9").
    public let dnsThreatGuardProvider: String?
    /// "awayOnly" | "always" (default "awayOnly").
    public let dnsThreatGuardScope: String?
    /// Dev-server ports the user has isolated from the LAN, ascending.
    public let isolatedDevPorts: [Int]?
    public let usbStorageAllowedVolumeCount: Int?
    public let caveats: [String]
}

/// One `ContainmentIncidentTimeline` entry. `source`/`actionTaken`/`status`
/// are stable identifiers; the `...Label` fields are localized.
public struct MCPIncidentTimelineEventPayload: Codable, Equatable {
    public let id: String
    public let timestamp: String
    /// "arpSpoof" | "ransomwareCanary" | "runtimeThreat" | "portAnomaly"
    public let source: String
    public let sourceLabel: String
    public let severity: String
    public let summary: String
    public let processName: String?
    public let processID: Int32?
    public let attackTechnique: String?
    /// "air_gap" | "port_block" | ...
    public let actionTaken: String
    public let actionTakenLabel: String
    /// "open" | "released" | "autoTimeout" | "allowlisted"
    public let status: String
    public let resolvedAt: String?
}

public struct MCPIncidentTimelinePayload: Codable, Equatable {
    public let unresolvedCount: Int
    public let events: [MCPIncidentTimelineEventPayload]
    public let caveats: [String]
}

public struct MCPKnownNetworkPayload: Codable, Equatable {
    public let ssid: String
    public let gatewayCount: Int
    public let lastSeen: String
}

public struct MCPLookalikeNetworkPairPayload: Codable, Equatable {
    public let ssid: String
    public let similarTo: String
    public let editDistance: Int
}

public struct MCPNetworkHistoryPayload: Codable, Equatable {
    public let knownNetworkCount: Int
    public let networks: [MCPKnownNetworkPayload]
    public let lookalikePairs: [MCPLookalikeNetworkPairPayload]
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
    // Keys below are verified against each guard's own `enabledKey` (see the
    // file named in the trailing comment); defaults mirror that guard's getter.
    static let ransomwareCanaryGuardKey = "RoamSwitch.RansomwareCanaryGuardEnabled"   // RansomwareCanaryGuard — false; Pro default-on
    static let clickFixGuardKey = "RoamSwitch.ClickFixGuardEnabled"                   // ClickFixGuard — false
    static let dockerEventGuardKey = "RoamSwitch.DockerEventGuardEnabled"             // DockerEventGuard — false
    static let criticalPathFimKey = "RoamSwitch.CriticalPathFimEnabled"               // CriticalPathFimGuard — false; Pro default-on
    static let persistenceMonitorKey = "RoamSwitch.PersistenceMonitorEnabled"         // PersistenceMonitorGuard — true
    static let gatewayARPLockKey = "RoamSwitch.GatewayARPLockEnabled"                 // GatewayARPLockManager — false
    static let scheduledLogAuditKey = "RoamSwitch.ScheduledLogAuditEnabled"           // ScheduledLogAuditGuard — false; Pro default-on
    static let secretLeakAuditorKey = "RoamSwitch.SecretLeakAuditorEnabled"           // SecretLeakAuditor (clipboard) — true
    static let airGapAutoWiFiKillKey = "RoamSwitch.AirGapAutoWiFiKillEnabled"         // *ContainmentManager — true
    static let wireGuardVPNKey = "RoamSwitch.WireGuardVPNEnabled"                     // WireGuardVPNManager — false
    static let tailscaleKillSwitchKey = "RoamSwitch.VPNTailscaleKillSwitch"           // TailscaleVPNManager — false
    static let tailscaleExitNodeKey = "RoamSwitch.VPNTailscaleExitNode"               // TailscaleVPNManager
    static let vpnBackendKey = "RoamSwitch.VPNBackend"                                // VPNBackend — "wireguard"
    static let linkGuardModeKey = "RoamSwitch.LinkGuardMode"                          // LinkGuardManager — "block"
    static let linkGuardUpdatesKey = "RoamSwitch.LinkGuardUpdatesEnabled"             // LinkGuardManager — true
    static let dnsThreatGuardProviderKey = "RoamSwitch.DNSThreatGuardProvider"        // DNSThreatGuard — "quad9"
    static let dnsThreatGuardScopeKey = "RoamSwitch.DNSThreatGuardScope"              // DNSThreatGuard — "awayOnly"
    static let isolatedDevPortsKey = "RoamSwitch.IsolatedDevPorts"                    // DevServerIsolator — [Int]
    static let usbAllowedVolumesKey = "RoamSwitch.USBGuardAllowedVolumes"             // USBStorageGuard — JSON array

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

        func entry(_ key: String, _ defaultsKey: String, defaultWhenUnset: Bool) -> MCPGuardEntryPayload {
            let isUnset = defaults.object(forKey: defaultsKey) == nil
            let enabled = isUnset ? defaultWhenUnset : defaults.bool(forKey: defaultsKey)
            return MCPGuardEntryPayload(key: key, enabledInSettings: enabled, usingDefault: isUnset)
        }

        let storedLinkMode = defaults.string(forKey: linkGuardModeKey)
        let linkMode = LinkGuardMode(rawValue: storedLinkMode ?? "") ?? .block

        var guards: [MCPGuardEntryPayload] = []
        guards.append(entry("portAnomalyGuard", portAnomalyGuardKey, defaultWhenUnset: false))
        guards.append(entry("arpSpoofAutoContainment", arpSpoofAutoContainmentKey, defaultWhenUnset: false))
        guards.append(entry("usbKeyboardGuard", usbKeyboardGuardKey, defaultWhenUnset: false))
        guards.append(entry("usbStorageGuard", usbStorageGuardKey, defaultWhenUnset: false))
        guards.append(entry("bluetoothGuard", bluetoothGuardKey, defaultWhenUnset: false))
        guards.append(entry("webMailDownloadGuard", webMailDownloadGuardKey, defaultWhenUnset: true))
        guards.append(entry("dnsThreatGuard", dnsThreatGuardKey, defaultWhenUnset: true))
        guards.append(entry("runtimeThreatContainment", runtimeThreatContainmentKey, defaultWhenUnset: false))
        guards.append(entry("ransomwareCanaryGuard", ransomwareCanaryGuardKey, defaultWhenUnset: false))
        guards.append(entry("clickFixGuard", clickFixGuardKey, defaultWhenUnset: false))
        guards.append(entry("dockerEventGuard", dockerEventGuardKey, defaultWhenUnset: false))
        guards.append(entry("criticalPathFim", criticalPathFimKey, defaultWhenUnset: false))
        guards.append(entry("persistenceMonitor", persistenceMonitorKey, defaultWhenUnset: true))
        guards.append(entry("gatewayARPLock", gatewayARPLockKey, defaultWhenUnset: false))
        guards.append(entry("scheduledLogAudit", scheduledLogAuditKey, defaultWhenUnset: false))
        guards.append(entry("secretLeakClipboardAuditor", secretLeakAuditorKey, defaultWhenUnset: true))
        guards.append(entry("airGapAutoWiFiKill", airGapAutoWiFiKillKey, defaultWhenUnset: true))
        guards.append(entry("wireGuardVPN", wireGuardVPNKey, defaultWhenUnset: false))
        guards.append(entry("tailscaleKillSwitch", tailscaleKillSwitchKey, defaultWhenUnset: false))
        guards.append(MCPGuardEntryPayload(key: "linkGuard", enabledInSettings: linkMode != .off, usingDefault: storedLinkMode == nil))
        guards.append(entry("linkGuardFeedUpdates", linkGuardUpdatesKey, defaultWhenUnset: true))
        guards.append(entry("activeVulnScan", ActiveVulnScan.enabledDefaultsKey, defaultWhenUnset: false))

        // Mirrors `VPNBackend.fromStored` (TailscaleVPNManager.swift, AppKit-only).
        let storedBackend = (defaults.string(forKey: vpnBackendKey) ?? "").lowercased()
        let vpnBackend = (storedBackend == "tailscale" || storedBackend == "ts") ? "tailscale" : "wireguard"
        let exitNode = defaults.string(forKey: tailscaleExitNodeKey) ?? ""

        // Mirrors `SecureDNSProvider` / `DNSApplicationScope` (DNSThreatGuard.swift).
        let knownProviders: Set<String> = ["quad9", "cloudflareSecurity", "adguard", "cleanBrowsing"]
        let storedProvider = defaults.string(forKey: dnsThreatGuardProviderKey) ?? ""
        let dnsProvider = knownProviders.contains(storedProvider) ? storedProvider : "quad9"
        let storedScope = defaults.string(forKey: dnsThreatGuardScopeKey) ?? ""
        let dnsScope = (storedScope == "always") ? "always" : "awayOnly"

        let isolatedPorts = ((defaults.array(forKey: isolatedDevPortsKey) as? [Int]) ?? []).sorted()

        var allowedVolumeCount = 0
        if let data = defaults.data(forKey: usbAllowedVolumesKey),
           let array = (try? JSONSerialization.jsonObject(with: data)) as? [Any] {
            allowedVolumeCount = array.count
        }

        var caveats: [String] = []
        caveats.append(loc("各ガードの実際の有効性はRoamSwitch Pro版のライセンス状態にも依存しますが、このツールは別プロセスのためライセンス状態を正確に確認できません。上記はSettingsのトグル状態のみを示しています。"))
        caveats.append(loc("usingDefault が true の項目は、ユーザーが一度も切り替えていない既定値です。ポート異常ガード・ARPスプーフィング自動封じ込め・ランタイム脅威封じ込め・ランサムウェア・カナリアガード・重要パスの改ざん監視・定期ログ監査は、Pro版を有効化した時点で一度だけ自動的にオンになります。"))
        caveats.append(loc("VPNトンネルの実際の接続状態とキルスイッチの適用状態は特権ヘルパーが管理しているため、このツールからは確認できません。VPN関連の項目は設定値のみを示しています。"))

        return MCPGuardStatusPayload(
            activeSecurityLevel: level.rawValue,
            activeSecurityLevelLabel: level.displayName,
            isCurrentNetworkTrusted: isCurrentNetworkTrusted(gatewayMAC: gatewayMAC, defaults: defaults),
            guards: guards,
            linkGuardMode: linkMode.rawValue,
            vpnBackend: vpnBackend,
            tailscaleExitNodeConfigured: !exitNode.isEmpty,
            dnsThreatGuardProvider: dnsProvider,
            dnsThreatGuardScope: dnsScope,
            isolatedDevPorts: isolatedPorts,
            usbStorageAllowedVolumeCount: allowedVolumeCount,
            caveats: caveats
        )
    }

    // MARK: get_incident_timeline

    static func containmentSourceLabel(_ source: ContainmentIncidentSource) -> String {
        switch source {
        case .arpSpoof: return loc("ARPスプーフィング自動封じ込め")
        case .ransomwareCanary: return loc("ランサムウェア・カナリアガード")
        case .runtimeThreat: return loc("ランタイム脅威封じ込め (XProtect連動)")
        case .portAnomaly: return loc("ポート異常ガード")
        }
    }

    static func containmentActionLabel(_ action: String) -> String {
        switch action {
        case "air_gap": return loc("ネットワーク全遮断 (Air-Gap)")
        case "port_block": return loc("ポートのLAN公開を遮断")
        default: return action
        }
    }

    public static func makeIncidentTimelinePayload(events: [ContainmentIncidentEvent]) -> MCPIncidentTimelinePayload {
        let iso = ISO8601DateFormatter()
        var payloads: [MCPIncidentTimelineEventPayload] = []
        var unresolved = 0
        for event in events {
            let status: String
            if let resolution = event.resolution {
                status = resolution.rawValue
            } else if event.resolvedAt != nil {
                status = "released"
            } else {
                status = "open"
                unresolved += 1
            }
            payloads.append(MCPIncidentTimelineEventPayload(
                id: event.id.uuidString,
                timestamp: iso.string(from: event.timestamp),
                source: event.source.rawValue,
                sourceLabel: containmentSourceLabel(event.source),
                severity: event.severity,
                summary: event.summary,
                processName: event.processName,
                processID: event.processID,
                attackTechnique: event.attackTechnique,
                actionTaken: event.actionTaken,
                actionTakenLabel: containmentActionLabel(event.actionTaken),
                status: status,
                resolvedAt: event.resolvedAt.map { iso.string(from: $0) }
            ))
        }
        let caveats: [String] = [
            loc("summary は検知時点に記録された文言をそのまま返します。後から表示言語を変更しても、過去の記録には反映されません。")
        ]
        return MCPIncidentTimelinePayload(unresolvedCount: unresolved, events: payloads, caveats: caveats)
    }

    // MARK: get_network_history

    static func makeNetworkHistoryPayload(
        entries: [NetworkHistoryGuard.HistorySnapshotEntry],
        lookalikes: [NetworkHistoryGuard.LookalikePair],
        limit: Int
    ) -> MCPNetworkHistoryPayload {
        let iso = ISO8601DateFormatter()
        let networks: [MCPKnownNetworkPayload] = entries.prefix(max(limit, 0)).map {
            MCPKnownNetworkPayload(ssid: $0.ssid, gatewayCount: $0.gatewayCount, lastSeen: iso.string(from: $0.lastSeen))
        }
        let pairs: [MCPLookalikeNetworkPairPayload] = lookalikes.map {
            MCPLookalikeNetworkPairPayload(ssid: $0.ssid, similarTo: $0.similarTo, editDistance: $0.distance)
        }
        let caveats: [String] = [
            loc("ゲートウェイのMACアドレスは出力せず、ネットワークごとの件数のみを返します。lookalikePairs は名前が酷似しているのに共通のゲートウェイ機器がない組み合わせで、なりすましアクセスポイント（Evil Twin）の可能性があります。")
        ]
        return MCPNetworkHistoryPayload(
            knownNetworkCount: entries.count,
            networks: networks,
            lookalikePairs: pairs,
            caveats: caveats
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
                    isSevere: $0.isSevere,
                    kind: $0.kind?.rawValue
                )
            }
        )
    }
}

public struct MCPLinkRiskFactorPayload: Codable, Equatable {
    public let title: String
    public let detail: String
    public let isSevere: Bool
    /// Language-independent `LinkRiskFactorKind` raw value (e.g. "homograph").
    public let kind: String?
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
