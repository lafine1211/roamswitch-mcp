// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.0 (build 116).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CoreWLAN

// Hand-rolled MCP stdio JSON-RPC server (no SDK dependency — the official
// swift-sdk's transitive `swift-system` package fails to compile against
// this machine's macOS 26.5 SDK: "module file '..._DarwinFoundation1...pcm'
// not found", reproducible even after a full DerivedData wipe). The stdio
// transport is simple enough (newline-delimited JSON-RPC 2.0, no framing
// headers) to implement directly against Foundation's JSONSerialization —
// see https://modelcontextprotocol.io/specification/2025-06-18/basic/transports
// and .../server/tools for the exact message shapes this follows.
//
// All parsing and dispatch lives here as pure functions so it can be unit
// tested and fuzzed. `main.swift` is only the stdin→stdout pump.

private let arpMonitor = ARPSpoofMonitor()

// `UserDefaults.standard` resolves to *this process's own* bundle
// identifier (com.tetsuharu.RoamSwitch.MCPServer) — a separate, empty
// preferences domain from the main app's. Explicitly target the app's
// domain by suite name so guard toggles and trusted-network state read
// what the app actually has configured.
private let sharedDefaults = UserDefaults(suiteName: "com.tetsuharu.RoamSwitch") ?? .standard

/// `RoamSwitchMCPServer` is a bare Mach-O executable embedded at
/// `RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer` — it has no real
/// `Contents/Info.plist` of its own next to it (unlike a regular `.app`),
/// so `Bundle.main.infoDictionary` resolves to nothing there and
/// `CFBundleShortVersionString` is never found. This climbs from the
/// running executable's own path to the nearest ancestor directory ending
/// in `.app` and reads that bundle's real Info.plist instead — the exact
/// same problem/fix as `AppLanguage.resourceBundle`'s `.lproj` lookup.
/// Falls back to `1.0.0` only when run standalone outside any `.app`
/// (e.g. a raw DerivedData build during local testing).
private let mcpServerVersion: String = {
    var dir = Bundle.main.executableURL?.deletingLastPathComponent()
    for _ in 0..<8 {
        guard let candidate = dir else { break }
        if candidate.pathExtension == "app",
           let appBundle = Bundle(url: candidate),
           let version = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        dir = candidate.pathComponents.count > 1 ? candidate.deletingLastPathComponent() : nil
    }
    return "1.0.0"
}()

enum MCPServer {

    /// One line is a single MCP message; anything past this is not a real
    /// request. The size cap also bounds the nesting scan below.
    private static let maxLineBytes = 4 * 1024 * 1024
    /// Real MCP messages nest ~4 deep. `JSONSerialization` stack-overflows
    /// (SIGBUS) on a deeply-nested *object* — deep arrays it rejects cleanly.
    /// Found by fuzzing; the pre-scan stops it before the parser sees it.
    private static let maxNestingDepth = 128

    /// Parse one newline-delimited input line and return the JSON-RPC response
    /// lines (0, 1, or — for a batch request — several) to write back, already
    /// serialized. Never throws, never blocks on input; a malformed or
    /// pathological line yields no output, exactly as the old `continue` did.
    static func handleLine(_ data: Data) -> [Data] {
        guard !data.isEmpty, data.count <= maxLineBytes,
              jsonNestingWithinLimit(data, max: maxNestingDepth),
              let parsed = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        let messages: [[String: Any]]
        if let message = parsed as? [String: Any] {
            messages = [message]
        } else if let batch = parsed as? [[String: Any]] {
            messages = batch
        } else {
            return []
        }

        return messages
            .flatMap { handleMessage($0) }
            .compactMap { try? JSONSerialization.data(withJSONObject: $0) }
    }

    /// O(n) byte scan for maximum `{` / `[` nesting, ignoring brackets inside
    /// JSON strings. Returns false as soon as `max` is exceeded, so a nesting
    /// bomb costs one linear pass and no allocation.
    static func jsonNestingWithinLimit(_ data: Data, max: Int) -> Bool {
        var depth = 0
        var inString = false
        var escaped = false
        for b in data {
            if inString {
                if escaped { escaped = false }
                else if b == 0x5C { escaped = true }   // backslash
                else if b == 0x22 { inString = false } // "
                continue
            }
            switch b {
            case 0x22: inString = true                 // "
            case 0x7B, 0x5B:                            // { [
                depth += 1
                if depth > max { return false }
            case 0x7D, 0x5D:                            // } ]
                if depth > 0 { depth -= 1 }
            default: break
            }
        }
        return true
    }

    // MARK: - JSON-RPC dispatch

    /// Response objects for one message. Empty for notifications (no `id`) and
    /// for `notifications/initialized`.
    static func handleMessage(_ message: [String: Any]) -> [[String: Any]] {
        guard let method = message["method"] as? String else { return [] }
        let id = message["id"] // nil for notifications — no response is sent for those

        switch method {
        case "initialize":
            guard let id else { return [] }
            let clientVersion = (message["params"] as? [String: Any])?["protocolVersion"] as? String
            return [result(id: id, [
                "protocolVersion": MCPProtocol.negotiateVersion(clientRequested: clientVersion),
                "capabilities": [
                    "tools": [String: Any](),
                    "resources": [String: Any](),
                ],
                "serverInfo": ["name": "RoamSwitch Security Advisor", "version": mcpServerVersion],
                "instructions": "Read-only, fully local (no network calls) access to RoamSwitch's Mac security diagnostics, comprehensive feature specifications, alert message advice, and operational guides. Use 'get_app_help' or read 'roamswitch://docs/...' resources for in-depth documentation. For incident triage (including from a local LLM during an Air-Gap), start with 'get_runtime_threat_status' and 'get_incident_timeline'. Cannot change security level, isolate ports, or eject devices.",
            ])]

        case "notifications/initialized":
            return [] // no response — this is a notification

        case "ping":
            guard let id else { return [] }
            return [result(id: id, [String: Any]())]

        case "resources/list":
            guard let id else { return [] }
            return [result(id: id, ["resources": resourceCatalog])]

        case "resources/read":
            guard let id else { return [] }
            guard let params = message["params"] as? [String: Any], let uri = params["uri"] as? String else {
                return [error(id: id, code: -32602, message: "Missing resource uri")]
            }
            // Skill documents are static and deliberately English-only
            // (agentskills.io convention), so they bypass the localized
            // RoamSwitchKnowledgeBase lookup below.
            if let skillContent = RoamSwitchMCPSkillsContent.skillsByURI[uri] {
                return [result(id: id, [
                    "contents": [["uri": uri, "mimeType": "text/markdown", "text": skillContent]],
                ])]
            }
            if let content = RoamSwitchKnowledgeBase.shared.resource(for: uri, language: RoamSwitchKnowledgeBase.activeLanguageCode()) {
                return [result(id: id, [
                    "contents": [["uri": uri, "mimeType": "text/markdown", "text": content]],
                ])]
            }
            return [error(id: id, code: -32602, message: "Resource not found: \(uri)")]

        case "tools/list":
            guard let id else { return [] }
            return [result(id: id, ["tools": toolDefinitions])]

        case "tools/call":
            guard let id else { return [] }
            guard let params = message["params"] as? [String: Any], let name = params["name"] as? String else {
                return [error(id: id, code: -32602, message: "Missing tool name")]
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]

            switch name {
            case "get_security_report":
                return [result(id: id, callGetSecurityReport())]
            case "get_exposed_ports":
                return [result(id: id, callGetExposedPorts(arguments: arguments))]
            case "get_guard_status":
                return [result(id: id, callGetGuardStatus())]
            case "run_active_vuln_scan":
                return [result(id: id, callRunActiveVulnScan())]
            case "run_package_cve_scan":
                return [result(id: id, callRunPackageCveScan())]
            case "run_package_cve_scan_languages":
                return [result(id: id, callRunPackageCveScanLanguages(arguments: arguments))]
            case "run_package_lifecycle_script_scan":
                return [result(id: id, callRunPackageLifecycleScriptScan(arguments: arguments))]
            case "run_typosquat_scan":
                return [result(id: id, callRunTyposquatScan(arguments: arguments))]
            case "run_npm_audit_signatures":
                return [result(id: id, callRunNpmAuditSignatures(arguments: arguments))]
            case "audit_url_safety":
                return [result(id: id, callAuditURLSafety(arguments: arguments))]
            case "get_app_help":
                return [result(id: id, callGetAppHelp(arguments: arguments))]
            case "audit_secrets":
                return [result(id: id, callAuditSecrets(arguments: arguments))]
            case "audit_security_logs":
                return [result(id: id, callAuditSecurityLogs(arguments: arguments))]
            case "get_quarantine_status":
                return [result(id: id, callGetQuarantineStatus())]
            case "get_canary_status":
                return [result(id: id, callGetCanaryStatus())]
            case "get_ransomware_entropy_guard_status":
                return [result(id: id, callGetRansomwareEntropyGuardStatus())]
            case "get_forensic_evidence_bundles":
                return [result(id: id, callGetForensicEvidenceBundles())]
            case "get_vulnerability_scan_history":
                return [result(id: id, callGetVulnerabilityScanHistory())]
            case "get_honeytoken_status":
                return [result(id: id, callGetHoneytokenStatus())]
            case "get_browser_credential_watch_status":
                return [result(id: id, callGetBrowserCredentialWatchStatus())]
            case "get_ransomware_recovery_snapshots":
                return [result(id: id, callGetRansomwareRecoverySnapshots())]
            case "get_notification_history":
                return [result(id: id, callGetNotificationHistory())]
            case "get_port_anomaly_incidents":
                return [result(id: id, callGetPortAnomalyIncidents(defaults: sharedDefaults))]
            case "get_runtime_threat_status":
                return [result(id: id, callGetRuntimeThreatStatus())]
            case "get_incident_timeline":
                return [result(id: id, callGetIncidentTimeline(arguments: arguments))]
            case "search_exec_events":
                return [result(id: id, callSearchExecEvents(arguments: arguments))]
            case "get_process_tree":
                return [result(id: id, callGetProcessTree(arguments: arguments))]
            case "get_network_history":
                return [result(id: id, callGetNetworkHistory(arguments: arguments))]
            case "get_sensor_audit_results":
                return [result(id: id, callGetSensorAuditResults())]
            default:
                return [error(id: id, code: -32602, message: "Unknown tool: \(name)")]
            }

        default:
            guard let id else { return [] }
            return [error(id: id, code: -32601, message: "Method not found: \(method)")]
        }
    }

    // MARK: - Response builders

    private static func result(id: Any, _ result: [String: Any]) -> [String: Any] {
        ["jsonrpc": "2.0", "id": id, "result": result]
    }

    private static func error(id: Any, code: Int, message: String) -> [String: Any] {
        ["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": message]]
    }

    private static func textContentResult(_ payload: some Encodable, isError: Bool = false) -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return [
            "content": [["type": "text", "text": json]],
            "isError": isError,
        ]
    }

    // MARK: - Tool implementations

    private static func callGetSecurityReport() -> [String: Any] {
        let ip = GatewayFingerprint.currentGatewayIPAddress()
        let mac = GatewayFingerprint.currentGatewayMACAddress()
        let wifi = WiFiSecurityMonitor.shared.checkCurrentWiFi()
        let arp = arpMonitor.inspectGateway(currentIP: ip, currentMAC: mac, currentSSID: wifi.ssid)
        let ports = ListeningPortMonitor.shared.scanListeningPorts()
        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: mac, defaults: sharedDefaults)
        let report = SecurityHealthChecker.shared.generateComprehensiveReport(
            wifiInfo: wifi,
            arpStatus: arp,
            listeningPorts: ports,
            activeSecurityLevel: level
        )
        let interfacePresent = CWWiFiClient.shared().interface() != nil
        let payload = MCPResponseFormatting.makeSecurityReportPayload(
            report: report,
            wifiInterfacePresent: interfacePresent,
            wifiSSIDResolved: wifi.ssid != nil
        )
        return textContentResult(payload)
    }

    private static func callGetExposedPorts(arguments: [String: Any]) -> [String: Any] {
        let includeLocalOnly = arguments["includeLocalOnly"] as? Bool ?? false
        let ports = ListeningPortMonitor.shared.scanListeningPorts()
        let level = MCPResponseFormatting.resolveActiveSecurityLevel(gatewayMAC: GatewayFingerprint.currentGatewayMACAddress(), defaults: sharedDefaults)
        let isFirewallBlocking = level.firewallBlockAll

        var payloads: [MCPPortPayload] = []
        let lock = NSLock()
        let group = DispatchGroup()

        for portInfo in ports {
            if portInfo.isGloballyExposed {
                group.enter()
                PortSecurityAuditor.shared.auditPort(portInfo: portInfo, isFirewallBlocking: isFirewallBlocking) { result in
                    lock.lock()
                    payloads.append(MCPResponseFormatting.makePortPayload(portInfo: portInfo, auditResult: result))
                    lock.unlock()
                    group.leave()
                }
            } else if includeLocalOnly {
                payloads.append(MCPResponseFormatting.makePortPayload(portInfo: portInfo, auditResult: nil))
            }
        }
        group.wait()

        let payload = MCPExposedPortsPayload(isFirewallShielded: isFirewallBlocking, ports: payloads)
        return textContentResult(payload)
    }

    /// Phase 2/3 of the active-vulnerability-verification roadmap (see
    /// `ActiveVulnScan.swift`). Unlike every other tool in this file, this one actually
    /// sends network requests — gated on the `ActiveVulnScan.enabledDefaultsKey` opt-in,
    /// read from `sharedDefaults` (the app-group suite) rather than `UserDefaults
    /// .standard`, since this MCP server runs as a separate process/bundle from the main
    /// app that owns the Settings toggle — the same cross-process reasoning already
    /// applied to every other guard-enabled flag in this file (see `sharedDefaults`
    /// usage above).
    private static func callRunActiveVulnScan() -> [String: Any] {
        guard sharedDefaults.bool(forKey: ActiveVulnScan.enabledDefaultsKey) else {
            let payload = MCPActiveVulnScanResultPayload(
                enabled: false,
                scannedTargetCount: 0,
                findings: [],
                message: loc("実証型脆弱性診断は既定で無効です。設定タブの「実証型脆弱性診断」をオンにしてから実行してください。")
            )
            return textContentResult(payload)
        }

        let ports = ListeningPortMonitor.shared.scanListeningPorts()
        let scan = ActiveVulnScan.runScan(ports: ports)
        let targetCount = ports.filter { port in
            !ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath).isEmpty
                || PortSecurityAuditor.isKnownDevServerPort(port.port)
        }.count

        // Distinct from "スキャンが完了しました" (no partial-failure concept):
        // a caller must be able to tell "N checks couldn't complete" apart from
        // "everything checked out clean" rather than both looking like an
        // empty findings list (see
        // https://dev.to/raknaos/my-wait-for-it-wrapper-reported-success-for-a-port-that-never-opened-ga3).
        let message = scan.inconclusive.isEmpty
            ? loc("スキャンが完了しました。")
            : String(format: loc("スキャンが完了しました（%d件は接続できず未確認）。"), scan.inconclusive.count)

        let payload = MCPActiveVulnScanResultPayload(
            enabled: true,
            scannedTargetCount: targetCount,
            findings: scan.findings.map {
                MCPActiveVulnScanFindingPayload(
                    port: $0.port,
                    processName: $0.processName,
                    title: $0.title,
                    description: $0.description,
                    recommendation: $0.recommendation
                )
            },
            confirmedSafe: scan.confirmedSafe.map {
                MCPScanCheckOutcomePayload(port: $0.port, processName: $0.processName, check: $0.check)
            },
            inconclusive: scan.inconclusive.map {
                MCPScanCheckOutcomePayload(port: $0.port, processName: $0.processName, check: $0.check)
            },
            message: message
        )
        return textContentResult(payload)
    }

    /// UNLIKE `run_active_vuln_scan`, this sends no network requests at all —
    /// a pure local inventory read (`brew list --versions` + a local JSON
    /// file), so there is no opt-in flag to check here.
    private static func callRunPackageCveScan() -> [String: Any] {
        let map = PackageCveScan.loadCVEMap()
        let findings = map.entries.isEmpty ? [] : PackageCveScan.runScan()
        let payload = MCPPackageCveScanResultPayload(
            mapInstalled: !map.entries.isEmpty,
            mapVersion: map.mapVersion,
            findings: findings.map {
                MCPPackageCveFindingPayload(
                    cveId: $0.cveId,
                    package: $0.package,
                    installedVersion: $0.installedVersion,
                    cvssScore: $0.cvssScore,
                    fixedVersion: $0.fixedVersion,
                    summary: $0.summary,
                    confidence: $0.confidence
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local files. Takes the
    /// caller-supplied `watchedFolders` argument directly (no persisted
    /// state read here) — mirrors the Linux MCP tool
    /// `run_package_cve_scan_languages` exactly.
    private static func callRunPackageCveScanLanguages(arguments: [String: Any]) -> [String: Any] {
        let folders = (arguments["watchedFolders"] as? [Any])?.compactMap { $0 as? String } ?? []
        let findings = PackageCveScanLanguages.runScan(watchedFolders: folders)
        let payload = MCPPackageCveScanLanguagesResultPayload(
            scannedFolderCount: folders.count,
            findings: findings.map {
                MCPPackageCveLanguageFindingPayload(
                    ecosystem: $0.ecosystem,
                    cveId: $0.cveId,
                    package: $0.package,
                    installedVersion: $0.installedVersion,
                    cvssScore: $0.cvssScore,
                    fixedVersion: $0.fixedVersion,
                    summary: $0.summary
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local files, executes
    /// nothing. A plain inventory of package.json lifecycle scripts, not a
    /// threat verdict — see `PackageCveScriptScan`'s doc comment. Pro-gated
    /// like the section itself in the app UI: re-checked here so a direct
    /// MCP call can't bypass it. Reads the plain UserDefaults mirror
    /// (`LicenseManager.isProCacheKey`) rather than `LicenseManager.shared`
    /// itself, since this file is also compiled into the minimal
    /// `RoamSwitchMCPServer` tool target, which doesn't link
    /// `LicenseManager`'s Keychain/Ed25519 dependency chain.
    private static func callRunPackageLifecycleScriptScan(arguments: [String: Any]) -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc("この機能はPro版限定です。RoamSwitchでPro版を有効化してください。")], isError: true)
        }
        let folders = (arguments["watchedFolders"] as? [Any])?.compactMap { $0 as? String } ?? []
        let findings = PackageCveScriptScan.runScan(watchedFolders: folders)
        let payload = MCPPackageLifecycleScriptScanResultPayload(
            scannedFolderCount: folders.count,
            findings: findings.map {
                MCPPackageLifecycleScriptFindingPayload(
                    packageName: $0.packageName,
                    packageVersion: $0.packageVersion,
                    scriptName: $0.scriptName,
                    scriptCommand: $0.scriptCommand,
                    relativePath: $0.relativePath,
                    isDangerPattern: $0.isDangerPattern,
                    dangerPatternLabel: $0.dangerPatternLabel
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local files. A
    /// reference-only heuristic, not a threat verdict — see
    /// `TyposquatGuard`'s doc comment. Same Pro-gate pattern as
    /// `callRunPackageLifecycleScriptScan` above (reads the UserDefaults
    /// mirror rather than `LicenseManager.shared` directly, for the minimal
    /// `RoamSwitchMCPServer` tool target's sake).
    private static func callRunTyposquatScan(arguments: [String: Any]) -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc("この機能はPro版限定です。RoamSwitchでPro版を有効化してください。")], isError: true)
        }
        let folders = (arguments["watchedFolders"] as? [Any])?.compactMap { $0 as? String } ?? []
        let findings = TyposquatGuard.runScan(watchedFolders: folders)
        let payload = MCPTyposquatScanResultPayload(
            scannedFolderCount: folders.count,
            findings: findings.map {
                MCPTyposquatFindingPayload(
                    dependencyName: $0.dependencyName,
                    suspectedTarget: $0.suspectedTarget,
                    distance: $0.distance
                )
            }
        )
        return textContentResult(payload)
    }

    /// UNLIKE EVERY OTHER PACKAGE/CVE TOOL IN THIS FILE, THIS SENDS NETWORK
    /// REQUESTS — `npm audit signatures` talks to the npm registry
    /// (registry.npmjs.org). Gated on `NpmAuditSignatures.enabledDefaultsKey`,
    /// read from `sharedDefaults` for the same cross-process reason as
    /// `run_active_vuln_scan` (see `callRunActiveVulnScan`'s doc comment).
    /// `rawOutput` is npm's own verbatim output, not hand-parsed — see
    /// `MCPNpmAuditSignaturesResultPayload`'s doc comment.
    private static func callRunNpmAuditSignatures(arguments: [String: Any]) -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc("この機能はPro版限定です。RoamSwitchでPro版を有効化してください。")], isError: true)
        }
        guard sharedDefaults.bool(forKey: NpmAuditSignatures.enabledDefaultsKey) else {
            let payload = MCPNpmAuditSignaturesResultPayload(
                enabled: false, directory: nil, rawOutput: nil, exitCode: nil, hasIssues: nil,
                message: loc("npm署名検証は既定で無効です。設定タブの「npm署名検証」をオンにしてから実行してください。")
            )
            return textContentResult(payload)
        }
        guard let directory = arguments["directory"] as? String, !directory.isEmpty else {
            return textContentResult(["error": loc("'directory' 引数を指定してください。")], isError: true)
        }

        switch NpmAuditSignatures.run(directory: directory) {
        case .success(let r):
            let payload = MCPNpmAuditSignaturesResultPayload(
                enabled: true, directory: r.directory, rawOutput: r.rawOutput, exitCode: r.exitCode,
                hasIssues: r.hasIssues, message: loc("npm audit signatures を実行しました。")
            )
            return textContentResult(payload)
        case .failure(.npmNotFound):
            let payload = MCPNpmAuditSignaturesResultPayload(
                enabled: true, directory: directory, rawOutput: nil, exitCode: nil, hasIssues: nil,
                message: loc("npmコマンドが見つかりませんでした。Node.js/npmをインストールしてください。")
            )
            return textContentResult(payload)
        case .failure(.launchFailed(let reason)):
            return textContentResult(["error": String(format: loc("npmの起動に失敗しました: %@"), reason)], isError: true)
        }
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local text/files.
    private static func callAuditSecrets(arguments: [String: Any]) -> [String: Any] {
        let findings: [SecretLeakScanning.SecretFinding]
        if let pathStr = arguments["path"] as? String {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: pathStr, isDirectory: &isDir) else {
                return textContentResult(["error": String(format: loc("パスが見つかりません: %@"), pathStr)], isError: true)
            }
            if isDir.boolValue {
                findings = SecretLeakScanning.auditDirectory(at: URL(fileURLWithPath: pathStr))
            } else {
                let text = (try? String(contentsOfFile: pathStr, encoding: .utf8)) ?? ""
                findings = SecretLeakScanning.auditText(text, filePath: pathStr)
            }
        } else if let text = arguments["text"] as? String {
            findings = SecretLeakScanning.auditText(text)
        } else {
            return textContentResult(["error": loc("'text' または 'path' のいずれかを指定してください。")], isError: true)
        }

        let payload = MCPAuditSecretsResultPayload(
            findings: findings.map {
                MCPSecretFindingPayload(
                    type: $0.type.rawValue,
                    lineNumber: $0.lineNumber,
                    masked: $0.masked,
                    entropy: $0.entropy,
                    filePath: $0.filePath
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local system logs via
    /// `/usr/bin/log show`. Uses `performAuditSync` (not the completion-
    /// handler `performAudit`, which dispatches its result via
    /// `DispatchQueue.main.async` — this process's `while readLine()` main
    /// loop never pumps `RunLoop.main`, so that would deadlock).
    private static func callAuditSecurityLogs(arguments: [String: Any]) -> [String: Any] {
        let hours = (arguments["hours"] as? Int) ?? 24
        let report = SecurityLogAuditor.shared.performAuditSync(timeWindowHours: hours)
        let iso = ISO8601DateFormatter()
        let payload = MCPSecurityLogAuditPayload(
            timeWindowHours: report.timeWindowHours,
            totalEvents: report.totalEvents,
            sudoFailures: report.sudoFailures,
            sshAttempts: report.sshAttempts,
            gatekeeperBlocks: report.gatekeeperBlocks,
            xprotectDetections: report.xprotectDetections,
            isClean: report.isClean,
            events: report.events.map {
                MCPSecurityLogEventPayload(
                    timestamp: iso.string(from: $0.timestamp),
                    process: $0.process,
                    category: $0.category.rawValue,
                    severity: $0.severity.rawValue,
                    message: $0.message
                )
            },
            templateAnomalies: report.templateAnomalies.map {
                MCPTemplateAnomalyPayload(
                    template: $0.template,
                    example: $0.example,
                    count: $0.count,
                    zScore: $0.zScore,
                    isNew: $0.isNew
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only a local metadata file.
    private static func callGetQuarantineStatus() -> [String: Any] {
        let qm = QuarantineManager.shared
        let iso = ISO8601DateFormatter()
        let payload = MCPQuarantineStatusPayload(
            quarantineDirectory: qm.quarantineDirectory,
            files: qm.listQuarantinedFiles().map {
                MCPQuarantinedFilePayload(
                    originalPath: $0.originalPath,
                    quarantinedPath: $0.quarantinedPath,
                    threatName: $0.threatName,
                    quarantinedAt: iso.string(from: $0.quarantinedAt),
                    fileSize: $0.fileSize
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads local UserDefaults only.
    private static func callGetNotificationHistory() -> [String: Any] {
        textContentResult(MCPNotificationHistoryPayload(notifications: NotificationHistory.load()))
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads local UserDefaults + disk
    /// state only.
    /// Read-only. Reads the snapshot records RoamSwitch keeps and re-checks which
    /// snapshots still exist with the local `tmutil`; creates, deletes and mounts nothing.
    /// Pro-gated like the recovery window in the app UI: re-checked here so a
    /// direct MCP call can't bypass it (same plain-UserDefaults mirror as
    /// `callRunPackageLifecycleScriptScan`).
    private static func callGetRansomwareRecoverySnapshots() -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc("この機能はPro版限定です。RoamSwitchでPro版を有効化してください。")], isError: true)
        }
        let status = RansomwareSnapshotStatusReader.currentStatus(defaults: sharedDefaults)
        return textContentResult(MCPRansomwareRecoveryFormatting.payload(status))
    }

    private static func callGetCanaryStatus() -> [String: Any] {
        let status = CanaryStatusReader.currentStatus(defaults: sharedDefaults)
        let incidents = CanaryStatusReader.persistedIncidents(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPCanaryStatusPayload(
            isEnabled: status.isEnabled,
            monitoredFilesCount: status.monitoredFilesCount,
            expectedFilesCount: status.expectedFilesCount,
            recentIncidentsAvailable: !incidents.isEmpty,
            recentIncidents: incidents.map {
                MCPCanaryIncidentPayload(
                    timestamp: iso.string(from: $0.timestamp),
                    fileName: $0.fileName,
                    detectedAction: $0.detectedAction,
                    suspectedProcess: $0.suspectedProcess,
                    affectedFilePaths: $0.affectedFilePaths
                )
            }
        )
        return textContentResult(payload)
    }

    private static func callGetForensicEvidenceBundles() -> [String: Any] {
        let payload = MCPForensicEvidenceBundlesPayload(bundles: ForensicCaptureManager.listBundles())
        return textContentResult(payload)
    }

    private static func callGetVulnerabilityScanHistory() -> [String: Any] {
        let payload = MCPVulnerabilityScanHistoryPayload(probes: ActiveVulnScan.probeStatusSummary())
        return textContentResult(payload)
    }

    private static func callGetBrowserCredentialWatchStatus() -> [String: Any] {
        let isEnabled = BrowserCredentialWatchStatusReader.isEnabled(defaults: sharedDefaults)
        let events = BrowserCredentialWatchStatusReader.persistedEvents(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPBrowserCredentialWatchStatusPayload(
            isEnabled: isEnabled,
            recentEventsAvailable: !events.isEmpty,
            recentEvents: events.map {
                MCPBrowserCredentialEventPayload(timestamp: iso.string(from: $0.timestamp), path: $0.path, suspectedProcess: $0.suspectedProcess)
            }
        )
        return textContentResult(payload)
    }

    private static func callGetHoneytokenStatus() -> [String: Any] {
        let isEnabled = HoneytokenStatusReader.isEnabled(defaults: sharedDefaults)
        let events = HoneytokenStatusReader.persistedEvents(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPHoneytokenStatusPayload(
            isEnabled: isEnabled,
            recentEventsAvailable: !events.isEmpty,
            recentEvents: events.map {
                MCPHoneytokenEventPayload(timestamp: iso.string(from: $0.timestamp), path: $0.path, kind: $0.kind, suspectedProcess: $0.suspectedProcess)
            }
        )
        return textContentResult(payload)
    }

    private static func callGetRansomwareEntropyGuardStatus() -> [String: Any] {
        let isEnabled = RansomwareEntropyStatusReader.isEnabled(defaults: sharedDefaults)
        let alerts = RansomwareEntropyStatusReader.persistedAlerts(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPRansomwareEntropyStatusPayload(
            isEnabled: isEnabled,
            recentAlertsAvailable: !alerts.isEmpty,
            recentAlerts: alerts.map {
                MCPRansomwareEntropyAlertPayload(
                    timestamp: iso.string(from: $0.timestamp),
                    processLabel: $0.processLabel,
                    affectedFilePaths: $0.affectedFilePaths,
                    averageEntropy: $0.averageEntropy
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local files
    /// (`RoamSwitchHelper/SensorPairingManager.swift`'s on-disk trusted-
    /// Sensor and audit-result stores, via `MCPSensorAuditStatusReader`).
    /// The audits themselves were requested from a paired RoamSwitch
    /// Sensor earlier (the app's "Sensorへ監査をリクエスト" action, or the
    /// Sensor's own scheduled/manual runs) — this tool never triggers one
    /// itself, it only reports whatever results have already been pulled
    /// back.
    private static func callGetSensorAuditResults() -> [String: Any] {
        let results = MCPSensorAuditStatusReader.auditResults()
        let payload = MCPSensorAuditResultsPayload(
            pairedSensorCount: MCPSensorAuditStatusReader.pairedSensorCount(),
            results: results.map {
                MCPSensorAuditResultPayload(
                    requestId: $0.id,
                    sensorName: $0.sensorName,
                    requestedAt: $0.requestedAt,
                    status: $0.status,
                    pullAttempts: $0.pullAttempts,
                    findings: $0.findings.map {
                        MCPSensorAuditFindingPayload(port: $0.port, title: $0.title, recommendation: $0.recommendation)
                    },
                    failureReason: $0.failureReason
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads local UserDefaults state
    /// only. `PortAnomalyGuard` is Pro-only, but the read itself doesn't
    /// gate on license status — an unlicensed install simply has an empty,
    /// disabled history, same as any other guard's status tool.
    /// `defaults` defaults to the real shared suite in production; the
    /// fire-drill regression test in `MCPPortAnomalyDrillTests` overrides it
    /// with a scratch `UserDefaults(suiteName:)` so the test never touches
    /// the app's real preferences.
    static func callGetPortAnomalyIncidents(defaults: UserDefaults = sharedDefaults) -> [String: Any] {
        let status = PortAnomalyStatusReader.currentStatus(defaults: defaults)
        let incidents = PortAnomalyStatusReader.persistedIncidents(defaults: defaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPPortAnomalyIncidentsPayload(
            incidentsNote: "Timestamped log of past auto-block decisions, newest first, capped at 50. This is the only field in this response that represents a timeline of events.",
            isEnabled: status.isEnabled,
            baselineCaptured: status.baselineCaptured,
            currentPortStateNote: "autoIsolatedPorts is a live snapshot of what's blocked right now, NOT a timeline. A port can sit here indefinitely from a block made long ago; its presence is not evidence of a recent or ongoing event, and it must not be attributed to any entry in incidents without a matching timestamp.",
            autoIsolatedPorts: status.autoIsolatedPorts,
            incidents: incidents.map {
                MCPPortAnomalyIncidentPayload(
                    timestamp: iso.string(from: $0.timestamp),
                    port: $0.port,
                    processName: $0.processName,
                    pid: $0.pid,
                    executablePath: $0.executablePath
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads local UserDefaults state
    /// only. Mac equivalent of the Linux eBPF Runtime Guard's incident tool
    /// — Apple XProtect's own malware engine convicting a file is the
    /// trigger, not raw exec interception (this app has no EndpointSecurity
    /// entitlement). Air-Gap network isolation, when active, is itself the
    /// reason a cloud-AI MCP client would be unreachable — this tool is
    /// meant to be queried by a *local* LLM during exactly that cutoff.
    private static func callGetRuntimeThreatStatus() -> [String: Any] {
        let status = RuntimeThreatStatusReader.currentStatus(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPRuntimeThreatStatusPayload(
            isEnabled: status.isEnabled,
            isIsolated: status.isIsolated,
            lastContainmentDate: status.lastContainmentDate.map { iso.string(from: $0) },
            lastIncident: status.lastIncident.map {
                MCPRuntimeThreatIncidentPayload(
                    timestamp: iso.string(from: $0.timestamp),
                    process: $0.process,
                    category: $0.category.rawValue,
                    severity: $0.severity.rawValue,
                    message: $0.message
                )
            }
        )
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads one local JSON file under
    /// ~/Library/Application Support/RoamSwitch/ (the app is not sandboxed,
    /// so this process resolves the same path). The only place ARP-spoof
    /// containment is recorded at all. Same name as Linux's
    /// `get_incident_timeline`.
    private static func callGetIncidentTimeline(arguments: [String: Any]) -> [String: Any] {
        let requested = (arguments["limit"] as? Int) ?? 50
        let limit = min(max(requested, 1), 200)
        let events = ContainmentIncidentTimeline.loadRecent(limit: limit)
        return textContentResult(MCPResponseFormatting.makeIncidentTimelinePayload(events: events))
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — read-only search over the process-exec
    /// recorder's local log (Pro). Never writes, never starts/stops the recorder.
    private static func callSearchExecEvents(arguments: [String: Any]) -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc(MCPExecRecorderTools.proRequiredMessage)], isError: true)
        }
        return textContentResult(MCPExecRecorderTools.search(arguments: arguments, defaults: sharedDefaults))
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — read-only process tree (ancestors and
    /// descendants) rebuilt from the process-exec recorder's local log (Pro).
    private static func callGetProcessTree(arguments: [String: Any]) -> [String: Any] {
        guard sharedDefaults.bool(forKey: "RoamSwitch.IsProCache") else {
            return textContentResult(["error": loc(MCPExecRecorderTools.proRequiredMessage)], isError: true)
        }
        guard let payload = MCPExecRecorderTools.processTree(arguments: arguments, defaults: sharedDefaults) else {
            return textContentResult(["error": loc("必須引数 'pid' が指定されていません。")], isError: true)
        }
        return textContentResult(payload)
    }

    /// SENDS NO NETWORK REQUESTS AT ALL — reads `network_history.json`
    /// directly (never instantiates `NetworkHistoryGuard.shared`, whose
    /// `observe` writes). Gateway MACs are reduced to counts before output.
    private static func callGetNetworkHistory(arguments: [String: Any]) -> [String: Any] {
        let requested = (arguments["limit"] as? Int) ?? 50
        let limit = min(max(requested, 1), 200)
        let snapshot = NetworkHistoryGuard.readSnapshot()
        let payload = MCPResponseFormatting.makeNetworkHistoryPayload(
            entries: snapshot.entries,
            lookalikes: snapshot.lookalikes,
            limit: limit
        )
        return textContentResult(payload)
    }

    private static func callGetGuardStatus() -> [String: Any] {
        let mac = GatewayFingerprint.currentGatewayMACAddress()
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: mac, defaults: sharedDefaults)
        return textContentResult(payload)
    }

    private static func callAuditURLSafety(arguments: [String: Any]) -> [String: Any] {
        guard let urlString = arguments["url"] as? String else {
            return textContentResult(["error": loc("必須引数 'url' が指定されていません。")], isError: true)
        }
        let report = LinkSafetyAuditor.shared.analyzeURL(urlString)
        let payload = MCPResponseFormatting.makeLinkAuditPayload(report: report)
        return textContentResult(payload)
    }

    private static func callGetAppHelp(arguments: [String: Any]) -> [String: Any] {
        let query = arguments["query"] as? String
        let topic = arguments["topic"] as? String
        // Explicit `language` wins when supported; otherwise the app's language
        // setting (English when that is an unsupported system language).
        let language = RoamSwitchKnowledgeBase.resolveLanguage(arguments["language"] as? String)
        let result = RoamSwitchKnowledgeBase.shared.search(query: query, topic: topic, language: language)
        return textContentResult(result)
    }

    // MARK: - Static catalogs

    /// The tool catalog, for tests that check what a client would be shown.
    static func toolDefinitionsForTesting() -> [[String: Any]] { toolDefinitions }

    private static let toolDefinitions: [[String: Any]] = [
        [
            "name": "get_security_report",
            "description": "Runs RoamSwitch's full local Mac security audit (FileVault, SIP, Gatekeeper, auto-update, XProtect, firewall, Wi-Fi encryption, ARP spoofing, exposed ports) and returns a scored report with per-item pass/fail status and localized recommendations for anything failing. Use this to answer 'is my Mac secure right now'.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_exposed_ports",
            "description": "Lists every TCP port currently listening on this Mac and, for each one exposed beyond localhost (including databases, dev servers, and local AI inference servers like Ollama:11434, LM Studio:1234, Gradio:7860, vLLM:8000), runs RoamSwitch's port security audit with risk levels and fix recommendations. Use this to answer 'what's exposed on my network' or 'is anything listening that shouldn't be'.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "includeLocalOnly": [
                        "type": "boolean",
                        "description": "Include localhost-only ports in the result (without the slower per-port audit). Defaults to false.",
                    ],
                ],
            ],
        ],
        [
            "name": "run_active_vuln_scan",
            "description": "UNLIKE EVERY OTHER TOOL ABOVE, THIS SENDS NETWORK REQUESTS. Three check families, all non-destructive, read-only, 127.0.0.1-only, single request with a short timeout, never touching another host: (1) known unauthenticated-by-default services already detected on this host — Redis, Memcached, MongoDB — verified with a protocol-appropriate probe (e.g. Redis PING); (2) generic checks against any detected local dev-server port — CORS misconfiguration (arbitrary Origin reflected with credentials allowed), path traversal (reading /etc/passwd via ../ to prove insufficient path validation), and open redirect (a handful of common parameter names like redirect/url/next tried against the root path, flagged only if the server actually redirects to our unregistered probe domain); (3) known-CVE version matching — when a Redis or Memcached instance is confirmed unauthenticated in (1), its version is read via a further non-destructive query (Redis INFO / Memcached stats) and checked against a small table of known CVEs (e.g. CVE-2022-24834 for Redis, CVE-2018-1000115 for Memcached) by version range only, never by sending an actual exploit payload. Disabled by default: requires the 'Active Vulnerability Verification' toggle enabled in RoamSwitch Settings, and refuses to run otherwise.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "run_package_cve_scan",
            "description": "UNLIKE run_active_vuln_scan, THIS SENDS NO NETWORK REQUESTS AT ALL. Enumerates installed Homebrew formulae (via `brew list --versions`) and checks each against a purely local, mechanically-generated known-CVE map pulled from NVD's real CVE API for a hand-curated formula\u{2192}CPE allowlist (real CVSS scores, real version ranges — never fabricated). Findings carry a `confidence` field: \"confirmed\" (the formula\u{2192}CPE mapping was individually hand-verified) or \"gray\" (an exact-keyword CPE match that was never hand-verified — treat as a possible false positive). The embedded baseline ships as a deliberately empty seed; until the daily updater installs real data, this reports mapInstalled: false and no findings, rather than fabricating results. No opt-in flag to check and nothing to confirm: a pure local inventory read has nothing to send anywhere.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "run_package_cve_scan_languages",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local files. Scans the given project folders for known dependency lockfiles (package-lock.json, requirements.txt, Pipfile.lock, poetry.lock, Cargo.lock, Gemfile.lock, composer.lock, go.sum, pom.xml) and checks each pinned dependency against a purely local, mechanically-generated known-CVE map per ecosystem (npm, PyPI, crates.io, RubyGems, Packagist, Go, Maven — CVSS >= 7.0, no recency cutoff, refreshed daily). Each ecosystem's embedded baseline ships as a deliberately empty seed; until the daily updater installs real data, no findings are reported for that ecosystem rather than fabricating results. Only a directly-pinned version counts as a match (e.g. an exact requirements.txt `==` pin, or a resolved lockfile entry) — an unpinned version range is never guessed at.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "watchedFolders": [
                        "type": "array",
                        "items": ["type": "string"],
                        "description": "Absolute paths to project folders to scan for lockfiles.",
                    ],
                ],
                "required": ["watchedFolders"],
            ],
        ],
        [
            "name": "run_package_lifecycle_script_scan",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local files, executes nothing. This is a plain inventory, NOT a threat verdict. Scans the given project folders' node_modules for package.json lifecycle scripts (preinstall/install/postinstall/prepare) that run unconditionally at `npm install` time and can execute arbitrary code (see the dev.to article on npm-install supply-chain risk this was inspired by). Each finding carries `isDangerPattern`: a lightweight, reference-only heuristic match against common risky shell patterns (curl|sh, wget|sh, eval(, base64 -d, node -e) — many legitimate scripts (native module rebuilds, setup wizards) also match, so this is never a definitive verdict. Only scans one level into node_modules (plus one extra level for @scope/ packages) — never descends into a dependency's own nested node_modules.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "watchedFolders": [
                        "type": "array",
                        "items": ["type": "string"],
                        "description": "Absolute paths to project folders whose node_modules should be scanned.",
                    ],
                ],
                "required": ["watchedFolders"],
            ],
        ],
        [
            "name": "run_typosquat_scan",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local files, contacts no registry. This is a reference-only heuristic, NOT a threat verdict. Checks each given project folder's package.json (dependencies/devDependencies/optionalDependencies) for names that are suspiciously close (Levenshtein edit distance 1-2) to a well-known popular npm package — the classic `expres`/`loadash`/`reactt` typosquatting attack, where a malicious package is published under a name a developer might mistype. The popular-package list is a static snapshot refreshed via the same daily signed manifest as the CVE maps, not a live registry query. A small allowlist (e.g. `preact`) suppresses the most common legitimate look-alikes, but it isn't exhaustive — some real findings can still be false positives. Only checks the project's own manifest, not node_modules (already-installed transitive dependencies).",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "watchedFolders": [
                        "type": "array",
                        "items": ["type": "string"],
                        "description": "Absolute paths to project folders whose package.json should be checked.",
                    ],
                ],
                "required": ["watchedFolders"],
            ],
        ],
        [
            "name": "run_npm_audit_signatures",
            "description": "THIS SENDS NETWORK REQUESTS TO THE NPM REGISTRY (registry.npmjs.org) — unlike every other package/CVE tool above. Runs `npm audit signatures` in the given directory to verify installed packages' registry signatures/provenance. Pro-only, and disabled by default even on Pro: requires the 'npm署名検証' (npm Signature Verification) toggle enabled in the Package CVE Scan window, and refuses to run otherwise. Returns npm's own raw command output verbatim (never hand-parsed into a rigid schema, since npm's exact wording isn't a contract this app controls) plus a lightweight `hasIssues` heuristic (non-zero exit code, or \"invalid\"/\"missing registry signature\" in the output).",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "directory": [
                        "type": "string",
                        "description": "Absolute path to the npm project directory to audit (must contain node_modules).",
                    ],
                ],
                "required": ["directory"],
            ],
        ],
        [
            "name": "audit_secrets",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local text/files. Scans for exposed API keys (OpenAI, Anthropic, GitHub, AWS, HuggingFace, Google AI/Gemini, Slack, Stripe), SSH/RSA private keys, and cryptocurrency wallet secrets (BIP39 seed phrases and Bitcoin WIF/BIP32 extended private keys, checksum-verified so ordinary text is never mistaken for one) with full masking, using regex plus Shannon entropy scoring. Pass either 'text' (a snippet) or 'path' (a file, or a directory to scan recursively).",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "text": [
                        "type": "string",
                        "description": "Text or code snippet to audit for secret leaks.",
                    ],
                    "path": [
                        "type": "string",
                        "description": "Absolute path to a file or directory to audit instead of 'text'. A directory is scanned recursively.",
                    ],
                ],
            ],
        ],
        [
            "name": "audit_security_logs",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only this Mac's own Unified Logging via `/usr/bin/log show`. Audits recent security-relevant log events (sudo failures, SSH connections, Gatekeeper blocks, XProtect detections, login/auth) over a time window and returns summary counts plus the individual events. Use this to answer 'has anything suspicious happened on this Mac recently'.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "hours": [
                        "type": "integer",
                        "description": "Time window in hours to audit. Defaults to 24.",
                    ],
                ],
            ],
        ],
        [
            "name": "get_quarantine_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only a local metadata file. Returns the malware quarantine vault's contents: each quarantined file's original path, the threat name ClamAV detected, when it was quarantined, and its size. Files are moved here (never deleted) by the Web/Mail download guard and on-demand ClamAV scans.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_notification_history",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns every notification RoamSwitch has sent over the past 7 days (timestamp, title, body), most recent first — real-time threat alerts (sendThreatAlert, e.g. the ClickFix clipboard guard, secret-leak detection, canary/port-anomaly/runtime-threat incidents) and Link Guard connection events. Use this to review what fired while the user wasn't watching, instead of relying on them to transcribe a live banner.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_canary_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults and disk state. Returns whether the Ransomware Canary Guard (Pro) is enabled, how many of its decoy bait files currently exist on disk (out of the expected set), and up to the 50 most recent detected incidents (each with timestamp, bait file name, detected action such as deletion/rename/tampering, suspected process if known, and any real user files that may also have been touched). Use this to answer 'has ransomware-like activity been detected on this Mac' — including during an Air-Gap network cutoff, since it reads local state only.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_ransomware_entropy_guard_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the general (non-canary-file-dependent) Ransomware Entropy Guard (Pro) is enabled, and up to the 50 most recent detected mass-encryption bursts (each with timestamp, best-effort suspected process, up to 50 affected file paths, and the average Shannon entropy observed). Unlike get_canary_status, this guard detects ransomware activity anywhere in the watched folders (Documents/Desktop/Downloads/Pictures), not only against a fixed set of decoy files — use it alongside get_canary_status for a fuller ransomware picture.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_forensic_evidence_bundles",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local disk state under ~/Library/Application Support/RoamSwitch/incident-evidence/. Lists up to the 20 most recent forensic evidence bundles RoamSwitch automatically captured alongside a ransomware/runtime-threat containment (process list snapshot, network connections snapshot, recently-modified files in the watched folders, and the suspected process's open files if one was identified) — each bundle's manifest is integrity-verifiable via per-artifact SHA-256. This does not include a packet capture or a full process memory/fd snapshot (unlike the Linux/roamswitch-os editions) — macOS has no unprivileged equivalent. No tool captures a NEW bundle on demand; bundles are only created automatically by the containment managers themselves.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_vulnerability_scan_history",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only the local heartbeat log run_active_vuln_scan itself writes to ~/Library/Application Support/RoamSwitch/active_vuln_scan_log.json. Returns the CURRENT STATUS of every probe this Mac has ever recorded a result for (one row per distinct probeName+port, most-stale first): probeName, port, the last outcome (vulnerable/safe/inconclusive), the ISO 8601 timestamp it was last checked, and passAgeDays — whole days since that check. There is no scheduled/background scanner, so passAgeDays reflects only however irregularly run_active_vuln_scan has actually been invoked; a probe with no row at all has simply never been checked, which this tool cannot distinguish from 'not applicable'. Same wire shape as the Linux edition's equivalent tool. Use this to answer 'what needs re-checking' rather than re-running the scan just to see what's stale.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_honeytoken_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Credential Honeytoken Guard (Pro) is enabled, and up to the 50 most recent detected accesses of a planted decoy credential file (~/.aws/credentials, ~/.ssh/id_rsa, ~/.docker/config.json — each with timestamp, kind, path, and best-effort suspected process). Any real access is a strong signal of active credential-harvesting reconnaissance (MITRE T1552) — this guard only notifies/records, it never triggers network containment the way the ransomware guards do.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_browser_credential_watch_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Browser Credential Watch Guard (Pro, opt-in, disabled by default) is enabled, and up to the 50 most recent detected non-browser accesses of a saved-password/session-cookie database (Chrome/Brave/Edge/Vivaldi/Chromium's Login Data/Cookies, Firefox's logins.json/key4.db/cookies.sqlite) — each with timestamp, path, and best-effort suspected process. A real hit (MITRE T1539) suggests credential-harvesting malware reading the browser's store directly off disk instead of through its APIs. Notify-only, never triggers containment.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_ransomware_recovery_snapshots",
            "description": "Pro only (returns an error when Pro is not active). SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state and asks the local `tmutil` which APFS local snapshots still exist; it creates, deletes and mounts nothing, and no MCP tool restores anything. Returns the ransomware recovery snapshots RoamSwitch has taken (newest first): id, kind, createdAt, whether it still exists on disk, and which one is recommended, plus the schedule (scheduledIntervalHours; 0 = off) and retentionMode. Kinds: `pre_damage` (taken on a schedule, independent of any detection — the ONLY kind to recover pre-encryption files from; the recommended one is the newest that still exists), `detection` (taken when the canary guard fired, so it may already contain files encrypted before the detection — NOT a recovery source), `manual`. retentionMode=true means a detection snapshot is newer than the last pre-damage one, so new scheduled snapshots and pruning are paused. macOS may delete local snapshots on its own after about 24 hours (sooner when space is low), hence `exists`. Recovery is always manual and file-level from the RoamSwitch Ransomware Recovery window (files are copied to ~/RoamSwitch-Recovered/<id>/; current files are never overwritten; no whole-volume restore; needs the helper to have Full Disk Access). Same JSON contract as the Linux edition's snapshot listing. Works during an Air-Gap.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_port_anomaly_incidents",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Port Anomaly Guard (Pro) is enabled, whether it has captured its baseline of known listening executables yet, which ports are currently auto-isolated from the LAN, and up to the 50 most recent detected incidents (each with timestamp, port, process name, PID, and executable path) — i.e. previously-unseen executables that suddenly started listening on an externally-exposed port and were auto-blocked. Use this to answer 'what triggered a port auto-block' or to triage a possible backdoor/C2 listener, including during an Air-Gap network cutoff. `incidents` is the only timestamped timeline in this response; `autoIsolatedPorts` is a present-tense snapshot of what's blocked right now and is NOT a log of recent events — a port can have been isolated at any point in the past, so do not attribute a port in it to a specific incident unless a timestamp in `incidents` actually corroborates it.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_runtime_threat_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Runtime Threat Containment guard (Pro) is enabled, whether this Mac is currently network-isolated (Air-Gapped) because of it, and the single most recent malware incident that triggered containment (timestamp, source process, category, severity, and Apple's detection message) — this guard fires when Apple's own XProtect malware engine actually convicts a file, and automatically air-gaps the network to limit damage. If an Air-Gap is currently active, this is one of the first tools to check to understand why — including from a local LLM during the network cutoff itself, since cloud AI clients are also severed at that point.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_incident_timeline",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only a local JSON file. Returns RoamSwitch's unified, chronological containment incident timeline (newest first) across ARP spoofing auto-containment, the Ransomware Canary Guard, Runtime Threat Containment (XProtect Air-Gap) and the Port Anomaly Guard. Each event has timestamp, source (stable id + localized sourceLabel), severity, summary, process name/PID when known, a MITRE ATT&CK technique ID only where confidently mappable (never guessed), the action taken (air_gap / port_block, + localized label) and resolution status (open / released / autoTimeout / allowlisted). ARP spoofing containment is recorded ONLY here — no other tool reports it. Additive to get_canary_status, get_port_anomaly_incidents and get_runtime_threat_status (use those for per-guard detail). Same name and shape as the Linux edition's get_incident_timeline. Works during an Air-Gap.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "limit": [
                        "type": "integer",
                        "description": "Maximum number of events to return, newest first (1-200). Defaults to 50.",
                    ],
                ],
            ],
        ],
        [
            "name": "search_exec_events",
            "description": "Pro only (returns an error when Pro is not active). SENDS NO NETWORK REQUESTS AT ALL — read-only search over RoamSwitch's local process-exec recorder log (macOS's own /usr/bin/eslogger exec events, recorded by the privileged helper into a root-owned, hash-chained JSON Lines log; the tool never writes and cannot start or stop the recorder). Returns matching exec events newest first: time, pid/ppid, executable path, command-line arguments (environment variables are never recorded; arguments can still contain secrets), cwd, code-signature class (platform = Apple, developer = signed with a Team ID, adhoc, unsigned), signing ID, Team ID, cdhash. Also returns the recorder state (running / needsFullDiskAccess / esloggerMissing / backoff / stopped, with a localized label) and counters (recorded, dropped, malformed, alerts). Limits: eslogger is a post-hoc observer (no blocking), needs Full Disk Access for RoamSwitchHelper, and events from before the recorder was enabled or the helper started do not exist; the log is root-only (it may contain secrets), so it is read through the running RoamSwitch app and its privileged helper — if the app is not running (or Pro / the helper is unavailable), logReadable=false and unavailableReason says why. Use this to answer 'what did this process run', 'was anything launched from /tmp', 'what did that installer execute'. Works during an Air-Gap.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "query": ["type": "string", "description": "Case-insensitive substring matched against the executable path, arguments, signing ID, Team ID and cwd."],
                    "pid": ["type": "integer", "description": "Only events of this process id."],
                    "ppid": ["type": "integer", "description": "Only events whose parent process id is this."],
                    "since": ["type": "string", "description": "Lower time bound: ISO-8601 or relative age such as 30m, 2h, 7d."],
                    "until": ["type": "string", "description": "Upper time bound: ISO-8601 or relative age such as 30m, 2h, 7d."],
                    "kind": ["type": "string", "enum": ["exec", "fork", "exit"], "description": "Event kind. Only exec is stored unless fork/exit persistence was enabled."],
                    "signature": ["type": "string", "enum": ["platform", "developer", "adhoc", "unsigned"], "description": "Only executables with this code-signature class."],
                    "teamID": ["type": "string", "description": "Only executables signed with this Apple Team ID."],
                    "limit": ["type": "integer", "description": "Maximum number of events (1-200). Defaults to 50."],
                ],
            ],
        ],
        [
            "name": "get_process_tree",
            "description": "Pro only (returns an error when Pro is not active). SENDS NO NETWORK REQUESTS AT ALL — read-only. Rebuilds the process tree around one pid from RoamSwitch's local process-exec recorder log: the chain of ancestors (root-most first), the process itself, and its descendants (breadth-first, depth-numbered), each with path, arguments, signature class and time. Only processes the recorder actually saw are known: a process that started before recording began simply ends the chain. pid reuse is disambiguated by time, so pass `at` (ISO-8601 or relative age like 2h) when asking about an old process. Same recorder state, limits and privacy caveats as search_exec_events (notify-only eslogger data, arguments may contain secrets). Works during an Air-Gap.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "pid": ["type": "integer", "description": "Process id to build the tree around (required)."],
                    "at": ["type": "string", "description": "Time the process was running: ISO-8601 or relative age such as 30m, 2h, 7d. Defaults to now."],
                    "lookbackHours": ["type": "integer", "description": "How far back to read the log before `at` (1-168). Defaults to 24."],
                ],
                "required": ["pid"],
            ],
        ],
        [
            "name": "get_network_history",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only a local JSON file. Summarizes RoamSwitch's cross-session network identity memory (its always-on Evil-Twin detector): each remembered Wi-Fi SSID with how many distinct gateway devices have answered for it and when it was last seen (gateway MAC addresses themselves are never returned), plus lookalikePairs — remembered SSIDs whose names are a suspicious near-miss of each other with no gateway device in common, i.e. past Evil-Twin access point candidates. Use this to answer 'have I joined a look-alike network' or 'have I used this Wi-Fi before'.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "limit": [
                        "type": "integer",
                        "description": "Maximum number of remembered networks to return, most recently seen first (1-200). Defaults to 50. lookalikePairs is always complete.",
                    ],
                ],
            ],
        ],
        [
            "name": "get_sensor_audit_results",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local files. Returns results from active audits this Mac has requested from a paired RoamSwitch Sensor (a separate product — software installed on the operator's own hardware on the same LAN, not a dedicated appliance — that performs external, active reachability verification against this Mac — a genuinely outside-in view, unlike every other tool in this file which inspects this Mac from the inside). Each result has a status (pending / completed / failed), how many pull attempts have been made (results are fetched asynchronously, up to 5 tries 5 minutes apart), when it was requested, and — once completed — the findings (port, title, recommendation) the Sensor found reachable/exposed from its vantage point. A `failed` result carries `failureReason`: `not_paired`/`invalid_signature` means the Sensor explicitly rejected the pull (most often this Mac was unpaired from the Sensor's side after the request was sent — re-pairing is needed, not a retry), `not_found` means the Sensor no longer has the request, `timed_out` means every pull attempt returned pending. `stale_timestamp` means this Mac's and the Sensor's clocks differ by more than 5 minutes, `replayed_nonce` means the Sensor saw the signed request as a replay, and `legacy_signature_refused` means the Sensor no longer accepts legacy signatures (these come from the Sensor's v2 signature checks). `pairedSensorCount` is how many Sensors are currently paired; 0 means Sensor pairing has never been set up. Use this to build an external-exposure picture as input to remediation planning, alongside get_exposed_ports (this Mac's own view of its listening ports) — the two are complementary, not redundant: this tool reflects what a real device on the LAN could actually reach, not just what this Mac believes it's listening on.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_guard_status",
            "description": "Reports the Settings on/off state of every RoamSwitch protection readable from its preferences — port anomaly auto-block, ARP spoofing auto-containment, USB keyboard/storage guards, Bluetooth guard, Web/Mail download guard (with AI Pickle model protection), DNS threat guard, runtime threat containment (XProtect Air-Gap), ransomware canary, ClickFix guard, process-exec recorder, Docker event guard, critical-path FIM, persistence monitor, gateway ARP lock, scheduled log audit, clipboard secret-leak auditor, Air-Gap auto Wi-Fi kill, WireGuard VPN, Tailscale kill-switch, Link Guard and its feed updates, active vuln scan opt-in — each flagged `usingDefault` when the user never toggled it. Also returns Link Guard mode (off / warn = pause and ask, blocked if unanswered / block), VPN backend (wireguard / tailscale), DNS threat guard provider and scope, isolated dev-server ports, USB storage allowlist size, the active security level and trusted-network status. Settings state only: Pro license state and live VPN tunnel / kill-switch state are not readable from this process. Use this to answer 'are my automatic protections turned on'.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "audit_url_safety",
            "description": "Analyzes an email link or web URL for phishing threats, homograph (Unicode spoofing) attacks, deceptive brand subdomains, high-risk TLDs, and unsafe HTTP plaintext without sending any data to external servers (Zero Telemetry). Each risk factor also carries a language-independent `kind` (e.g. homograph, brandSubdomainSpoofing, highRiskTLD) so results can be matched regardless of the user's UI language. Use this to inspect whether a link in an email, chat, or document is safe to click.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "url": [
                        "type": "string",
                        "description": "The URL string to inspect (e.g. 'https://apple.com.secure-login.xyz' or 'http://192.168.1.1/login').",
                    ],
                ],
                "required": ["url"],
            ],
        ],
        [
            "name": "get_app_help",
            "description": "Searches RoamSwitch's complete, authoritative knowledge base (written in ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt-PT; answers in the app's language unless 'language' is given; queries match in any language) covering every feature: network auto-switching & PF levels, network history / Evil Twin SSID detection, ARP spoofing auto-block, gateway ARP/NDP pinning, WireGuard/Tailscale VPN kill switch, emergency Air-Gap (Wi-Fi radio kill, 10-minute failsafe), unknown-port auto-block & dev/AI server isolation, active vuln scan, BadUSB keyboard guard with keystroke timing analysis, USB storage guard, ClamAV download quarantine & quarantine manager, Pickle model warning, DNS threat guard, Link Guard (system extension, DoH/SNI, JA3, fail-closed warn mode), ransomware canary with SIGSTOP freeze, XProtect-linked Air-Gap, ClickFix guard, LaunchAgent/Daemon persistence monitor, Docker privileged-container guard, critical-path FIM, log audit & scheduled template anomaly detection, incident timeline, notification history (EICAR recorded without alert), clipboard & secret leak auditor, package CVE scan, 18-item security audit, simulations, MCP setup, and license — plus settings guides (manual override durations, Pro default-on guards), troubleshooting, and advice for displayed alert banners or error messages. Use this to answer 'how does feature X work', 'what does this notification/alert mean', 'what should I do about message Y', or 'how do I configure Z'.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "query": [
                        "type": "string",
                        "description": "Natural language query, error message substring, alert text, or keyword to search (e.g. 'ARP', 'USB', 'canary', 'Ollama', 'API key', 'Pickle', 'Helper not connected', '127.0.0.1', 'ClamAV').",
                    ],
                    "topic": [
                        "type": "string",
                        "description": "Filter by topic: 'all' (default), 'feature', 'alert_message', 'setting', or 'troubleshooting'.",
                        "enum": ["all", "feature", "alert_message", "setting", "troubleshooting"],
                    ],
                    "language": [
                        "type": "string",
                        "description": "Optional response language: 'ja', 'en', 'zh-Hans', 'zh-Hant', 'ko', 'de', 'fr', 'es', 'it', or 'pt-PT' (tags like 'en-US' or 'zh-TW' are accepted). Defaults to the RoamSwitch app's language setting; unsupported values fall back to that, and an unsupported system language falls back to English.",
                    ],
                ],
            ],
        ],
    ]

    private static let resourceCatalog: [[String: Any]] = [
        [
            "uri": "roamswitch://docs/features",
            "name": "RoamSwitch Features Specification",
            "description": "Full technical specifications, defaults, and internal mechanics for every RoamSwitch security feature (network auto-switching & PF levels, Evil Twin SSID detection, ARP guard & gateway pinning, WireGuard/Tailscale VPN, emergency Air-Gap, port anomaly guard & dev server isolation, active vuln scan, BadUSB keyboard & USB storage guards, download quarantine & Pickle warning, DNS threat guard, Link Guard, ransomware canary, XProtect Air-Gap, ClickFix, persistence monitor, Docker guard, critical-path FIM, log audit, incident timeline, notification history, secret leak & package CVE scanners, 18-item audit, simulations, MCP, license), in the app's language.",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/alerts-and-messages",
            "name": "RoamSwitch Alert & Notification Advice Catalog",
            "description": "Catalog of all alert banners, notifications, and warning messages shown by RoamSwitch (ARP spoofing, Evil Twin Wi-Fi, port anomaly, exposed database, BadUSB & scripted keyboard, USB storage, download quarantine, EICAR, Pickle, Link Guard block/hold, ransomware, XProtect Air-Gap, Gatekeeper, ClickFix, persistence, Docker, file tampering, log audit anomalies, clipboard secrets, Air-Gap failure, helper, score drop), with exact causes, automated defenses, and recommended step-by-step user actions, in the app's language.",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/settings-guide",
            "name": "RoamSwitch Settings & Operations Guide",
            "description": "Step-by-step guidance for registered networks and protection levels, the away default level, manual override durations, guards Pro turns on by default, USB/BadUSB allowlists, watched folders, secure DNS policy, Link Guard modes, VPN backend (WireGuard/Tailscale), and language, in the app's language.",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/troubleshooting",
            "name": "RoamSwitch Troubleshooting & Technical FAQ",
            "description": "Authoritative guidance for Free vs Pro, helper disconnection and install location, ClamAV/Homebrew and blueutil setup, network cut off by Air-Gap, false positives (quarantine, Link Guard, blocked dev servers, keyboards), EICAR test behavior, system extension approval, VPN issues, repeated log audit alerts, MCP setup, and Zero Telemetry privacy design, in the app's language.",
            "mimeType": "text/markdown",
        ],
    ] + RoamSwitchMCPSkillsContent.catalogEntries.map { entry in
        ["uri": entry.uri, "name": entry.name, "description": entry.description, "mimeType": "text/markdown"]
    }
}
