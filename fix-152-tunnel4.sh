#!/bin/bash
# 查错误日志
echo "=== Error log ==="
ssh bruce@192.168.0.152 'cat /tmp/openclaw-tunnel.err 2>/dev/null || echo "empty"'

# 手动跑一次看报什么错
echo ""
echo "=== Manual test ==="
ssh bruce@192.168.0.152 'ssh -N -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o BatchMode=yes -L 28789:127.0.0.1:18789 bruce@192.168.0.205 &
sleep 3
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ Manual tunnel OK" || echo "❌ Manual tunnel failed"
cat /tmp/openclaw-tunnel.err 2>/dev/null'
