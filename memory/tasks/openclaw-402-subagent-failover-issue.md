# OpenClaw 上游 Issue 草稿:402 错误不触发 failover + 子 agent 模型解析不一致

**版本**: OpenClaw 2026.6.5 (5181e4f)
**环境**: 自定义 provider(ZenMux,`api: anthropic-messages`,baseUrl `https://zenmux.ai/api/v1`)
**日期**: 2026-06-12

---

## 一句话

当 provider 在 JSON 错误体里把状态码写成**字符串值**(`"code":"402"`)时,OpenClaw 既不会把它分类成可 failover 的错误(导致配置好的 fallback 链完全不触发),子 agent 也无法通过 `agents.defaults.subagents.model` 真正改变执行期模型。结果:主 session 已 failover 到健康 key,派出的子 agent 仍从欠费 key 起步并**单发即死(0 token,无重试)**。

---

## Bug 1:`RAW_402_MARKER_RE` 入口正则不容忍引号包裹的码值

`dist/errors-*.js` 中:
```js
const RAW_402_MARKER_RE = /["']?(?:status|code)["']?\s*[:=]\s*402\b/i;
```
该正则允许 key 被引号包裹,但**不允许 value(402)被引号包裹**。

实测:
```
'"code":"402"'  -> false   (ZenMux 真实返回,值带引号)
'"code":402'    -> true    (值不带引号)
```

下游 `classify402Message()` 其实**有**正确逻辑:
```js
function hasQuotaRefreshWindowSignal(text){
  return text.includes("subscription quota limit") &&
    (text.includes("automatic quota refresh") || text.includes("rolling time window"));
}
// classify402Message: if (hasQuotaRefreshWindowSignal(normalized)) return "rate_limit";
```
ZenMux 的配额错误文案完全匹配,本应判 `rate_limit`(立即 failover)。但因为入口正则被引号挡住,这段逻辑根本到不了。

## Bug 2:错误信息在传到 failover 决策点前被压扁,丢失 status

真值表(用 `classifyFailoverSignal()` 实跑):

| 传入分类器的内容 | 判定 | 是否 failover |
|---|---|---|
| 完整配额原文 + status 402 | rate_limit | ✅ 立即跳 |
| `LLM request failed.` + status 402 | billing | ⚠️ 长冷却 |
| `LLM request failed.`(无 status) | **null** | ❌ 不跳 |

实际日志里,failover 层拿到的就是被收敛后的 `LLM request failed.`,原始 rawError(含 402 + 配额文案)和 HTTP status **都没传到分类器**。所以最终落到 `null` → 不 failover。

实测日志(子 agent):
```
embedded run start: provider=zenmux-key1
model-fetch response: status=402 elapsedMs=755
embedded run agent end: isError=true error=LLM request failed.
  rawError={"error":{"code":"402","type":"quote_exceeded","message":"...subscription quota limit...rolling time window..."}}
→ 全程 ~1s,0 token,无任何 fallback 重试
```

## Bug 3(可能相关):`agents.defaults.subagents.model` 不改变执行期 provider

配置:
```json
"agents.defaults.subagents.model": {
  "primary": "zenmux-key2/anthropic/claude-opus-4.8",
  "fallbacks": ["codex/gpt-5.5", "zenmux-key1/anthropic/claude-opus-4.8"]
}
```
`config get` 确认已写入。`sessions_spawn` 返回 `resolvedModel: zenmux-key2`。
但**实际运行日志**显示子 agent 仍 `provider=zenmux-key1`,撞 402 秒死。
报告值(key2)与执行值(key1)不一致。

需上游确认:`subagents.model` 是否真正作用于子 agent 任务运行,还是只影响元数据/announce 路径。

---

## 复现

1. 配两个同类型自定义 provider(返回 anthropic-messages 形态),其中之一返回 `{"error":{"code":"402","type":"...","message":"...subscription quota limit...rolling time window..."}}`(值为字符串 `"402"`)。
2. 设 `agents.defaults.model = { primary: keyA, fallbacks: [keyC, keyB] }`。
3. keyA 配额耗尽,触发 402。
4. 观察:主 session 一次性失败,不 failover 到 keyC/keyB(或仅靠粘住的旧 override 才用上 keyB);子 agent 从 keyA 起步,单发即死。

## 期望

- `RAW_402_MARKER_RE` 容忍引号包裹的码值:`["']?(?:status|code)["']?\s*[:=]\s*["']?402\b`
- 或/并:failover 分类器应拿到原始 provider 错误体 + HTTP status,而不是被收敛的 `LLM request failed.`
- `subagents.model` 的 primary/fallbacks 应真正决定子 agent 执行期 provider/model。

## 本地现状(我们的处置)

- 已修我们这侧一个无关的死配置(`billingBackoffHoursByProvider` 的 key 之前写成不存在的 `custom-zenmux-ai`,改为真实 `zenmux-key1`/`zenmux-key2`)。
- 子 agent model 覆盖实测无效,已回滚。
- 根治依赖上游修 Bug 1/2(/3)。临时绕过:让欠费 key 自身恢复(配额窗口刷新或充值)。
