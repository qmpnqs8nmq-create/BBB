# HANDOFF

最后活跃: 2026-06-12 15:18
当前话题: OpenClaw 402 failover 修通(已交付,Bruce 主导)

关键结论:
- 根因:dist/errors-DcOiGp7S.js RAW_402_MARKER_RE 正则不认带引号的 "402"(ZenMux字符串码值)→ 整个failover对此类错误视而不见→子agent撞key1秒死0token。
- 已外科手术修补该正则(加 ["']? 容忍引号),端到端验证通过:子agent从key1起步撞402→自动切→跑通PATCH_WORKS。日志见 reason=rate_limit + failover decision=fallback_model。
- Bruce 模型设定保留未动:primary=key1,fallbacks=[codex,key2]。
- 同时保留的真实修复:billingBackoffHoursByProvider key 改为真实 zenmux-key1/key2=1h。
- ⚠️ 补丁在 node_modules,升级OpenClaw会被覆盖→需重打。原文件备份在 backups/errors-DcOiGp7S.js.orig-*。

决定(2026-06-12 17:30):
- 不提交上游 issue(Bruce 拍板)。
- 补丁改为自愈:幂等脚本 workspace/scripts/patch-402-failover.py + systemd drop-in ~/.config/systemd/user/openclaw-gateway.service.d/10-patch-402.conf (ExecStartPre,ignore_errors=yes)。每次 Gateway 启动自动重打,不依赖 hash 文件名,升级后无需手动操作。已重启验证 status=0 + 补丁在位。
- task 文件可保留作 bug 技术档,issue 不发。
- 2026-06-12 17:40 真实欠费场景端到端复测通过:子 agent 从 key1(欠费)起步→402→reason=rate_limit→自动切 codex/gpt-5.5→返回正确结果(17×23=391)。subagents.model 空=继承主链,符合预期。
