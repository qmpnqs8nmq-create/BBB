# SYSTEM_CHANGE_LEDGER.md

全局系统级变更台账。适用范围：OpenClaw 平台、CEO/chief 系统、多 agent 路由、cron、workspace symlink、Gateway、渠道插件。

## 当前决策 · 2026-05-04

- **系统级升级/回滚/架构变更 DRI：main。**
- CEO/chief 系统可以提出业务需求和风险判断，但不得自行重复执行平台级回滚、cron 全局清理、workspace 大范围恢复。
- chief 若发现疑似需要回滚：先写入 `workspace-chief/memory/OPS_INBOX.md` 并通知 main；main 负责核验历史台账、备份、影响面和最终执行。
- 每次系统级变更必须同步到：
  1. main: `memory/SYSTEM_CHANGE_LEDGER.md`
  2. main: 当日日志 `memory/YYYY-MM-DD.md`
  3. chief: `memory/OPS_INBOX.md`
  4. 如影响长期行为，再更新 chief/main `MEMORY.md`

## 2026-04-29 · chief rollback / cron boundary incident

- 事实：main 日志 `workspace/memory/2026-04-29.md` 记录了 “Cron boundary audit after chief rollback”。
- 当时发现：chief-side cleanup removed 6 jobs，其中 5 个是 chief，1 个是非 CEO 的 mangba `信号雷达周报` cron。
- 结论：Gateway cron 是全局资源；chief 拥有 cron 工具/文件访问时，回滚/清理可能越界影响其他 agent。
- 处理：main 从 `/root/.openclaw/cron/jobs.json.bak.pre-rollback-20260429` 恢复 mangba 该 cron，并重启 Gateway 验证。
- 后续规则：类似回滚不得由 chief 单独执行；必须先查本台账，避免重复回滚和跨 agent 误删。

## 2026-05-04 · OpenClaw upgrade / service cleanup

- OpenClaw 从 2026.4.24 升级到 2026.5.2。
- Gateway service PATH 已收窄，版本标记更新为 2026.5.2；备份：`/root/.config/systemd/user/openclaw-gateway.service.bak-20260504-1310`。
- 验证：Gateway running，connectivity probe OK，admin-capable。
