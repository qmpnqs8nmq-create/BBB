# HANDOFF

- 最后活跃：2026-04-21 00:26
- 当前话题：修复 mangba 微信 cron delivery 账号漂移
- 关键上下文：
  - mangba 4 个 cron delivery.accountId 旧 `08a8c78d3ebe-im-bot` → 新 `5814497b5df4-im-bot`（已切并验证投递成功）
  - Bruce 个人微信 peer id（OpenID）：`o9cq80zPDVZ65x_dc91XzBkQUvr0@im.wechat`
  - accountId = bot 侧收件账号；peer.id = 用户侧 OpenID；两者非对应关系
- 教训：self-check "同 channel 其他 cron 正常 = 瞬时" 是错的。lastError 含 `weixin not configured` / `Unsupported channel` 时必须核对 accountId 是否仍有效
- 待办：
  - 把上面这条判据写进 daily-self-check cron 的异常分支
  - 5/2 coach 双周审计 execution wecom_mcp 灰度
  - 5/17 Tier 2 ADR 治理试点复盘
  - 排期：统一各 agent agents.defaults.models 主/备链跨 provider 异构
- 今日笔记：memory/2026-04-20.md
