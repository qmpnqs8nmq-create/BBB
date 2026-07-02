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
- 本机版本 OpenClaw 2026.6.10（2026-06-24 从 2026.6.5 升级，CLI/Gateway 已一致）
- ⚠️ `daily-self-check-8am` cron 反复 timeout（~600s 撞上限，6/14、6/19 均 consecutiveErrors↑），每轮快速收尾会清零但根因是自检任务拖太久，已报 Bruce，建议拆分/提速
- 6.10 升级后插件漂移经验：codex/feishu 若 doctor 报旧版本且 `plugins update` 误报 up-to-date，直接 `openclaw plugins install @openclaw/{codex,feishu}@版本 --force --pin` 后 restart；systemd service 文件旧版本号非致命。
- benben/web_search 用 Perplexity：不要配置 `plugins.entries.perplexity.config.webSearch.model=sonar-pro`，否则带 `max_tokens` 会走 legacy path 报 `unsupported_content_budget`；保留 API key + `timeoutSeconds=60` 即可。

## ⚠️ 402/failover 本地补丁（2026-06-12，升级后必重打）
- 根因：OpenClaw 的 RAW_402_MARKER_RE 入口正则不认带引号码值（ZenMux 返 `"code":"402"` 字符串）→ 撞 402 后 errCount 恒 0、零 failover、子 agent 0token 秒死。
- 补丁：定位 dist 中 `RAW_402_MARKER_RE`，把 `[:=]\s*402\b` / `[:=]\s*` 这类入口补成可容忍引号的 `[:=]\s*["']?402\b` / `[:=]\s*["']?`。只改 1 处。2026-06-12 备份 `/root/.openclaw/backups/errors-DcOiGp7S.js.orig-*`；2026-06-24 升级 6.10 后重打到 `dist/errors-BmvajW3H.js`，备份 `backups/errors-BmvajW3H.js.orig-20260624-214119`。
- ⚠️ 改的是 node_modules 编译文件，**OpenClaw 升级会覆盖→升级后需 grep `RAW_402_MARKER_RE` 重打同一补丁**。验证：子agent key1→402→failover decision reason=rate_limit→自动切→run done。
- 另修：billingBackoffHoursByProvider key 从不存在的 "custom-zenmux-ai" → 真实 zenmux-key1/key2=1h（保留）。子 agent model 覆盖实测无效（报告值≠执行值）已回滚。上游 issue 草稿：memory/tasks/openclaw-402-subagent-failover-issue.md（Bug1=正则已本地修 / Bug2=收敛丢 status / Bug3=subagents.model 执行不一致）。
- 配置保留：primary=key1，fallbacks=[codex/gpt-5.5, key2]。

## Recent Findings（2026-06-27，可滚动）
- benben "failed before producing a reply" 根因：会话历史里 Anthropic thinking 签名无法重放/已损（`Invalid signature in thinking block`）→ 旧会话反复失败。临时解：`/new` 开新会话；彻底清需 Bruce 确认后归档/重置 session 文件。（非上下文超限、非 dummy MCP）
- benben `dummy` MCP 报错（`unknown MCP server 'dummy'`）：模型工具路由误把占位名 dummy 当 MCP server 调，非配置缺失；频繁复发再清 Codex session/cache。

## Promoted From Short-Term Memory (2026-07-02)

<!-- openclaw-memory-promotion:memory:memory/2026-06-29.md:2:5 -->
- 08:00 Daily self-check: Gateway healthy: systemd user service active, connectivity probe ok, admin-capable.; Recent logs had no errors; noted one migration warning about legacy plugin install index conflicts for codex/feishu.; Cron check: daily-self-check-8am lastStatus=ok, consecutiveErrors=0.; Auto snapshots created: workspace 31384f2, workspace-chief b557e60; push attempted best-effort. [score=0.815 recalls=0 avg=0.620 source=memory/2026-06-29.md:2-5]
