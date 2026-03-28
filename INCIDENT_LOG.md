# INCIDENT_LOG.md

用于记录重复性故障和关键变更，避免同病反复发作、变更不可追溯。

---

## 故障模板

### [YYYY-MM-DD] 标题
- 现象：
- 触发条件：
- 根因层级：运行层 / 状态层 / 上下文层 / 治理层 / 产品缺口
- 临时止血：
- 永久修复 / 待验证：

## 变更模板

### [YYYY-MM-DD] 标题
- 改了什么：
- 为什么改：
- 影响范围：
- 回滚方式：

---

## 现有记录

### [2026-03-26] /new 后 402 中间错误对用户可见
- 现象：/new 后先出现两条 402 报错，随后才轮换到可用 key 并成功回复。
- 触发条件：custom-zenmux-ai 多 key 中前两个 key 额度不足，第三个 key 可用；failover 发生在用户可见链路中。
- 根因层级：产品缺口 + 状态层
- 临时止血：清理 auth profile 冷却状态；调整 auth 轮换与 cooldown 相关 patch；重启 Gateway。
- 永久修复 / 待验证：需要验证 failover 中间错误是否能完全对用户隐藏；OpenClaw 升级后需重打 monkey-patch。

### [2026-03-26] api_key 轮换策略与预期不一致
- 现象：`/new` 后可能优先命中旧的、已无额度的 key，而不是继续沿用刚刚成功的 key。
- 触发条件：auth profile 排序与 api_key 使用场景不匹配；explicit auth.order 干扰预期选择。
- 根因层级：产品缺口 + 状态层
- 临时止血：改为 MRU sticky 思路；移除不合适的 explicit order；调整 cooldown 策略。
- 永久修复 / 待验证：等待实际 402 场景继续验证；必要时向上游提 issue。

### [2026-03-26] Zenmux 三级保障方案（变更）
- 改了什么：auth-profiles.js MRU sticky 排序、cooldown bypass 移除、openclaw.json cooldown/fallback 重构
- 为什么改：/new 后 402 轮换对用户可见 + key 选择策略不合理
- 影响范围：所有 agent 的 auth profile 选择逻辑、fallback 链路
- 回滚方式：`patch-backup/` 目录有旧文件；openclaw.json 改动见 memory/2026-03-26.md

### [2026-03-27] OpenClaw 升级 2026.3.23-2 → 2026.3.24 + monkey-patch 重打（变更）
- 改了什么：npm 升级 openclaw；auth-profiles + pi-embedded 两处 patch 重打到新版文件
- 为什么改：跟进上游版本
- 影响范围：全局；patch 文件名变更（新 hash）
- 回滚方式：旧版文件备份在 `patch-backup/`；`npm install -g openclaw@2026.3.23-2` 可回退

### [2026-03-28] monkey-patch 自动化脚本（变更）
- 改了什么：新建 `patch-openclaw.sh`，升级后一条命令自动重打2处patch
- 为什么改：手动打patch已2次，接近3次熔断线；规则4判定自动化为短期最优
- 影响范围：所有agent的auth轮换和402处理
- 回滚方式：脚本自动备份到 patch-backup/；上游 issue openclaw/openclaw#55897 跟踪根本解决

### [2026-03-27] 默认主模型多次切换（变更）
- 改了什么：zenmux key1 → key2 → key3 → openai-codex/gpt-5.4 → 最终回到 zenmux key1
- 为什么改：key 额度问题排查，最终确认 key1 恢复可用
- 影响范围：所有 agent 默认模型
- 回滚方式：openclaw.json 改 auth profiles + model.default

### [2026-03-27] 152 SSH 隧道过夜断开，缺少自动恢复
- 现象：152 到 205 的 SSH 隧道过夜断线，次日无法通过 localhost:28789 使用 Gateway。
- 触发条件：手工建立的隧道没有稳定自恢复机制。
- 根因层级：运行层
- 临时止血：手动重建隧道。
- 永久修复 / 待验证：152 上改为 wrapper 脚本 + LaunchAgent + kickstart；205 heartbeat 增加隧道监控与远程拉起。
