// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.17 (build 74).
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
                "instructions": "Read-only, fully local (no network calls) access to RoamSwitch's Mac security diagnostics, comprehensive feature specifications, alert message advice, and operational guides. Use 'get_app_help' or read 'roamswitch://docs/...' resources for in-depth documentation. Cannot change security level, isolate ports, or eject devices.",
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
            if let content = RoamSwitchKnowledgeBase.shared.resource(for: uri) {
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
            case "get_notification_history":
                return [result(id: id, callGetNotificationHistory())]
            case "get_port_anomaly_incidents":
                return [result(id: id, callGetPortAnomalyIncidents())]
            case "get_runtime_threat_status":
                return [result(id: id, callGetRuntimeThreatStatus())]
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
        let findings = ActiveVulnScan.runScan(ports: ports)
        let targetCount = ports.filter { port in
            !ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath).isEmpty
                || PortSecurityAuditor.isKnownDevServerPort(port.port)
        }.count

        let payload = MCPActiveVulnScanResultPayload(
            enabled: true,
            scannedTargetCount: targetCount,
            findings: findings.map {
                MCPActiveVulnScanFindingPayload(
                    port: $0.port,
                    processName: $0.processName,
                    title: $0.title,
                    description: $0.description,
                    recommendation: $0.recommendation
                )
            },
            message: "Scan complete."
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

    /// SENDS NO NETWORK REQUESTS AT ALL — reads only local text/files.
    private static func callAuditSecrets(arguments: [String: Any]) -> [String: Any] {
        let findings: [SecretLeakScanning.SecretFinding]
        if let pathStr = arguments["path"] as? String {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: pathStr, isDirectory: &isDir) else {
                return textContentResult(["error": "path not found: \(pathStr)"], isError: true)
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
            return textContentResult(["error": "Provide either 'text' or 'path'"], isError: true)
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

    /// SENDS NO NETWORK REQUESTS AT ALL — reads local UserDefaults state
    /// only. `PortAnomalyGuard` is Pro-only, but the read itself doesn't
    /// gate on license status — an unlicensed install simply has an empty,
    /// disabled history, same as any other guard's status tool.
    private static func callGetPortAnomalyIncidents() -> [String: Any] {
        let status = PortAnomalyStatusReader.currentStatus(defaults: sharedDefaults)
        let incidents = PortAnomalyStatusReader.persistedIncidents(defaults: sharedDefaults)
        let iso = ISO8601DateFormatter()
        let payload = MCPPortAnomalyIncidentsPayload(
            isEnabled: status.isEnabled,
            baselineCaptured: status.baselineCaptured,
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

    private static func callGetGuardStatus() -> [String: Any] {
        let mac = GatewayFingerprint.currentGatewayMACAddress()
        let payload = MCPResponseFormatting.makeGuardStatusPayload(gatewayMAC: mac, defaults: sharedDefaults)
        return textContentResult(payload)
    }

    private static func callAuditURLSafety(arguments: [String: Any]) -> [String: Any] {
        guard let urlString = arguments["url"] as? String else {
            return textContentResult(["error": "Missing required argument 'url'"], isError: true)
        }
        let report = LinkSafetyAuditor.shared.analyzeURL(urlString)
        let payload = MCPResponseFormatting.makeLinkAuditPayload(report: report)
        return textContentResult(payload)
    }

    private static func callGetAppHelp(arguments: [String: Any]) -> [String: Any] {
        let query = arguments["query"] as? String
        let topic = arguments["topic"] as? String
        let result = RoamSwitchKnowledgeBase.shared.search(query: query, topic: topic)
        return textContentResult(result)
    }

    // MARK: - Static catalogs

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
            "name": "audit_secrets",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local text/files. Scans for exposed API keys (OpenAI, Anthropic, GitHub, AWS, HuggingFace, Google AI/Gemini, Slack, Stripe) and SSH/RSA private keys with masking, using regex plus Shannon entropy scoring. Pass either 'text' (a snippet) or 'path' (a file, or a directory to scan recursively).",
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
            "name": "get_port_anomaly_incidents",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Port Anomaly Guard (Pro) is enabled, whether it has captured its baseline of known listening executables yet, which ports are currently auto-isolated from the LAN, and up to the 50 most recent detected incidents (each with timestamp, port, process name, PID, and executable path) — i.e. previously-unseen executables that suddenly started listening on an externally-exposed port and were auto-blocked. Use this to answer 'what triggered a port auto-block' or to triage a possible backdoor/C2 listener, including during an Air-Gap network cutoff.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_runtime_threat_status",
            "description": "SENDS NO NETWORK REQUESTS AT ALL — reads only local UserDefaults state. Returns whether the Runtime Threat Containment guard (Pro) is enabled, whether this Mac is currently network-isolated (Air-Gapped) because of it, and the single most recent malware incident that triggered containment (timestamp, source process, category, severity, and Apple's detection message) — this guard fires when Apple's own XProtect malware engine actually convicts a file, and automatically air-gaps the network to limit damage. If an Air-Gap is currently active, this is one of the first tools to check to understand why — including from a local LLM during the network cutoff itself, since cloud AI clients are also severed at that point.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "get_guard_status",
            "description": "Reports whether RoamSwitch's optional Pro-tier auto-response guards (port anomaly auto-block, ARP spoofing auto-containment, USB keyboard/storage auto-eject, Bluetooth guard, Web/Mail download guard with AI Pickle model protection, DNS threat guard, runtime threat containment / XProtect Air-Gap) are turned on in Settings, plus the currently active security level and trusted-network status. Use this to answer 'are my automatic protections turned on'.",
            "inputSchema": ["type": "object", "properties": [String: Any]()],
        ],
        [
            "name": "audit_url_safety",
            "description": "Analyzes an email link or web URL for phishing threats, homograph (Unicode spoofing) attacks, deceptive brand subdomains, high-risk TLDs, and unsafe HTTP plaintext without sending any data to external servers (Zero Telemetry). Use this to inspect whether a link in an email, chat, or document is safe to click.",
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
            "description": "Searches RoamSwitch's complete, authoritative knowledge base covering all features (PF packet filter, ARP spoofing, USB storage guard, dev/AI server isolation, ClamAV quarantine, Pickle model download guard, secret leak prevention, DNS threat guard, ransomware canary, Bluetooth guard), settings guides, troubleshooting, and advice for displayed alert banners or error messages. Use this to answer 'how does feature X work', 'what does this notification/alert mean', 'what should I do about message Y', or 'how do I configure Z'.",
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
                ],
            ],
        ],
    ]

    private static let resourceCatalog: [[String: Any]] = [
        [
            "uri": "roamswitch://docs/features",
            "name": "RoamSwitch Features Specification",
            "description": "Full technical specifications and internal mechanics for all RoamSwitch security features (PF packet filter, ARP guard, USB storage guard, dev server isolation, download quarantine, DNS threat guard, ransomware canary, Bluetooth guard).",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/alerts-and-messages",
            "name": "RoamSwitch Alert & Notification Advice Catalog",
            "description": "Catalog of all alert banners, notifications, and warning messages shown by RoamSwitch, with exact causes, automated defenses, and recommended step-by-step user actions.",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/settings-guide",
            "name": "RoamSwitch Settings & Operations Guide",
            "description": "Step-by-step guidance for configuring network tiers, manual overrides, USB whitelists, watched folders, and secure DNS policies.",
            "mimeType": "text/markdown",
        ],
        [
            "uri": "roamswitch://docs/troubleshooting",
            "name": "RoamSwitch Troubleshooting & Technical FAQ",
            "description": "Authoritative guidance for helper disconnection, ClamAV/Homebrew setup, blueutil configuration, false-positive handling, and Zero Telemetry privacy design.",
            "mimeType": "text/markdown",
        ],
    ]
}
