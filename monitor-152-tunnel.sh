#!/bin/bash
# 检查 152 的隧道是否在运行，不在就 kickstart
ALIVE=$(ssh -o ConnectTimeout=5 bruce@192.168.0.152 'lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null | grep -c 28789' 2>/dev/null)

if [ "$ALIVE" -gt 0 ] 2>/dev/null; then
  echo "✅ 152 tunnel OK"
else
  echo "⚠️  152 tunnel down, kickstarting..."
  ssh -o ConnectTimeout=5 bruce@192.168.0.152 'launchctl kickstart gui/501/com.openclaw.tunnel 2>/dev/null || launchctl kickstart gui/$(id -u)/com.openclaw.tunnel 2>/dev/null'
  sleep 3
  RETRY=$(ssh -o ConnectTimeout=5 bruce@192.168.0.152 'lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null | grep -c 28789' 2>/dev/null)
  if [ "$RETRY" -gt 0 ] 2>/dev/null; then
    echo "✅ Tunnel restored"
  else
    echo "❌ Kickstart failed, may need manual intervention on 152"
  fi
fi
