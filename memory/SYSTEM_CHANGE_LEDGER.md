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

## 2026-07-14 · Gateway 重启与 memory_search 验证

- 经 Bruce 明确要求重启；实际执行为 OpenClaw Gateway restart，未重启宿主机 OS。
- Gateway 新进程于 23:02:38 CST 启动，PID 86541；systemd active/running，connectivity probe OK，CLI/Gateway 版本均为 `2026.7.1-beta.6`。
- 重启后实际调用 `memory_search` 成功：backend=builtin，provider=`gemini`，model=`gemini-embedding-001`，返回 5 条语义检索结果。
- 未修改配置；无需回滚。

## 2026-07-19 · OpenClaw 切换至 2026.7.1 稳定版

- 按 Bruce 要求，将 OpenClaw 从 `2026.7.1-beta.6` 升级到 npm stable/latest `2026.7.1-2`；当前 channel=stable，CLI/Gateway 均为 `2026.7.1-2`。
- 官方插件同步到各自实际 stable：Feishu/Perplexity `2026.7.1`；Codex 保持其 npm latest `2026.7.1-1`。CLI 曾错误建议不存在的插件版本 `2026.7.1-2`，已按 npm dist-tag 纠正。
- Gateway 经 systemd 重启，PID `316700`；connectivity probe、event loop、飞书/微信/企业微信深度状态均正常，插件版本漂移已消失。
- 启动前 402/failover 自愈脚本成功重打补丁，当前 `RAW_402_MARKER_RE` 可识别引号包裹的 `"code":"402"`。
- 既有安全审计保持 `0 critical / 4 warn / 1 info`；未修改通道、安全边界或模型路由。回滚命令：`npm install -g openclaw@2026.7.1-beta.6`，并将官方插件恢复到 beta.6 后重启。

## 2026-07-19 · 默认模型切换至 Claude Fable 5

- 经 Bruce 明确决定，默认链更新为 `zenmux-key1/anthropic/claude-fable-5` → `openai/gpt-5.6-sol` → `zenmux-key2/anthropic/claude-fable-5`。
- ZenMux key1/key2 均登记 Fable 5、Sonnet 5、Opus 4.8、Sonnet 4.6；OpenAI allowlist 保留 GPT-5.6 Sol 与 GPT-5.5。同步范围：`openclaw.json`、顶层 `models.json`、12 个 agent 的 `models.json`。
- `api-worker`、`market` 的既有专用模型策略未改；其他无覆盖 agent 继承新默认链。Gateway 热加载，无重启、无中断，probe OK。
- `models list` 运行态标签已确认 default/fallback#1/fallback#2 正确；端到端自动 failover 因两个 ZenMux key 当前均返回 402，由 `openai/gpt-5.6-sol` 成功接管。
- 回滚备份：`/root/.openclaw/backups/fable5-default-sync-20260719-164051`。

## 2026-07-19 · Claude Sonnet 4.6 全量迁移至 Sonnet 5

- 经 Bruce 明确要求，将所有活动配置中的 `claude-sonnet-4.6` 替换为 `claude-sonnet-5`；历史日志与备份不改。
- 已覆盖 OpenClaw 主配置、顶层模型目录、12 个 agent 模型目录，以及 ZenMux key1/key2、OpenRouter 模型项；`market` 专用链更新为 key1/Sonnet 5 → GPT-5.5 → key2/Sonnet 5。
- 活动配置 Sonnet 4.6 引用=0；ZenMux key1/key2 与 OpenRouter 实时目录均确认 Sonnet 5 存在，`models list` 三路均 available。
- Gateway 热加载，无重启、无中断，connectivity probe OK；默认 Fable 5 模型链未改变。
- 回滚备份：`/root/.openclaw/backups/sonnet46-to-sonnet5-20260719-165631`。

## 2026-07-20 · benben Memory Search 独立索引重建

- 经 Bruce 确认，仅对 benben 执行 `openclaw memory index --agent benben --force`，修复 `index provider settings changed`；未改全局配置、未重启 Gateway。
- 变更前完整备份 benben SQLite/WAL/SHM 至 `/root/.openclaw/backups/benben-memory-reindex-20260720-1405/`（562MB，已生成 SHA256）。
- 验证：index identity=valid，301 files/5089 chunks，Gemini embedding probe 与 sqlite-vec 正常；Jamie 实际查询返回 5 条结果，最高分 0.781。
- 回滚：停止对 benben 索引写入后，用上述备份恢复 `/root/.openclaw/agents/benben/agent/openclaw-agent.sqlite{,-wal,-shm}`；当前无需回滚。

## 2026-07-20 · benben 单独关闭 Memory Search MMR

- 经 Bruce 确认，仅为 benben 增加 agent 级覆盖：`memorySearch.query.hybrid.mmr.enabled=false`；全局默认仍启用 MMR，其他 agent、Gemini provider、candidateMultiplier 与15秒工具截止均未修改。
- 原因：benben 在 `maxResults=20`、candidateMultiplier=4 时，完整 MMR 同步重排耗时约46.6秒，超过工具15秒硬截止；统一错误包装误报 embedding/provider。
- 验证：三次 `maxResults=20` CLI 搜索为6.383/6.370/6.076秒，均返回20条；Gateway 下 benben 实际工具调用 success=true，工具阶段约1.841秒并返回20条。Gateway 未重启、probe OK。
- 回滚备份：`/root/.openclaw/backups/benben-mmr-disable-20260720-1443/openclaw.json`；恢复该文件或删除 benben 的 `memorySearch` 覆盖即可。

## 2026-07-20 · GPT-5.6 Sol 显示名恢复

- 按 Bruce 要求，仅将 `models.providers.openai.models[gpt-5.6-sol].name` 从 `GPT-5.6 Sol (OAuth 250k cap)` 改为 `GPT-5.6 Sol`。
- `contextWindow=250000`、`contextTokens=250000`、`maxTokens=128000` 及模型链、认证均未修改；配置校验通过。
- Gateway 未重启，PID 变更前后均为 1719，connectivity probe OK；回滚备份：`/root/.openclaw/backups/gpt56-sol-display-name-20260720-1525/openclaw.json`。

## 2026-07-20 · benben Memory Search 编排规则修正

- 将父线程动态检索规则写入父线程确定加载的 `workspace-benben/TOOLS.md`；原 `AGENTS.md` 保留为 Codex 原生子线程防线。
- 规则要求：父线程先完成检索/解析/证据包再 spawn；批量事实检索默认 `corpus=memory`；`corpus=all` 仅按需单次；禁止动态工具 `Promise.all`；逐次解析、保存并 fail closed；子线程不调用 OpenClaw 动态工具。
- 隔离新 benben 会话验证 TOOLS/AGENTS 均完整注入，本本准确复述关键限制。未改 Gateway、索引、embedding 或模型配置，无需重启。
- 回滚备份：`/root/.openclaw/backups/benben-memory-orchestration-20260720-1612/`。
