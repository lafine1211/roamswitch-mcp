# roamswitch-mcp

[![CI](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

The **read-only [MCP](https://modelcontextprotocol.io) server and the detection logic** behind
[RoamSwitch](https://lafine.net) — a macOS menu-bar app that automatically defends your Mac's
network boundary — published so you can read exactly what it computes and what it exposes to an
AI client.

This repository is a **verifiable mirror** of the corresponding source in the RoamSwitch app. It
is not the app: no privileged helper, no packet-filter (`pf`) control, no guards that actually
block traffic, no license or payment code, no UI. Just the code that *observes* and the code that
*answers questions over stdio*.

## What's here

| Area | Files |
| --- | --- |
| MCP stdio server (hand-rolled JSON-RPC 2.0) | `main.swift`, `MCPProtocol.swift`, `MCPResponseFormatting.swift` |
| Network trust / gateway fingerprint | `TrustedNetwork.swift`, `GatewayFingerprint.swift` |
| ARP spoofing detection | `ARPSpoofMonitor.swift` |
| Listening-port enumeration & audit | `ListeningPortMonitor.swift`, `PortSecurityAuditor.swift` |
| Wi-Fi encryption check | `WiFiSecurityMonitor.swift` |
| 10-point macOS security posture | `SecurityHealthChecker.swift` |
| Phishing / homograph / URL safety (offline) | `LinkSafetyAuditor.swift` |
| Bundled knowledge base (`get_app_help`) | `RoamSwitchKnowledgeBase.swift` |
| Localization plumbing | `AppLanguage.swift` |
| Tests | `Tests/roamswitch-mcpTests/` — mirrored unit tests + `StdioSmokeTests.swift` |

## Tools exposed (`tools/list`)

- `get_security_report` — FileVault / SIP / Gatekeeper / auto-update / XProtect / firewall /
  Wi-Fi encryption / ARP / exposed ports / guard config, scored with per-item advice.
- `get_exposed_ports` — every listening TCP port; those exposed beyond localhost are matched
  against a known-dangerous-service database and probed at `127.0.0.1:<port>` for CORS/headers.
- `get_guard_status` — on/off of RoamSwitch's Pro auto-response guards, current protection
  level, trusted-network state (read from the app's preferences domain — see *Standalone* below).
- `audit_url_safety` — phishing / Unicode homograph / brand-subdomain spoofing / high-risk TLD /
  plaintext HTTP. **Synchronous and fully offline**; the URL is sent nowhere.
- `get_app_help` — full-text search of the bundled knowledge base.

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

Tests (mirrored from the app's suite, plus an end-to-end stdio test that also
feeds the read loop hostile input):

```sh
swift test
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
(`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`) — setup at
<https://lafine.net/mcp-setup.html>.

## Standalone vs. bundled

Run inside the RoamSwitch app bundle, this code reads the app's live state. Built standalone from
this repo, two things differ:

- **`get_guard_status`** reads the `com.tetsuharu.RoamSwitch` preferences domain, which is empty
  for a binary that isn't the app — so it reports guards off / network untrusted.
- **Localization**: without the app's `.lproj` resources, `loc(_:)` falls back to the key, which
  is the Japanese source string. Output is otherwise identical.

Everything else — the ARP inspection, port scan, HTTP probe, posture checks, URL audit — runs
exactly the same, because it shells out to `arp`, `route`, `lsof`, `fdesetup`, `csrutil`,
`spctl`, `pfctl -sr`, and friends, and reads system state directly.

## Security properties

- **Read-only.** No API mutates anything.
- **No socket.** Reads one line from stdin, writes one line to stdout, exits when the client
  closes the pipe.
- **No telemetry, no outbound network** — except the local `127.0.0.1` probe in
  `get_exposed_ports`. `audit_url_safety` never touches the network.
- MIT licensed.

## This is a mirror — do not edit here

Every `.swift` file carries a header saying which RoamSwitch version it was mirrored from. The
**RoamSwitch app is the source of truth**; edits made here are not compiled into the shipping app
and are overwritten on the next sync. Each release of RoamSwitch is mirrored and tagged here so
the code can be checked against the shipping binary's symbols. See [`SYNC.md`](./SYNC.md).

## More

- Architecture & security whitepaper: <https://lafine.net/security.html> (§8 covers this server)
- The Swift client library for querying an installed RoamSwitch:
  [RoamSwitchKit](https://github.com/lafine1211/RoamSwitchKit)
