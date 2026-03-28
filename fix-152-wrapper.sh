#!/bin/bash
# 在 152 上部署重连 wrapper 脚本 + 更新 LaunchAgent

ssh bruce@192.168.0.152 '
# 创建 wrapper 脚本
cat > ~/openclaw-tunnel.sh << "WEOF"
#!/bin/bash
while true; do
  /usr/bin/ssh -N \
    -o ServerAliveInterval=10 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=10 \
    -o BatchMode=yes \
    -o TCPKeepAlive=yes \
    -L 28789:127.0.0.1:18789 \
    bruce@192.168.0.205
  # SSH 退出后等 3 秒重连
  sleep 3
done
WEOF
chmod +x ~/openclaw-tunnel.sh

# 更新 LaunchAgent 使用 wrapper
cat > ~/Library/LaunchAgents/com.openclaw.tunnel.plist << "PEOF"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/bruce/openclaw-tunnel.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-tunnel.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-tunnel.log</string>
</dict>
</plist>
PEOF

# 杀旧进程，重启
pkill -f "ssh.*28789.*192.168.0.205" 2>/dev/null
sleep 1
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist
sleep 3

lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel running with auto-reconnect wrapper" || echo "❌ Failed"'
