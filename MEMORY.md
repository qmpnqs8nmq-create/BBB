# MEMORY.md
<!-- 成熟期硬上限 80 行；只保留稳定、长期、可复用信息。具体历史见 memory/archive.md 与 daily notes。 -->

## Identity & Preferences
- User: Bruce（Asia/Shanghai）；Assistant: Kaopuge 🐎（企业微信名“服务员Bruce”），冷静带幽默。
- 工作偏好：先动手验证再下结论，报方案不报困难；优先 Dashboard + 本地 Gateway，先核心后原生 app。
- 当前优先企业微信私聊；每天 08:00 自检，正常不打扰、异常先修再报。

## Architecture Decisions
- 单 Gateway :18789；企业微信 Bruce(QiuHongYue)→chief、其他→chief-user；飞书 Bruce→chief、其他→chief-user（peer binding 带 accountId: "*"）；个人微信/本地浏览器→chief。
- CEO 阵列：chief 是默认业务入口，main 是系统主脑/平台维护；平台级变更 DRI 归 main。
- 权限边界：对 chief/CEO 阵列只披露结论与对方所需动作，不披露 main 内部台账、全局审计过程或其他 agent 状态。
- CEO 5-Agent 用 symlink 同步，chief workspace 为业务 single source of truth；独立沙箱 agent 不走 symlink，全球治理规则由每日 03:00 cron 从 main 同步。
- 私有 workspace 仓库：https://github.com/qmpnqs8nmq-create/BBB.git。
- Sandbox 镜像 openclaw-sandbox:bookworm-slim 必须包含 python3；benben/mangba/mangba-guest 默认无网络，web_fetch 走 Gateway。
- benben→main A2A 长期放行；PACT 新课表由 benben 去重、换算 America/New_York 前一晚 22:00 后交 main 创建 deleteAfterRun 一次性 cron。
- Jamie 主动联系上限：24h≤1、7d≤3；无日志默认不发。

## Models & Memory
- 当前默认模型为 openai/gpt-5.6-sol（Codex OAuth，250k），唯一默认 fallback 为 key2/anthropic/claude-fable-5；Codex OAuth 不能直接供 chief 独立 cron 使用。
- market agent 使用 Sonnet 5，主备跨 ZenMux key，GPT-5.5 兜底。
- 模型配置需同步 openclaw.json、顶层 models/auth-profiles.json、各 agent models/auth-profiles.json；ZenMux base URL 是 https://zenmux.ai/api/v1。
- memory_search embedding 使用 Gemini：provider=gemini、model=gemini-embedding-001；配置/凭据指纹变化后逐 agent 备份 SQLite、强制重建索引并真实检索验证。
- benben 检索超时曾由同步 MMR 放大候选集导致；仅对 benben 关闭 MMR 后恢复，其他 agent 保持默认。

## Operations
- 安全巡检归 main；main 周日 05:00 做平台复盘，chief 10:00 做业务复盘。
- 会话 context 60–70% 建议 /new，70%+ 必须切；长内容先写文件，HANDOFF 承接。
- 日志成熟期：daily ≤60 行、MEMORY ≤80 行、7 天归档；当前 heartbeat 仍按 14 天归档规则执行，直至治理规则正式切换。
- 可能中断服务、改变安全边界或修改全局配置的操作必须先获 Bruce 确认；禁止在 main 会话直接 stop/restart Gateway。
- 高频 cron（<60 秒）必须人工 review，并有删除/终止条件；轮询优先后台脚本 + 低频 cron 关门。
- 插件升级后若 plugins update 误报 up-to-date，直接 plugins install @openclaw/{codex,feishu}@版本 --force --pin，再按变更门禁重启验证。

## Channels
- 企业微信 wecom 与个人微信 openclaw-weixin 是独立链路，禁止混作验证或未经确认互设兜底。
- 个人微信 liteapp.weixin.qq.com/q/ 登录链接仅几分钟有效；Bruce 说“发链接”后现场启动 login、autobind 监听与通知流程。
- 老用户可能走 binded_redirect、不生成新账号文件；以 Gateway dispatch 日志确认路由，不以新文件或 sessions_list 活跃数判断。
- 个人微信用户超过 24h 无 inbound 时冷推送可能 ret=-2；warm-up/重试补丁只改善可见性，不能突破服务端窗口。
- wecom_mcp allowlist 告警表示工具插件未启用，不代表企业微信 DM 被拒，勿误报审批。

## Upgrade-Sensitive Patches
- openclaw-weixin 2.4.8 的 channel.js 已移植 warm-up + ret=-2 重试补丁；插件升级会覆盖，升级后复核。
- ZenMux 402 failover 补丁：OpenClaw 的 RAW_402_MARKER_RE 需容忍带引号的 "402"；升级会覆盖，升级后 grep 定位、单点重打并用子 agent 真实 failover 验证。
- 编译文件补丁必须先备份、只改一处；不要用 reload 叠补丁规避 upstream bug。

## Active Commitments
- 跟踪 openclaw/openclaw#55897。
- chief 业务层改善：启动流程、探索熔断、Exploration Discipline 具体化。
- 修正 symlink-integrity-check cron C3：不要用不受支持的 docker ps --format '{{.ImageID}}'，改为逐容器 docker inspect --format '{{.Image}}'。
- 持续已知项：openclaw-weixin 账号 4d5b593c token/session 已失效；wecom admin WSClient best-effort 投递偶发失败；均不自动改凭据或安全边界。
