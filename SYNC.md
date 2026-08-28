# Sync policy

This repository **mirrors** source from the private RoamSwitch app repository. The app is the
source of truth. This copy exists so the MCP server and detection logic can be read and audited
independently; it is not developed here.

## Why a copy and not a package dependency

The alternative — extracting these files into a SwiftPM package that the app also consumes — would
couple the shipping app's build to this public repository (a force-push, bad tag, or GitHub outage
would break app builds) and would require turning app-internal code into a stable public API. A
mirror keeps the app independent and lets each publish be reviewed as a snapshot. The tradeoff is
drift, mitigated by the rules below.

## File map

All files live in `Sources/roamswitch-mcp/`.

| This repo | RoamSwitch app repo |
| --- | --- |
| `main.swift` | `RoamSwitchMCPServer/main.swift` |
| `AppLanguage.swift` | `RoamSwitch/AppLanguage.swift` |
| `TrustedNetwork.swift` | `RoamSwitch/TrustedNetwork.swift` |
| `GatewayFingerprint.swift` | `RoamSwitch/GatewayFingerprint.swift` |
| `WiFiSecurityMonitor.swift` | `RoamSwitch/WiFiSecurityMonitor.swift` |
| `ARPSpoofMonitor.swift` | `RoamSwitch/ARPSpoofMonitor.swift` |
| `ListeningPortMonitor.swift` | `RoamSwitch/ListeningPortMonitor.swift` |
| `PortSecurityAuditor.swift` | `RoamSwitch/PortSecurityAuditor.swift` |
| `SecurityHealthChecker.swift` | `RoamSwitch/SecurityHealthChecker.swift` |
| `LinkSafetyAuditor.swift` | `RoamSwitch/LinkSafetyAuditor.swift` |
| `RoamSwitchKnowledgeBase.swift` | `RoamSwitch/RoamSwitchKnowledgeBase.swift` |
| `MCPResponseFormatting.swift` | `RoamSwitch/MCPResponseFormatting.swift` |
| `MCPProtocol.swift` | `RoamSwitch/MCPProtocol.swift` |
| `MCPServer.swift` | `RoamSwitch/MCPServer.swift` |

This is exactly the source set the app compiles into its `RoamSwitchMCPServer` target
(see `project.yml` in the app repo).

`MCPServer.swift` (the pure parse/dispatch) lives in `RoamSwitch/`, compiled into both
the app and the `RoamSwitchMCPServer` targets, so the app's own test suite can reach it
via `@testable import RoamSwitch`. Only `main.swift` (the stdin→stdout pump) is
`RoamSwitchMCPServer/`-only.

> Between RoamSwitch releases this mirror can be **ahead** of the last publicly
> distributed build — it follows the app's `main` and is tagged with the
> version in the source tree. The per-file header names that version.

### Tests

`Tests/roamswitch-mcpTests/` mirrors the app test files whose subjects live in this repo, with
`@testable import RoamSwitch` rewritten to `@testable import roamswitch_mcp`:

| This repo | RoamSwitch app repo |
| --- | --- |
| `LinkSafetyAuditorTests.swift` | `RoamSwitchTests/LinkSafetyAuditorTests.swift` |
| `MCPKnowledgeBaseTests.swift` | `RoamSwitchTests/MCPKnowledgeBaseTests.swift` |
| `MCPProtocolTests.swift` | `RoamSwitchTests/MCPProtocolTests.swift` |
| `MCPResponseFormattingTests.swift` | `RoamSwitchTests/MCPResponseFormattingTests.swift` |
| `ARPSpoofMonitorTests.swift` | `RoamSwitchTests/ARPSpoofMonitorTests.swift` |
| `MCPServerRobustnessTests.swift` | `RoamSwitchTests/MCPServerRobustnessTests.swift` |
| `ParserRobustnessTests.swift` | `RoamSwitchTests/ParserRobustnessTests.swift` |
| `StdioSmokeTests.swift` | **not mirrored** — specific to this repo (drives the built binary over stdio) |
| `MutationFuzzTests.swift` | **not mirrored** — specific to this repo |

App tests for guards that are not in this repo (`PortAnomalyGuardTests`, `RansomwareCanaryGuardTests`,
`WebMailDownloadGuardTests`, `DNSThreatGuardTests`, `DangerousPortExposureTests`) are not mirrored.

## Rules

1. **Never hand-edit `Sources/roamswitch-mcp/*.swift`.** Change the app instead.
2. On each RoamSwitch release, run the sync and tag this repo with the same version:

   ```sh
   ./scripts/sync-from-roamswitch.sh /path/to/RoamSwitch
   swift build -c release            # must succeed
   git commit -am "Sync from RoamSwitch <version>"
   git tag v<version>
   ```
3. The per-file header must always name the RoamSwitch version it came from.
4. If the app's `RoamSwitchMCPServer` source set changes, update the list in
   `scripts/sync-from-roamswitch.sh` and the table above.
