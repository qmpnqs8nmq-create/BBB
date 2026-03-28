#!/bin/bash
set -e

echo "=============================="
echo "OpenClaw Reverse Tunnel Setup"
echo "205 → 152 (reverse forward)"
echo "Effect: 152's localhost:28789 → 205's Gateway:18789"
echo "=============================="

# Step 1: 清理 152 上所有旧方案
echo ""
echo "[1/5] Cleaning up 152..."
ssh bruce@192.168.0.152 '
pkill -f "ssh.*28789" 2>/dev/null
pkill -f "openclaw-tunnel" 2>/dev/null
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
rm -f ~/Library/LaunchAgents/com.openclaw.tunnel.plist
rm -f ~/openclaw-tunnel.sh
crontab -l 2>/dev/null | grep -v openclaw-tunnel | crontab - 2>/dev/null
echo "  ✅ 152 cleaned"' || echo "  ⚠️  152 cleanup had warnings (OK)"

# Step 2: 清理 205 上旧的自连隧道残留
echo ""
echo "[2/5] Cleaning up 205..."
launchctl bootout gui/$(id -u)/com.autossh.openclaw 2>/dev/null
rm -f ~/Library/LaunchAgents/com.autossh.openclaw.plist
pkill -f "ssh.*-L.*28789.*192.168.0.205" 2>/dev/null
echo "  ✅ 205 cleaned"

# Step 3: 确认 autossh
echo ""
echo "[3/5] Checking autossh..."
AUTOSSH_PATH=$(which autossh 2>/dev/null)
if [ -z "$AUTOSSH_PATH" ]; then
  echo "  ❌ autossh not found, installing..."
  brew install autossh
  AUTOSSH_PATH=$(which autossh)
fi
echo "  ✅ autossh: $AUTOSSH_PATH"

# Step 4: 确保 152 允许反向端口转发 (GatewayPorts 默认 no 就够用，localhost 绑定不需要)
echo ""
echo "[4/5] Creating LaunchAgent on 205..."
cat > ~/Library/LaunchAgents/com.openclaw.reverse-tunnel-152.plist << PEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.reverse-tunnel-152</string>
    <key>ProgramArguments</key>
    <array>
        <string>${AUTOSSH_PATH}</string>
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
        <string>-o</string>
        <string>BatchMode=yes</string>
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
    <string>/tmp/openclaw-reverse-tunnel-152.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-reverse-tunnel-152.log</string>
</dict>
</plist>
PEOF
echo "  ✅ Plist created"

# Step 5: 启动并验证
echo ""
echo "[5/5] Starting and verifying..."
launchctl bootout gui/$(id -u)/com.openclaw.reverse-tunnel-152 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.reverse-tunnel-152.plist
sleep 4

echo ""
echo "=== Verification ==="
echo "--- 205 autossh process ---"
ps aux | grep "autossh.*152" | grep -v grep || echo "  ❌ autossh not running"

echo ""
echo "--- 152 port 28789 ---"
ssh -o ConnectTimeout=5 bruce@192.168.0.152 'lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null' && echo "  ✅ 152 localhost:28789 is live!" || echo "  ❌ Port not listening on 152"

echo ""
echo "=============================="
echo "Setup complete."
echo "Architecture: 205 autossh -R → 152:28789 → 205:18789"
echo "Auto-start: LaunchAgent on 205 (RunAtLoad + KeepAlive)"
echo "Auto-reconnect: autossh + ServerAlive"
echo "=============================="
