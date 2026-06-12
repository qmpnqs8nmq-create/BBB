# HANDOFF

最后活跃: 2026-06-12 15:00
当前话题: OpenClaw fallback / 子agent failover 排查(Bruce 主导,已收尾)

关键结论:
- 根因是 OpenClaw 2026.6.5 上游 bug:ZenMux 返回 "code":"402"(字符串值)被入口正则 RAW_402_MARKER_RE 挡掉 + 错误被收敛成 "LLM request failed." 丢 status → failover 分类判 null → fallback 链不触发(配了也没用)。
- 子 agent 秒死 0 token 根因同上:从配置 primary(欠费 key1)起步 + 撞 402 不 failover。agents.defaults.subagents.model 覆盖实测无效(报告 key2 但执行 key1)。
- 已修:billingBackoffHoursByProvider key 从假的 custom-zenmux-ai → 真实 zenmux-key1/key2=1h(保留生效)。
- 子 agent 无效配置已回滚。Gateway 已 restart,running/probe ok。
- 临时绕过:key1 配额刷新/充值后即缓解。根治靠上游 issue。

待办:
- Bruce 决定是否提交上游 issue(草稿已备)
- → task: memory/tasks/openclaw-402-subagent-failover-issue.md
