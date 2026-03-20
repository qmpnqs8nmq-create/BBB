#!/bin/zsh
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <snapshot-dir>"
  echo "Example: $0 ~/Desktop/openclaw-manual-snapshots/2026-03-18-124800"
  exit 1
fi
SNAP="$1"
echo "Restore hints for snapshot: $SNAP"
echo
echo "1) Restore config only:"
echo "   cp \"$SNAP/.openclaw/openclaw.json\" \"$HOME/.openclaw/openclaw.json\""
echo
echo "2) Restore LaunchAgents:"
echo "   cp \"$SNAP/LaunchAgents/ai.openclaw.gateway.plist\" \"$HOME/Library/LaunchAgents/\" 2>/dev/null || true"
echo "   cp \"$SNAP/LaunchAgents/ai.openclaw.lan8888-proxy.plist\" \"$HOME/Library/LaunchAgents/\" 2>/dev/null || true"
echo
echo "3) Restore a workspace file example:"
echo "   cp \"$SNAP/.openclaw/workspace/scripts/https_lan_proxy_8888.js\" \"$HOME/.openclaw/workspace/scripts/\""
echo
echo "4) Restart gateway after config changes:"
echo "   openclaw gateway restart"
