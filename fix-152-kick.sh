#!/bin/bash
ssh bruce@192.168.0.152 '
echo "[1] kickstart 强制启动..."
launchctl kickstart gui/$(id -u)/com.openclaw.tunnel 2>&1

sleep 3

echo ""
echo "[2] 状态检查"
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | grep -E "(state =|runs =|last exit)"

echo ""
echo "[3] 进程"
ps aux | grep -E "(openclaw-tunnel|ssh.*28789)" | grep -v grep || echo "  无进程"

echo ""
echo "[4] 端口"
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null && echo "  ✅ 28789 监听中!" || echo "  ❌ 28789 未监听"

echo ""
echo "[5] 日志"
tail -3 /tmp/openclaw-tunnel.err 2>/dev/null || echo "  无错误日志"
tail -3 /tmp/openclaw-tunnel.log 2>/dev/null || echo "  无输出日志"'
