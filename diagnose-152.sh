#!/bin/bash
echo "=============================="
echo "152 LaunchAgent 完整诊断"
echo "=============================="

ssh bruce@192.168.0.152 '
echo "[1] macOS 版本"
sw_vers

echo ""
echo "[2] 当前用户和 UID"
whoami
id -u

echo ""
echo "[3] LaunchAgent plist 是否存在且合法"
ls -la ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>/dev/null || echo "  plist 不存在"
plutil -lint ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>/dev/null || echo "  plutil check failed"

echo ""
echo "[4] launchctl 能否看到 GUI domain"
launchctl print gui/$(id -u)/ 2>&1 | head -5

echo ""
echo "[5] 列出 gui/501 下所有 openclaw 相关 job"
launchctl print gui/$(id -u)/ 2>&1 | grep -i openclaw || echo "  没有 openclaw 相关 job"

echo ""
echo "[6] 尝试 bootstrap 并捕获完整错误"
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.openclaw.tunnel.plist 2>&1 || echo "  bootstrap 返回错误"

echo ""
echo "[7] bootstrap 后检查 job 状态"
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1

echo ""
echo "[8] 等 5 秒后检查进程和端口"
sleep 5
echo "--- 进程 ---"
ps aux | grep -E "(openclaw-tunnel|ssh.*28789)" | grep -v grep || echo "  无相关进程"
echo "--- 端口 ---"
lsof -iTCP:28789 -sTCP:LISTEN -P -n 2>/dev/null || echo "  28789 无监听"
echo "--- 错误日志 ---"
cat /tmp/openclaw-tunnel.err 2>/dev/null | tail -5 || echo "  无错误日志"
cat /tmp/openclaw-tunnel.log 2>/dev/null | tail -5 || echo "  无输出日志"'
