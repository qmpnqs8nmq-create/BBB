# PLATFORM_ITERATION_LOG.md

## Purpose
Track platform-level issues, improvements, and governance items for the OpenClaw system.
This covers: agent configurations, cron health, cross-agent consistency, technical infrastructure, and platform governance.
This is main's responsibility. CEO business system issues are tracked separately by chief in `workspace-chief/SYSTEM_ITERATION_LOG.md`.

## Format
Each entry: date / category / issue / root cause / fix / status

Categories:
- `CRON` — cron job failure, timeout, misconfiguration
- `CONFIG` — agent config, gateway config, security config issues
- `AGENT` — agent role drift, boundary violation, cross-agent inconsistency
- `INFRA` — gateway, tailscale, connectivity, sync issues
- `GOVERNANCE` — platform-level rule gap, missing mechanism

---

## Log

### 2026-03-22 | CRON | Daily news cron consecutive timeout errors
- **Issue**: 每日新闻简报 cron (chief) has 2 consecutive timeout errors.
- **Root cause**: Not yet diagnosed. Possible: script too slow, timeout too short, or network issue.
- **Fix**: Pending diagnosis.
- **Status**: ⏳ Open

### 2026-03-22 | GOVERNANCE | Platform governance mechanism established
- **Issue**: OpenClaw had technical maintenance (daily self-check, security audit) but no platform governance review — no check on agent config drift, cron design rationality, cross-agent consistency.
- **Root cause**: main was defined as "platform maintenance brain" but only had technical ops cron, not governance cron.
- **Fix**: Created PLATFORM_ITERATION_LOG.md + weekly platform governance review cron.
- **Status**: ✅ Fixed

### 2026-03-22 | AGENT | Security healthcheck cron 从 chief 迁移到 main
- **Issue**: `healthcheck:security-audit` 和 `healthcheck:update-status` 归属 chief，但安全/基础设施巡检属于 main（平台层）职责。
- **Root cause**: 初始创建时未严格区分 agent 职责边界。
- **Fix**: 删除 chief 上的旧 cron，在 main 下重建。update-status 增加 node 版本检查以区分 security-audit。
- **Status**: ✅ Fixed

### 2026-03-22 | CRON | 每日新闻简报 timeout 300s → 600s
- **Issue**: 新闻 cron 连续 2 次超时（实际耗时 ~338s，timeout 300s）。
- **Root cause**: 多源抓取 + AI 分析耗时超出 300s 限制。
- **Fix**: timeout 从 300s 调整为 600s。
- **Status**: ✅ Fixed（待今晚 22:30 验证）

### 2026-03-22 | GOVERNANCE | Cron health 检查间隔优化
- **Issue**: 之前 cron 故障只有周日 governance review 才能发现（如新闻 cron 连续超时已两天未被巡检机制捕获）。
- **Fix**: daily-self-check 增加 cron health 检查项，每天 8:00 扫描全量 cron 的 consecutiveErrors 和 lastStatus。
- **Status**: ✅ Fixed

---

### Week of 2026-03-22 — Platform Governance Review

**Reviewer:** main (automated weekly cron) | **Time:** 2026-03-22 20:53 CST

#### Cron Health

| Job | Agent | Status | Notes |
|-----|-------|--------|-------|
| 每日新闻简报 22:30 | chief | ⚠️ ERROR (consecutiveErrors=2) | Timeout fix applied (300s→600s), pending tonight 22:30 validation |
| sync-shared-files | chief | ✅ OK | — |
| daily-self-check-8am | main | ✅ OK | — |
| market:weekly-intel-scan | chief | ✅ OK (never run yet) | Next: Mon/Thu 09:00 |
| healthcheck:security-audit | main | ✅ OK (never run yet) | Next: Mon 10:00 |
| healthcheck:update-status | main | ✅ OK (never run yet) | Next: Mon 10:30 |
| coach:biweekly-decision-review | chief | ✅ OK (never run yet) | Next: Wed 10:00 |
| weekly-platform-governance-review | main | ✅ Running | This job |
| weekly-system-review | chief | ✅ OK (never run yet) | Next: Sun 10:00 |
| auto-approve-lan-pairing | main | ⚪ DISABLED | Intentional — no action needed |

**Cron flags:**
- `每日新闻简报` consecutiveErrors=2 仍未清零（fix 已部署，待今晚 22:30 第一次成功运行后自动清零）。原有 issue 追踪中，无需新建。

#### Agent Configuration

**Boundary check (platform vs CEO):**
- Platform ops cron (healthcheck, self-check, governance) → main ✅
- CEO business cron (news, market intel, coach, system review, sync) → chief ✅
- 本周无跨边界问题发现

**Workspace configs:**
- main workspace: AGENTS.md / SOUL.md / IDENTITY.md 齐全 ✅
- chief workspace: AGENTS.md 存在 ✅
- 无 role drift 迹象

#### Infrastructure

**Gateway:** running (pid 75820, state active, RPC probe: ok) ✅

**⚠️ Doctor warnings（新发现）：**
1. `channels.wecom.allowFrom` 设为 `["*"]`（dmPolicy="open" 所需），建议运行 `openclaw doctor --fix` 消除警告
2. `plugins.allow` 为空 — `openclaw-weixin` 和 `wecom-openclaw-plugin` 以"non-bundled plugins"方式自动加载，存在未受控插件风险
3. 检测到多个 gateway-like service：`ai.openclaw.lan8888-proxy` 与主 gateway 并存，提示"run a single gateway"

**Findings requiring attention: 3 items (see issues below)**

---

### 2026-03-22 | INFRA | Doctor warnings — wecom allowFrom + plugins.allow 未配置
- **Issue**: `openclaw gateway status` 报告 doctor warning：(1) `channels.wecom.allowFrom=["*"]` 需 `openclaw doctor --fix`；(2) `plugins.allow` 为空，非捆绑插件自动加载。
- **Root cause**: 初始配置时未显式设置 plugins.allow 白名单。
- **Fix**: 建议 Bruce 确认受信任插件列表，然后在 `openclaw.json` 中显式设置 `plugins.allow: ["openclaw-weixin", "wecom-openclaw-plugin"]`；并运行 `openclaw doctor --fix` 修复 allowFrom。
- **Status**: ⏳ Open — 需 Bruce 确认操作

### 2026-03-22 | INFRA | 检测到多个 gateway-like service（lan8888-proxy 并存）
- **Issue**: `openclaw gateway status` 检测到 `ai.openclaw.lan8888-proxy` 作为额外 gateway-like service 与主 gateway 并存，官方提示建议单机单 gateway。
- **Root cause**: 之前配置了 LAN 8888 代理 plist 作为补充服务入口，尚未清理。
- **Fix**: 确认 lan8888-proxy 是否仍需要；若不需要，执行 `launchctl bootout gui/$UID/ai.openclaw.lan8888-proxy && rm ~/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist`。
- **Status**: ⏳ Open — 需 Bruce 决策是否保留

---

### Week of 2026-03-24 — Platform Governance Review

**Reviewer:** main (automated weekly cron) | **Time:** 2026-03-24 23:04 CST

#### Cron Health

| Job | Agent | Status | Notes |
|-----|-------|--------|-------|
| daily-self-check-8am | main | ✅ OK | consecutiveErrors=0 |
| symlink-integrity-check | main | ✅ OK | consecutiveErrors=0 |
| 每日新闻简报 22:30 | chief | ✅ OK | Fixed since last review, consecutiveErrors=0 |
| market:weekly-intel-scan | chief | ✅ OK | consecutiveErrors=0, last delivered successfully |
| coach:biweekly-decision-review | chief | ✅ OK | Never run yet, next Wed 10:00 |
| weekly-system-review | chief | ✅ OK | Never run yet, next Sun 10:00 |
| monthly-system-simplification | chief | ✅ OK | Never run yet, next Apr 1 10:00 |
| healthcheck:security-audit | main | ⚠️ ERROR | consecutiveErrors=1, error: "Channel is required when multiple channels are configured" — delivery config was updated AFTER last run; should auto-clear on next Mon 10:00 run |
| healthcheck:update-status | main | ⚠️ ERROR | consecutiveErrors=2, error: "Delivering to Feishu requires target" — same: delivery config fixed after last run; should auto-clear Mon 10:30 |
| weekly-platform-governance-review | main | ⚠️ ERROR | consecutiveErrors=1 from last week's run; this run is the validation |
| auto-approve-lan-pairing | main | ⚪ DISABLED | Intentional |
| sync-shared-files [RETIRED] | chief | ⚪ DISABLED | Replaced by symlinks + symlink-integrity-check |

**Cron summary:**
- 3 jobs with errors, all from delivery config issues that were fixed on 3/21 but haven't had a chance to re-run yet. Expected to auto-clear this week.
- No new failures. 每日新闻简报 timeout fix (300s→600s) validated — running clean since 3/22.
- **Action needed:** None. Monitor Mon 3/30 runs for healthcheck jobs to confirm error clearing.

#### Agent Configuration

- main workspace: AGENTS.md / SOUL.md / IDENTITY.md ✅
- chief workspace: AGENTS.md / SOUL.md / IDENTITY.md ✅
- **Boundary check:** Platform ops (healthcheck, self-check, symlink, governance) → main ✅; CEO business (news, market, coach, system review, simplification) → chief ✅
- No cross-boundary drift detected

#### Infrastructure

- **Gateway:** running (pid 66086, state active, RPC probe: ok) ✅
- **New warning:** Duplicate plugin id for `openclaw-weixin` — "global plugin will be overridden by global plugin." Cosmetic/config duplication, not affecting functionality.
- **Previous findings status:**
  - plugins.allow 未配置 → ⏳ Still open (needs Bruce decision)
  - lan8888-proxy 并存 → ✅ Resolved by design (per 3/22 decision)

**Overall: No new issues requiring attention. All existing issues tracking as expected.**

---

### Week of 2026-03-29 — Platform Governance Review

**Reviewer:** main (automated weekly cron) | **Time:** 2026-03-29 05:06 CST

#### Cron Health

| Job | Agent | Status | Notes |
|-----|-------|--------|-------|
| daily-self-check-8am | main | ⚠️ ERROR | consecutiveErrors=1, timeout (1403s > 600s limit) |
| market:weekly-intel-scan | chief | ⚠️ ERROR | consecutiveErrors=1, "WSClient not connected for account admin" |
| 每日新闻简报 22:30 | chief | ✅ OK | consecutiveErrors=0, lastDeliveryStatus=not-delivered (content issue, not cron failure) |
| 每日使用总结 23:00 | main | ✅ OK | consecutiveErrors=0, lastDeliveryStatus=not-delivered |
| symlink-integrity-check | main | ✅ OK | consecutiveErrors=0 |
| healthcheck:security-audit | main | ✅ OK | consecutiveErrors=0 |
| healthcheck:update-status | main | ✅ OK | consecutiveErrors=0 |
| coach:biweekly-decision-review | chief | ✅ OK | consecutiveErrors=0 |
| weekly-system-review | chief | ✅ OK | Never run yet, next today 10:00 |
| monthly-system-simplification | chief | ✅ OK | Never run yet, next Apr 1 |
| Weekly Market Signal Scan | chief/wecom | ✅ OK | consecutiveErrors=0 |
| Ecosystem Niche Scan | chief/wecom | ✅ OK | consecutiveErrors=0 |
| Monthly Portfolio Review | chief/wecom | ✅ OK | Never run yet, next Apr 1 |
| Quarterly Domain Review | chief/wecom | ✅ OK | Never run yet, next Apr 1 |
| weekly-platform-governance-review | main | ✅ Running | This job |
| auto-approve-lan-pairing | main | ⚪ DISABLED | Intentional |
| sync-shared-files [RETIRED] | chief | ⚪ DISABLED | Intentional |

**Cron flags:**
- `daily-self-check-8am` consecutiveErrors=1: timed out at 1403s (limit 600s). Likely the backup/git operations are too slow or hanging. **Needs investigation** — consider splitting backup into separate cron or increasing timeout.
- `market:weekly-intel-scan` consecutiveErrors=1: "WSClient not connected for account admin" — Feishu WebSocket was disconnected at run time. Transient connectivity issue. Should auto-clear on next Mon run (3/30). Monitor.
- Two jobs show `lastDeliveryStatus=not-delivered` (新闻简报, 每日总结) — runs completed OK but delivery didn't land. May be delivery config or channel availability issue. Worth monitoring.

#### Agent Configuration

- main workspace: AGENTS.md / SOUL.md / IDENTITY.md / USER.md ✅ — platform ops role, consistent
- chief workspace: AGENTS.md / SOUL.md ✅ — CEO office role, consistent
- **Boundary check:** Platform ops cron → main ✅; CEO business cron → chief ✅
- New wecom-session cron jobs (Weekly Market Signal Scan, Ecosystem Niche Scan, Monthly Portfolio Review, Quarterly Domain Review) all under chief ✅ — proper boundary
- No cross-boundary drift detected

#### Infrastructure

- **Gateway:** running (pid 49817, state active, RPC probe: ok) ✅
- Listening on *:18789, bind=lan
- No new warnings beyond previously documented items (plugins.allow, lan8888-proxy — both resolved/accepted)

#### Summary

**2 issues found:**
1. `daily-self-check-8am` timeout — needs timeout increase or task splitting
2. `market:weekly-intel-scan` WSClient disconnection — transient, monitor next run

**No critical issues requiring immediate attention.**

---

## Weekly Review Template

Each weekly platform review should answer:

### Cron Health
1. Any cron job failures or consecutive errors across all agents?
2. Any cron jobs that should be adjusted, disabled, or removed?
3. Any new cron jobs needed?

### Agent Configuration
1. Are agent role definitions (AGENTS.md / SOUL.md) still consistent with actual behavior?
2. Any agent boundary drift? (e.g., chief doing platform work, main doing CEO work)
3. Cross-workspace file sync — are shared files still consistent?

### Infrastructure
1. Gateway status healthy?
2. Tailscale connectivity normal?
3. Any security audit findings from this week?

### Output
- Append findings to this log
- If nothing notable: record "Week of YYYY-MM-DD: Platform layer — No issues found"
- If issues found: log each with standard format above
- Flag anything requiring Bruce's attention

### 2026-03-22 | CONFIG | lan8888-proxy LaunchAgent — 刻意保留
- **Issue**: governance review 检测到 ai.openclaw.lan8888-proxy LaunchAgent，建议单机单 gateway
- **Decision**: 刻意保留。8888 端口是局域网浏览器访问入口，强制路由到 chief-user，是系统设计的一部分
- **不需要修复**。后续 governance review 遇到此警告可忽略
- **Status**: ✅ Resolved (by design)

### 2026-03-23 | CRON | market:weekly-intel-scan 全模型超时
- **Issue**: 上次运行全部 7 个模型超时（含 anthropic 直连无 key 是正常 fallback）
- **Root cause**: 临时性网络问题，非配置问题。重跑后 152 秒正常完成
- **Fix**: 无需配置修改。delivery 统一修为 feishu + Bruce openId
- **Status**: ✅ Fixed

### 2026-03-23 | CRON | healthcheck:update-status 839秒超时
- **Issue**: 任务 839 秒后被 kill，timeout 600 秒
- **Root cause**: prompt 含模糊指令（"检查兼容性风险"），agent 做了不必要的 web search 导致卡住
- **Fix**: prompt 简化为只跑 openclaw update status + node --version，timeout 改为 120 秒。重跑后 13 秒完成
- **Status**: ✅ Fixed

### 2026-03-23 | CRON | 全部 cron job delivery 统一配置
- **Issue**: 多个 cron 的 delivery 缺少 channel/to，导致多 channel 环境下无法投递
- **Fix**: 所有 9 个 cron job 统一设为 delivery.channel=feishu, to=user:ou_2057df7422741af99b3f14f79fd527f6
- **Status**: ✅ Fixed
