// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.1 (build 180).
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
    public let checkId: String
    public let cisControl: String?
    public let nistCsf: [String]
    /// 任意。この項目の合否が信頼できない(測定できなかった・当てにならない)ときだけ入る、言語非依存の理由コード
    /// (helper_unavailable / gateway_unknown / no_baseline / location_unavailable / tool_failed / not_verifiable)。
    /// `verify_security_findings` が inconclusive と判定する根拠と同じ値で、nil のときは JSON にキー自体を出さない。
    /// 入っているとき `isPassed` / `statusText` は「正常」に見えても確認済みではない。
    public let inconclusiveReason: String?
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

/// `verify_security_findings` の1項目。`get_security_report` の項目(`MCPSecurityAuditItemPayload`)とは別の型で、
/// 既存のレポート出力・Kitのデコードには影響しない。Linux版と共通の契約。
public struct MCPVerifiedFindingPayload: Codable, Equatable {
    public let checkId: String
    public let title: String
    public let verdict: SecurityCheckVerification
    /// 言語に依存しない理由コード(failing / passing / not_applicable / helper_unavailable / gateway_unknown /
    /// no_baseline / location_unavailable / unknown_check_id / not_verifiable / tool_failed)。
    public let reason: String
    public let statusText: String
    public let detail: String
    /// How well the verdict is established: `verified`, `false_positive` (does not apply by design) or
    /// `unverified` (the probe could not be trusted). See `VerifyFindingDiscipline`.
    public let verificationStatus: String
    /// One sentence on why the verdict has that status, chosen by `reason`.
    public let rationale: String
    /// Only when the check still fails: the strongest reason it could be benign.
    public let counterEvidence: String?
    /// Only when the check still fails: what would raise or lower the concern.
    public let severityChangesIf: String?
}

public struct MCPVerifySecurityFindingsPayload: Codable, Equatable {
    public let results: [MCPVerifiedFindingPayload]
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
    /// Local AI runtimes recognised from the port and the response headers (absent when none was).
    public let aiRuntimes: [MCPAIRuntimePayload]?
}

/// `confidence` is `confirmed` (single-purpose default port, a marker the product itself sets, or a header
/// that agrees with its default port) or `likely` (shared default port or a header a fronting proxy could
/// add). `basis` lists what matched: `port`, `header`, `server-banner`. Same shape on the Linux edition.
public struct MCPAIRuntimePayload: Codable, Equatable {
    public let product: String
    public let confidence: String
    public let basis: [String]
}

public struct MCPActiveVulnScanFindingPayload: Codable, Equatable {
    public let port: Int
    public let processName: String
    public let title: String
    public let description: String
    public let recommendation: String
    /// Additive. The probe that produced the finding (see `probesRun`), and how strong the evidence is:
    /// `confirmed` (a request showed the weakness), `version_range_match` (only the version is in an affected
    /// range), `external_tool_report` (nmap's own output, not verified by RoamSwitch).
    public var probeName: String? = nil
    public var evidenceKind: String? = nil
    /// Additive. ISO 8601 time this probe on this port last reached a verdict before this run, present only when
    /// that verdict was `safe`. It does not say a fix was undone: the listener may be another program.
    public var previouslySafeAt: String? = nil
}

/// What one probe that ran declares it leaves on the machine (`ProbeSideEffect` raw values: `ioc_in_logs`,
/// `temporary_listener`, `many_requests`; an empty list means only one ordinary request) and what a positive
/// result from it means (`EvidenceKind`).
public struct MCPProbeDeclarationPayload: Codable, Equatable {
    public let probeName: String
    public let sideEffects: [String]
    public let evidenceKind: String
}

/// One probe that did NOT produce a finding — either the target was
/// actually confirmed safe, or the probe itself couldn't complete
/// (connection refused, timeout). Reported separately in
/// `MCPActiveVulnScanResultPayload` so a caller can't mistake "checked, and
/// it's fine" for "never actually got to check" — both used to collapse
/// into the same empty `findings` list (see the 2026-09 discussion of
/// `wait-for-it.sh` reporting success for a port that never opened —
/// https://dev.to/raknaos/my-wait-for-it-wrapper-reported-success-for-a-port-that-never-opened-ga3).
public struct MCPScanCheckOutcomePayload: Codable, Equatable {
    public let port: Int
    public let processName: String
    public let check: String
}

public struct MCPActiveVulnScanResultPayload: Codable, Equatable {
    public let enabled: Bool
    public let scannedTargetCount: Int
    public let findings: [MCPActiveVulnScanFindingPayload]
    /// Checks that ran to completion and found no issue.
    public var confirmedSafe: [MCPScanCheckOutcomePayload] = []
    /// Checks that could not complete (unreachable/timeout) — never
    /// evidence of safety.
    public var inconclusive: [MCPScanCheckOutcomePayload] = []
    /// Additive: the probes this run executed with their declared side effects.
    public var probesRun: [MCPProbeDeclarationPayload] = []
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
    /// EPSS (0...1) from the signed feed, with the day it was taken. Absent when the feed carried none.
    /// A statistical estimate of exploitation activity within 30 days, not a record that one occurred.
    public var epss: Double? = nil
    public var epssDate: String? = nil
}

/// How many of a scan's findings a person has accepted (see `VulnerabilityAcceptance`). Counts only: the
/// accepted findings stay in `findings`, and no tool can accept one.
public struct MCPVulnerabilityAcceptancePayload: Codable, Equatable {
    /// Findings covered by an acceptance that has not expired.
    public let accepted: Int
    /// Of `accepted`, how many expire within 14 days.
    public let expiringWithin14Days: Int
    /// Findings whose acceptance has expired; they count as needing action again.
    public let expired: Int
    /// Findings not covered by an acceptance in force: `findings.count - accepted`.
    public let needsAttention: Int

    init(_ counts: VulnerabilityAcceptance.Counts) {
        accepted = counts.accepted
        expiringWithin14Days = counts.expiringSoon
        expired = counts.expired
        needsAttention = counts.needsAttention
    }
}

public struct MCPPackageCveScanResultPayload: Codable, Equatable {
    public let mapInstalled: Bool
    public let mapVersion: String
    public let findings: [MCPPackageCveFindingPayload]
    public let acceptance: MCPVulnerabilityAcceptancePayload
    /// `read` (Homebrew's package list was read), `brew_missing` (no Homebrew: nothing was checked) or `brew_failed`
    /// (`brew list` failed: nothing was checked). Empty `findings` means "nothing found" only for `read` with
    /// `packagesChecked` above 0.
    public var homebrewInventory: String? = nil
    public var packagesChecked: Int? = nil
    /// Present while the last update of the CVE data failed; the map used may be old.
    public var mapUpdateError: String? = nil
}

public struct MCPPackageCveLanguageFindingPayload: Codable, Equatable {
    /// Absolute path of the lockfile the package was found in (which project).
    public let lockfile: String
    public let ecosystem: String
    public let cveId: String
    public let package: String
    public let installedVersion: String
    public let cvssScore: Double
    public let fixedVersion: String
    public let summary: String
    public var epss: Double? = nil
    public var epssDate: String? = nil
}

public struct MCPPackageCveScanLanguagesResultPayload: Codable, Equatable {
    public let scannedFolderCount: Int
    public let findings: [MCPPackageCveLanguageFindingPayload]
    public let acceptance: MCPVulnerabilityAcceptancePayload
    /// Pinned dependencies read from the lockfiles, by ecosystem.
    public let dependencyCountByEcosystem: [String: Int]
    /// Ecosystems that have dependencies but no CVE map on this Mac. Those dependencies were not checked, so an
    /// empty `findings` says nothing about them.
    public let ecosystemsWithoutMap: [String]
}

public struct MCPPackageLifecycleScriptFindingPayload: Codable, Equatable {
    public let packageName: String
    public let packageVersion: String
    public let scriptName: String
    public let scriptCommand: String
    public let relativePath: String
    /// Reference-only heuristic — see `PackageCveScriptScan`'s doc comment.
    /// Never a threat verdict.
    public let isDangerPattern: Bool
    /// Which heuristic pattern matched (e.g. "curl | sh"), or nil when
    /// `isDangerPattern` is false.
    public let dangerPatternLabel: String?
}

/// Install-time code that appeared in a package since the state a person accepted in the RoamSwitch window.
public struct MCPPackageInstallDriftPayload: Codable, Equatable {
    public let packageName: String
    public let oldVersion: String?
    public let newVersion: String
    /// `script_added`, `script_changed`, `native_added` or `new_package_with_install_code`.
    public let kind: String
    public let scriptName: String?
    /// `high` or `medium`.
    public let severity: String
    public let dangerPatternLabel: String?
}

public struct MCPPackageLifecycleScriptScanResultPayload: Codable, Equatable {
    public let scannedFolderCount: Int
    public let findings: [MCPPackageLifecycleScriptFindingPayload]
    /// When the state the `drift` list compares with was accepted (ISO 8601); nil if no state was ever accepted,
    /// in which case `drift` is empty. This tool never accepts one, so an agent cannot accept its own change.
    public let baselineAcceptedAt: String?
    public let drift: [MCPPackageInstallDriftPayload]
    /// `node_modules` folders found now that the accepted state does not cover. `drift` skips them, so an empty
    /// `drift` says nothing about them. Empty when no state was ever accepted.
    public let uncoveredFolders: [String]
}

public struct MCPTyposquatFindingPayload: Codable, Equatable {
    /// The project folder whose `package.json` declares the dependency.
    public let projectDir: String
    public let dependencyName: String
    public let suspectedTarget: String
    public let distance: Int
}

/// Result payload for `run_typosquat_scan` — a reference-only heuristic
/// match, never a verdict. See `TyposquatGuard`'s doc comment.
public struct MCPTyposquatScanResultPayload: Codable, Equatable {
    public let scannedFolderCount: Int
    public let findings: [MCPTyposquatFindingPayload]
}

public struct MCPDependencySourceFindingPayload: Codable, Equatable {
    /// `pip_extra_index_url` or `npm_scope_not_pinned`.
    public let kind: String
    public let file: String
    /// 1-based line (pip); absent for npm.
    public let line: Int?
    /// Host of the index or registry, never with credentials.
    public let host: String
    /// `@acme` (npm); absent for pip.
    public let scope: String?
    /// npm: how many packages of the scope the lockfile resolves from `host`; 0 for pip.
    public let packageCount: Int
}

/// Result payload for `run_dependency_source_scan` — settings that allow dependency confusion, found by reading
/// files. It never asks a registry whether a name could be claimed. See `DependencySourceScan`.
public struct MCPDependencySourceScanResultPayload: Codable, Equatable {
    public let scannedFolderCount: Int
    public let findings: [MCPDependencySourceFindingPayload]
    public let note: String
}

/// Result payload for `run_npm_audit_signatures` — unlike every other
/// package/CVE payload in this file, `rawOutput` is npm's own verbatim
/// command output rather than a hand-parsed structure: npm's exact wording
/// isn't a contract this app controls, so it's surfaced directly instead of
/// being fitted into a rigid schema that could silently misparse a future
/// npm version's phrasing.
public struct MCPNpmAuditSignaturesResultPayload: Codable, Equatable {
    public let enabled: Bool
    public let directory: String?
    public let rawOutput: String?
    public let exitCode: Int32?
    public let hasIssues: Bool?
    public let message: String
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

public struct MCPFrontendFindingPayload: Codable, Equatable {
    public let kind: String
    public let file: String
    public let line: Int
    public let detail: String
    public let masked: String
}

/// What the `include_build_output` option of `audit_secrets` adds: the build output a web front end publishes.
public struct MCPFrontendScanPayload: Codable, Equatable {
    public let scannedDirs: [String]
    public let scannedFiles: Int
    public let truncated: Bool
    public let findings: [MCPFrontendFindingPayload]
}

public struct MCPAuditSecretsResultPayload: Codable, Equatable {
    public let findings: [MCPSecretFindingPayload]
    /// Present only when the caller asked for the build output as well.
    public var buildOutput: MCPFrontendScanPayload? = nil
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

/// What the log read could not deliver (see `SecurityLogReadStatus`). `unreadable` means the audit says nothing.
public struct MCPLogReadStatusPayload: Codable, Equatable {
    public let hoursRequested: Int
    public let hoursQueried: Int
    public let unreadable: Bool
    public let limited: Bool
    public let timedOut: Bool
    public let outputTruncated: Bool
    public let failureReason: String?
    public let exitStatus: Int32?
    public let linesLossy: Int
    public let linesUnparsable: Int

    public init(_ s: SecurityLogReadStatus) {
        hoursRequested = s.hoursRequested
        hoursQueried = s.hoursQueried
        unreadable = s.unreadable
        limited = s.limited
        timedOut = s.timedOut
        outputTruncated = s.outputTruncated
        failureReason = s.failureReason
        exitStatus = s.exitStatus
        linesLossy = s.linesLossy
        linesUnparsable = s.linesUnparsable
    }
}

public struct MCPSecurityLogAuditPayload: Codable, Equatable {
    public let timeWindowHours: Int
    public let totalEvents: Int
    public let sudoFailures: Int
    public let sshAttempts: Int
    public let gatekeeperBlocks: Int
    public let xprotectDetections: Int
    /// False when the log could not be read: nothing found is then not the same as clean.
    public let isClean: Bool
    /// Present only when part of the log was not examined, or none could be read.
    public let coverageNote: String?
    public let readStatus: MCPLogReadStatusPayload
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

/// Status for `RansomwareEntropyGuard` — general, non-canary-dependent
/// mass-encryption detection. Distinct tool/payload from
/// `MCPCanaryStatusPayload`: the canary guard reports fixed bait-file
/// tamper events, this one reports Shannon-entropy burst alerts anywhere in
/// the watched folders.
public struct MCPRansomwareEntropyStatusPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let recentAlertsAvailable: Bool
    public let recentAlerts: [MCPRansomwareEntropyAlertPayload]
}

public struct MCPRansomwareEntropyAlertPayload: Codable, Equatable {
    public let timestamp: String
    public let processLabel: String
    public let affectedFilePaths: [String]
    public let averageEntropy: Double
}

/// Wraps `ForensicBundleSummary` (see `ForensicCaptureManager.swift`) for
/// the `get_forensic_evidence_bundles` MCP tool.
public struct MCPForensicEvidenceBundlesPayload: Codable, Equatable {
    public let bundles: [ForensicBundleSummary]
    /// False when `chain.log` was edited or truncated: `chainBrokenAt` names the first bundle that no longer follows.
    public var chainOk: Bool = true
    public var chainBrokenAt: String? = nil
    /// Bundles the chain names that are no longer on disk.
    public var missingBundles: [String] = []
}

/// Wraps `ActiveVulnScan.ProbeStatus` for the
/// `get_vulnerability_scan_history` MCP tool — same wire shape
/// (`{"probes": [...]}`) as the Linux edition's equivalent tool, so a
/// consumer reading both doesn't need platform-specific parsing.
public struct MCPVulnerabilityScanHistoryPayload: Codable, Equatable {
    public let probes: [ActiveVulnScan.ProbeStatus]
}

/// Wraps `PersistedHoneytokenEvent` for the `get_honeytoken_status` MCP tool.
public struct MCPHoneytokenStatusPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let recentEventsAvailable: Bool
    public let recentEvents: [MCPHoneytokenEventPayload]
    /// How many decoy files are really in place, and why the others are not. A guard that is on with `placed` 0 watches
    /// nothing. Absent until the app has placed once.
    public var placement: MCPDecoyPlacementPayload? = nil
}

public struct MCPDecoyPlacementPayload: Codable, Equatable {
    public let placed: Int
    public let expected: Int
    /// Paths that hold a file that is not ours: left alone, not watched.
    public let realFilesKept: Int
    /// Paths that are a symbolic link or a special file: left alone.
    public let specialSkipped: Int
    public let writeFailed: Int
    public let at: String

    init(_ record: DecoyPlacementRecord) {
        placed = record.placed
        expected = record.expected
        realFilesKept = record.realFilesKept
        specialSkipped = record.specialSkipped
        writeFailed = record.writeFailed
        at = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: record.at))
    }
}

public struct MCPHoneytokenEventPayload: Codable, Equatable {
    public let timestamp: String
    public let path: String
    public let kind: String
    public let suspectedProcess: String
}

/// Wraps `PersistedBrowserCredentialEvent` for the
/// `get_browser_credential_watch_status` MCP tool.
public struct MCPBrowserCredentialWatchStatusPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let recentEventsAvailable: Bool
    public let recentEvents: [MCPBrowserCredentialEventPayload]
}

public struct MCPBrowserCredentialEventPayload: Codable, Equatable {
    public let timestamp: String
    public let path: String
    public let suspectedProcess: String
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

/// `autoIsolatedPorts` is a present-tense snapshot with no timestamps;
/// nothing used to distinguish it from the timestamped `incidents` list
/// once both landed in the same object, which is exactly what let a local
/// LLM fold a long-isolated, unrelated port into a live incident's
/// narrative during a fire drill (same bug, same fix, as the Linux
/// edition). The two `*Note` fields are additive rather than a
/// restructuring — the existing flat fields are kept as-is so this stays
/// source-compatible with anything already decoding this type.
public struct MCPPortAnomalyIncidentsPayload: Codable, Equatable {
    public let incidentsNote: String
    public let isEnabled: Bool
    public let baselineCaptured: Bool
    public let currentPortStateNote: String
    public let autoIsolatedPorts: [Int]
    public let incidents: [MCPPortAnomalyIncidentPayload]
}

/// One SSH login as `get_ssh_guard_incidents` reports it (an `Accepted` line of sshd's log).
public struct MCPSSHSessionPayload: Codable, Equatable {
    public let time: String
    public let user: String
    public let ip: String
    public let port: Int
    public let method: String
    public let keyType: String?
    public let fingerprint: String?
    /// Whether the connection was still open when the app last looked (the newest sessions only).
    public let active: Bool?
}

/// One SSH brute-force record. `kind`: `banned` (the source reached the limit and was banned),
/// `detected` (it reached the limit but nothing was banned; `note` says why), `successAfterFailures`
/// (a login succeeded from a source that had been failing; `session` is that login).
public struct MCPSSHGuardIncidentPayload: Codable, Equatable {
    public let timestamp: String
    public let kind: String
    public let source: String
    public let failureCount: Int
    public let windowSecs: Int
    public let banSecs: Int?
    public let ports: [Int]
    public let note: String?
    public let usersTried: [String]
    public let session: MCPSSHSessionPayload?
}

public struct MCPSSHBanPayload: Codable, Equatable {
    public let source: String
    public let expiresAt: String
    public let remainingSecs: Int
}

public struct MCPSSHGuardPayload: Codable, Equatable {
    public let isEnabled: Bool
    public let attackTechnique: String
    public let incidentsNote: String
    public let incidents: [MCPSSHGuardIncidentPayload]
    public let statusNote: String
    public let statusAsOf: String?
    public let remoteLoginOn: Bool?
    public let watching: Bool?
    public let sshPorts: [Int]
    public let otherBanningTool: String?
    public let activeBans: [MCPSSHBanPayload]
    public let sessionsNote: String
    public let recentSessions: [MCPSSHSessionPayload]
}

/// Field-for-field mirror of `SensorAuditFinding` (`Shared/HelperProtocol.swift`),
/// itself a mirror of `roamswitch-sensor`'s `ScanFinding`.
public struct MCPSensorAuditFindingPayload: Codable, Equatable {
    public let port: Int
    public let title: String
    public let recommendation: String
}

/// One outstanding or completed active-audit request this Mac made to a
/// paired RoamSwitch Sensor — mirrors `SensorAuditResult`. `status` is
/// "pending" / "completed" / "failed"; see that type's doc comment.
public struct MCPSensorAuditResultPayload: Codable, Equatable {
    public let requestId: String
    public let sensorName: String
    public let requestedAt: String
    public let status: String
    public let pullAttempts: Int
    public let findings: [MCPSensorAuditFindingPayload]
    /// Set only when `status == "failed"`: `"not_paired"` / `"invalid_signature"`
    /// (the Sensor explicitly rejected the pull — see `SensorAuditResult
    /// .failureReason`'s doc comment), `"not_found"`, or `"timed_out"`.
    public let failureReason: String?
}

public struct MCPSensorAuditResultsPayload: Codable, Equatable {
    public let pairedSensorCount: Int
    public let results: [MCPSensorAuditResultPayload]
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
    /// `on`, `off`, `partial` or `unknown`. Unlike `enabledInSettings` (the toggle), this says whether the guard can
    /// see its input: a guard whose reader cannot read its source is `off`, one that lost input within the last day
    /// is `partial`, one that has not reported is `unknown`. Absent from older builds.
    public var liveState: String? = nil
    /// Why `liveState` is not the state of the readers: `pro_not_active` (the guard needs Pro and Pro is not active),
    /// `helper_not_connected` (it needs the helper, or part of it does, and the app says the helper is not connected) or
    /// `helper_status_unknown` (it needs the helper and the app has not reported lately, so it may not be running).
    /// Absent when `liveState` is just the toggle and the readers.
    public var liveStateReason: String? = nil
    /// For a guard that reads a stream or a file: what its reader(s) have lost. Absent for the others.
    public var readers: [MCPReaderHealthPayload]? = nil
}

/// What one input source of a guard has lost (see `GuardReaderHealth`). Times are ISO 8601.
/// `gaps` counts the times the input stopped while it should have been flowing; nothing is replayed afterwards, so what
/// happened in between was not seen. `reason`: reader_not_running, start_refused, launch_failed, too_many_restarts,
/// permission, tool_missing, restarting, not_running, source_missing, unreadable_file, helper_unreachable, watch_failed.
public struct MCPReaderHealthPayload: Codable, Equatable {
    public let source: String
    public let unreadable: Bool
    public let reason: String?
    public let restarts: Int
    public let lastRestartAt: String?
    public let gaps: Int
    public let lastGapAt: String?
    public let linesDropped: UInt64?
    public let oversizeDropped: UInt64?
    /// Files the last scan or batch skipped because they could not be opened or read (nil where the guard has no such step),
    /// and when a scan last skipped one. The guard's detection is unchanged; those files were not looked at.
    public var filesUnreadable: Int? = nil
    public var filesUnreadableAt: String? = nil
    /// Folders the last scan could not list (everything below them was not looked at), and files it read only the start of.
    public var foldersUnreadable: Int? = nil
    public var filesTruncated: Int? = nil
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
    /// When each signed data feed last updated and the last failure, if the last attempt failed. A feed that keeps
    /// failing leaves old data in use (a CVE scan against an old map, an old link list).
    public var feedUpdates: [MCPFeedUpdatePayload]? = nil
}

public struct MCPFeedUpdatePayload: Codable, Equatable {
    /// `packageCveMap`, `activeVulnCveMap` or `linkGuardFeed`.
    public let feed: String
    public let lastSuccessAt: String?
    /// Present only while the last attempt failed.
    public let lastError: String?
    public let lastErrorAt: String?

    static func make(feed: String, record: FeedUpdateRecord) -> MCPFeedUpdatePayload {
        let iso = ISO8601DateFormatter()
        func time(_ t: Double?) -> String? { t.map { iso.string(from: Date(timeIntervalSince1970: $0)) } }
        return MCPFeedUpdatePayload(feed: feed, lastSuccessAt: time(record.lastSuccessAt),
                                    lastError: record.isFailing ? record.lastError : nil, lastErrorAt: record.isFailing ? time(record.lastErrorAt) : nil)
    }
}

/// One `ContainmentIncidentTimeline` entry. `source`/`actionTaken`/`status`
/// are stable identifiers; the `...Label` fields are localized.
public struct MCPIncidentTimelineEventPayload: Codable, Equatable {
    public let id: String
    public let timestamp: String
    /// "arpSpoof" | "ransomwareCanary" | "runtimeThreat" | "portAnomaly" | "clickFix"
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
    /// `ok`, `missing` (no incident was ever recorded) or `unreadable` (the file exists but cannot be read: an empty
    /// `events` list then does NOT mean there were no incidents).
    public var recordFile: String? = nil
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
    static let ransomwareEntropyGuardKey = "RoamSwitch.RansomwareEntropyGuardEnabled" // RansomwareEntropyGuard — false; Pro default-on
    static let credentialHoneytokenGuardKey = "RoamSwitch.CredentialHoneytokenGuardEnabled" // CredentialHoneytokenGuard — false; Pro default-on
    static let reverseShellWatchKey = "RoamSwitch.ReverseShellWatchEnabled"           // ReverseShellWatchGuard — false; Pro default-on
    static let networkSettingsWatchKey = "RoamSwitch.NetworkSettingsWatchEnabled"     // NetworkSettingsWatchGuard — false; Pro default-on
    static let browserCredentialWatchGuardKey = "RoamSwitch.BrowserCredentialWatchGuardEnabled" // BrowserCredentialWatchGuard — false; opt-in even for Pro
    static let clickFixGuardKey = "RoamSwitch.ClickFixGuardEnabled"                   // ClickFixGuard — false
    static let execRecorderKey = "RoamSwitch.ExecRecorder.Enabled"                    // ExecRecorderManager — false (Pro, opt-in)
    static let dockerEventGuardKey = "RoamSwitch.DockerEventGuardEnabled"             // DockerEventGuard — false
    static let criticalPathFimKey = "RoamSwitch.CriticalPathFimEnabled"               // CriticalPathFimGuard — false; Pro default-on
    static let lockfileTamperGuardKey = "RoamSwitch.LockfileTamperGuardEnabled"       // LockfileTamperGuard — false; Pro default-on
    static let portScanGuardKey = "RoamSwitch.PortScanGuardEnabled"                   // PortScanGuard — false; Pro default-on
    static let sshGuardKey = "RoamSwitch.SSHGuardEnabled"                             // SSHGuard — false; Pro default-on (works only while Remote Login is on)
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

    /// Wi-Fiインターフェースはあるが SSID が取れなかった状態。「本当に未接続」と「位置情報の権限が無くて読めない」を
    /// 区別できないので、この読み取りは信頼できない。`get_security_report` の注意書きと
    /// `verify_security_findings` の inconclusive 判定で同じ条件を使う。
    public static func wifiReadingUnreliable(interfacePresent: Bool, ssidResolved: Bool) -> Bool {
        interfacePresent && !ssidResolved
    }

    static var wifiLocationCaveat: String {
        loc("Wi-Fi暗号化強度の判定は、位置情報の権限を持たないためこのツールからは行えない場合があります。「未接続」と表示されていても、実際にはOpen Wi-Fi等に接続している可能性があります。RoamSwitchアプリ本体の表示もあわせてご確認ください。")
    }

    /// 判定が「RoamSwitchでオンにしているか」という設定値で、実際に動作していることの実測ではない項目。
    /// `host_firewall` / `network_stealth_mode` と同じ扱い: 合否は設定どおりに出し(inconclusive にはしない)、
    /// 注意書きでその限界を明示する。
    static let configOnlyCheckIds: Set<String> = ["gateway_arp_lock", "malware_scanning", "dns_threat_guard", "usb_zero_trust"]

    static var configOnlyCaveat: String {
        loc("ゲートウェイARP固定・ダウンロード自動スキャン(マルウェア対策)・DNS脅威保護・USBガードの判定は、RoamSwitchでオンにしているかという設定値で、実際に動作して効いていることの実測ではありません。")
    }

    /// ARP監視が「問題なし」と言えるのは、登録済みの信頼ネットワークのゲートウェイMACと一致したときだけ。
    static var arpTrustedBaselineCaveat: String {
        loc("ARPスプーフィング監視は、登録済みの信頼ネットワークのゲートウェイMACと一致したときだけ「問題なし」と判定します。登録が無いと、このプロセス自身の観測だけでは偽装を見抜けないため確認できません (no_baseline)。")
    }

    static let trustedOpenCheckIds: Set<String> = ["host_firewall", "network_stealth_mode"]

    /// 保護レベルが信頼(open)だと、ファイアウォール/ステルスは設計上「対象外」。macOS側の状態が変わったわけではない。
    static var trustedOpenNotApplicableCaveat: String {
        loc("保護レベルが信頼(open)のため対象外です。macOSファイアウォール自体の状態は変更されていません。")
    }

    /// 非特権の lsof には root 所有のリスナーが出ない(この別プロセスは特権ヘルパーを持たない)。
    static var exposedPortsVisibilityCaveat: String {
        loc("外部公開ポートの判定は lsof の結果に基づきます。このツールを実行しているユーザーから見えるリスナーに限られ、root所有のものは見えません。")
    }

    static var exposedPortsUnmeasuredCaveat: String {
        loc("外部公開ポートは lsof の実行に失敗したため測定できていません。「公開ポートなし」という意味ではありません。")
    }

    /// `get_exposed_ports` / `run_active_vuln_scan` が lsof の失敗を空リスト(= ポートなし)で返さないためのエラー文。
    static var portListUnavailableMessage: String {
        loc("待ち受けポートの一覧を取得できませんでした (lsof の実行に失敗)。ポートが無いという意味ではありません。")
    }

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
        if wifiReadingUnreliable(interfacePresent: wifiInterfacePresent, ssidResolved: wifiSSIDResolved) {
            caveats.append(wifiLocationCaveat)
        }
        if report.items.contains(where: { $0.checkId == "exposed_ports" }) {
            caveats.append(exposedPortsVisibilityCaveat)
        }
        if report.items.contains(where: { $0.checkId == "exposed_ports" && $0.inconclusiveReason == "tool_failed" }) {
            caveats.append(exposedPortsUnmeasuredCaveat)
        }
        if report.items.contains(where: { configOnlyCheckIds.contains($0.checkId) }) {
            caveats.append(configOnlyCaveat)
        }
        if report.items.contains(where: { $0.checkId == "arp_spoof_monitor" && $0.inconclusiveReason == "no_baseline" }) {
            caveats.append(arpTrustedBaselineCaveat)
        }
        if report.items.contains(where: { trustedOpenCheckIds.contains($0.checkId) && !$0.isApplicable }) {
            caveats.append(trustedOpenNotApplicableCaveat)
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
                    isApplicable: $0.isApplicable,
                    checkId: $0.checkId,
                    cisControl: $0.cisControlID,
                    nistCsf: $0.nistCsfCategories,
                    inconclusiveReason: SecurityCheckVerification.inconclusiveReason(of: $0)
                )
            },
            caveats: caveats,
            timestamp: ISO8601DateFormatter().string(from: report.timestamp)
        )
    }

    // MARK: verify_security_findings

    /// 1回に指定できる checkId の上限(超過分は無視して注意書きを付ける)。全22項目より十分大きく、
    /// 巨大な引数でレスポンスが膨らまないための歯止め。
    public static let maxVerifyCheckIds = 50
    /// 未知の checkId をそのまま返すときの最大文字数(入力はエージェント由来で信頼できない)。
    static let maxEchoedCheckIdLength = 64

    /// `verify_security_findings` の `checkIds` 引数の検証。省略・null は「全項目」(`ids == nil`)。
    /// 配列でない・文字列以外を含むものは不正(`isValid == false`)。空配列は `makeVerifyPayload` で全項目扱い。
    static func parseVerifyCheckIds(_ arguments: [String: Any]) -> (ids: [String]?, isValid: Bool) {
        guard let raw = arguments["checkIds"], !(raw is NSNull) else { return (nil, true) }
        guard let list = raw as? [Any], let ids = list as? [String] else { return (nil, false) }
        return (ids, true)
    }

    /// 全項目を再評価した `report` から、`requestedCheckIds`(nil/空 = 全項目)に絞って判定を作る純粋関数。
    /// 結果は指定順(重複は最初の1件)。レポートに無い id は、全体を失敗させず、その id だけ
    /// `inconclusive` + `unknown_check_id` にする。
    public static func makeVerifyPayload(
        report: ComprehensiveSecurityReport,
        requestedCheckIds: [String]?,
        wifiInterfacePresent: Bool,
        wifiSSIDResolved: Bool
    ) -> MCPVerifySecurityFindingsPayload {
        var caveats: [String] = []
        var itemsById: [String: SecurityAuditItem] = [:]
        for item in report.items where !item.checkId.isEmpty && itemsById[item.checkId] == nil {
            itemsById[item.checkId] = item
        }

        let selected: [String]
        if let requested = requestedCheckIds, !requested.isEmpty {
            // 長すぎる id は先に切り詰め、切り詰めた後の文字列で重複を除く(先頭64文字が同じ別々の id が
            // 同じ checkId の2行にならないように)。実在する checkId はどれも短いので、切り詰めても一致は変わらない。
            var seen = Set<String>()
            var ordered: [String] = []
            for raw in requested {
                let id = String(raw.prefix(maxEchoedCheckIdLength))
                if seen.insert(id).inserted { ordered.append(id) }
            }
            if ordered.count > maxVerifyCheckIds {
                ordered = Array(ordered.prefix(maxVerifyCheckIds))
                caveats.append(String(format: loc("一度に指定できる checkId は %d 件までです。それを超える分は無視しました。"), maxVerifyCheckIds))
            }
            selected = ordered
        } else {
            selected = report.items.map(\.checkId).filter { !$0.isEmpty }
        }

        let results: [MCPVerifiedFindingPayload] = selected.map { id in
            guard let item = itemsById[id] else {
                return MCPVerifiedFindingPayload(
                    checkId: String(id.prefix(maxEchoedCheckIdLength)),
                    title: "",
                    verdict: .inconclusive,
                    reason: "unknown_check_id",
                    statusText: "",
                    detail: "",
                    verificationStatus: VerifyFindingDiscipline.status(verdict: .inconclusive, reason: "unknown_check_id"),
                    rationale: VerifyFindingDiscipline.rationale(reason: "unknown_check_id"),
                    counterEvidence: nil,
                    severityChangesIf: nil
                )
            }
            let classification = SecurityCheckVerification.classify(item)
            return MCPVerifiedFindingPayload(
                checkId: item.checkId,
                title: item.title,
                verdict: classification.verdict,
                reason: classification.reason,
                statusText: item.statusText,
                detail: item.detail,
                verificationStatus: VerifyFindingDiscipline.status(verdict: classification.verdict, reason: classification.reason),
                rationale: VerifyFindingDiscipline.rationale(reason: classification.reason),
                counterEvidence: classification.verdict == .stillPresent ? VerifyFindingDiscipline.counterEvidence(checkId: item.checkId) : nil,
                severityChangesIf: classification.verdict == .stillPresent ? VerifyFindingDiscipline.severityChangesIf(checkId: item.checkId) : nil
            )
        }
        let evaluated = Set(results.filter { $0.reason != "unknown_check_id" }.map(\.checkId))

        if wifiReadingUnreliable(interfacePresent: wifiInterfacePresent, ssidResolved: wifiSSIDResolved),
           evaluated.contains("wifi_encryption_strength") {
            caveats.append(wifiLocationCaveat)
        }
        if !evaluated.isDisjoint(with: ["host_firewall", "network_stealth_mode"]) {
            caveats.append(loc("macOS ファイアウォールとステルスモードの判定は、RoamSwitchの保護レベル設定がそうなっているべき状態を示すもので、macOS自体のファイアウォール設定の実測値ではありません。"))
        }
        if evaluated.contains("exposed_ports") {
            caveats.append(exposedPortsVisibilityCaveat)
            if results.contains(where: { $0.checkId == "exposed_ports" && $0.reason == "tool_failed" }) {
                caveats.append(exposedPortsUnmeasuredCaveat)
            }
        }
        if !evaluated.isDisjoint(with: configOnlyCheckIds) {
            caveats.append(configOnlyCaveat)
        }
        if results.contains(where: { $0.checkId == "arp_spoof_monitor" && $0.reason == "no_baseline" }) {
            caveats.append(arpTrustedBaselineCaveat)
        }
        if results.contains(where: { trustedOpenCheckIds.contains($0.checkId) && $0.reason == "not_applicable" }) {
            caveats.append(trustedOpenNotApplicableCaveat)
        }

        return MCPVerifySecurityFindingsPayload(
            results: results,
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
            processName: MCPUntrustedText.sanitize(portInfo.processName),
            pid: portInfo.pid,
            port: portInfo.port,
            isGloballyExposed: portInfo.isGloballyExposed,
            executablePath: portInfo.executablePath.map { MCPUntrustedText.sanitize($0) },
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
            httpHeaders: auditResult?.httpHeaders,
            aiRuntimes: (auditResult?.aiRuntimes).flatMap { $0.isEmpty ? nil : $0.map { MCPAIRuntimePayload(product: $0.product, confidence: $0.confidence.rawValue, basis: $0.basis) } }
        )
    }

    static func inventoryCode(_ state: PackageCveScan.InventoryState) -> String {
        switch state {
        case .brewMissing: return "brew_missing"
        case .brewFailed: return "brew_failed"
        case .read: return "read"
        }
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
        defaults: UserDefaults = .standard,
        readerHealth: [String: GuardReaderHealth]? = nil,
        now: Date = Date(),
        environment: GuardEnvironment = .unchecked,
        agentSetupBaselineAccepted: Bool = false
    ) -> MCPGuardStatusPayload {
        let level = resolveActiveSecurityLevel(gatewayMAC: gatewayMAC, defaults: defaults)
        let health = readerHealth ?? GuardReaderHealthStore.all(defaults: defaults)
        let iso = ISO8601DateFormatter()
        func time(_ t: Double?) -> String? { t.map { iso.string(from: Date(timeIntervalSince1970: $0)) } }

        func entry(_ key: String, _ defaultsKey: String, defaultWhenUnset: Bool) -> MCPGuardEntryPayload {
            let isUnset = defaults.object(forKey: defaultsKey) == nil
            let enabled = isUnset ? defaultWhenUnset : defaults.bool(forKey: defaultsKey)
            return MCPGuardEntryPayload(key: key, enabledInSettings: enabled, usingDefault: isUnset,
                                        liveState: GuardReaderHealthStore.guardLiveState(guardKey: key, enabledInSettings: enabled, records: health, now: now.timeIntervalSince1970),
                                        readers: readers(for: key))
        }
        func readers(for key: String) -> [MCPReaderHealthPayload]? {
            let ids = GuardReaderHealthStore.sourceIDs(forGuard: key)
            guard !ids.isEmpty else { return nil }
            return ids.compactMap { id in
                health[id].map {
                    MCPReaderHealthPayload(source: id, unreadable: $0.unreadable, reason: $0.reason, restarts: $0.restarts,
                                           lastRestartAt: time($0.lastRestartAt), gaps: $0.gaps, lastGapAt: time($0.lastGapAt),
                                           linesDropped: $0.linesDropped, oversizeDropped: $0.oversizeDropped,
                                           filesUnreadable: $0.filesUnreadable, filesUnreadableAt: time($0.filesUnreadableAt),
                                           foldersUnreadable: $0.foldersUnreadable, filesTruncated: $0.filesTruncated)
                }
            }
        }

        let storedLinkMode = defaults.string(forKey: linkGuardModeKey)
        let linkMode = LinkGuardMode(rawValue: storedLinkMode ?? "") ?? .block

        var guards: [MCPGuardEntryPayload] = []
        guards.append(entry("portAnomalyGuard", portAnomalyGuardKey, defaultWhenUnset: false))
        guards.append(entry("portScanGuard", portScanGuardKey, defaultWhenUnset: false))
        guards.append(entry("sshGuard", sshGuardKey, defaultWhenUnset: false))
        guards.append(entry("arpSpoofAutoContainment", arpSpoofAutoContainmentKey, defaultWhenUnset: false))
        guards.append(entry("usbKeyboardGuard", usbKeyboardGuardKey, defaultWhenUnset: false))
        guards.append(entry("usbStorageGuard", usbStorageGuardKey, defaultWhenUnset: false))
        guards.append(entry("bluetoothGuard", bluetoothGuardKey, defaultWhenUnset: false))
        guards.append(entry("webMailDownloadGuard", webMailDownloadGuardKey, defaultWhenUnset: true))
        guards.append(entry("dnsThreatGuard", dnsThreatGuardKey, defaultWhenUnset: true))
        guards.append(entry("runtimeThreatContainment", runtimeThreatContainmentKey, defaultWhenUnset: false))
        guards.append(entry("ransomwareCanaryGuard", ransomwareCanaryGuardKey, defaultWhenUnset: false))
        guards.append(entry("ransomwareEntropyGuard", ransomwareEntropyGuardKey, defaultWhenUnset: false))
        guards.append(entry("credentialHoneytokenGuard", credentialHoneytokenGuardKey, defaultWhenUnset: false))
        guards.append(entry("browserCredentialWatchGuard", browserCredentialWatchGuardKey, defaultWhenUnset: false))
        guards.append(entry("reverseShellWatch", reverseShellWatchKey, defaultWhenUnset: false))
        guards.append(entry("networkSettingsWatch", networkSettingsWatchKey, defaultWhenUnset: false))
        guards.append(entry("clickFixGuard", clickFixGuardKey, defaultWhenUnset: false))
        guards.append(entry("execRecorder", execRecorderKey, defaultWhenUnset: false))
        guards.append(entry("dockerEventGuard", dockerEventGuardKey, defaultWhenUnset: false))
        guards.append(entry("criticalPathFim", criticalPathFimKey, defaultWhenUnset: false))
        guards.append(entry("lockfileTamperGuard", lockfileTamperGuardKey, defaultWhenUnset: false))
        guards.append(entry("persistenceMonitor", persistenceMonitorKey, defaultWhenUnset: true))
        guards.append(entry("gatewayARPLock", gatewayARPLockKey, defaultWhenUnset: false))
        guards.append(entry("scheduledLogAudit", scheduledLogAuditKey, defaultWhenUnset: false))
        guards.append(entry("secretLeakClipboardAuditor", secretLeakAuditorKey, defaultWhenUnset: true))
        guards.append(entry("airGapAutoWiFiKill", airGapAutoWiFiKillKey, defaultWhenUnset: true))
        guards.append(entry("wireGuardVPN", wireGuardVPNKey, defaultWhenUnset: false))
        guards.append(entry("tailscaleKillSwitch", tailscaleKillSwitchKey, defaultWhenUnset: false))
        // The better enforcement point (the content-filter system extension) may be missing or waiting for the person's
        // approval; then the guard works with less (the /etc/hosts list only), which DoH browsers bypass.
        var linkLive = linkMode != .off ? "on" : "off"
        var linkReason: String?
        if linkMode != .off, let enforcement = LinkGuardEnforcement.read(defaults: defaults, now: now.timeIntervalSince1970), enforcement.isDegraded {
            linkLive = "partial"
            linkReason = enforcement == .waitingForApproval ? "system_extension_not_approved" : "system_extension_not_active"
        }
        guards.append(MCPGuardEntryPayload(key: "linkGuard", enabledInSettings: linkMode != .off, usingDefault: storedLinkMode == nil,
                                           liveState: linkLive, liveStateReason: linkReason))
        guards.append(entry("linkGuardFeedUpdates", linkGuardUpdatesKey, defaultWhenUnset: true))
        guards.append(entry("activeVulnScan", ActiveVulnScan.enabledDefaultsKey, defaultWhenUnset: false))
        // The web-rules folder scan has no switch of its own: it runs daily for Pro. Its entry follows the Pro cache.
        let scanOn = defaults.bool(forKey: "RoamSwitch.IsProCache")
        guards.append(MCPGuardEntryPayload(
            key: "webRulesFolderScan", enabledInSettings: scanOn, usingDefault: nil,
            liveState: GuardReaderHealthStore.guardLiveState(guardKey: "webRulesFolderScan", enabledInSettings: scanOn, records: health, now: now.timeIntervalSince1970),
            readers: readers(for: "webRulesFolderScan")))

        // The web worker crash watch has no switch either: it starts with the app and follows the error logs it finds; its
        // alert is Pro. Its entry follows the Pro cache, like the web rules folder scan.
        guards.append(MCPGuardEntryPayload(
            key: "webWorkerCrashWatch", enabledInSettings: scanOn, usingDefault: nil,
            liveState: GuardReaderHealthStore.guardLiveState(guardKey: "webWorkerCrashWatch", enabledInSettings: scanOn, records: health, now: now.timeIntervalSince1970),
            readers: readers(for: "webWorkerCrashWatch")))

        // The AI agent setup change watch has no switch: it compares with the state the person accepted in the "AI agent
        // setup" window, so "on" means such a state exists. Without one it watches nothing (`no_baseline`).
        guards.append(MCPGuardEntryPayload(
            key: "agentSetupWatch", enabledInSettings: agentSetupBaselineAccepted, usingDefault: nil,
            liveState: GuardReaderHealthStore.guardLiveState(guardKey: "agentSetupWatch", enabledInSettings: agentSetupBaselineAccepted, records: health, now: now.timeIntervalSince1970),
            readers: readers(for: "agentSetupWatch")))

        // Pro and the helper: a guard that needs either and does not have it is not working, whatever its toggle says.
        guards = guards.map { g in
            let folded = GuardReaderHealthStore.applyingEnvironment(guardKey: g.key, enabledInSettings: g.enabledInSettings,
                                                                    state: g.liveState ?? (g.enabledInSettings ? "on" : "off"), environment: environment)
            var out = g
            out.liveState = folded.state
            out.liveStateReason = folded.reason ?? g.liveStateReason
            if g.key == "agentSetupWatch", !g.enabledInSettings { out.liveStateReason = "no_baseline" }
            return out
        }

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
        caveats.append(loc("enabledInSettings は、Settingsのトグルだけを示します。liveState には、アプリが保存したPro版の有効の記録と、ヘルパーの接続の記録も使います。このツールは別プロセスなので、ライセンスの署名は検証しません。"))
        caveats.append(loc("usingDefault が true の項目は、ユーザーが一度も切り替えていない既定値です。ポート異常ガード・着信ポートスキャン検知・ARPスプーフィング自動封じ込め・ランタイム脅威封じ込め・ランサムウェア検知（カナリア・エントロピー）・認証情報ハニートークン・重要パスの改ざん監視・依存関係ロックファイルの改ざん監視・定期ログ監査は、Pro版を有効化した時点で一度だけ自動的にオンになります。USBキーボード／ストレージ・Bluetooth・ClickFix・Docker・ゲートウェイARP固定・プロセス実行記録・ブラウザ認証情報の監視・VPNは、Proでも既定ではオフです。"))
        caveats.append(loc("liveState が off のとき、そのガードは入力を読めていないか、必要なPro版やヘルパーがありません(入力は readers に、Pro版とヘルパーは liveStateReason に理由があります)。partial は、直近24時間に入力を取りこぼしたことを示します。gaps は、読み取りが止まってから再開するまでの間に起きたことを見られなかった回数で、再開しても遡って読むことはありません。unknown は、まだ状態の報告がないことを示します。ヘルパーが止まっていると記録は更新されません。"))
        caveats.append(loc("VPNトンネルの実際の接続状態とキルスイッチの適用状態は特権ヘルパーが管理しているため、このツールからは確認できません。VPN関連の項目は設定値のみを示しています。"))
        caveats.append(loc("clickFixGuard は、シェルが履歴ファイルに書いたコマンドを読みます。zshの既定設定では、書かれるのはシェルを終了したときなので、Terminalのタブを閉じるまで検知されません。~/.zshrc に「setopt INC_APPEND_HISTORY」を足すと、実行の直後に読めます。"))

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
            caveats: caveats,
            feedUpdates: FeedUpdateStatusStore.all.map { MCPFeedUpdatePayload.make(feed: $0, record: FeedUpdateStatusStore.read($0, defaults: defaults)) }
        )
    }

    // MARK: get_incident_timeline

    static func containmentSourceLabel(_ source: ContainmentIncidentSource) -> String {
        switch source {
        case .arpSpoof: return loc("ARPスプーフィング自動封じ込め")
        case .ransomwareCanary: return loc("ランサムウェア・カナリアガード")
        case .runtimeThreat: return loc("ランタイム脅威封じ込め (XProtect連動)")
        case .portAnomaly: return loc("ポート異常ガード")
        case .clickFix: return loc("ClickFixガード（不審なコマンド検知）")
        case .execRecorder: return loc("プロセス実行レコーダー（相関ルール）")
        case .ransomwareEntropy: return loc("汎用ランサムウェア検知（エントロピー解析）")
        case .honeytoken: return loc("認証情報ハニートークン")
        case .browserCredentialWatch: return loc("ブラウザ認証情報アクセス監視")
        case .reverseShellWatch: return loc("リバースシェル検知")
        case .networkSettingsWatch: return loc("ネットワーク設定の変化の監視")
        case .sshGuard: return loc("SSH総当たり検知")
        case .vulnerabilityAcceptance: return loc("脆弱性の受容")
        case .criticalPathFim: return loc("重要ファイルの改ざん監視")
        }
    }

    static func containmentActionLabel(_ action: String) -> String {
        switch action {
        case "air_gap": return loc("ネットワーク全遮断 (Air-Gap)")
        case "port_block": return loc("ポートのLAN公開を遮断")
        case "ssh_block": return loc("SSH接続元を遮断（新しい接続のみ）")
        case "notify_only": return loc("通知のみ（遮断は行わない）")
        case "air_gap_degraded": return loc("Air-Gapを縮退モードへ移行（新規の外部通信は遮断を継続）")
        case "baseline_accepted": return loc("基準を更新（人の操作）")
        default: return action
        }
    }

    public static func makeIncidentTimelinePayload(events: [ContainmentIncidentEvent], fileState: ContainmentIncidentTimeline.FileState = .ok) -> MCPIncidentTimelinePayload {
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
        var caveats: [String] = [
            loc("summary は検知時点に記録された文言をそのまま返します。後から表示言語を変更しても、過去の記録には反映されません。")
        ]
        if fileState == .unreadable {
            caveats.append(loc("インシデントの記録ファイルを読めませんでした。events が空でも、インシデントがなかったとは限りません。壊れたファイルは、次の記録の前に .bak として退避されます。"))
        }
        let fileName: String
        switch fileState {
        case .ok: fileName = "ok"
        case .missing: fileName = "missing"
        case .unreadable: fileName = "unreadable"
        }
        return MCPIncidentTimelinePayload(unresolvedCount: unresolved, events: payloads, caveats: caveats, recordFile: fileName)
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


// MARK: - get_ransomware_recovery_snapshots

/// One snapshot as `get_ransomware_recovery_snapshots` reports it.
public struct MCPRansomwareSnapshotPayload: Codable, Equatable {
    public let id: String
    /// `pre_damage`, `detection` or `manual`.
    public let kind: String
    public let createdAt: String
    /// False once macOS (or anyone) removed the snapshot.
    public let exists: Bool
    /// True for the one snapshot to recover from: the newest pre-damage one that still exists.
    public let recommended: Bool
    /// Present where the kind needs explaining (a detection snapshot may already hold encrypted files).
    public let note: String?
}

public struct MCPRansomwareRecoverySnapshotsPayload: Codable, Equatable {
    /// Hours between scheduled pre-damage snapshots; 0 means they are turned off.
    public let scheduledIntervalHours: Int
    /// True while a detection snapshot is newer than the last pre-damage one: new
    /// scheduled snapshots and pruning are paused so the encrypted state cannot
    /// push out the last good generation.
    public let retentionMode: Bool
    public let recommendedSnapshotId: String?
    public let snapshots: [MCPRansomwareSnapshotPayload]
    public let notes: [String]
    /// Present when the last attempt to take a snapshot failed (`tmutil localsnapshot`): the reason, when, and how
    /// many attempts in a row. A list that is empty or old may be because of this. Absent after a success.
    public var lastSnapshotError: MCPRansomwareSnapshotErrorPayload? = nil
}

public struct MCPRansomwareSnapshotErrorPayload: Codable, Equatable {
    public let message: String
    public let at: String
    public let consecutiveFailures: Int
}

enum MCPRansomwareRecoveryFormatting {
    static let detectionNote = "Taken when a detection fired, so it may already contain files encrypted before the detection. It is NOT a source to recover pre-encryption data from; use the recommended pre-damage snapshot."

    static let generalNotes: [String] = [
        "Read-only: this tool never creates, deletes or mounts a snapshot, and there is no MCP tool that restores anything. Recovery is always manual and file-level, from the RoamSwitch Ransomware Recovery window: files are copied to ~/RoamSwitch-Recovered/<snapshot id>/, and current files are never overwritten. A whole-volume restore is not offered.",
        "macOS may delete local snapshots on its own after about 24 hours, and sooner when free space is low; `exists` is re-checked against the disk on every call.",
        "Taking files out of a snapshot needs the RoamSwitch helper to have Full Disk Access (creating snapshots does not).",
    ]

    static func payload(_ status: RansomwareSnapshotStatusReader.Status) -> MCPRansomwareRecoverySnapshotsPayload {
        let iso = ISO8601DateFormatter()
        return MCPRansomwareRecoverySnapshotsPayload(
            scheduledIntervalHours: status.intervalHours,
            retentionMode: status.retentionMode,
            recommendedSnapshotId: status.recommendedID,
            snapshots: status.snapshots.map {
                MCPRansomwareSnapshotPayload(
                    id: $0.id,
                    kind: $0.kind.rawValue,
                    createdAt: iso.string(from: $0.createdAt),
                    exists: $0.exists,
                    recommended: $0.id == status.recommendedID,
                    note: $0.kind == .detection ? detectionNote : nil
                )
            },
            notes: generalNotes,
            lastSnapshotError: status.lastFailure.map {
                MCPRansomwareSnapshotErrorPayload(message: $0.message, at: iso.string(from: $0.at), consecutiveFailures: $0.consecutive)
            }
        )
    }
}

// MARK: - Finding discipline for verify_security_findings

/// The fields `verify_security_findings` adds so a reader can tell how far a verdict can be trusted.
/// Everything here is a fixed, hand-written text chosen by the language-independent `checkId` / `reason`
/// codes (no model, no free text from the machine), in the app's display language.
///
/// - `verificationStatus` says how well the *verdict* is established, not which way it points:
///   `verified` (the check applies and was measured: `stillPresent` or `resolved`/`passing`),
///   `false_positive` (by design the check does not apply with the current settings, so it never stood
///   as a finding), `unverified` (the probe could not be trusted; the verdict is `inconclusive`).
/// - `rationale` explains the status in one sentence, per `reason` code.
/// - `counterEvidence` is the strongest reason a failing check could be benign, and `severityChangesIf`
///   what would raise or lower the concern. Both are only given when the check still fails.
///
/// Same field names and status values on the Linux edition.
enum VerifyFindingDiscipline {
    static func status(verdict: SecurityCheckVerification, reason: String) -> String {
        switch verdict {
        case .inconclusive: return "unverified"
        case .resolved: return reason == "not_applicable" ? "false_positive" : "verified"
        case .stillPresent: return "verified"
        }
    }

    static func rationale(reason: String) -> String {
        switch reason {
        case "failing": return loc("同じ判定条件で測り直した結果、この項目は今も不合格です。")
        case "passing": return loc("同じ判定条件で測り直した結果、この項目は合格しています。")
        case "not_applicable": return loc("この項目は、現在の設定では適用対象外です(意図した設定のため、指摘としては成立しません)。")
        case "helper_unavailable": return loc("特権ヘルパーに接続できず、確認できませんでした。判断は保留です。")
        case "gateway_unknown": return loc("ゲートウェイを特定できず、確認できませんでした。判断は保留です。")
        case "no_baseline": return loc("比較の基準になる、登録済みの信頼ネットワークがなく、確認できませんでした。判断は保留です。")
        case "location_unavailable": return loc("位置情報の権限がなく、Wi-Fiの情報を読めませんでした。判断は保留です。")
        case "tool_failed": return loc("確認に必要なコマンドの実行に失敗しました。判断は保留です。")
        case "not_verifiable": return loc("この項目は、今の方法では状態を確かめられません。判断は保留です。")
        case "not_measured": return loc("この項目はまだ測定が終わっていません。時間をおいて、もう一度確認してください。判断は保留です。")
        case "unknown_check_id": return loc("この checkId は存在しません。get_security_report で有効な checkId を確認してください。")
        default: return loc("この項目は、今の方法では状態を確かめられません。判断は保留です。")
        }
    }

    /// Hand-written, per check. nil for an id this table does not know.
    static func counterEvidence(checkId: String) -> String? {
        switch checkId {
        case "luks_encryption": return loc("FileVaultが無効でも、持ち出さない据え置きのMacで、機密データを保存していなければ、実害は小さい構成です。")
        case "lsm_active": return loc("開発や研究のためにSIPを意図して無効、または一部だけ無効にしているMacでは、この状態は設定どおりです。")
        case "gatekeeper_app_verification": return loc("署名のないアプリを意図して実行している開発用のMacでは、この状態は設定どおりのことがあります。")
        case "auto_security_updates": return loc("更新を手動、または管理ツール(MDM)で適用している場合は、自動更新がオフでもパッチは当たっています。")
        case "os_builtin_malware_detection": return loc("判定は確認した時点の状態です。一時的に停止中と読めた可能性があるため、時間をおいて同じ結果になるか確かめてください。")
        case "host_firewall": return loc("この判定は、RoamSwitchの保護レベルが示す状態で、macOS自体のファイアウォール設定を測ったものではありません。自宅など信頼できるネットワークだけで使うMacなら、優先度は下がります。")
        case "network_stealth_mode": return loc("ステルスモードは存在を見えにくくするだけで、待ち受けているポートそのものは守りません。公開しているポートが無ければ、影響は小さいです。")
        case "wifi_encryption_strength": return loc("Wi-Fiが暗号化されていなくても、VPNなどで通信自体が暗号化されていれば、盗聴の影響は小さくなります。")
        case "arp_spoof_monitor": return loc("ARPの変化は、ルーターの交換や、ゲートウェイが複数台ある構成でも起きます。実際の攻撃ではない可能性があります。")
        case "gateway_arp_lock": return loc("ゲートウェイARP固定は予防策で、オフでも攻撃を受けているとは限りません。この判定はRoamSwitchの設定値で、実際に効いていることの実測ではありません。")
        case "ssh_hardening": return loc("リモートログイン(SSH)が外部から届かない状態(ファイアウォールで遮断、または信頼できるネットワークの中だけ)なら、設定の甘さは悪用されにくいです。")
        case "sudo_hygiene": return loc("NOPASSWDは、自動化スクリプトのために、特定のコマンドだけを対象にして意図して設定している場合があります。")
        case "exposed_ports": return loc("公開ポートは、意図して起動した開発サーバーなどかもしれません。また、root所有のリスナーはこの確認では見えません。")
        case "malware_scanning": return loc("この判定は、RoamSwitchの設定値(ダウンロード自動スキャンのオン/オフ)です。ClamAV以外のマルウェア対策を使っているなら、オフでも無防備とは限りません。")
        case "dns_threat_guard": return loc("この判定は、RoamSwitchの設定値です。ルーターなど別のDNSサービスで悪質なドメインを遮断しているなら、オフでも保護はあります。")
        case "browser_phishing_protection": return loc("Safariを使わず、別のブラウザだけで閲覧している場合、Safariの詐欺Webサイト警告の設定は日常の保護に影響しません。")
        case "usb_zero_trust": return loc("この判定は、RoamSwitchの設定値です。外部のUSB機器を使わない据え置きのMacでは、物理ポートからの攻撃のリスクは小さいです。")
        case "accessory_connection_protection": return loc("この設定が扱うのは、Macがロックされている間の新しいアクセサリの接続だけです。使用中の接続は対象外です。")
        case "backup_recency": return loc("Time Machine以外の方法(別のバックアップアプリなど)でバックアップしている場合、この判定は実態と違います。RoamSwitchが読めるのはTime Machineの記録だけです。")
        case "proxy_autodiscovery": return loc("会社や学校が管理するMacで、プロキシ自動検出を管理者が意図して設定している場合は、この状態は設定どおりです。")
        case "trust_anchors": return loc("会社が配布した証明書や、開発用の証明書(mkcert など)を意図して信頼している場合は、この状態は設定どおりです。")
        case "agent_credential_files": return loc("同期フォルダやgit管理下に見えても、そのファイルを同期や追跡の対象から外している場合は、実際には外に出ていません。RoamSwitchは、その除外設定までは確認しません。")
        default: return nil
        }
    }

    static func severityChangesIf(checkId: String) -> String? {
        switch checkId {
        case "luks_encryption": return loc("ノートPCなど持ち出すMac、または機密データや認証情報を保存しているMacなら、重大になります。別の方法でディスク全体が暗号化されていると確認できれば、下がります。")
        case "lsm_active": return loc("通常の作業(Web閲覧、ダウンロードしたアプリの実行)に使うMacでSIPが無効なら、重大になります。隔離した検証専用の環境なら、下がります。")
        case "gatekeeper_app_verification": return loc("ダウンロードしたアプリを頻繁に開くMacなら、重大になります。実行するアプリが自作のものだけなら、下がります。")
        case "auto_security_updates": return loc("macOSが最新でない場合は、重大になります。システム設定で最新の状態と確認できれば、下がります。")
        case "os_builtin_malware_detection": return loc("macOSの更新が長く止まっている場合は、重大になります。再確認で稼働中に戻れば、下がります。")
        case "host_firewall": return loc("公衆Wi-Fiなど信頼できないネットワークで使うなら、重大になります。外部から届くポートが無ければ、下がります。")
        case "network_stealth_mode": return loc("公衆Wi-Fiなど信頼できないネットワークで使うなら、上がります。信頼できるネットワークだけで使うなら、下がります。")
        case "wifi_encryption_strength": return loc("VPNを使わずに、暗号化のないWi-FiやWEPに接続しているなら、重大になります。WPA2またはWPA3の接続に切り替えれば、解消します。")
        case "arp_spoof_monitor": return loc("ゲートウェイのMACアドレスが予期せず変わり、同時に通信の途切れや証明書エラーも出ているなら、重大になります。ルーターを交換した直後なら、下がります。")
        case "gateway_arp_lock": return loc("カフェなど信頼できないネットワークをよく使うなら、上がります。自宅など信頼できるネットワークだけなら、下がります。")
        case "ssh_hardening": return loc("SSHがインターネットや共有のLANから届く状態なら、重大になります。パスワード認証を止めて鍵認証のみにし、rootログインを禁止すれば、解消します。")
        case "sudo_hygiene": return loc("すべてのコマンドを対象にした NOPASSWD: ALL なら、重大になります。限定された1つのコマンドだけなら、下がります。")
        case "exposed_ports": return loc("認証のないデータベース、AIの推論サーバー、管理画面が公開されているなら、重大になります。待ち受けを127.0.0.1に限定するか、ファイアウォールで遮断すれば、下がります。")
        case "malware_scanning": return loc("ブラウザやメールで受け取ったファイルをよく開くなら、上がります。受け取るファイルが少ない環境なら、下がります。")
        case "dns_threat_guard": return loc("公衆Wi-Fiなど信頼できないネットワークで使うなら、上がります。信頼できるネットワークだけなら、下がります。")
        case "browser_phishing_protection": return loc("Safariで知らない相手のリンクを開くことがあるなら、上がります。")
        case "usb_zero_trust": return loc("共有スペースや外出先で、他人がMacに触れられるなら、上がります。")
        case "accessory_connection_protection": return loc("席を離れたMacに他人が触れられる場所で使うなら、上がります。")
        case "backup_recency": return loc("ランサムウェアに暗号化されたら取り戻せない大事なファイルがあるなら、重大になります。大事なデータがすべて別の場所に世代管理つきで保存されているなら、下がります。")
        case "proxy_autodiscovery": return loc("カフェやホテルなど、他人が管理するネットワークをよく使うなら、重大になります。自宅や職場の管理されたネットワークだけなら、下がります。")
        case "trust_anchors": return loc("ログインやAPIキーを含む通信を、カフェなど他人が管理するネットワークで行うなら、重大になります。信頼している証明書をすべて把握しているなら、下がります。")
        case "agent_credential_files": return loc("ファイルが他のユーザーに読める権限や、公開されうる同期・git管理下にあるなら、重大になります。所有者だけが読める権限で、手元のディスクにだけあるなら、解消します。")
        default: return nil
        }
    }
}
