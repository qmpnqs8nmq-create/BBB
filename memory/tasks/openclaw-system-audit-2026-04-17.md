# OpenClaw 系统审计报告 — 2026-04-17

> 审计人：Kaopuge（main）  
> 范围：OpenClaw 系统本体（Gateway / 核心配置 / 认证 / 版本 / 暴露面 / 日志），**不含**业务层 memory/agent workspace/cron job 内容  
> 原则：只读、只审不改  
> 版本：OpenClaw 2026.4.14 (323493f)

## Executive Summary

系统**整体运行正常**：Gateway 15:42 启动后持续 active，端口 :18789 正常监听，核心 9 个 agent 中 7 个 auth 完整。

但存在 **3 个高危问题**，其中两个是"活火山"——业务层随时可能复盘昨天 benben 瘫痪那一幕：

- 🔴 **mangba / mangba-guest auth-profiles 为空**（37 字节，profiles 数=0）——与 2026-04-16 benben 瘫痪事故同根因，只是目前业务未触发（没有活跃提问/路由流量），一旦有消息会走 `All models failed`
- 🔴 **Gateway auth token 明文存储** 在 `openclaw.json` 里（48 字符），且 `bind=lan (0.0.0.0)` + nginx 443 反代暴露至公网 IP `43.106.3.174`
- 🔴 **Sub-agent 模型 allowlist 与默认 primary 不一致**：默认 `primary = zenmux-key1/anthropic/claude-opus-4.7`，但 sub-agent spawn 时被拒 `model not allowed`——说明 sub-agent 路径有独立 model allowlist 未与 default 同步

**风险分级统计**
- 🔴 高危：4 项
- 🟡 中等：6 项
- 🟢 低/关注项：5 项

---

## 1. Gateway 服务状态 ✅

| 项 | 值 |
|---|---|
| 状态 | active (running) |
| PID | 320470 |
| 启动时间 | 2026-04-17 15:42:29 CST |
| 内存峰值 | 921.6M（当前 662.1M） |
| systemd unit | `~/.config/systemd/user/openclaw-gateway.service`（enabled） |
| 启动命令 | `/usr/bin/node /usr/lib/node_modules/openclaw/dist/index.js gateway --port 18789` |
| bind | `lan` → 0.0.0.0:18789 |
| RPC probe | ok |
| Dashboard | http://172.27.206.34:18789/ |

**结论**：进程本身健康。无异常重启。

---

## 2. 核心配置 (openclaw.json)

### 2.1 结构健康
- 顶层 keys：`meta, wizard, auth, models, agents, tools, bindings, commands, session, hooks, channels, gateway, plugins` — 完整
- **无废弃残留**：未检出 `team-gateway / :8899 / :8888 / ai.openclaw.team / ai.openclaw.lan8888-proxy` 任何字样 ✅ 与 MEMORY.md 宣称的 2026-03-23 清理一致

### 2.2 Channels
| 渠道 | 状态 | DM 策略 | 要点 |
|------|------|---------|------|
| feishu | enabled | pairing | 仅 `admin` 账号启用（`cli_a93875ac3d38dcc9`），`default` 账号 `enabled=false`；groupPolicy=allowlist；appSecret 明文在 config 中 🔴 |
| wecom | enabled | allowlist | 白名单 7 人（与 MEMORY.md 一致）；botId + secret 明文 🔴 |
| openclaw-weixin | accounts={} | — | channelConfigUpdatedAt=2026-04-15；真实账号绑定走 bindings（非内嵌） |

### 2.3 Agents (agents.list)
共 **11 个 agent**：main / chief / chief-user / api-worker / strategy / market / execution / coach / mangba / mangba-guest / benben

| agent | model.primary | workspace | elevated | 备注 |
|-------|---------------|-----------|----------|------|
| main | (继承默认) | workspace | deny wecom_mcp | heartbeat 30m, 08-23 |
| chief | (继承默认) | workspace-chief | ✅ allowFrom Bruce | default agent |
| chief-user | (继承默认) | workspace-chief-user | ❌ | sandbox ro |
| api-worker | openai-codex/gpt-5.4 | workspace-chief-user | ❌ | sandbox ro, scope=agent |
| strategy | (继承默认) | workspace-strategy | — | |
| market | zenmux-key3/sonnet-4.6 | workspace-market | — | |
| execution | (继承默认) | workspace-execution | — | |
| coach | (继承默认) | workspace-coach | — | |
| mangba | zenmux-key3/opus-4.7 | workspace-mangba | ✅ Bruce | 🔴 auth 空 |
| mangba-guest | zenmux-key3/opus-4.7 | workspace-mangba-guest | ❌ | 🔴 auth 空, profile=minimal |
| benben | (继承默认) | workspace-benben | ❌ | 昨天刚修复 |

### 2.4 Bindings（8 条）
wechat: benben 绑 2 个账号（`e1263c708c9c-im-bot`, `jamie`）+ mangba-guest 绑 1 个（`4d5b593c4a1b-im-bot`）+ mangba 兜底 `*`；wecom/feishu 各一条 Bruce→chief + 一条 `*`→chief-user — 与 MEMORY.md 架构决策完全一致 ✅

### 2.5 Plugins
已启用：feishu / wecom-openclaw-plugin / perplexity / openclaw-weixin / openrouter / openai / anthropic / memory-wiki；memory-core `enabled` 未显式设置（日志"cron service unavailable"告警，见 §6.2）

### 2.6 Session & Maintenance
- `dmScope=per-channel-peer`
- `reset.mode=idle, idleMinutes=1440`（24h）与 MEMORY.md 一致 ✅
- `maintenance`：pruneAfter=30d, maxEntries=500, rotateBytes=10mb, resetArchiveRetention=14d ✅

---

## 3. 认证体系 (auth-profiles)

**目录清单**（`/root/.openclaw/agents/`）：13 个子目录，其中 `_backup-models-20260329` 是归档备份，`claude` 目录无 auth 文件（未登记为 agent）。

| Agent | 大小 | Profile 数 | mtime | 状态 |
|-------|------|-----------|-------|------|
| main | 5577 | 7 | 2026-04-17 15:55 | ✅ |
| chief | 5518 | 7 | 2026-04-17 09:30 | ✅ |
| chief-user | 6379 | 7 | 2026-04-02 16:17 | ✅ |
| benben | 5577 | 7 | 2026-04-17 07:06 | ✅（昨天刚修） |
| api-worker | 6379 | 7 | 2026-04-02 16:17 | ✅ |
| strategy | 5518 | 7 | 2026-04-10 14:29 | ✅ |
| market | 5518 | 7 | 2026-04-10 20:48 | ✅ |
| execution | 6358 | 7 | 2026-04-02 16:17 | ✅ |
| coach | 6379 | 7 | 2026-04-02 21:50 | ✅ |
| **mangba** | **37** | **0** | 2026-04-10 23:55 | 🔴 **空文件** |
| **mangba-guest** | **37** | **0** | 2026-04-13 00:33 | 🔴 **空文件** |

**7 个标准 profile**（所有非空 agent 一致）：  
`openai-codex:bobstazenski8u6145@gmail.com, openai-codex:default, openai:default, openrouter:default, zenmux-key1:default, zenmux-key2:default, zenmux-key3:default`

**关键风险**：mangba 和 mangba-guest 的 primary model 是 `zenmux-key3/...`，但本地 profile 缺失时，agent 一般从共享 auth（`~/.openclaw/openclaw.json` 的 auth.profiles）回退；昨天 benben 的事故证明这条路径并不稳健——**一旦 agent 被触发（有消息进入 mangba workspace），极可能复现 `All models failed`**。

---

## 4. 安装与版本 ✅

- **版本**：OpenClaw 2026.4.14 (commit 323493f)
- **node**：v22.22.0
- **节点入口**：`/usr/lib/node_modules/openclaw/dist/index.js` 存在
- **extensions**：95 个模块全部就位（acpx / active-memory / anthropic / feishu / wecom-... / memory-core / memory-wiki 等均存在）
- **内置 skills**：53 个，覆盖 github / healthcheck / weather / tmux / taskflow / skill-creator / news-aggregator / obsidian-vault-maintainer / wiki-maintainer 等
- **workspace extensions**：`openclaw-weixin`, `wecom-openclaw-plugin`

---

## 5. 对外暴露面

### 5.1 端口监听
| Port | 进程 | 绑定 | 暴露性 |
|------|------|------|--------|
| 22 | sshd | 0.0.0.0 + [::] | 公网可达 |
| 80 | nginx | 0.0.0.0 + [::] | 公网可达（default server，未配置 openclaw） |
| 443 | nginx | 0.0.0.0 | 公网可达 → **反代到 127.0.0.1:18789 的 Gateway** |
| 18789 | openclaw-gateway | **0.0.0.0** | 🔴 **直接暴露到公网 + LAN + docker bridge** |
| 53 | systemd-resolve | 127.0.0.x | 本地 |

### 5.2 公网映射
- 公网 IP：`43.106.3.174`
- nginx `openclaw-https` 配置：`server_name 43.106.3.174` → proxy_pass `http://127.0.0.1:18789/`
- 使用自签 SSL（`/etc/nginx/ssl/openclaw.crt`）
- Dashboard `https://43.106.3.174` 对外可达

### 5.3 Gateway 认证
- `auth.mode=token`, token 长度 48 字符，**明文存放** 在 `openclaw.json` 🔴
- `rateLimit`: 60s 内 10 次失败 → 锁 5 分钟 ✅
- `allowTailscale=true`（但 tailscale.mode=off，实际未启用）
- `controlUi.allowedOrigins`: `http://127.0.0.1:33338` + `https://43.106.3.174`

### 5.4 Pairing / Device
- plugins.entries 中**未配置 `device-pair`**
- 配置中提到 `pairing` 主要指 feishu `dmPolicy=pairing`（渠道层配对），非设备配对
- 无其他公开 URL 残留

### 5.5 没用防火墙
- `ufw` 未安装；iptables 状态未检（阿里云安全组通常在云端管控）

---

## 6. 日志与诊断

### 6.1 日志体积
| 文件 | 大小 |
|------|------|
| openclaw-2026-04-16.log | 2.3M |
| openclaw-2026-04-17.log | 494K（半天） |

按此速度每日 ~1-3MB，短期无压力。

### 6.2 今日 error/warn 关键模式
- **7 次**：`Unknown model: anthropic/claude-opus-4.7` — 有路径把完整 `zenmux-key1/anthropic/claude-opus-4.7` 当成裸 model id 请求，provider 无法识别。与 sub-agent allowlist 问题同一症候群。🔴
- **4 次**：`EISDIR: illegal operation on a directory` — 文件操作把目录当文件，需定位具体 op。🟡
- **3 次**：`LLM request failed: provider rejected the request schema or tool payload` — 可能是 tool schema 在某些 provider 不兼容。🟡
- **2 次**：`HTTP 402 quote_exceeded`（某 zenmux key 配额满）🟡 — 本身不致命，fallback 能顶上
- **8 次**：`Agent-to-agent status is disabled. Set tools.agentToAgent.enabled=true` — 多 agent 想跨会话 status 探测被拒，影响 Control UI 展示其它 agent 状态。🟡
- **3 次**：`memory-core: managed dreaming cron could not be reconciled (cron service unavailable)` — memory-core 插件启动时 cron service 还没 ready，dreaming 可能未按 `0 5 * * *` 调度。🟡
- **启动 warn**：`Gateway is binding to a non-loopback address. Ensure authentication is configured before exposing to public networks.` — Gateway 自己给的 warning，印证 §5 暴露面问题。🟡
- **1 次**：`websocket server close exceeded 1000ms; forcing shutdown continuation with 1 tracked client(s)` — 关机时 WS 客户端未优雅断开，1s 超时后强关。🟢 可接受
- **sandbox pinned mutation helper requires python3 or python**：sandbox 内执行 python helper 失败；涉及 benben 业务写 `students/jamie.md`，非系统问题 🟢

### 6.3 Cron 调度器
- `cron status: enabled=true, jobs=25, nextWake=1776427200000`（2026-04-18 00:00 CST）✅
- 但 memory-core 启动时说 `cron service unavailable` → 可能启动时序竞态，重启后已正常，但 managed cron 可能未重新 reconcile 🟡

---

## 发现问题清单

| 级别 | 类别 | 现状 | 风险 | 建议 |
|------|------|------|------|------|
| 🔴 | 认证/高可用 | mangba auth-profiles.json 空（37B） | 触发时 `All models failed`，和昨天 benben 瘫痪同根因 | 参照 benben 修法：从 main 覆盖同步 |
| 🔴 | 认证/高可用 | mangba-guest auth-profiles.json 空 | 同上，mangba-guest 是学员版，入口活跃度高 | 同上 |
| 🔴 | 安全/暴露面 | Gateway :18789 `bind=lan` 监听 0.0.0.0，nginx 443 反代至公网 IP | Gateway 暴露在公网，仅靠 48 字符 token + rateLimit 防护；云安全组若放行 443 则任何人可尝试 | ①改 `gateway.bind=loopback` 只让 nginx 反代；②考虑加 IP 白名单或强制 OAuth；③审云安全组 |
| 🔴 | 安全/凭证 | `openclaw.json` 明文存：gateway.auth.token / wecom.secret / feishu.appSecret / perplexity apiKey | 配置文件泄漏=全线权限泄漏；现在 `workspace` 还同步到私有 GitHub 仓（MEMORY.md 提到） | ①确认 `openclaw.json` **不在** workspace 目录下（在 `~/.openclaw/`，ok）；②考虑 secrets 外置到 env / vault |
| 🔴 | 路由/默认链 | Sub-agent spawn 被拒 `model not allowed: zenmux-key1/anthropic/claude-opus-4.7`，但该 id 恰是 `agents.defaults.model.primary` | 主会话能用，sub-agent 就用不了；并行扩展能力受限 | 排查 sub-agent 路径的 model allowlist（可能 providers.zenmux-key1.models 与实际请求 id 格式不匹配） |
| 🟡 | 日志/错误 | `Unknown model: anthropic/claude-opus-4.7` 出现 7 次 | 说明某处路由拆 provider/model 时把前缀 `zenmux-key1/` 丢掉 | 跟踪发起方，查 model resolution 链路是否有 strip 逻辑 bug |
| 🟡 | 日志/错误 | `EISDIR` 4 次 | 潜在功能故障点 | 按 errorHash `99cb52a218ff` 找具体调用栈 |
| 🟡 | 插件 | memory-core dreaming cron 启动时 `cron service unavailable` | dreaming 报告（`0 5 * *`）可能未正常跑 | 启动后验证：`cron list` 查 dreaming job 是否注册；若缺失则重启插件 |
| 🟡 | 配置 | `agents.chief.tools.deny=[]`，chief 又 elevated=true | chief 无任何工具 deny + elevated 打开 | 按需补一层 deny 兜底（至少 sensitive tools 白名单） |
| 🟡 | 配置 | `tools.agentToAgent` 未显式设置（null/默认 false） | 跨 agent status/通信能力被整体关闭 | 决策：要开就开；保持关则在 agent SOUL 文档里明示 |
| 🟡 | 配置 | `auth.allowTailscale=true`（但 tailscale.mode=off） | 无害但配置矛盾 | 统一成 off/off 或 on/on |
| 🟡 | 安全/防火墙 | 无 ufw，ssh:22 直接公开 | 依赖阿里云安全组和 sshd 强认证 | 建议核对云安全组规则 + 关闭 password auth（若还开着） |
| 🟢 | 残留 | `/root/.openclaw/agents/_backup-models-20260329` 孤立备份 | 无风险，占位 | 7 天没用过可以清掉 |
| 🟢 | 残留 | `/root/.openclaw/agents/claude/` 无 auth 文件，不在 agents.list | 可能是 ACP claude code 留的，检查用途 | 若未用则 trash |
| 🟢 | 监控 | 自签 SSL 证书（nginx） | 浏览器会告警，用户需手动信任 | 可选：上 Let's Encrypt（需域名） |
| 🟢 | 文件权限 | 多数 agentDir 为 `drwx------`，少数 `drwxr-xr-x`（api-worker/benben/mangba/mangba-guest）| 权限不一致 | 统一成 `drwx------` |
| 🟢 | 日志轮转 | /tmp/openclaw/ 按日分文件，暂不清 | /tmp 在某些系统重启会清 | 若要长期留存，移到 /var/log/openclaw |

---

## 下一步建议（按优先级）

### 🔥 今天就做（高危 + 低成本）
1. **修 mangba / mangba-guest 的 auth**：从 main 覆盖同步（参照 2026-04-16 benben 做法，先备份再覆盖）
2. **排 sub-agent model allowlist bug**：找到 sub-agent 侧的模型校验路径，验证为什么 `zenmux-key1/anthropic/claude-opus-4.7` 被 reject（可能需要读 extensions 源码或提 issue）
3. **Gateway bind 收窄**：改 `gateway.bind=loopback`，让 nginx 做唯一入口；重启 Gateway 验证

### 🟡 本周/下次迭代
4. 查 `Unknown model: anthropic/claude-opus-4.7` 的调用路径（和 #2 可能是同一问题的两面）
5. 定位 `EISDIR` 错误上下文
6. 补 chief tool deny 兜底
7. 统一 allowTailscale / tailscale.mode
8. Tailscale/域名 + Let's Encrypt（可选，看是否需要对外给非 IP 访问）
9. 清理 `_backup-models-20260329`、`agents/claude/`、20 次 agent-to-agent 拒绝日志（要么开、要么真关）

### 🟢 常态化（纳入 healthcheck 或周日复盘）
10. 把 auth-profiles 空文件检查加到 healthcheck skill 或 heartbeat 定期检查
11. 每次新建 agent 的模板强制 copy 一份 auth-profiles（别再让空文件溜出来）
12. 配置文件里的 secrets 外化方案（长期债）

---

## 附录：审计方法

| 领域 | 命令 |
|------|------|
| Gateway 状态 | `openclaw gateway status`, `ps -ef`, `systemctl --user status openclaw-gateway` |
| 端口/暴露 | `ss -tlnp`, nginx sites-enabled 检视 |
| 配置解析 | Python 读 `/root/.openclaw/openclaw.json`（屏蔽 secret values） |
| auth 完整性 | 遍历 `/root/.openclaw/agents/*/agent/auth-profiles.json` + 大小/profile 数统计 |
| 版本 | `openclaw --version`, `package.json` |
| 日志 | `grep -iE 'error|fatal|warn'` on `/tmp/openclaw/openclaw-2026-04-17.log` |
| Cron | `cron status` |

**未触及**（承诺 out-of-scope）：
- `memory/`, `MEMORY.md`, 日常笔记内容
- 各 agent workspace 的业务文件内容
- cron job 的具体 payload
- workspace git 提交历史

---

## 修复执行记录（2026-04-17 16:00-16:12）

### 已修复 ✅
1. **mangba auth-profiles.json**: 37B/0 profiles → 5577B/7 profiles（从 main 覆盖）
2. **mangba-guest auth-profiles.json**: 37B/0 profiles → 5577B/7 profiles（从 main 覆盖）
3. **孤立目录迁移**: `agents/_backup-models-20260329`（3/29备份）、`agents/claude/`（空 sessions）→ `/root/.openclaw/_attic/2026-04-17/`
4. **`gateway.auth.allowTailscale` 改为 false**: 与 `tailscale.mode=off` 一致
5. **agent 目录权限统一 700**: api-worker / benben / mangba / mangba-guest（原为 755）
6. **Sub-agent model allowlist bug 根治**: 清空 `agents.defaults.models={}` → `allowAny=true`
   - 根因：`buildAllowedModelSet()` 把 `agents.defaults.models` 的 key 当 allowlist；之前只有 `openai-codex/gpt-5.4`，导致 sub-agent 路径的 defaultKey 不命中直接 reject 其它合法 model
   - 验证：spawn sub-agent with `model="zenmux-key1/anthropic/claude-opus-4.7"` → 返回 `modelApplied: true`
   - 副作用修复（推测）：日志里 7 次 `Unknown model: anthropic/claude-opus-4.7` 应同步消失（同一 bug 两面）

### 未修（Bruce 拍板或暂缓）
- Gateway `bind=loopback`：Bruce 决定不改，保持 token-only 对外入口
- chief `tools.deny` 补兜底：待 Bruce 决定 deny 哪些工具
- memory-core dreaming plugin 显式 `enabled: true`：dreaming 会主动改 MEMORY.md，与 Bruce 人工记忆纪律可能冲突，待决
- main agent 目录权限 700：避免踩当前会话 agentDir，留给下次
- 把 auth-profiles 空文件检查加进 healthcheck skill：防复发的机制化，下周迭代

### 备份清单
- `/root/.openclaw/agents/mangba/agent/auth-profiles.json.bak-20260417-160554`
- `/root/.openclaw/agents/mangba-guest/agent/auth-profiles.json.bak-20260417-160554`
- `/root/.openclaw/openclaw.json.bak-20260417-160621`（allowTailscale 改动前）
- `/root/.openclaw/openclaw.json.bak-modelallowlist-20260417-160950`（models 清空前）
- `/root/.openclaw/_attic/2026-04-17/_backup-models-20260329/`
- `/root/.openclaw/_attic/2026-04-17/agents-claude-empty/`
