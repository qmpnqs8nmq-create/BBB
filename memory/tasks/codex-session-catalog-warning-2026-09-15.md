# Codex session catalog 解析告警（2026-09-15）

- 目标：安全处理 OpenClaw 2026.9.4 的既有 `sessions.catalog.list` 告警；不删除历史会话。
- 候选原件：`/root/.openclaw/agents/benben/agent/codex-home/sessions/2026/08/03/rollout-2026-08-03T10-22-26-019fc56d-f9ad-73f2-a6ae-4d739053f3d9.jsonl`。
- 原件已恢复：194,908 bytes；SHA-256 `9ed13bbc0769dd881a04894bf438a471659b88da2414f2f9b64f095aafe295ff`。
- 可恢复备份：`/root/.openclaw/backups/benben-codex-session-parse-20260915-111547/`；同尺寸、同哈希、`cmp` 相同。
- 格式检查：27 条均为合法 JSON；首条 `session_meta` 完整，最大单行约 39.9 KB、最大字符串约 23.7K 字符。
- A/B：临时移出候选后告警仍复现且延迟未改善，随后原子恢复；候选不是 exact culprit。
- 根因：Codex app-server `thread/list` 的多行 JSON 聚合帧超过插件 `CODEX_APP_SERVER_PARSE_BUFFER_MAX=8388608`；溢出后余下预览正文被逐行误解析，产生连锁告警。
- 触发：Control UI 固定请求 `limitPerHost:40`；2026.9.4 Codex 插件 `PAGE_LIMIT=100`，因此一次上游请求可返回 40 条超大 preview。
- 基线：40 条约 61.14s、客户端 60s 超时、新增 10 条解析告警；50 条此前约 17–20s并触发告警；10 条约 6–8s且单次无告警。
- 穿透：benben 后续 10 条页分别约 4.54s、4.40s，cursor 正常结束；无需删除或改写历史。
- 推荐热修：把当前 Codex 插件 `dist/index.js` 的 `PAGE_LIMIT` 从 100 改为 10，使 UI 的 40 条请求在 app-server 层拆成小页并保留最终 40 条语义；不建议单纯扩大 8 MiB 缓冲。
- 待 Bruce 明确批准：备份插件文件、应用单常量补丁、校验语法/插件 doctor、重启 Gateway 一次，复测 40 条延迟与新增告警为 0；失败则恢复备份并重启。

