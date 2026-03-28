#!/bin/bash
ssh bruce@192.168.0.152 '
# 杀旧进程
pkill -f "ssh.*28789.*192.168.0.205" 2>/dev/null
pkill -f "openclaw-tunnel" 2>/dev/null
sleep 1

# 写 wrapper 脚本（保持前台运行，SSH 断了就重连）
cat > ~/openclaw-tunnel.sh << "WEOF"
#!/bin/bash
cleanup() { kill $SSH_PID 2>/dev/null; exit 0; }
trap cleanup SIGTERM SIGINT

while true; do
  /usr/bin/ssh -N \
    -o ServerAliveInterval=10 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=no \
    -o ConnectTimeout=10 \
    -o BatchMode=yes \
    -o TCPKeepAlive=yes \
    -L 28789:127.0.0.1:18789 \
    bruce@192.168.0.205 &
  SSH_PID=$!
  wait $SSH_PID
  echo "$(date): SSH exited, reconnecting in 5s..." >> /tmp/openclaw-tunnel.log
  sleep 5
done
WEOF
chmod +x ~/openclaw-tunnel.sh

# 更新 plist - 去掉 KeepAlive，让 wrapper 自己管重连
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

# 重载
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
sleep 1
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist
sleep 4

echo "=== Status ==="
ps aux | grep openclaw-tunnel | grep -v grep | head -3
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel running" || echo "❌ Not running"'
