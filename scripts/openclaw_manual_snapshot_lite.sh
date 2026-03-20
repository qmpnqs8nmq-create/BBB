#!/bin/zsh
set -euo pipefail
TS="$(date +%F-%H%M%S)"
BASE="$HOME/Desktop/openclaw-manual-snapshots-lite"
SNAP="$BASE/$TS"
mkdir -p "$SNAP/.openclaw" "$SNAP/LaunchAgents" "$SNAP/meta"

cp "$HOME/.openclaw/openclaw.json" "$SNAP/.openclaw/"
cp "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" "$SNAP/LaunchAgents/" 2>/dev/null || true
cp "$HOME/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist" "$SNAP/LaunchAgents/" 2>/dev/null || true
cp "$HOME/.openclaw/workspace/scripts/https_lan_proxy_8888.js" "$SNAP/.openclaw/" 2>/dev/null || true

cat > "$SNAP/meta/README.txt" <<EOT
OpenClaw manual snapshot (lite)
Created: $TS
Host: $(hostname)
Includes:
- ~/.openclaw/openclaw.json
- ~/Library/LaunchAgents/ai.openclaw.gateway.plist
- ~/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist
- ~/.openclaw/workspace/scripts/https_lan_proxy_8888.js
Purpose:
- fast rollback for gateway config / launch agents / 8888 proxy script
EOT

echo "Lite snapshot created: $SNAP"