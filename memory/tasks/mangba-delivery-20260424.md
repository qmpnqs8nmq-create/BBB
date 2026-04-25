# mangba cron 投递失败 — 完整复盘 + 修复路径

**最后更新**：2026-04-25 01:38 CST

## TL;DR（最终版本）

**根因**：`openclaw-weixin` 插件用的 iLink `context_token` 有 **~24 小时 TTL**；插件没有保活/刷新机制，只在收到 inbound 时更新 token。Bruce 连续 >24h 没主动回 mangba → cron 用的是 stale token → iLink 返回 HTTP 200 + body `{"ret":-2}` → 插件 `sendMessage` 不检查 ret，静默吞掉 → cron runs jsonl 骗人标记 `delivered=true`，实际消息从未到达。

## 24h TTL 假说（严格符合所有事实）

| 时间 | 距上次 inbound | cron 结果 | Bruce 收到？ |
|---|---|---|---|
| 4/22 20:00 学习 | 几小时（当日） | ok | ✅ 收到（Bruce 确认） |
| 4/22 22:00 晚报 | 几小时 | ok | ✅ 收到 |
| 4/22 22:19 Bruce 最后 inbound | - | - | - |
| 4/23 20:00 学习 | 21.7h | ok | ✅ 收到 |
| 4/23 22:00 晚报 | 23.7h | ok | ✅ 收到 |
| 4/24 20:00 学习 | 45.7h | ok（骗人）| ❌ |
| 4/24 22:00 晚报 | 47.7h | ok（骗人）| ❌ |
| 4/25 01:06 手动测试 | 50.8h | ret=-2（骗人成功）| ❌ |
| 4/25 01:19 手动测试（补丁后）| 51h | ret=-2 error（真实）| ❌ |

Bruce 自述：周四（4/23）白天跟 mangba 发过消息；周四/周五都没回 → 4/24 晚上 cron 就凉了。完美契合 24h 假说。

## 证据链

### 核心代码 bug（已打本地补丁）
`/root/.openclaw/extensions/openclaw-weixin/src/api/api.ts:273-285` 原版 `sendMessage`：
```ts
await apiPostFetch({...});  // 只检查 HTTP status
// 不解析 body，不检查 ret
```
→ 本地补丁：解析 rawText，ret!=0 时 throw。备份 `api.ts.bak-20260425-0115` / `types.ts.bak-20260425-0115`

### 补丁验证
- 4/25 01:06 运行（补丁前）：`status=ok, delivered=true`（骗人）
- 4/25 01:19 运行（补丁后）：`status=error, delivered=false, error="Error: sendMessage business failure: ret=-2"`
- **补丁行为正确，可观测性已修复**

### context_token 存储
- 文件：`/root/.openclaw/openclaw-weixin/accounts/5814497b5df4-im-bot.context-tokens.json`
- 该 bot 下 mangba 用户 `o9cq80zPDVZ65x_dc91XzBkQUvr0@im.wechat` 的 token mtime = **4/22 22:19:50**
- 来源：`inbound.ts:setContextToken` 仅在收到 inbound 时调用（process-message.ts:268-270）
- Token 本体 prefix `AARzJW...`，len 136，3 天没变过

### 日志追踪发现的误解（记录以免下次再绕弯）
- **`outbound: to=... contextToken=AARzJW...` 日志只在 process-message.ts 里打**，它是 **inbound→agent→dispatchReply 路径**的痕迹
- **channel.ts 的 `outbound.sendText`（cron announce 用的）不打这条日志**
- 之前用"有无 outbound 日志"来判断 cron 成败 → 错误的判据
- 两种推送路径都用相同的 `sendMessage` API，只是日志埋点不同

## 路径 1：消除 TTL（治本，依赖腾讯）

向 `@tencent-weixin/openclaw-weixin` 或 `openclaw/openclaw` 报 issue：
1. `sendMessage` body 返回 `{"ret":-2}` 时插件静默吞掉（bug）
2. `context_token` ~24h TTL 机制导致无法做长周期定时推送
3. 建议：提供不依赖 inbound 的 token refresh API 或延长 TTL

**状态**：未动手，待路径 2 验证后一并交

## 路径 2：客户端保活（治标，我们能改）

### 计划
- 每隔 <24h（比如 23h）自动对每个有 token 的 user 调用某个 iLink API
- 目标：让 iLink 返回新 token 或刷新现有 token 的 server-side TTL
- 候选 API：`getConfig`, `sendTyping`, 不带 context_token 的 sendMessage

### 可行性实验
1. ⏳ `getConfig(userId, context_token)` 过期后是否返回新 token
2. ⏳ `sendTyping` 是否能以不扰民方式刷 token
3. ⏳ `sendMessage` 不带 `context_token` 是否被 iLink 接受

## 运维兜底（不管方案 A/B/C，都要有）

方案 B：cron announce 失败时，通过另一个在线 channel（webchat/wecom/feishu）告警 Bruce
- 让失败显性
- 提示 Bruce "手动发句话刷新 token"
- 5 分钟工作量

## 当前 gateway 状态（实时）

- pid 634580，起于 4/25 01:17:13
- `OPENCLAW_LOG_LEVEL=debug` 通过 systemd drop-in 生效（`~/.config/systemd/user/openclaw-gateway.service.d/debug-log.conf`）
- 所有 4 个 im-bot running
- 补丁已加载，sendMessage ret 检查生效
- mangba cron next runAt = 明晚 2026-04-26 20:00 自然触发（nextRunAtMs=1777118400000）

## 接下来的 next steps

1. [ ] 验证 iLink refresh API 可行性（路径 2 实验）
2. [ ] 实现保活 loop（路径 2 实现）
3. [ ] 实现失败告警（方案 B 兜底）
4. [ ] 起草 openclaw/openclaw issue（路径 1）
5. [ ] 明晚 20:00 自然触发验证端到端

## 经验教训（给未来的自己）

- **"日志里没看到"≠"没发生"** —— 不同代码路径埋点位置不同，必须先读源码确认 log 点
- **不要用假说质疑用户的实证** —— Bruce 说收到了就是收到了，我必须围绕他的事实反推
- **Bruce 对技术精度要求高**：三次被他戳穿（hot-reload / 半死状态 / token stale linear），每次都值得吸取
- **承认"不知道"比给"看似合理的假说"更有价值**
- **中途可能被 systemd restart 踢断 session** —— 关键状态及时 persist 到文件
