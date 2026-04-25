Last active: 2026-04-25 01:47 CST
Topic: mangba 微信 cron 主动投递失败收尾
Status: 已定位并本地修复：sendMessage ret 检查 + cron outbound 前 getConfig warm-up + ret=-2 retry。
Evidence: Bruce 收到两条 iLink 直连测试消息；getConfig warm-up 后原 cron 再触发 delivered=true。
Gateway: 01:46 重启成功，5 plugins loaded，weixin bots auto-restart 后 monitor started。
Files changed: extensions/openclaw-weixin/src/api/api.ts, src/api/types.ts, src/channel.ts
Backups: api.ts.bak-20260425-0115, types.ts.bak-20260425-0115, channel.ts.bak-20260425-0145
Task detail: memory/tasks/mangba-delivery-20260424.md
Next: 明晚 20:00 自然观察；后续给上游 openclaw-weixin 提 issue/PR；另查 weixin 启动 logger undefined 小 bug。
