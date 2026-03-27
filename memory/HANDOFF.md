# HANDOFF.md — 会话接力卡

- **最后活跃:** 2026-03-26 21:08 (Asia/Shanghai)
- **当前话题:** Zenmux 3-key 轮换系统性修复（三级保障方案，已完成代码改动，待 gateway restart 验证）
- **上下文:** Level1 MRU sticky + Level2 冷却1h + Level3 fallback openrouter sonnet → openai oauth
- **monkey-patch 文件:** auth-profiles-DRuJBw5y.js（MRU排序 line1178 + 去bypass line708）
- **配置改动:** openclaw.json — 删 auth.order、加 billingBackoffHoursByProvider=1h、fallback 改 openrouter sonnet
- **遗留:** (1) gateway restart 后验证 /new 不再 402 (2) 升级 OpenClaw 后需重打 monkey-patch (3) upstream issue 待提
- **今日笔记:** `memory/2026-03-26.md`
