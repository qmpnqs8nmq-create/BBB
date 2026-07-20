# HANDOFF
最后活跃: 2026-07-19 17:00 Asia/Shanghai
当前话题: 默认模型链已切换至 Fable 5
关键状态:
- defaults 已改为 key1/Fable 5 → OpenAI GPT-5.6 Sol → key2/Fable 5，运行态标签正确。
- key1/key2 均登记 Fable 5、Sonnet 5、Opus 4.8；Sonnet 4.6 已从所有活动配置移除；OpenAI 保留 5.6 Sol/5.5。
- market 专用链已迁移为 key1/Sonnet 5 → GPT-5.5 → key2/Sonnet 5；api-worker 策略未改。
- 两个 ZenMux key 当前实际调用均 402；自动 failover 已验证由 GPT-5.6 Sol 成功接管。
- Sonnet 5 已由 ZenMux 双 key 与 OpenRouter 实时目录确认；三路运行态均 available，默认 Fable 5 链不变。
- Gateway 热加载，无重启；备份 `/root/.openclaw/backups/fable5-default-sync-20260719-164051`。
待办: memory_search 因 embedding 配置指纹变化暂停，后续单独重建索引；ZenMux 等额度刷新。
今日笔记: memory/2026-07-19.md
