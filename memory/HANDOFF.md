last: 2026-05-08 23:29
topic: OpenClaw 升级 2026.5.2 → 2026.5.7 完成
context:
  - wecom 插件同步升到 2026.5.7（最新）
  - doctor --fix 应用：bundledDiscovery=compat, visibleReplies=message_tool, 禁用 10 个未用 skill
  - Gateway PID 1341263 健康
  - 核心仍硬编码推荐 wecom@2026.4.23（过期文案，无视）
todo:
  - 留意 wecom 插件 5.7 实际跑一段时间后是否稳定
  - 关注 OpenClaw 下个版本是否更新硬编码推荐文案
lesson:
  - doctor --fix / gateway restart 会 SIGTERM 当前 exec 会话，要先告诉 Bruce 会被打断，做完主动 poll 状态再汇报，不要让对方反过来催
note: 今日 memory/2026-05-08.md 已记录
