#!/bin/bash
ssh bruce@192.168.0.152 '
# 杀掉所有手动隧道
pkill -f "ssh.*28789.*192.168.0.205" 2>/dev/null
sleep 1

# 确认端口释放
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "❌ Port still occupied" || echo "✅ Port free"

# 重启 LaunchAgent
launchctl kickstart -k gui/$(id -u)/com.openclaw.tunnel 2>/dev/null || {
  launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist
}

sleep 3

# 验证
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ LaunchAgent tunnel running!" || echo "❌ Still not running"
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | grep "state ="'
