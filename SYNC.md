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

This is exactly the source set the app compiles into its `RoamSwitchMCPServer` target
(see `project.yml` in the app repo).

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
