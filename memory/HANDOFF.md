# HANDOFF

- 最后活跃：2026-05-02 12:26 GMT+8
- 当前话题：给 Bruce 朋友接入 mangba-guest（openclaw-weixin）
- 关键上下文：
  - 朋友要用个人微信扫码/点链接，绑到 agent `mangba-guest`
  - openclaw-weixin login 链接 `liteapp.weixin.qq.com/q/` 只有几分钟有效期
  - 协作模式：Bruce 说"发链接" → 我现场生成 + 起 autobind 监听 + 通知 cron → 全自动绑定、重启 Gateway、回报结果
  - autobind 脚本模板见本次会话（watch /root/.openclaw/openclaw-weixin/accounts/ 新 .json → diff 出 accountId+userId → 写 binding → gateway restart）
  - 已写入 MEMORY.md Misc 分区
- 待办：
  - 等 Bruce 说"发链接"（朋友准备就绪时）
  - 遗留：Jamie 那"3 条主动消息"来源仍没澄清（日志只有 1 条 reply，见 2026-05-02 10:10）
- 今日笔记：memory/2026-05-02.md
