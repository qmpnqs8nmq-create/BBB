#!/bin/bash
# 杀掉 152 上所有占用 28789 的旧隧道，重启 LaunchAgent
ssh bruce@192.168.0.152 '
pkill -f "ssh.*28789.*192.168.0.205" 2>/dev/null
sleep 1
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist
sleep 3
echo "=== Tunnel status ==="
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel running via LaunchAgent" || echo "❌ Still not running"
echo "=== Process ==="
ps aux | grep "ssh.*28789" | grep -v grep'
