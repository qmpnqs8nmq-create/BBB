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

## 2026-07-13 · OpenClaw beta.6 + GPT-5.6 Sol OAuth

- 经 Bruce 明确确认，OpenClaw 主程序与官方 codex/feishu/perplexity 插件升级到 `2026.7.1-beta.6`；Codex 插件捆绑 `@openai/codex@0.144.1`。
- 仅替换 OAuth/Codex fallback：`codex/gpt-5.5` → canonical `openai/gpt-5.6-sol`；主模型仍为 `zenmux-key1/anthropic/claude-opus-4.8`，第二 fallback 仍为 key2 Opus 4.8。
- 5.6 已加入 `agents.defaults.models` allowlist；此前测试留下的当前会话 5.5 pin 已清除并恢复 default。
- 真实强制请求验证：provider=`openai`、model=`gpt-5.6-sol`、harness=`codex`、fallbackUsed=false；端到端验证又确认 key1 402 后实际由 5.6 Sol 成功接管。
- Gateway CLI/service 均为 beta.6，probe OK，Feishu/微信/企业微信通道均 OK；402 自愈补丁已自动重打到 `errors-XbAR6hS3.js`。
- 配置备份：`/root/.openclaw/openclaw.json.bak{,.1,.2}`；402 原文件备份：`/root/.openclaw/backups/errors-XbAR6hS3.js.orig-402patch-20260713044150`。

## 2026-07-13 · ZenMux key2 模型切换为 Claude Fable 5

- 经 Bruce 明确要求，将 ZenMux key2 的模型从 `anthropic/claude-opus-4.8` 替换为 `anthropic/claude-fable-5`；主模型与第一 fallback 均未改变。
- 已同步全局、顶层及 12 个 agent 模型目录，并更新 fallback#2/allowlist 引用；Gateway 热加载，无需重启。
- ZenMux 模型目录与实际请求双重验证通过；活动模型列表显示 `zenmux-key2/anthropic/claude-fable-5` 为 fallback#2。
- 回滚备份：`/root/.openclaw/backups/zenmux-key2-fable5-20260713-153718`。

## 2026-07-13 · GPT-5.6 Sol OAuth 上下文预算设为 250k

- 经 Bruce 明确确认，仅为 `openai/gpt-5.6-sol` 增加 provider 模型覆盖：`contextWindow=250000`、`contextTokens=250000`、`maxTokens=128000`；主模型及 fallback 顺序未变。
- 变更前完整备份主配置、顶层模型目录及 12 个 agent 模型目录，共 14 文件并生成 SHA256：`/root/.openclaw/backups/gpt56-sol-250k-20260713-201406`。
- 校验：配置 schema 合法；`models list` 显示 250000/250000、text+image、available；Gateway 已热加载，无重启、无中断，probe OK。
- 回滚：从上述备份恢复 `openclaw.json`；其余13份为一致性快照，本次未修改。
