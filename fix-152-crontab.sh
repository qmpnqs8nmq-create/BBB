#!/bin/bash
# 清理 152 上之前的所有方案
ssh bruce@192.168.0.152 '
pkill -f "ssh.*28789" 2>/dev/null
pkill -f "openclaw-tunnel" 2>/dev/null
launchctl bootout gui/$(id -u)/com.openclaw.tunnel 2>/dev/null
rm -f ~/Library/LaunchAgents/com.openclaw.tunnel.plist
rm -f ~/openclaw-tunnel.sh

# 写 tunnel 脚本
cat > ~/openclaw-tunnel.sh << "WEOF"
#!/bin/bash
while true; do
  ssh -N -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ConnectTimeout=10 -o BatchMode=yes -o TCPKeepAlive=yes -L 28789:127.0.0.1:18789 bruce@192.168.0.205
  sleep 5
done
WEOF
chmod +x ~/openclaw-tunnel.sh

# 用 crontab @reboot 实现开机自启
(crontab -l 2>/dev/null | grep -v openclaw-tunnel; echo "@reboot /bin/bash /Users/bruce/openclaw-tunnel.sh > /tmp/openclaw-tunnel.log 2>&1 &") | crontab -

# 立即启动
nohup /bin/bash ~/openclaw-tunnel.sh > /tmp/openclaw-tunnel.log 2>&1 &
sleep 3

lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Tunnel running" || echo "❌ Not running"
echo "Crontab:"
crontab -l 2>/dev/null | grep openclaw'
