#!/bin/bash
# 先恢复隧道连接
ssh bruce@192.168.0.152 'nohup ssh -N -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -L 28789:127.0.0.1:18789 bruce@192.168.0.205 > /dev/null 2>&1 &
sleep 2
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel restored" || echo "❌ Failed"

echo ""
echo "=== LaunchAgent debug ==="
plutil -lint ~/Library/LaunchAgents/com.openclaw.tunnel.plist
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | head -30'
