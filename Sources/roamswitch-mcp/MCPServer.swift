// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.7.1 (build 41).
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
                "serverInfo": ["name": "RoamSwitch Security Advisor", "version": "1.0.0"],
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
            case "audit_url_safety":
                return [result(id: id, callAuditURLSafety(arguments: arguments))]
            case "get_app_help":
                return [result(id: id, callGetAppHelp(arguments: arguments))]
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
        let arp = arpMonitor.inspectGateway(currentIP: ip, currentMAC: mac)
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
            "name": "get_guard_status",
            "description": "Reports whether RoamSwitch's optional Pro-tier auto-response guards (port anomaly auto-block, ARP spoofing auto-containment, USB storage auto-eject, Bluetooth guard, Web/Mail download guard with AI Pickle model protection, DNS threat guard) are turned on in Settings, plus the currently active security level and trusted-network status. Use this to answer 'are my automatic protections turned on'.",
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
