# roamswitch-mcp

**English** | [日本語](README.ja.md)

[![CI](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

The **read-only [MCP](https://modelcontextprotocol.io) server and the detection logic** behind
[RoamSwitch](https://roamswitch.com) — a macOS menu-bar app that automatically defends your Mac's
network boundary — published so you can read exactly what it computes and what it exposes to an
AI client.

This repository is a **verifiable mirror** of the corresponding source in the RoamSwitch app. It
is not the app: no privileged helper, no packet-filter (`pf`) control, no guards that actually
block traffic, no license or payment code, no UI. Just the code that *observes* and the code that
*answers questions over stdio*.

## What's here

| Area | Files |
| --- | --- |
| MCP stdio server (hand-rolled JSON-RPC 2.0) | `main.swift`, `MCPProtocol.swift`, `MCPServer.swift`, `MCPResponseFormatting.swift` |
| Network trust / gateway fingerprint | `TrustedNetwork.swift`, `GatewayFingerprint.swift` |
| ARP spoofing detection | `ARPSpoofMonitor.swift` |
| Listening-port enumeration & audit | `ListeningPortMonitor.swift`, `PortSecurityAuditor.swift`, `ServiceSignatures.swift` |
| Wi-Fi encryption check | `WiFiSecurityMonitor.swift` |
| 18-point macOS security posture | `SecurityHealthChecker.swift` |
| Phishing / homograph / URL safety (offline) | `LinkSafetyAuditor.swift` |
| Secret / API-key leak scanning (offline) | `SecretLeakScanning.swift` |
| Unified-log security audit + log-template anomalies | `SecurityLogAuditor.swift`, `LogTemplateAnalyzer.swift` |
| Active vulnerability verification (`127.0.0.1` only, opt-in) | `ActiveVulnScan.swift`, `ActiveVulnCveMapData.swift` |
| Local, network-free CVE matching (Homebrew + lockfiles) | `PackageCveScan.swift`, `PackageCveMapData.swift`, `PackageCveScanLanguages.swift`, `PackageCveMapLanguagesData.swift` |
| Guard state readers (quarantine, canary, port anomaly, runtime threat, notifications, containment timeline, network history) | `QuarantineManager.swift`, `CanaryStatusReader.swift`, `PortAnomalyStatusReader.swift`, `RuntimeThreatStatusReader.swift`, `NotificationHistory.swift`, `ContainmentIncidentTimeline.swift`, `NetworkHistoryGuard.swift` |
| Bundled knowledge base (`get_app_help`) | `RoamSwitchKnowledgeBase.swift` |
| Localization plumbing | `AppLanguage.swift` |
| Tests | `Tests/roamswitch-mcpTests/` — mirrored unit tests + `StdioSmokeTests.swift` |

## Tools exposed (`tools/list`)

31 tools (the length of `toolDefinitions` in `MCPServer.swift`, which is what `tools/list` returns).
Every one is read-only. `get_exposed_ports` and the opt-in `run_active_vuln_scan` are pinned to
`127.0.0.1`; the one tool that contacts an external host is the opt-in, Pro-only
`run_npm_audit_signatures`, which runs `npm audit signatures` against the npm registry. The
diagnostic tools (`get_security_report`, `verify_security_findings`, `get_exposed_ports`,
`get_guard_status`) may send one ICMP ping to the default gateway on the LAN to look up its MAC
address.

### Posture & network

- `get_security_report` — the full 18-point macOS posture audit (FileVault, SIP, Gatekeeper,
  auto-update, XProtect, firewall, stealth mode, Wi-Fi encryption, ARP spoofing, gateway ARP
  pinning, SSH, sudo `NOPASSWD`, exposed ports, download/DNS/link protection, USB &
  accessory guards), scored with per-item advice. An item that could not be measured reliably
  carries an optional language-independent `inconclusiveReason` (e.g. `no_baseline`,
  `location_unavailable`): its `isPassed` / `statusText` may look healthy but are not confirmed.
- `verify_security_findings` — re-checks, right now, whether specific findings from
  `get_security_report` are still present (optional `checkIds`, default all). Each result is
  `stillPresent`, `resolved` or `inconclusive` with a language-independent `reason`; read-only,
  never fixes anything, contacts no external host (it may send one ICMP ping to the default gateway
  on the LAN to look up its MAC address). Items decided by RoamSwitch's own settings
  (`host_firewall`, `network_stealth_mode`, `gateway_arp_lock`, `malware_scanning`,
  `dns_threat_guard`, `usb_zero_trust`) reflect those in-app settings, not a re-measurement of the
  OS state. `arp_spoof_monitor` is `resolved` only when the gateway MAC matches a registered
  trusted network; otherwise it is `inconclusive` (`no_baseline`).
- `get_exposed_ports` — every listening TCP port; those exposed beyond localhost are matched
  against a known-dangerous-service database (Redis, MongoDB, …, plus local AI inference
  servers such as Ollama:11434, LM Studio:1234, Gradio:7860, vLLM:8000) and probed at
  `127.0.0.1:<port>` for CORS/headers.
- `get_guard_status` — on/off of all 22 guard settings (port anomaly, ARP containment, USB, Bluetooth,
  download/DNS guards, runtime threat, ransomware canary, ClickFix, Docker events, critical-path FIM,
  persistence monitor, gateway ARP lock, scheduled log audit, clipboard secret-leak auditor, Air-Gap
  Wi-Fi kill, WireGuard / Tailscale kill-switch, Link Guard + feed updates, active vuln scan), each
  flagged `usingDefault` when never toggled; plus Link Guard mode, VPN backend, DNS threat guard
  provider/scope, isolated dev-server ports, USB storage allowlist size, current protection level
  and trusted-network state (read from the app's preferences domain — see *Standalone* below).
  Settings only: live VPN tunnel state lives in the privileged helper and is not reported.

### Offline auditing

- `audit_url_safety` — phishing / Unicode homograph / brand-subdomain spoofing / high-risk TLD /
  plaintext HTTP. **Synchronous and fully offline**; the URL is sent nowhere and is never fetched.
  Each risk factor carries a language-independent `kind` (e.g. `homograph`).
- `audit_secrets` — API keys (OpenAI, Anthropic, GitHub, AWS, HuggingFace, Google AI/Gemini,
  Slack, Stripe) and SSH/RSA private keys in a string, a file, or a directory tree, via regex
  plus Shannon-entropy scoring. Matches are masked in the output.
- `audit_security_logs` — recent security events from this Mac's own Unified Log
  (`log show`): sudo failures, SSH connections, Gatekeeper blocks, XProtect detections,
  login/auth. Every message is masked for keys/tokens before it leaves the process, and
  log-template anomalies (never-before-seen patterns, statistical frequency spikes) are
  reported alongside the counts.
- `get_app_help` — full-text search of the bundled knowledge base.
- `audit_mcp_configs` — reads the MCP client configuration files in their well-known per-user
  locations (Claude Desktop, Claude Code, Cursor, Windsurf, VS Code, Cline, Gemini CLI) plus the
  project-level `.mcp.json` files in registered folders, and flags risky entries: auto-approved
  tools, plaintext `http://` servers on a non-loopback host, shell one-liner launch commands,
  entries pointing at HexStrike AI, group/world-writable config files and Claude Code's
  `enableAllProjectMcpServers`. Never returns env or header values or arguments. No network.

### Vulnerability & CVE

- `run_active_vuln_scan` — **the only tool that sends verification probes.** Non-destructive,
  read-only, `127.0.0.1`-only, one short-timeout request per check, never another host:
  unauthenticated-by-default services already detected here (Redis/Memcached/MongoDB) verified
  with a protocol-appropriate probe; CORS misconfiguration / path traversal / open redirect
  against detected dev-server ports; and version-range-only known-CVE matching (never an
  exploit payload). **Off by default** — refuses to run until the user enables *Active
  Vulnerability Verification* in RoamSwitch's settings.
- `run_package_cve_scan` — installed Homebrew formulae vs. a purely local, mechanically
  generated CVE map built from real NVD data. No network.
- `run_package_cve_scan_languages` — dependency lockfiles (`package-lock.json`,
  `requirements.txt`, `Pipfile.lock`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`,
  `composer.lock`, `go.sum`, `pom.xml`) in the given folders vs. the same local map. No network.
- `run_package_lifecycle_script_scan` — inventory of `package.json` lifecycle scripts
  (preinstall / install / postinstall / prepare) in the given folders' `node_modules`, each with
  a reference-only `isDangerPattern` flag. A list, not a threat verdict. No network, executes
  nothing. Pro.
- `run_typosquat_scan` — dependency names in `package.json` within edit distance 1-2 of a
  well-known npm package (`expres`, `loadash`, …). Reference-only heuristic against a static
  list; some hits are false positives. No network. Pro.
- `run_npm_audit_signatures` — runs `npm audit signatures` to verify installed packages'
  registry signatures and provenance and returns npm's output verbatim. **Contacts the npm
  registry.** Pro, and off by default until the toggle in the Package CVE Scan window is on.
- `get_vulnerability_scan_history` — last outcome (vulnerable / safe / inconclusive) of every
  probe `run_active_vuln_scan` has recorded, with the days since it was checked. No network.

### Incident state (works during an Air-Gap)

These read local state only, so an AI client backed by a local model can still triage while
RoamSwitch has severed the network.

- `get_runtime_threat_status` — whether this Mac is currently Air-Gapped because Apple's
  XProtect convicted a file, and the incident that triggered it. **Check this first to explain
  an active Air-Gap.**
- `get_canary_status` — Ransomware Canary Guard: decoy bait-file counts and up to the 50 most
  recent incidents.
- `get_port_anomaly_incidents` — Port Anomaly Guard: baseline state, currently auto-isolated
  ports, and up to the 50 most recent incidents (previously-unseen executables that began
  listening on an externally-exposed port).
- `get_quarantine_status` — the malware quarantine vault: original path, ClamAV threat name,
  timestamp and size per quarantined file. Files are moved here, never deleted.
- `get_notification_history` — every notification RoamSwitch sent in the past 7 days, newest
  first.
- `get_incident_timeline` — one chronological view across ARP-spoof auto-containment, the
  Ransomware Canary Guard, Runtime Threat Containment and the Port Anomaly Guard: source,
  severity, summary, process, MITRE ATT&CK ID (only where confidently mappable), action taken,
  and open/released/allowlisted status. ARP-spoof containment is recorded only here. Same name
  as the Linux edition's tool.
- `get_network_history` — the always-on Evil-Twin detector's memory: remembered SSIDs with a
  gateway-device *count* and last-seen time (MAC addresses are never returned), plus look-alike
  SSID pairs that never shared a gateway.
- `get_ransomware_entropy_guard_status` — Ransomware Entropy Guard state and up to the 50 most
  recent mass-encryption bursts in the watched folders. Pro.
- `get_ransomware_recovery_snapshots` — ransomware-recovery snapshots (kind, still on disk,
  recommended) and the schedule. Read-only: nothing can be restored through MCP. Pro.
- `get_forensic_evidence_bundles` — up to the 20 most recent evidence bundles captured
  automatically during a containment, each verifiable by per-artifact SHA-256.
- `get_honeytoken_status` — Credential Honeytoken Guard state and up to the 50 most recent
  accesses of a planted decoy credential file. Pro.
- `get_browser_credential_watch_status` — Browser Credential Watch state and up to the 50 most
  recent non-browser reads of a saved-password or cookie database. Pro, opt-in.
- `search_exec_events` — search of the process-exec recorder log (eslogger). Read-only;
  secrets in arguments are masked best-effort. Pro.
- `get_process_tree` — ancestor / descendant process tree around one pid, rebuilt from the same
  recorder log. Pro.
- `get_sensor_audit_results` — results of outside-in reachability audits requested from a paired
  RoamSwitch Sensor.

### Resources (`resources/list`)

Four `roamswitch://docs/*` documents an AI client can pull in as context: the feature
specification, the alert & notification catalog, the settings & operations guide, and the
troubleshooting FAQ.

There is **no** tool that changes anything: no lockdown toggle, no port isolation, no device
eject. That surface does not exist in this code, by design (§8 of the whitepaper).

## Build & run

```sh
swift build -c release
./.build/release/roamswitch-mcp
```

Quick check:

```sh
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | ./.build/release/roamswitch-mcp
```

Tests — mirrored unit tests, an end-to-end stdio test, adversarial-input tests
for the JSON-RPC parser and the `lsof`/`arp` parsers, and mutation fuzzing.
See [`SECURITY_TESTING.md`](./SECURITY_TESTING.md).

```sh
swift test
FUZZ_ITERATIONS=200000 swift test --filter MutationFuzzTests   # longer fuzz run
```

### Use from an MCP client

```jsonc
// Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json
{
  "mcpServers": {
    "roamswitch": {
      "command": "/absolute/path/to/roamswitch-mcp/.build/release/roamswitch-mcp"
    }
  }
}
```

If you have RoamSwitch installed, prefer the binary it ships
(`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`) — setup for Claude Desktop,
Claude Code, Codex CLI, OpenCode and Antigravity at <https://roamswitch.com/mcp-setup.html>.

## Standalone vs. bundled

Run inside the RoamSwitch app bundle, this code reads the app's live state. Built standalone from
this repo, four things differ:

- **`get_guard_status`** reads the `com.tetsuharu.RoamSwitch` preferences domain, which is empty
  for a binary that isn't the app — so it reports guards off / network untrusted.
- **The incident-state tools** (`get_canary_status`, `get_port_anomaly_incidents`,
  `get_runtime_threat_status`, `get_notification_history`, `get_quarantine_status`) read the same
  preferences domain and the app's quarantine vault, so standalone they report "not enabled" with
  empty history rather than failing.
- **`get_incident_timeline` / `get_network_history`** read JSON files under
  `~/Library/Application Support/RoamSwitch/`, so they show the real history when RoamSwitch is
  installed for the same user, and empty results otherwise.
- **Localization**: without the app's `.lproj` resources, `loc(_:)` falls back to the key, which
  is the Japanese source string. Output is otherwise identical.

Everything else — the ARP inspection, port scan, HTTP probe, posture checks, URL audit, secret
scan, log audit, CVE matching — runs exactly the same, because it shells out to `arp`, `route`,
`lsof`, `fdesetup`, `csrutil`, `spctl`, `pfctl -sr`, `log show`, `brew`, and friends, and reads
system state directly.

## Security properties

- **Read-only.** No API mutates anything.
- **No socket.** Reads one line from stdin, writes one line to stdout, exits when the client
  closes the pipe.
- **No telemetry, no outbound traffic to external hosts** — except the opt-in, Pro-only
  `run_npm_audit_signatures` (npm registry). Local-only traffic: the `127.0.0.1` probe in
  `get_exposed_ports`, the opt-in, off-by-default `run_active_vuln_scan` (also `127.0.0.1`-only),
  and the single ICMP ping to the LAN's default gateway that the diagnostic tools may send to look
  up its MAC address. `audit_url_safety` never touches the network and never fetches the URL.
- MIT licensed.

## This is a mirror — do not edit here

Every `.swift` file carries a header saying which RoamSwitch version it was mirrored from. The
**RoamSwitch app is the source of truth**; edits made here are not compiled into the shipping app
and are overwritten on the next sync. Each release of RoamSwitch is mirrored and tagged here so
the code can be checked against the shipping binary's symbols. See [`SYNC.md`](./SYNC.md).

## More

- Architecture & security whitepaper: <https://roamswitch.com/security.html> (§8 covers this server)
- The Swift client library for querying an installed RoamSwitch:
  [RoamSwitchKit](https://github.com/lafine1211/RoamSwitchKit)
- The Linux edition ships its own MCP server (`roamswitch-mcp`, 36 tools) and an async Rust
  client, [roamswitch-linux-kit](https://github.com/lafine1211/roamswitch-linux-kit).
