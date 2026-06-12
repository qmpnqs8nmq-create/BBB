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

## Promoted From Short-Term Memory (2026-06-12)

<!-- openclaw-memory-promotion:memory:memory/2026-06-06.md:3:6 -->
- 08:00 每日自检: Gateway: running, healthy (pid 1786727, probe ok); 日志: 无 error; Cron: daily-self-check 昨日(06-05)run 失败 — zenmux quota_exceeded（订阅额度耗尽），今日 run 已恢复正常。consecutiveErrors=1 为昨日遗留。; Git: workspace + workspace-chief 均已 commit（push best-effort） [score=0.926 recalls=0 avg=0.620 source=memory/2026-06-06.md:3-6]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:3:6 -->
- 08:00 daily-self-check: Gateway running (pid 1689797, probe ok), 无最近 error 日志; workspace + chief 自动 snapshot 已 push; ⚠️ 3 个 cron 处于 error 状态（均为历史失败，非今日新增）：; 7a59f223 周日系统巡检（5d ago） [score=0.904 recalls=0 avg=0.620 source=memory/2026-05-29.md:3-6]
<!-- openclaw-memory-promotion:memory:memory/2026-06-01.md:3:6 -->
- 08:00 每日自检: Gateway 正常运行 (pid 1722065, active, probe ok)。; Cron：仅 1 个任务 (daily-self-check)，consecutiveErrors=0, lastStatus=ok。; Git：workspace + chief 均已提交快照 (14 / 13 files)。; ⚠️ 注意：日志中 openclaw-weixin 通道反复报错 `getUpdates: session expired (errcode -14), pausing bot for 60 min`，自 05:32 起每小时一次（05:32/06:32/07:32）。weixin bot 会话过期，需重新登录/刷新凭证，非可安全自修复项，已告知 Bruce。 [score=0.900 recalls=0 avg=0.620 source=memory/2026-06-01.md:3-6]
<!-- openclaw-memory-promotion:memory:memory/2026-06-01.md:9:12 -->
- 10:00 周度安全巡检 (cron security-audit): status: gateway 健康，sessions+cron 正常运行（本 job 在列）。--deep 探针超时=误报（插件加载~21-27s 超过 10s 探针窗）; security audit: 0 critical / 6 warn / 1 info。warn 均为既有配置姿态：exec security=full(多 agent)、find/sed 无 strictInlineEval、codex/feishu 未 pin 版本、openclaw-weixin 两处 exfiltration 启发式告警、feishu doc create 授权。单操作员信任模型下属可接受姿态; update: 有可用更新 npm 2026.5.28（当前 stable）; 结论：本周巡检正常，无 critical，无新增风险，未通知 Bruce [score=0.900 recalls=0 avg=0.620 source=memory/2026-06-01.md:9-12]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:11:14 -->
- 10:30 ZenMux opus 升级 4.8 + 删 key3（Bruce 主导）: 验证 ZenMux 确有 opus-4.8（key1/key2 实跑 HTTP 200，真回包），sonnet 无 4.8 → sonnet 保持 4.6 不动; 目标态：key1/key2 都有 opus-4.8 + sonnet-4.6；删除 key3（provider+模型+auth+fallback 全清）; ⚠️ 关键教训：模型配置有 **3 层来源会被合并**，改一处不够，key3 反复"复活"：; /root/.openclaw/openclaw.json [score=0.879 recalls=0 avg=0.620 source=memory/2026-05-29.md:11-14]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:15:18 -->
- 10:30 ZenMux opus 升级 4.8 + 删 key3（Bruce 主导）: 顶层 /root/.openclaw/models.json + auth-profiles.json; **每个 agent 各自的** agents/*/agent/models.json + auth-profiles.json（24 文件）; 处理：脚本 /root/.openclaw/tmp/zenmux-key3-cleanup.py 批量删 key3 + opus4.7→4.8，全量备份在 backups/zenmux-key3-cleanup-20260529-105511/; 验证：openclaw models list 只剩 key1/key2 × (opus-4.8 + sonnet-4.6)，无 key3；main 自身已跑在 opus-4.8 [score=0.879 recalls=0 avg=0.620 source=memory/2026-05-29.md:15-18]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:19:20 -->
- 10:30 ZenMux opus 升级 4.8 + 删 key3（Bruce 主导）: 副作用提醒：restart 会断当前 webchat 连接（SIGTERM），属正常，等几秒重连即可; market agent 之前是 4.7，本次一并统一到 4.8（其 primary 仍是 sonnet，未变） [score=0.879 recalls=0 avg=0.620 source=memory/2026-05-29.md:19-20]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:23:26 -->
- 15:45 OpenClaw 升级 2026.5.18 → 2026.5.27: 触发：Bruce 问最新版/是否值得升。最新稳定 5.27（5/28 发布），隔 6 个稳定版~11天; 升级理由：安全加固（群prompt不进system、记忆按不可信处理、SSRF/路径穿越修复、无auth Tailscale拒绝）+ Gateway启动/回复性能 + Memory/QMD召回正确性 + cron并发默认提到8; 执行：备份27个配置文件→/root/.openclaw/backups/pre-upgrade-20260529-110818；npm -g 升级；config validate 通过；gateway restart（SIGTERM带走旧进程，systemd自动拉起）; 验证 OK：CLI+Gateway 均 2026.5.27 一致、running；models list 三层无旧key复活/无幽灵sonnet-4.8（MEMORY最担心的点，干净）；fallback链完整；cron 35 jobs enabled，下次唤醒 20:00 [score=0.879 recalls=0 avg=0.620 source=memory/2026-05-29.md:23-26]
<!-- openclaw-memory-promotion:memory:memory/2026-05-29.md:27:28 -->
- 15:45 OpenClaw 升级 2026.5.18 → 2026.5.27: 唯一差异：6个无tag的 codex/* 本地harness目录消失（codex CLI不在PATH，残留探测目录，无害）; 无breaking change影响本部署 [score=0.879 recalls=0 avg=0.620 source=memory/2026-05-29.md:27-28]
<!-- openclaw-memory-promotion:memory:memory/2026-06-07.md:9:12 -->
- 11:12 OpenClaw 最新版本复核: Bruce 质疑“这么长时间都没有新版本吗”，复查 npm + GitHub。; npm `openclaw` dist-tags: stable `latest=2026.6.1`，beta `2026.6.5-beta.2`，alpha `2026.5.19-alpha.1`，modified `2026-06-07T00:17:47.824Z`。; GitHub Releases: `v2026.6.5-beta.2` published `2026-06-07T00:26:39Z`，为 prerelease；最新稳定仍是 `v2026.6.1`。; 本机仍是 `OpenClaw 2026.5.27 (27ae826)`。 [score=0.868 recalls=0 avg=0.620 source=memory/2026-06-07.md:9-12]
