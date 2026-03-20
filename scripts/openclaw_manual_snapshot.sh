#!/bin/zsh
set -euo pipefail
TS="$(date +%F-%H%M%S)"
BASE="$HOME/Desktop/openclaw-manual-snapshots"
SNAP="$BASE/$TS"
mkdir -p "$SNAP/.openclaw" "$SNAP/LaunchAgents" "$SNAP/meta"
cp "$HOME/.openclaw/openclaw.json" "$SNAP/.openclaw/"
cp -R "$HOME/.openclaw/agents" "$SNAP/.openclaw/"
cp -R "$HOME/.openclaw/workspace" "$SNAP/.openclaw/"
cp "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" "$SNAP/LaunchAgents/" 2>/dev/null || true
cp "$HOME/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist" "$SNAP/LaunchAgents/" 2>/dev/null || true
cat > "$SNAP/meta/README.txt" <<EOT
OpenClaw manual snapshot
Created: $TS
Host: $(hostname)
Includes:
- ~/.openclaw/openclaw.json
- ~/.openclaw/agents/
- ~/.openclaw/workspace/
- ~/Library/LaunchAgents/ai.openclaw.gateway.plist
- ~/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist
EOT
echo "Snapshot created: $SNAP"
