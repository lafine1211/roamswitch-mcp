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

for f in "${CORE[@]}"; do
  { printf '%s\n' "$HEADER"; cat "$SRC/RoamSwitch/$f.swift"; } > "$DST/$f.swift"
done
{ printf '%s\n' "$HEADER"; cat "$SRC/RoamSwitchMCPServer/main.swift"; } > "$DST/main.swift"

echo "Synced ${#CORE[@]}+1 files from RoamSwitch $VER (build $BUILD)."
echo "Next: swift build -c release && git commit -am 'Sync from RoamSwitch $VER' && git tag v$VER"
