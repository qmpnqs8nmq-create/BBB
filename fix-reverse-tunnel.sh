#!/bin/bash
# 方案：从 205 用 autossh 建反向隧道到 152
# 效果：152 的 localhost:28789 → 205 的 localhost:18789

# 0. 清理 152 上所有旧隧道和 LaunchAgent
ssh bruce@192.168.0.152 '
pkill -f "ssh.*28789" 2>/dev/null
pkill -f "openclaw-tunnel" 2>/dev/null
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
rm -f ~/Library/LaunchAgents/com.openclaw.tunnel.plist
rm -f ~/openclaw-tunnel.sh
echo "✅ 152 cleaned up"'

sleep 1

# 1. 在 205 上用 autossh 建反向隧道
# 先确认 autossh 可用
if ! which autossh >/dev/null 2>&1; then
  echo "❌ autossh not found on 205"
  exit 1
fi
echo "✅ autossh found: $(which autossh)"

# 2. 创建 LaunchAgent
cat > ~/Library/LaunchAgents/com.openclaw.reverse-tunnel.plist << 'PEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.reverse-tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/autossh</string>
        <string>-M</string>
        <string>0</string>
        <string>-N</string>
        <string>-o</string>
        <string>ServerAliveInterval=10</string>
        <string>-o</string>
        <string>ServerAliveCountMax=3</string>
        <string>-o</string>
        <string>ExitOnForwardFailure=yes</string>
        <string>-o</string>
        <string>ConnectTimeout=10</string>
        <string>-R</string>
        <string>28789:127.0.0.1:18789</string>
        <string>bruce@192.168.0.152</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>EnvironmentVariables</key>
    <dict>
        <key>AUTOSSH_GATETIME</key>
        <string>0</string>
    </dict>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-reverse-tunnel.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-reverse-tunnel.log</string>
</dict>
</plist>
PEOF

# 3. 加载
launchctl bootout gui/$(id -u)/com.openclaw.reverse-tunnel 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.reverse-tunnel.plist

sleep 3

# 4. 验证
echo "=== 205 process ==="
ps aux | grep "autossh.*152" | grep -v grep

echo "=== 152 port 28789 ==="
ssh bruce@192.168.0.152 'lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null' && echo "✅ Reverse tunnel working!" || echo "❌ Not working"
