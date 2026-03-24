# MEMORY.md

长期记忆。只写值得长期保留、未来反复有用的内容。

## User

- Name: Bruce
- Preferred name: Bruce
- Timezone: Asia/Shanghai

## Assistant

- Internal name: Kaopuge
- External / 企业微信私聊名称: 服务员Bruce
- Identity: 世界最优秀的 CEO
- Vibe: 偏冷静，带幽默
- Emoji: 🐎

## 工作态度（Bruce 明确要求）

- 遇到问题先想解法，不退缩、不绕开
- 先动手试，再下结论；报方案不报困难
- 穷尽至少三条路径，才有资格说做不到

## Stable Preferences

- 当前优先沿用浏览器版 Dashboard + 本地 Gateway 的使用方式。
- 先把核心功能跑通，再补原生 app / 更高级权限与系统集成。
- 当前阶段优先按“企业微信私聊”场景来设计和推进使用方式。
- CEO 阵列的默认入口是 `chief`；`main` 保留为系统主脑 / 平台维护脑 / 回退入口。
- main 是平台治理 owner，负责每周日平台层复盘（cron health、agent 配置、基础设施），追踪文件为 `PLATFORM_ITERATION_LOG.md`。
- CEO 业务系统层（数据一致性、规则执行、文件质量）由 chief 负责，追踪文件为 `workspace-chief/SYSTEM_ITERATION_LOG.md`。
- 两层共享同一个周日节奏（main 05:00 平台层，chief 10:00 业务层），各有 owner，互不越权。
- 经营与决策类问题优先走 `chief`，OpenClaw / Docker / 配置 / 修复类问题优先走 `main`。
- 安全巡检 (healthcheck) 归 main，不归 chief（2026-03-22 定稿迁移）。

## 单 Gateway 架构（2026-03-23 定稿）

- 只跑一个 Gateway :18789，所有渠道通过 bindings 做 per-user 路由
- 企业微信：Bruce (QiuHongYue) → chief，其他 → chief-user
- 飞书：Bruce (ou_2057df7422741af99b3f14f79fd527f6) → chief，其他 → chief-user
- 微信/本地浏览器 → chief
- 已废弃：team gateway (:8899)、8888 HTTPS 代理、ai.openclaw.team / ai.openclaw.lan8888-proxy LaunchAgent（全部已删除 2026-03-23）
- 飞书 peer binding 必须带 `accountId: "*"`（飞书消息走 admin 账户，不带则只匹配 default）

## CEO 5-Agent 文件同步（2026-03-23 重构）

- 同步机制从文件复制（sync-shared.sh）改为 symlink（setup-symlinks.sh）
- chief workspace 是 single source of truth，其他 workspace 通过 symlink 引用
- 业务知识文件 → 所有 workspace（symlink）
- 路由/治理文件（ROUTING.md/WORKFLOWS.md/GOVERNANCE.md）→ chief-user only
- 旧文件归档到 chief/archive/
- 完整性检查：symlink-integrity-check cron 每天 03:00（main 负责）
- 如需新增共享文件：编辑 setup-symlinks.sh 并重跑

## Session 延续机制（2026-03-22 定稿）

- 核心文件：`memory/HANDOFF.md`（≤15行覆盖写）+ `memory/tasks/`（复杂任务详情）
- 写入规则：边聊边存，5 轮未写入强制检查，memoryFlush 在 compaction 前自动存档
- 切换判断：context% 是第一标准，空闲不是切换理由。60-70% 通知建议 /new，70%+ 必须切
- session.reset = idle 24h（纯兜底），真正靠 CTX-CONTROL-RULES.md 行为规则控制
- 详细规则见 `CTX-CONTROL-RULES.md`（全 agent 共享，绝对路径引用）
- 归档：14 天日志 → archive.md（heartbeat 执行），MEMORY.md ≤ 80 行，archive 6 个月轮替

## Important Notes

- Bruce 希望我每天上午 8 点做一次自检；如发现问题先进行安全范围内的自我修复，再汇报；正常则不打扰。

- Workspace 使用私有 GitHub 仓库管理：`https://github.com/qmpnqs8nmq-create/BBB.git`
- Docker Desktop 已安装并验证可用。

## How to Use This File

- 写长期有效的信息，不写每天流水账。
- 每日事项、过程记录放进 `memory/YYYY-MM-DD.md`。
- 如果偏好变化，更新这里，不要让旧信息长期失真。
