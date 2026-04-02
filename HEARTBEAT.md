# HEARTBEAT.md

## 定期任务（每次 heartbeat 检查，按需执行）

- 如果 memory/ 中有 14 天以上的日志文件：提取关键结论追加到 memory/archive.md（对应月段），然后删除原文件
- 如果 MEMORY.md 超过 80 行：精简旧条目
- 如果 archive.md 有超过 6 个月的段落：删除该段落

## 企业微信 DM 白名单审批

检查 Gateway 日志（journalctl _PID=$(pgrep openclaw-gateway)）中是否有企业微信 DM 被拒/拦截的记录（关键词：allowlist、dm policy、deny、blocked、rejected + wecom）。
如果发现新的被拦截用户：
1. 通过企业微信通知 Bruce：「有新用户 xxx 尝试私聊 bot，是否批准？」
2. Bruce 回复"批准"后，将该用户 ID 加入 /root/.openclaw/openclaw.json 的 channels.wecom.allowFrom 数组
3. 重启 Gateway 生效
当前白名单：QiuHongYue, vickyli, frankye, amyliu, taoshuaiying, peterpeng, janezhou, jashguo
