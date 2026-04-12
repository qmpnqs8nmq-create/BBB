# archive.md — 月度归档摘要

> 由 heartbeat 自动维护。每月一段，≤20 行。超过 6 个月的段落可删除。

## 2026-03（至今）

- 03-13: 身份设定(Kaopuge/🐎)、Docker安装、模型切换至openai-codex/gpt-5.4 OAuth、飞书通道启用
- 03-14: 企业微信私聊场景确定，助手名"服务员Bruce"，默认简洁风格
- 03-22: Session延续机制上线（HANDOFF+边聊边写+tasks/+5轮强制检查）；OpenClaw原生能力启用；weekly-governance-review cron创建；OpenRouter key异常→临时切gpt-5.4
- 03-16: 三套 Gateway 入口架构（local/team/remote），8888 局域网 HTTPS 代理 + session 隔离上线
- 03-17: 三套 token 核清，pairing 批准流程确立，发现 WebChat 默认共享主会话问题
- 03-18: 每日 8 点自检 cron 创建，安全自查修复无效字段，应急修复资料建立，8888 pairing watcher 上线
- 03-19: 自检正常运行，pairing-required 反复排查（WebSocket 代理 + trustedProxies），scope 基线不完整待修
- 03-20: 8888 代理架构定稿（直连主 Gateway :18789），废弃独立 team gateway :8899
- 03-21: Bruce 明确工作态度要求（先试再说、报方案不报困难、穷尽三条路径），写入长期记忆
- 03-22: Session 延续机制定稿（HANDOFF + 增量写入 + 归档闭环），安全巡检归 main
- 03-23: 单 Gateway 架构定稿，5-Agent symlink 同步重构，废弃 8888/8899/team 全套
- 03-24: Daily self-check 正常，多个 cron job 因 LLM 超时/网络报错，git push 超时
- 03-25: Chief系统全面核查（sandbox安全矩阵定稿、weixin清除保留wecom、zenmux 402正则monkey-patch、webchat elevated不可靠→引导终端操作）
- 03-26: Zenmux 3-key 轮换系统性重构（MRU sticky + 冷却轮换 + 跨 provider fallback 三级方案），402 仍泄露到 UI 待 upstream 修复
- 03-27: 152 SSH 隧道自动重连方案落地（LaunchAgent+wrapper脚本）；WORKING_RULES.md+INCIDENT_LOG.md最小治理闭环上线；webchat approval链路故障止血（缩回单key）；OpenClaw升级 3.23-2→3.24+monkey-patch重打；patch-openclaw.sh自动化脚本+上游issue#55897
- 03-28: 记忆系统重构（main+chief）——单日单文件、MEMORY.md 五分区、archive.md；OpenClaw 升级 3.24→3.28+monkey-patch重打；doctor --fix 迁移飞书配置；cron 超时修复；35个 topic-split+20个废弃脚本清理
