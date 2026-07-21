# MEMORY.md
<!-- 硬上限 120 行。超限时压缩：具体事实下沉 memory/*.md，Hot 层只留模式和结论。 -->

长期记忆。只写值得长期保留、未来反复有用的内容。按分区管理，新信息替换旧信息而非追加。

## Identity & Preferences（身份与偏好）

- User: Bruce, timezone Asia/Shanghai
- Assistant: Kaopuge (🐎), 企业微信名"服务员Bruce", 世界最优秀的 CEO, 偏冷静带幽默
- 工作态度：先动手试再下结论；报方案不报困难；穷尽三条路径才有资格说做不到
- 优先沿用浏览器 Dashboard + 本地 Gateway；先跑通核心功能再补原生 app
- 当前阶段优先"企业微信私聊"场景
- 每天上午 8 点自检，正常不打扰，异常先修再报

## Architecture Decisions（架构决策）

- 单 Gateway :18789，所有渠道通过 bindings per-user 路由
- 企业微信：Bruce (QiuHongYue) → chief，其他 → chief-user
- 飞书：Bruce (ou_2057df7422741af99b3f14f79fd527f6) → chief，其他 → chief-user；peer binding 须带 `accountId: "*"`
- 微信/本地浏览器 → chief
- 已废弃：team gateway (:8899)、8888 HTTPS 代理、ai.openclaw.team / ai.openclaw.lan8888-proxy（2026-03-23 全删）
- CEO 阵列：chief 是默认业务入口，main 是系统主脑/平台维护
- **权限边界**：main = 平台最高权限 + 全局 OpenClaw 可见性（cron / workspace / 其他 agent 资源）。chief 无权知晓 main 内部台账、全局审计过程、其他 agent workspace 状态。对 chief / 任何 CEO 阵列成员回复时：只曝露 “结论 + 对对方的要求”，不曝露审计过程 / 其他 agent 状态 / 平台内部机制。
- CEO 5-Agent 同步：symlink 方案（setup-symlinks.sh），chief workspace 为 single source of truth
- symlink-integrity-check cron 每天 03:00（main 负责）
- Workspace 私有仓库：`https://github.com/qmpnqs8nmq-create/BBB.git`
- Sandbox 镜像 `openclaw-sandbox:bookworm-slim` 必须装 python3（pinned mutation helper 依赖）。2026-04-20 加装；重建基础镜像时要沿用
- 独立沙箱 agent（benben/mangba/mangba-guest）的 workspace 不走 symlink，CTX-CONTROL-RULES.md 由每日 03:00 cron 自动 rsync 同步（main 为权威副本）
- benben 沙箱安全基线（2026-04-20）：docker.network=none（无 egress，web_fetch 走 Gateway）+ 每日 03:00 cron 审计（git remote 白名单 qmpnqs8nmq-create/ + network 配置漂移检测 + 容器镜像陈旧检测）
- Jamie 频率上限硬规则：24h ≤ 1 主动、 7d ≤ 3 主动，无日志则默认不发（fail-safe）；见 workspace-benben/jamie-weekly-companion-cron.md Step 2.5
- market agent 模型规则：用 Sonnet 5（不用 Fable/Opus，轻量场景），主/备跨 ZenMux key，GPT-5.5 兜底；2026-07-19 已将活动配置中的 Sonnet 4.6 全量迁移为 Sonnet 5
- **ZenMux/OpenAI 模型路由（2026-07-19）**：default = key1/`anthropic/claude-fable-5`；fallback#1 = `openai/gpt-5.6-sol`（ChatGPT Pro OAuth/Codex harness，250k）；fallback#2 = key2/Fable 5。两个 ZenMux key 均登记 Fable 5、Sonnet 5、Opus 4.8，Sonnet 4.6 已从活动配置移除；OpenAI 保留 GPT-5.6 Sol/5.5。当前两个 ZenMux key 实际请求均因额度 402，已验证自动由 5.6 Sol 接管。
- **memory_search embedding = Gemini（2026-05-30 切换）**：`agents.defaults.memorySearch` 必须写 provider `gemini`（不是 google）+ `gemini-embedding-001`（3072 维），auth 走 google:default(api_key)；OpenAI OAuth 不能做 embedding。改配置后须 restart Gateway，并对**每个 agent**分别 `openclaw memory index --agent <id> --force`；索引 `providerKey` 含实际凭据 hash，各 agent 凭据解析不同也会触发 settings changed
- **⚠️ 改模型配置必须三层同步**：Gateway 会合并 (1) openclaw.json (2) 顶层 models/auth-profiles.json (3) 各 agent 的 models/auth-profiles.json；只改一处会让旧 key/版本复活。ZenMux 正确 base URL 为 `https://zenmux.ai/api/v1`（不是 `/v1`）。统一脚本批量处理、全量备份后验证 `openclaw models list`

## Operations（运维经验）

- 安全巡检 (healthcheck) 归 main，不归 chief（2026-03-22 定稿）
- 两层周日复盘：main 05:00 平台层 (PLATFORM_ITERATION_LOG.md)，chief 10:00 业务层 (SYSTEM_ITERATION_LOG.md)
- session 切换：context% 第一标准，60-70% 建议 /new，70%+ 必须切，详见 CTX-CONTROL-RULES.md
- session.reset = idle 24h（纯兜底），memoryFlush 在 compaction 前自动存档
- 日志归档：建设期 14 天，成熟后回收到 7 天，heartbeat 执行蒸馏+删除
- Docker: docker.io 28.2.2 (apt)，用于 agent sandbox

## Active Commitments（进行中的承诺）

- 跟踪 openclaw/openclaw#55897
- chief 业务层改善：启动流程、探索熔断、Exploration Discipline 具体化

## Misc
- openclaw-weixin 新用户接入：`liteapp.weixin.qq.com/q/` 链接有效期只有几分钟，必须朋友人在旁边能立刻点时才生成。协作模式：Bruce 说"发链接" → 我起 `openclaw channels login --channel openclaw-weixin` + autobind 监听脚本 + 通知 cron，一条龙自动绑 agent（如 mangba-guest），不要提前生成囤着。
- 记忆系统 2026-03-28 重构：单日单文件 + 五分区 + 禁止 topic-split，详见 AGENTS.md
- 建设期容量策略：每日 ≤150 行、MEMORY ≤120 行、14 天归档；成熟后收紧到 60/80/7
- **成熟切换时机**：系统连续 2 周无架构级变更、日均话题 ≤3 个时，执行容量回收

## Recent State（近期状态，可滚动覆盖）
- 本机版本 OpenClaw `2026.7.1-2`，channel=stable（2026-07-19 从 beta.6 切换）；Feishu/Perplexity 为各自 stable `2026.7.1`，Codex 为其 latest `2026.7.1-1`（内含 Codex 0.144.1）。CLI/Gateway probe 正常，402 自愈补丁会在 Gateway 启动前自动重打
- 持续性已知项（非故障，待 Bruce）：weixin getUpdates errcode -14 每小时 session-expired pause 60min（需重登/换 token）；wecom admin WSClient bestEffort 投递偶发失败（cron e463b042 疑似孤儿）；两个 ZenMux key 当前均 402，由 GPT-5.6 Sol 自动接管
- cron timeout 治理：`daily-self-check-8am` 与 chief 周日系统巡检反复 timeout；已用 `openclaw doctor --fix` + 周日巡检 `lightContext=true`/timeout 900s/thinking=minimal + coach audit `lightContext=true`/timeout 360s；禁用两个 2026-05 陈旧 NVDA reminder cron。装 bubblewrap 0.9.0 修 Codex sandbox 告警
- 周度安全巡检最新为 0 critical / 4 warn / 1 info（2026-07-13；均既有姿态：多 agent `exec security=full`、main allowlist 的 find/sed 缺 strictInlineEval、weixin 读文件+网络发送启发式、飞书建文档可授请求者权限）。可选加固需 Bruce 确认，未自动改安全/全局配置
- benben 排障：① web_search 用 Perplexity 别配 `webSearch.model=sonar-pro`（带 max_tokens 走 legacy 报 unsupported_content_budget），保留 key + `timeoutSeconds=60`；② "failed before producing a reply"=会话历史 Anthropic thinking 签名损坏（`Invalid signature in thinking block`），`/new` 开新会话解；③ `dummy` MCP 报错=工具路由误调占位名，非配置缺失
- 日志噪音（已知非故障）：`[agent] run ... stopReason=stop` 以 ERROR 记录但实为 dream cycle 正常完成（isError=false）；`EmbeddedAttemptSessionTakeoverError` = chief dreaming-narrative 多 lane 并发抢 session 文件锁，反复出现但暂无害，均可忽略
- 接入老用户经验（刘董事长 mangba-guest 2026-06-08）：老用户走 binded_redirect 不产新账号文件→链接误判"过期"；直接看网关 dispatch 日志确认路由，别等新文件/别只信 sessions_list 活跃数；确认网关 pid 用 `openclaw gateway status`（pgrep 会误匹配 exec shell）
- 插件漂移经验：升级后 codex/feishu 若 doctor 报旧版且 `plugins update` 误报 up-to-date → 直接 `openclaw plugins install @openclaw/{codex,feishu}@版本 --force --pin` + restart；systemd 单元旧版本号非致命

## ⚠️ 402/failover 本地补丁（2026-06-12，升级后必重打）
- 根因：OpenClaw 的 RAW_402_MARKER_RE 入口正则不认带引号码值（ZenMux 返 `"code":"402"` 字符串）→ 撞 402 后 errCount 恒 0、零 failover、子 agent 0token 秒死。
- 补丁：定位 dist 中 `RAW_402_MARKER_RE`，把 `[:=]\s*402\b` / `[:=]\s*` 这类入口补成可容忍引号的 `[:=]\s*["']?402\b` / `[:=]\s*["']?`。只改 1 处。2026-06-12 备份 `/root/.openclaw/backups/errors-DcOiGp7S.js.orig-*`；2026-06-24 升级 6.10 后重打到 `dist/errors-BmvajW3H.js`，备份 `backups/errors-BmvajW3H.js.orig-20260624-214119`。
- ⚠️ 改的是 node_modules 编译文件，**OpenClaw 升级会覆盖→升级后需 grep `RAW_402_MARKER_RE` 重打同一补丁**。验证：子agent key1→402→failover decision reason=rate_limit→自动切→run done。
- 另修：billingBackoffHoursByProvider key 从不存在的 "custom-zenmux-ai" → 真实 zenmux-key1/key2=1h（保留）。子 agent model 覆盖实测无效（报告值≠执行值）已回滚。上游 issue 草稿：memory/tasks/openclaw-402-subagent-failover-issue.md（Bug1=正则已本地修 / Bug2=收敛丢 status / Bug3=subagents.model 执行不一致）。
- 配置保留：primary=key1，fallbacks=[codex/gpt-5.5, key2]。

## Promoted From Short-Term Memory (2026-07-21)

<!-- openclaw-memory-promotion:memory:memory/2026-07-20.md:22:33 -->
- 两个 workspace 已完成日快照并推送尝试；外部模型额度和插件配置未擅自更改。 ## 14:00 本本 memory_search 重复报错诊断 - 本本自 7/18 23:09 起反复报 `index provider settings changed`；7/20 13:38 同一轮连续 6 次失败，界面显示的 Tool error 与 trajectory 原始结果一致。 - 深度探针确认 Gemini `gemini-embedding-001` 可用、3072 维向量扩展/FTS 均正常；唯一失败项为 benben 索引 identity mismatched，非 Gateway、模型或 provider 故障。 - benben SQLite 中旧 providerKey `bd508113…` 仍有 5612 处；当前运行时凭据/配置指纹已变化。该类问题在 7/15 chief 已发生并通过逐 agent `--force` 重建修复。 - 触发链：7/13 OpenClaw beta.6 升级后 provider/凭据解析指纹变化；main/chief 已重建或修复，benben 未重建，直到 7/18 再调用才暴露。 - 当前只完成诊断；未改全局配置、未重启 Gateway、未执行 benben 全量重建。修复应仅针对 benben：先备份 SQLite，再 `openclaw memory index --agent benben... [score=0.859 recalls=6 avg=0.782 source=memory/2026-07-20.md:22-33]
<!-- openclaw-memory-promotion:memory:memory/2026-07-20.md:30:41 -->
- 当前只完成诊断；未改全局配置、未重启 Gateway、未执行 benben 全量重建。修复应仅针对 benben：先备份 SQLite，再 `openclaw memory index --agent benben --force`，完成后做真实检索验证。 ## 14:08 本本 memory_search 索引重建完成 - Bruce 确认后，先备份 benben SQLite 至 `/root/.openclaw/backups/benben-memory-reindex-20260720-1405/`（562MB，SHA256 已生成），再执行 `openclaw memory index --agent benben --force`。 - 命令正常完成：`Memory index updated (benben)`；索引 identity 从 mismatched 变为 valid，文件 276→301，chunks 4621→5089，Gemini/向量深度探针正常。 - 真实检索 `Jamie Peddie GPA SAT 1550 基本情况` 返回 5 条结果，最高分 0.781，命中 MEMORY.md 与本本 session；原 `index provider settings changed` 已消失。 - `dirty=true` 仍存在，但 scan=301/301、issues=[] 且实时检索成功，判断为活动 session... [score=0.818 recalls=5 avg=0.797 source=memory/2026-07-20.md:30-41]
<!-- openclaw-memory-promotion:memory:memory/2026-07-16.md:2:4 -->
- 08:01 每日自检: Gateway 运行正常，connectivity probe=ok；21 个 cron 无 consecutiveErrors/lastStatus=error。; 两个 workspace 已自动提交并推送：main `f5dd09a`，chief `fbe4178`。; 最近 50 行日志无 error，但持续出现配置告警：openclaw-weixin 重复插件 ID、whatsapp/wecom 配置指向未安装插件；未自动改配置，避免影响现有消息通道。 [score=0.803 recalls=0 avg=0.620 source=memory/2026-07-16.md:2-4]
<!-- openclaw-memory-promotion:memory:memory/2026-07-16.md:7:8 -->
- 08:03 自检重试: 08:00 首次运行因错误命令 `openclaw logs 50` 超时，任务状态短暂为 error/consecutiveErrors=1；本次改用日志文件 `tail -n 50` 后完成，Gateway 与其余 cron 正常。; main workspace 已生成快照 `efcb6fd`；配置告警未自动修复，避免误伤现有消息通道。 [score=0.803 recalls=0 avg=0.620 source=memory/2026-07-16.md:7-8]
