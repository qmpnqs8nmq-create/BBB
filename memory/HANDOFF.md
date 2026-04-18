# HANDOFF

- **最后活跃**：2026-04-17 16:12 CST
- **当前话题**：OpenClaw 系统审计 + 修复（第一轮已完成）
- **关键上下文**：
  - Bruce 拍板：Gateway 公网暴露 **不改**（token-only 够用）
  - 完成的修复：mangba/mangba-guest auth 空文件、孤立目录清理、sub-agent model allowlist bug（清空 agents.defaults.models）、权限/配置小项
  - 实测 sub-agent spawn `zenmux-key1/opus-4.7` 已 modelApplied:true
- **等 Bruce 决策的项**（都不紧急）：
  - chief tools.deny 兜底
  - memory-core dreaming plugin 是否启用
  - main agent 目录权限 700
  - 把 auth-profiles 空文件检查加到 healthcheck skill（防复发）
- **今日笔记**：memory/2026-04-17.md
- **完整报告**：memory/tasks/openclaw-system-audit-2026-04-17.md（待我追加修复记录）
