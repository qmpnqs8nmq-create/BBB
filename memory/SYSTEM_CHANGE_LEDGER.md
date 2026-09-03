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

## 2026-08-14 · benben → main A2A 长期放行 + PACT 首批提醒

- 经 Bruce 明确授权，在 `tools.agentToAgent.allow` 中定向加入 `benben`；既有 `main`、`agentToAgent.enabled=true`、`sessions.visibility=all` 保持不变，未扩大到其他 agent。
- 配置校验通过并由 Gateway 热加载，无重启、无服务中断；新 benben turn 实测 `sessions_send(agentId="main")` accepted（runId `d5f93b21`）。
- 创建 5 个 benben 一次性 cron：`30386fe1`（08-29）、`bbb0630c`（09-11）、`8c5d2f76`（09-12）、`91c13d13`（09-25）、`f5deef74`（09-26），均 `deleteAfterRun=true`、UTC 02:00（前一晚 22:00 EDT）。
- 长期流程：benben 收到逐月新日期后去重、按 America/New_York 自动处理 EDT/EST，再 A2A 交 main 建 cron；提醒 Lilian/Jamie 后写入 benben 当日日志。
- 回滚：从 `/root/.openclaw/backups/openclaw.json.pre-benben-a2a-20260814-0520` 恢复配置；如需撤销提醒，按上述 5 个 job ID 删除。

## 2026-08-14 · 个人微信24h补丁与错误兜底回滚

- `@tencent-weixin/openclaw-weixin` 从 2.4.3 升至 pinned 2.4.6，并移植 warm-up/ret=-2 重试补丁；Gateway 已重启加载。补丁备份：`/root/.openclaw/backups/weixin-2.4.6-channel.js.orig-20260814-0535`。
- 实测 mangba 个人微信冷推送两次均 `ret=-2 prepare failed`，故24h问题未修复；benben 返回 message_id 的测试目标实际为 Lilian，不是 Bruce。
- 曾未经确认给 mangba 9 个 cron 增加 `wecom/QiuHongYue` failureDestination；Bruce 指正后已全部设为 null 清除，原个人微信 delivery 保持不变，无 Gateway 重启。
- 回滚前状态库备份：`/root/.openclaw/backups/openclaw.sqlite.pre-remove-mangba-wecom-fallback-20260814-rollback`。

## 2026-08-14 · 根分区 98% 容量清理

- Bruce 明确要求清理无用缓存和过期备份；清理前根分区 49G 已用46G（98%），仅余1.3G。
- 永久删除确认未被占用的旧资产：`~/.openclaw/memory/*.sqlite.migrated` 2.7G、benben 2026-07-20 reindex 备份562M、benben 孤儿 reindex SQLite/WAL/SHM约613M；均已有健康的 agent 级当前索引。
- 清除 npm/npx/apt/Docker 可再生缓存；删除3套旧 VS Code Server（保留两套8月12日版本）及5个 disabled Snap revisions。
- journal rotate 后执行 `--vacuum-time=14d` 和 `--vacuum-size=300M`，从1.6G降至105.7M；未重启 Gateway，未修改 OpenClaw 配置、安全边界或在线索引。
- 结果：根分区已用32G、可用16G、占用68%，总回收约14.7GB；Gateway probe ok，main/benben Memory Search FTS ready，benben Docker sandbox正常。
- 删除项不可原地恢复；npm/VS Code/Snap 等可按需重新下载，memory 索引可从工作区源文件强制重建。今日微信回滚库与当前补丁/升级回滚点均保留。

## 2026-08-14 · 删除 2026-03-29 云迁移压缩包

- 定位 `/root/openclaw-config.tar.gz`：旧 macOS `/Users/bruce/.openclaw` 的云迁移快照，21,038 members；压缩253,645,043 bytes，文件内容613.56MiB，原tar约661MB。
- 迁移已于2026-03-30闭环；当前系统从 `/root/.openclaw` 运行。删除前确认无进程打开、无配置或cron运行引用、gzip完整性正常。
- 经 Bruce 明确确认，按 SHA256 `1f03b3508b258a1b87882ee586416947faf469589d649ea67f5c0f720bff7d53` 精确匹配后永久删除；无单独 `/root/openclaw-config.tar`。
- 释放253,645,043 bytes；根盘约68%、可用16G。删除后 Gateway runtime/probe正常，chief当前索引路径不变且FTS ready。
- 该历史迁移快照不可恢复；当前业务源文件、agent数据和活动索引均未修改。

## 2026-08-14 · 旧系统/安装文件第二阶段清理

- 经 Bruce 明确授权，删除已失败回滚的 `codex-0144`、旧 Codex beta.6 generation、未被当前注册表使用的旧 npm `node_modules`。
- 删除 Puppeteer Chrome/Headless Shell 131（保留148）、已停用 Weixin 2.3.1、Claude 4.7 迁移临时目录及 2026-05-01 Weixin 旧备份；目标均先验证为非符号链接目录且无进程占用。
- 清空 Snap 下载缓存，当前已安装 Snap 修订与实体保留；apt 无可 autoremove 包，Docker 活动 sandbox 保留。
- 精确回收 3,519,983,616 bytes；根盘 68%→61%，当前可用19G。连同当日前两次清理，按删除记录累计回收约18.5GB。
- 验证：Gateway probe ok；当前5个插件均从保留的新 generation 加载；main/chief FTS ready；Snap、Docker、inode 健康。
- 删除项不可原地恢复，但均是过期安装副本或可重新下载的缓存；当前版本、当前备份及 agent 数据未动。

## 2026-09-01 · GPT-5.6 Sol 提升为全局默认模型

- 按 Bruce 要求，将 `agents.defaults.model` 调整为 `openai/gpt-5.6-sol` → ZenMux key1/Fable 5 → ZenMux key2/Fable 5。
- `api-worker`、`market` 的 agent 级模型覆盖保持不变；其余未覆盖 agent 继承新默认链。
- 配置 dry-run 与写入校验通过，Gateway 热加载，无重启；`openclaw models list` 标记顺序正确，runtime/probe 正常。
- 回滚备份：`/root/.openclaw/backups/openclaw.json.pre-gpt56sol-default-20260901`。

## 2026-09-01 · 永久删除客服 agent

- 按 Bruce 明确要求永久删除 `kefu`，且不创建备份；执行前确认其无 binding、无专属 cron、无运行进程或沙箱容器。
- 通过 `openclaw agents delete kefu --force` 删除注册项、workspace、agent 状态/会话；清理 6 个旧备份中的客服专属子目录和 1 个建客服前的专属配置备份。
- 清理 Wiki 中 370 个 `bridge-workspace-kefu-*` source，执行 compile + lint 更新索引；共享历史日志中偶发文字提及未作为删除目标。
- 共享 `symlink-integrity-check` cron 仅移除客服同步、remote 与 sandbox 检查，其他 agent 检查保持不变；10 份共享配置备份仅移除 `kefu` agent 对象。
- 最终验证：agent/binding/cron/命名路径与 Wiki 索引均无客服活动残留；Gateway runtime/probe 正常。删除不可恢复。

## 2026-09-02 · OpenClaw 2026.8.2 升级与中断后审计

- OpenClaw 从 `2026.7.1-2` 升级到 stable `2026.8.2`；安装后曾短暂出现磁盘 8.2 / Gateway 旧进程错位，Bruce 通过 SSH 重启 Gateway，09:29:27 起 CLI/npm/runtime 均为 8.2。
- 只读验证：systemd active、probe ok、单一 Gateway PID；回滚目录 81M，6 个 tgz 均通过 gzip 校验，目录/敏感文件权限为 700/600。
- 升级后阻塞项：个人微信 2.4.6 导入 8.2 已移除的 `plugin-sdk/channel-runtime` export 失败，所有账号 not-running；Feishu/Perplexity 仍为 2026.7.1；plugin registry stale。
- 402 自愈脚本只扫描 `dist/errors-*.js`，而 8.2 的 `RAW_402_MARKER_RE` 位于 `classify-*.js`，ExecStartPre 虽返回成功但日志显示未找到目标，补丁未生效。
- 企业微信与飞书连接日志正常；安全审计保持 `0 critical / 4 warn / 1 info`，防火墙/端口暴露面无回归。Gateway cgroup current/peak 达 5.16G/5.67G，微信 5 账号累计 40 次失败并继续重试。
- npm latest 微信插件 2.4.8 已移除旧 `channel-runtime` import，具备 8.2 兼容修复方向；但不含现有 warm-up/ret=-2 本地补丁，升级时需重移植。
- 本轮仅审计，未修改配置/插件/服务；后续插件更新、补丁适配与 Gateway restart 必须经 Bruce 确认。

## 2026-09-02 · OpenClaw 2026.8.2 升级后集中修复

- 经 Bruce 明确批准，创建修复前快照 `/root/.openclaw/backups/openclaw-2026.8.2-repair-pre-20260902-094821`，包含 npm generations、主配置、微信原文件、脚本/systemd 与 contact-delivery 元数据；压缩包与权限校验通过。
- `@tencent-weixin/openclaw-weixin` 升级并 pin 到 2.4.8，`@openclaw/feishu`、`@openclaw/perplexity-plugin` pin 到 2026.8.2；微信 warm-up/ret=-2 补丁已移植，文件语法与 12/12 插件加载检查通过。
- `scripts/patch-402-failover.py` 不再猜测 `errors-*` 文件名，改为扫描含 `RAW_402_MARKER_RE` 的顶层 bundle；8.2 `classify-*` 已补可选引号，零候选/正则形状变化返回非零，systemd 重启前后均验证幂等。
- 为本地 `contact-delivery` manifest 增加 `contracts.tools=["send_contact"]`；为现有 WeCom 2026.5.7 增加 `plugins.entries.wecom-openclaw-plugin.hooks.allowConversationAccess=true`，未升级会替换整套技能的 WeCom 2026.8.17。
- 09:56:43 systemd 重启完成，新 PID 1913334；CLI/Gateway 2026.8.2、probe ok、Result=success、NRestarts=0。重启切断旧 Codex app-server turn 属预期维护中断，新会话已正常运行。
- 飞书/企业微信均 running+works，5 个个人微信账号均 running，且重启后真实微信消息完成处理；Memory Search 543/543、Dirty=no、FTS ready。
- Gateway cgroup 首次数据库校验短时峰值 4.07G，worker 退出后约 1.1G，低于修复前 5.16G；后续无 memory pressure/channel restart。安全审计维持 0 critical / 4 warn / 1 info。
- 未处理的独立治理项：Codex npm spec 未 pin、doctor 工具策略提示、Google 图像模型显式注册缺口与 ZenMux 订阅错误、宿主机 OS 待重启；本次未扩大权限、未改模型链。

## 2026-09-02 · 宿主机重启闭环与 OpenAI 迁移回滚

- 经 Bruce 已批准的维护窗口完成宿主机 reboot；新 boot_id `69b59229-f859-4c44-9cd3-77ad34861c26`，libc6 的 reboot-required 标记已清除。
- OpenClaw/Gateway 2026.8.2、12/12 插件、Feishu/WeCom/5 Weixin、Google 模型、key2 fallback、402 marker 与防火墙姿态均复测通过；安全审计 0 critical / 3 warn / 1 info。
- Bruce 要求把 Validation Tracker 从 Gemini 迁到 OpenAI。确认该任务纯文本；系统默认 imageModel 已是 OpenAI GPT-5.5，先前 `MODEL_OK` 仅验证文本请求。
- 真实后台请求显示：OpenAI 5.6 Sol 无 chief usable profile，OpenAI 5.5 账户 inactive，OpenAI-Codex 与 OpenRouter/OpenAI 均 HTTP 403。临时 allowlist/model 试验项已全部删除。
- 为保证生产任务可用，Validation Tracker 已回滚至 `google/gemini-3.1-flash-image-preview`，并真实返回 `POST_REBOOT_GOOGLE_OK`；OpenAI 迁移待受保护认证可用后再执行。
- 回滚/恢复基线仍为 `/root/openclaw-backups/openclaw-post-8.2-{config,sqlite,metadata}-pre-20260902-101915*`。

## 2026-09-02 · OpenClaw 8.2 最终升级后审计与宿主机加固

- 创建并验证回滚点 `/root/.openclaw/backups/openclaw-8.2-final-audit-pre-20260902-1400`；所有 SHA-256 与 gzip 数据校验通过。
- 修复 8.2 升级后插件 registry/CLI metadata、402 marker、memory provenance identity、api-worker/market 路由；11 个 agent FTS/vector/embedding 全可用。
- 微信插件持久化生成独立 `cli-metadata.js`，未知 CLI 命令不再加载 runtime；个人微信向 Bruce 的升级测试消息真实 delivered，临时 cron 已删除。
- 安装 61 个 Ubuntu 更新并修复 fwupd 2.0.20 daemon/lib 一致性；因 AppArmor 更新完成整机重启。最终 failed units=0、reboot-required=no、Node 24.20.0。
- SSH 保持仅密钥认证，关闭 X11、MaxAuthTries=3；UFW 仅 22/80/443，nginx/AppArmor/unattended-upgrades 正常，18789 无公网防火墙放行。
- 最终门禁：OpenClaw/CLI/Gateway/stable=2026.8.2，plugins doctor/三通道/health/event loop 正常；安全审计 0 critical / 2 warn / 1 info。
- Registry stale 的剩余原因是 8.2 多 workspace 元数据不一致（persisted main/current chief，differences=[]），不影响插件加载；未修改核心代码。
- 46 条历史 outbound dead-letter 无官方安全清理 API；128 条 plaintext secret finding 均位于权限 700/600 的受限状态文件，0 unresolved，不能绕过掩码录入自动搬迁。
- chief OpenAI cron 仍无法直用 OpenAI，测试实际 reroute 到 ZenMux；Validation Tracker 保留 Gemini。heartbeat 在本轮长 main turn 中排队超时，既有成功历史与主模型实测证明非配置故障。

