#!/bin/bash
# 1. 查看错误日志
echo "=== Error log ==="
ssh bruce@192.168.0.152 'cat /tmp/openclaw-tunnel.err 2>/dev/null || echo "no log"'

# 2. 设置 152→205 免密登录（把 152 的公钥复制到 205）
echo ""
echo "=== Setting up 152→205 key auth ==="
ssh bruce@192.168.0.152 'cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null || echo "NO_KEY"'
