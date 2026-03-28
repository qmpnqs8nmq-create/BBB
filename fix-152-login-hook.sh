#!/bin/bash
echo "=============================="
echo "152 登录自启修复"
echo "=============================="

ssh bruce@192.168.0.152 '
# 在 152 本地创建一个登录时自动 kickstart 的脚本
mkdir -p ~/bin

cat > ~/bin/kickstart-tunnel.sh << "WEOF"
#!/bin/bash
sleep 10
launchctl kickstart gui/501/com.openclaw.tunnel 2>/dev/null
WEOF
chmod +x ~/bin/kickstart-tunnel.sh

# 用 Login Items 的方式：通过 LaunchAgent 实现登录后延迟 kickstart
cat > ~/Library/LaunchAgents/com.openclaw.tunnel-kick.plist << "PEOF"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.tunnel-kick</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/bruce/bin/kickstart-tunnel.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LaunchOnlyOnce</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-tunnel-kick.log</string>
</dict>
</plist>
PEOF

# kickstart 这个 kick agent 本身（同样的问题...）
# 换思路：直接写到 zprofile，用户登录 GUI 时 macOS 会执行
grep -q "kickstart-tunnel" ~/.zprofile 2>/dev/null || {
  echo "" >> ~/.zprofile
  echo "# Auto-kickstart OpenClaw tunnel on login" >> ~/.zprofile
  echo "( sleep 10 && launchctl kickstart gui/501/com.openclaw.tunnel 2>/dev/null ) &" >> ~/.zprofile
}

echo "✅ 已添加到 ~/.zprofile"
echo "152 重启并登录后会自动 kickstart 隧道"
cat ~/.zprofile | grep kickstart'
