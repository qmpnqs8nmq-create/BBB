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
- CEO 5-Agent 同步：symlink 方案（setup-symlinks.sh），chief workspace 为 single source of truth
- symlink-integrity-check cron 每天 03:00（main 负责）
- Workspace 私有仓库：`https://github.com/qmpnqs8nmq-create/BBB.git`
- Sandbox 镜像 `openclaw-sandbox:bookworm-slim` 必须装 python3（pinned mutation helper 依赖）。2026-04-20 加装；重建基础镜像时要沿用
- 独立沙箱 agent（benben/mangba/mangba-guest）的 workspace 不走 symlink，CTX-CONTROL-RULES.md 由每日 03:00 cron 自动 rsync 同步（main 为权威副本）
- benben 沙箱安全基线（2026-04-20）：docker.network=none（无 egress，web_fetch 走 Gateway）+ 每日 03:00 cron 审计（git remote 白名单 qmpnqs8nmq-create/ + network 配置漂移检测 + 容器镜像陈旧检测）
- Jamie 频率上限硬规则：24h ≤ 1 主动、 7d ≤ 3 主动，无日志则默认不发（fail-safe）；见 workspace-benben/jamie-weekly-companion-cron.md Step 2.5
- market agent 模型规则：用 sonnet（不用 opus，轻量场景），主/备跨 zenmux 三把 key 异构，GPT 兜底；Anthropic 版本跳过 4.7，4.6 之后直接 4.8（5 月），所以市面上没有 sonnet-4.7 这个东西

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

- 记忆系统 2026-03-28 重构：单日单文件 + 五分区 + 禁止 topic-split，详见 AGENTS.md
- 建设期容量策略：每日 ≤150 行、MEMORY ≤120 行、14 天归档；成熟后收紧到 60/80/7
- **成熟切换时机**：系统连续 2 周无架构级变更、日均话题 ≤3 个时，执行容量回收
