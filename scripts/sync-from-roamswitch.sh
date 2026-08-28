#!/bin/bash
# Re-mirror the MCP server + detection logic from the RoamSwitch app repo.
#
# Usage: ./scripts/sync-from-roamswitch.sh [/path/to/RoamSwitch]
#   defaults to ../RoamSwitch
#
# See SYNC.md. After running: `swift build -c release` must succeed, then commit
# and tag this repo with the same version as the RoamSwitch release.
set -euo pipefail

SRC="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../RoamSwitch" && pwd)}"
DST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Sources/roamswitch-mcp"

[ -f "$SRC/RoamSwitch/Info.plist" ] || { echo "Not a RoamSwitch checkout: $SRC" >&2; exit 1; }

VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$SRC/RoamSwitch/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$SRC/RoamSwitch/Info.plist")

read -r -d '' HEADER <<EOF || true
// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch $VER (build $BUILD).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────

EOF

# The source set the app's RoamSwitchMCPServer target compiles (project.yml).
CORE=(AppLanguage TrustedNetwork GatewayFingerprint WiFiSecurityMonitor \
      ARPSpoofMonitor ListeningPortMonitor PortSecurityAuditor SecurityHealthChecker \
      LinkSafetyAuditor RoamSwitchKnowledgeBase MCPResponseFormatting MCPProtocol)

# App test files that only exercise types present in this repo. Their
# `@testable import RoamSwitch` is rewritten to this package's module name.
# (Tests for app-only guards — PortAnomalyGuard, RansomwareCanaryGuard, etc. —
# are intentionally not mirrored.) StdioSmokeTests.swift is specific to this
# repo and is not touched by the sync.
TESTS=(LinkSafetyAuditorTests MCPKnowledgeBaseTests MCPProtocolTests \
       MCPResponseFormattingTests ARPSpoofMonitorTests MCPServerRobustnessTests ParserRobustnessTests)

TDST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Tests/roamswitch-mcpTests"

for f in "${CORE[@]}"; do
  { printf '%s\n' "$HEADER"; cat "$SRC/RoamSwitch/$f.swift"; } > "$DST/$f.swift"
done
for f in main MCPServer; do
  { printf '%s\n' "$HEADER"; cat "$SRC/RoamSwitchMCPServer/$f.swift"; } > "$DST/$f.swift"
done

for f in "${TESTS[@]}"; do
  { printf '// Mirrored from RoamSwitchTests/ — RoamSwitch %s (build %s). Do not edit here; see SYNC.md.\n\n' "$VER" "$BUILD"
    sed 's/@testable import RoamSwitch/@testable import roamswitch_mcp/' "$SRC/RoamSwitchTests/$f.swift"; } > "$TDST/$f.swift"
done

echo "Synced $((${#CORE[@]}+2)) source files and ${#TESTS[@]} test files from RoamSwitch $VER (build $BUILD)."
echo "Next: swift test && git commit -am 'Sync from RoamSwitch $VER' && git tag v$VER"
