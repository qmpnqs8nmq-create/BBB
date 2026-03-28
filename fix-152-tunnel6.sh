#!/bin/bash
# 深入排查：直接在 152 上看 LaunchAgent 状态和手动启动测试
ssh bruce@192.168.0.152 '
echo "=== LaunchAgent status ==="
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | head -20

echo ""
echo "=== Plist content check ==="
plutil -lint ~/Library/LaunchAgents/com.openclaw.tunnel.plist

echo ""
echo "=== Try manual foreground start ==="
/usr/bin/ssh -v -N -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o BatchMode=yes -L 28789:127.0.0.1:18789 bruce@192.168.0.205 2>&1 &
SSH_PID=$!
sleep 4
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Running" || echo "❌ Failed"
kill $SSH_PID 2>/dev/null'
