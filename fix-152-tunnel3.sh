#!/bin/bash
# 1. 把 152 的公钥加到 205 的 authorized_keys
KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/xMFMM3rLoalLw/XLq8MT+5+XSg9jWCSKMkXQCih5H bruce@MacBook-Air.local"
grep -qF "$KEY" ~/.ssh/authorized_keys 2>/dev/null || echo "$KEY" >> ~/.ssh/authorized_keys
echo "✅ Key added to 205"

# 2. 验证 152→205 免密
echo "=== Testing 152→205 passwordless ==="
ssh bruce@192.168.0.152 'ssh -o BatchMode=yes -o ConnectTimeout=5 bruce@192.168.0.205 "echo OK"' && echo "✅ Passwordless works" || echo "❌ Still needs password"

# 3. 重启隧道
echo "=== Restarting tunnel ==="
ssh bruce@192.168.0.152 'launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist'
sleep 3

# 4. 验证
echo "=== Tunnel status ==="
ssh bruce@192.168.0.152 'lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null' && echo "✅ Tunnel running" || echo "❌ Tunnel not running"
