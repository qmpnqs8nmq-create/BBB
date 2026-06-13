# 402 with string-typed error code is not classified as failover-worthy → fallback chain never triggers

**Version:** OpenClaw 2026.6.5 (5181e4f)
**Provider setup:** custom OpenAI-compatible / anthropic-messages provider whose JSON error body encodes the status code as a **string** (`"code":"402"`).

## Summary

When a provider returns an HTTP 402 whose JSON error body has a **string-typed** code value (`{"error":{"code":"402", ...}}`), OpenClaw does not classify it as failover-worthy. The configured model fallback chain never triggers: the request fails single-shot with 0 tokens, no retry, no profile cooldown recorded. A primary key that has exhausted its quota keeps getting retried by every new run/sub-agent instead of failing over to a healthy fallback model.

## Root cause

In `dist/errors-*.js`:

```js
const RAW_402_MARKER_RE = /["']?(?:status|code)["']?\s*[:=]\s*402\b| ... /i;
```

The pattern allows the *key* (`status`/`code`) to be quoted, but requires the **value `402` to be unquoted**.

```
'"code":"402"'  -> false   // provider returns string value
'"code":402'    -> true    // unquoted value
```

Because the entry matcher fails, the 402 classification path is skipped entirely. The downstream logic is actually correct and *would* classify it as `rate_limit` (retryable usage-window) if it were reached:

```js
function hasQuotaRefreshWindowSignal(text){
  return text.includes("subscription quota limit") &&
    (text.includes("automatic quota refresh") || text.includes("rolling time window"));
}
// classify402Message(): if (hasQuotaRefreshWindowSignal(normalized)) return "rate_limit";
```

## Evidence (before fix)

A run hitting the quota-exhausted key:
```
provider=<keyA> status=402
embedded run agent end: isError=true error="LLM request failed."
  rawError={"error":{"code":"402","type":"...","message":"...subscription quota limit...rolling time window..."}}
→ ~1s, 0 tokens, no failover, profile errorCount stays 0 (no cooldown recorded)
```

## Suggested fix

Tolerate a quoted status/code value in the entry matcher:

```js
/["']?(?:status|code)["']?\s*[:=]\s*["']?402\b/i
```

After this change (verified locally, end-to-end):
```
provider=<keyA> → 402
auth profile failure state updated: reason=rate_limit window=cooldown
embedded run failover decision: decision=fallback_model reason=rate_limit from=<keyA>
→ failed over to next model, run completed successfully
```

## Related (may warrant separate issues)

1. The failover classifier at the decision point often receives the collapsed `"LLM request failed."` message rather than the raw provider error body + HTTP status. When status is lost, even a 402 with a clear retryable message classifies as `null` (no failover). Consider always passing the original status/raw body to the classifier.
2. `agents.defaults.subagents.model` (primary + fallbacks) did not change the sub-agent's executed provider in testing: `config get` and the spawn `resolvedModel` reported the override, but the actual run used the agent's configured default `primary`. Needs confirmation whether `subagents.model` is meant to drive sub-agent task execution.
