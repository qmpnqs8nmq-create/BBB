#!/bin/bash
echo "=============================="
echo "152 LaunchAgent 修复"
echo "=============================="

ssh bruce@192.168.0.152 '
# 1. 清理所有旧 job
echo "[1] 清理旧 job..."
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
launchctl bootout gui/$(id -u)/com.ssh.openclaw 2>/dev/null
pkill -f "ssh.*28789" 2>/dev/null
pkill -f "openclaw-tunnel" 2>/dev/null
sleep 1
echo "  ✅ 清理完成"

# 2. 确保 plist 和脚本正确
echo "[2] 部署文件..."
cat > ~/openclaw-tunnel.sh << "WEOF"
#!/bin/bash
while true; do
  /usr/bin/ssh -N \
    -o ServerAliveInterval=10 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o BatchMode=yes \
    -o TCPKeepAlive=yes \
    -L 28789:127.0.0.1:18789 \
    bruce@192.168.0.205
  sleep 5
done
WEOF
chmod +x ~/openclaw-tunnel.sh

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
echo "  ✅ 文件就绪"

# 3. 通过 osascript 在 GUI 会话中执行 launchctl
echo "[3] 通过 GUI 会话加载 LaunchAgent..."
osascript -e "do shell script \"launchctl bootstrap gui/501 /Users/bruce/Library/LaunchAgents/com.openclaw.tunnel.plist 2>&1\"" 2>&1
sleep 4

# 4. 验证
echo ""
echo "=== 验证 ==="
echo "--- job 状态 ---"
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | grep -E "(state =|runs =|last exit)"
echo "--- 进程 ---"
ps aux | grep -E "(openclaw-tunnel|ssh.*28789)" | grep -v grep || echo "  无进程"
echo "--- 端口 ---"
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "  ✅ 28789 正在监听!" || echo "  ❌ 28789 未监听"'
