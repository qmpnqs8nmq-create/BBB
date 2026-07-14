# HANDOFF
最后活跃: 2026-07-13 20:15 Asia/Shanghai
当前话题: GPT-5.6 Sol OAuth 上下文预算已设为 250k
上下文:
- OpenClaw/官方插件为 `2026.7.1-beta.6`，Codex `0.144.1`。
- 主模型仍为 key1/Opus 4.8；fallback 顺序为 `openai/gpt-5.6-sol` → key2/`anthropic/claude-fable-5`。
- 已同步 openclaw.json、顶层 models.json 和 12 个 agent models.json；活动配置无 key2/Opus 旧引用。
- ZenMux 目录及实际请求均确认 Fable 5 可用；Gateway 热加载，probe OK，未重启。
- 5.6 Sol：标准 API=1.05M；OpenClaw OAuth 运行硬编码=372k；当前 Codex 后端实时目录=272k（95% effective）。
- 已为 5.6 Sol 设置 `contextWindow/contextTokens=250000`；models list=250k，Gateway 热加载，未重启。
- 回滚备份: `/root/.openclaw/backups/gpt56-sol-250k-20260713-201406`（14文件+SHA256）。
待办: 后续 OpenClaw 升级后复核 402 补丁；stable 支持 5.6 后评估退出 beta。
今日笔记: memory/2026-07-13.md
