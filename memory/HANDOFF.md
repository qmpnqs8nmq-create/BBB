# HANDOFF

最后活跃: 2026-07-12 23:08
当前话题: Bruce 要求把 OpenAI/Codex OAuth 从 5.5 升到 gpt-5.6-sol

关键结论:
- 已查 OpenAI 文档：GPT-5.6 Sol 在 Codex 需要 Codex CLI >= 0.144.0；Bruce 账号 OAuth 是 Pro，有资格。
- 路线①外科式尝试失败：装 `@openai/codex@0.144.1` 到 `/root/.openclaw/codex-0144`，但 OpenClaw 2026.6.11 仍拒绝 `codex/gpt-5.6-sol` (`not allowed`)。
- 尝试补插件/主程序 catalog 与白名单仍不生效，判断 6.11 有更深 provider merge/cache/allow 逻辑；不宜继续 monkey patch。
- 已回滚本次所有补丁和 openclaw.json codex appServer 配置，Gateway active，当前仍是原 `codex/gpt-5.5` fallback；未设置 5.6。
- 下一步可选：升级到 `2026.7.1-beta.5`（官方组合含 `@openai/codex@0.144.1`）或等下个 stable。

今日笔记: memory/2026-07-12.md
