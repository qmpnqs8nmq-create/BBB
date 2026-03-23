# HEARTBEAT.md

## 定期任务（每次 heartbeat 检查，按需执行）

- 如果 memory/ 中有 14 天以上的日志文件：提取关键结论追加到 memory/archive.md（对应月段），然后删除原文件
- 如果 MEMORY.md 超过 80 行：精简旧条目
- 如果 archive.md 有超过 6 个月的段落：删除该段落
