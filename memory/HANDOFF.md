# HANDOFF

最后活跃: 2026-06-12 15:18
当前话题: OpenClaw 402 failover 修通(已交付,Bruce 主导)

关键结论:
- 根因:dist/errors-DcOiGp7S.js RAW_402_MARKER_RE 正则不认带引号的 "402"(ZenMux字符串码值)→ 整个failover对此类错误视而不见→子agent撞key1秒死0token。
- 已外科手术修补该正则(加 ["']? 容忍引号),端到端验证通过:子agent从key1起步撞402→自动切→跑通PATCH_WORKS。日志见 reason=rate_limit + failover decision=fallback_model。
- Bruce 模型设定保留未动:primary=key1,fallbacks=[codex,key2]。
- 同时保留的真实修复:billingBackoffHoursByProvider key 改为真实 zenmux-key1/key2=1h。
- ⚠️ 补丁在 node_modules,升级OpenClaw会被覆盖→需重打。原文件备份在 backups/errors-DcOiGp7S.js.orig-*。

待办:
- Bruce 决定是否提交上游 issue(草稿已备,3个bug)
- 升级 OpenClaw 后记得重打 402 正则补丁
- → task: memory/tasks/openclaw-402-subagent-failover-issue.md
