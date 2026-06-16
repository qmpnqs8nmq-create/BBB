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
- market agent 模型规则：用 sonnet（不用 opus，轻量场景），主/备跨 zenmux key 异构，GPT 兜底；Anthropic 版本跳过 4.7，4.6 之后直接 4.8（5 月）
- **ZenMux key 现状（2026-05-29）**：只剩 key1 + key2（key3 已删）。每把 key 带 opus-4.8 + sonnet-4.6。opus 已全线升 4.8；sonnet 无 4.8 版本，保持 4.6。default 主模型 = key1/opus-4.8，fallback = gpt-5.5 + key2/opus-4.8
- **memory_search embedding = Gemini（2026-05-30 切换）**：OpenAI embedding 额度 429 耗尽后切到 Gemini。`agents.defaults.memorySearch` = provider `gemini`（**必须写 gemini，不是 google**——google 插件注册的 adapter id=gemini/authProviderId=google；写 google 报 "Unknown memory embedding provider"）+ model `gemini-embedding-001`（3072 维），auth 走 google:default(api_key) 自动映射，免费。维度 3072 对当前 ~1200 chunk 规模属过剩但无害（存储/检索成本忽略），不降级；涨到几万 chunk 再考虑降 1536。⚠️ OpenAI OAuth(openai-codex) 不能做 embedding（无 /v1/embeddings 端点）。改 memorySearch 后必须 restart Gateway（CLI 重读但 Gateway 缓存旧值）+ 换 provider 后 `openclaw memory index --force` 全量重建（维度变了不兼容）
- **⚠️ 改模型配置必须三层同步**：模型/auth 配置有 3 处来源会被 Gateway 合并——(1) openclaw.json (2) 顶层 models.json + auth-profiles.json (3) 每个 agent 各自的 agents/*/agent/{models,auth-profiles}.json（约 24 文件）。只改一处会导致旧 key/旧版本"复活"。统一改用脚本批量处理（参考 tmp/zenmux-key3-cleanup.py 思路），全量备份后 restart 验证 `openclaw models list`

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
- 刘董事长接入 mangba-guest 已闭环（2026-06-08）：老用户走 binded_redirect 复用旧绑定不产新账号文件→链接误判"过期"；接入老用户直接看网关 dispatch 日志确认路由，别等新文件、别只信 sessions_list 活跃数；确认网关 pid 用 `openclaw gateway status`（pgrep -f openclaw-gateway 会误匹配 exec shell）
- 持续性已知项（非故障）：weixin getUpdates errcode -14 每小时 session-expired 自动 pause 60min（待 Bruce 关注 weixin 凭证）；wecom admin WSClient bestEffort 投递偶发失败；opus-4.8 偶发 timeout 由 gpt-5.5 兜底
- 本机版本 OpenClaw 2026.5.27；最新稳定 2026.6.1（2026-06-07 复核）

## Promoted From Short-Term Memory (2026-06-15)

<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:13:14 -->
- 14:00 fallback/子agent failover 深度排查(Bruce 主导): 临时绕过:等 key1 配额窗口刷新或充值,key1 本身能用后子 agent 撞它就不死。 根治:上游修 Bug1/2(/3)。 [score=0.815 recalls=0 avg=0.620 source=memory/2026-06-12.md:13-14]
<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:5:7 -->
- 14:00 fallback/子agent failover 深度排查(Bruce 主导): RAW_402_MARKER_RE 入口正则不容忍引号包裹的码值 → ZenMux 返回 "code":"402"(字符串)被挡 → 下游本可正确判 rate_limit 的逻辑到不了。; failover 决策点拿到的是被收敛的 "LLM request failed."(丢了 status+原文)→ 分类 null → 整条 fallback 链不触发(无论怎么配)。; agents.defaults.subagents.model 实测无效:config get 写入 key2,spawn 报告 key2,但执行日志仍 provider=key1 秒死。报告值≠执行值。 [score=0.815 recalls=0 avg=0.620 source=memory/2026-06-12.md:5-7]

## Promoted From Short-Term Memory (2026-06-16)

<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:10:12 -->
- 14:00 fallback/子agent failover 深度排查(Bruce 主导): 修了真实死配置:billingBackoffHoursByProvider 的 key 从不存在的 "custom-zenmux-ai" → 真实 zenmux-key1/key2=1h。保留。; 子 agent model 覆盖实测无效 → 已回滚。; 起草上游 issue:memory/tasks/openclaw-402-subagent-failover-issue.md [score=0.888 recalls=0 avg=0.620 source=memory/2026-06-12.md:10-12]
<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:17:20 -->
- 15:17 外科手术修补:402 failover 跑通(Bruce 要求"不管什么办法,跑通"): 根因确诊:dist/errors-DcOiGp7S.js 的 RAW_402_MARKER_RE 入口正则不认带引号的码值 "402"(ZenMux 返回字符串)。证据:撞402后 errCount恒为0、零failover动作、子agent 0token秒死。; 补丁:正则 `[:=]\s*402\b` → `[:=]\s*["']?402\b`(插入 ["']? 容忍引号)。仅1处替换。; 原文件备份:/root/.openclaw/backups/errors-DcOiGp7S.js.orig-*; 验证(端到端,日志铁证):子agent从key1起步→402→"auth profile failure state updated reason=rate_limit window=cooldown"→"failover decision decision=fallback_model reason=rate_limit"→自动切→run done PATCH_WORKS 19.7k tokens。对比修复前同测试:0token秒死零failover。 [score=0.837 recalls=0 avg=0.620 source=memory/2026-06-12.md:17-20]
<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:21:24 -->
- 15:17 外科手术修补:402 failover 跑通(Bruce 要求"不管什么办法,跑通"): Bruce 设定保留未动:primary=key1,fallbacks=[codex/gpt-5.5, key2]。; ⚠️ 代价:改的是 node_modules 编译文件,OpenClaw 升级会被覆盖→升级后需重打补丁 or 等上游issue合并。; 升级重打方法:同上 python 替换;补丁点 RAW_402_MARKER_RE。; 长久解:上游 issue 草稿 memory/tasks/openclaw-402-subagent-failover-issue.md(Bug1=正则,已本地修;Bug2=收敛丢status;Bug3=subagents.model执行不一致)。 [score=0.837 recalls=0 avg=0.620 source=memory/2026-06-12.md:21-24]
<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:3:4 -->
- 14:00 fallback/子agent failover 深度排查(Bruce 主导): 触发:Bruce 问 fallback 是否真能用 + 为何 402 满额不自动跳 + 子 agent 秒死自己不换。 根因(代码+实测坐实,OpenClaw 2026.6.5): [score=0.837 recalls=0 avg=0.620 source=memory/2026-06-12.md:3-4]
<!-- openclaw-memory-promotion:memory:memory/2026-06-12.md:8:8 -->
- 14:00 fallback/子agent failover 深度排查(Bruce 主导): 现象链:主 session 靠早先粘住的 key2 auto-override 活着;子 agent 全新 session 无 override → 从配置 primary(key1)起步 → 撞欠费 402 → 单发即死 0 token → 主 session 收 failed 回执 → 自己接手跑(Bruce 反复遇到的体验)。 [score=0.837 recalls=0 avg=0.620 source=memory/2026-06-12.md:8-8]
<!-- openclaw-memory-promotion:memory:memory/2026-06-13.md:3:6 -->
- 08:00 daily-self-check: Gateway: running healthy (pid 1889215, probe ok, v2026.6.5).; Logs: no errors in last 50 lines.; Git: workspace + chief committed daily snapshot. ✅; Note: self-check cron showed consecutiveErrors=2 / lastStatus=error from prior 2 runs ("LLM request failed") — transient LLM failures on previous days; today's run succeeded, so counter will reset. No action needed. [score=0.815 recalls=0 avg=0.620 source=memory/2026-06-13.md:3-6]
