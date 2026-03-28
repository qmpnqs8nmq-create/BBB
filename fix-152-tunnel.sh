#!/bin/bash
# 更新 152 的 LaunchAgent：加 ServerAlive 断线检测 + 自动重连

ssh bruce@192.168.0.152 'cat > ~/Library/LaunchAgents/com.openclaw.tunnel.plist << "PEOF"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/ssh</string>
        <string>-N</string>
        <string>-o</string>
        <string>ServerAliveInterval=15</string>
        <string>-o</string>
        <string>ServerAliveCountMax=3</string>
        <string>-o</string>
        <string>ExitOnForwardFailure=yes</string>
        <string>-o</string>
        <string>ConnectTimeout=10</string>
        <string>-L</string>
        <string>28789:127.0.0.1:18789</string>
        <string>bruce@192.168.0.205</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-tunnel.err</string>
</dict>
</plist>
PEOF

launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist

sleep 2
echo "=== Tunnel status ==="
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel running" || echo "❌ Tunnel not running"'
