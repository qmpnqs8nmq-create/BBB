#!/bin/bash
ssh bruce@192.168.0.152 '
echo "=== Error log ==="
cat /tmp/openclaw-tunnel.err 2>/dev/null || echo "empty"

echo ""
echo "=== Output log ==="
cat /tmp/openclaw-tunnel.log 2>/dev/null || echo "empty"

echo ""
echo "=== Is wrapper running? ==="
ps aux | grep openclaw-tunnel | grep -v grep

echo ""
echo "=== Port 28789 ==="
lsof -iTCP:28789 -P -n 2>/dev/null || echo "nothing on 28789"

echo ""
echo "=== Manual SSH test ==="
ssh -v -o BatchMode=yes -o ConnectTimeout=5 -N -L 28789:127.0.0.1:18789 bruce@192.168.0.205 2>&1 &
sleep 3
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "✅ manual works" || echo "❌ manual failed"
kill %1 2>/dev/null'
