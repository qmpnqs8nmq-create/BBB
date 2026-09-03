---
name: "openclaw-upgrade-audit"
description: "Audit OpenClaw upgrades and produce a safe remediation gate."
---

# OpenClaw Upgrade Audit

## Procedure

1. Establish the target release and read the system change ledger, current handoff, incident log, and relevant local patch notes; record the expected core, plugin, service, and rollback versions before checking live state. Complete when the intended version and known upgrade-sensitive customizations are explicit.

2. Run read-only version and process checks for the CLI, global package, update channel, Gateway runtime, systemd main PID/start time/restart count, and matching Gateway processes. Treat the upgrade as core-complete only when CLI, package, and runtime agree and exactly one healthy Gateway is active.

3. Validate rollback material before diagnosing forward fixes: verify the backup directory permissions, list expected configuration/service/plugin artifacts, and test every archive with both compression integrity and archive listing. Complete when the rollback set is readable without extracting over live files.

4. Inspect plugin inventory and compare each enabled external or official plugin against its own current release metadata; do not assume plugin patch versions equal the OpenClaw core version. Check persisted-registry diagnostics separately from runtime plugin loading.

5. Verify channels from runtime evidence, not the status table alone. Inspect startup logs for authentication, WebSocket readiness, provider exits, auto-restart loops, and import/export failures; classify each channel independently so one healthy messaging provider never masks another broken provider.

6. Verify every upgrade-sensitive local patch against the installed build. Locate the semantic marker across current `dist` files instead of relying on an old hashed filename or prefix, confirm the intended replacement is present, and read the service pre-start log. Treat “no target found” or zero changed/already-patched candidates as a failed patch gate even if the helper exits successfully.

7. For a plugin carrying a local patch, compare the live file with its patched backup, inspect the candidate replacement package without installing it, and determine whether the candidate fixes compatibility and whether the local behavior must be re-applied. Complete when both upstream compatibility and local customization preservation have an evidence-backed path.

8. Run `openclaw doctor`, `openclaw security audit --deep`, `openclaw status --deep`, memory status/search, firewall/listener checks, disk space, reboot-required state, and Gateway memory/task counters. Retry memory search once after indexing activity settles when a concurrent revision change occurs; report persistent index failure separately from upgrade health.

9. Classify the result as: core failed, core upgraded but peripherals unsynchronized, or fully healthy. Report severity, evidence, rollback readiness, and the smallest staged remediation. Require explicit approval before plugin installation, global configuration or service edits, firewall changes, Gateway restart, or host reboot.

10. Before the approved restart, run configuration validation, post-upgrade/plugin compatibility checks, refresh the persisted plugin registry after the final plugin or manifest mutation, and verify each local patch is syntactically valid and idempotent. Request one coordinated safe restart; if it remains deferred behind the maintenance turn or scheduled work, verify that no PID change occurred before performing the already-approved service restart once. Expect that restart to terminate the controlling Codex/tool turn, then resume from the handoff rather than repeating installation or patching.

11. After restart, separate old-process shutdown errors from new-process health by the new PID and start timestamp. Re-run version agreement, single PID/probe, `channels status --probe`, plugin doctor/drift, local patch marker and pre-start log, failover classification or trace when safely testable, memory/index state, doctor, and security audit. Accept a startup memory spike only when it is attributable to a bounded worker, the worker exits, memory falls, and no later pressure recurs. Complete only when business channels and upgrade-sensitive patches pass, not merely when Gateway starts.

12. Close the upgrade separately from residual-system triage. Recheck reboot-required packages, recent model/fallback errors, dead-letter age/count, current versus peak Gateway memory, security warnings, and doctor capability suggestions; rank them as blocking repair, near-term reliability maintenance, optional security hardening, or historical cleanup. Do not expand agent permissions merely to silence doctor warnings, and do not treat a generic health summary such as an unconfigured default account as a channel failure when account-specific probes pass. Complete when every residual has an owner/recommendation and none is mislabeled as an upgrade regression.

13. Before migrating a model used by an isolated automation, identify whether the workload is text inference, image understanding, or image generation, then test the candidate from the exact owning agent and headless execution path without delivery. Do not infer automation availability from a successful interactive Codex/OAuth session or from catalog `available` metadata. Keep the prior model until the candidate returns a real successful response; if every configured OpenAI route fails, restore the proven model and request any new credential only through protected masked entry. Complete when the automation route itself is proven or safely rolled back.

14. Test external plugins against CLI metadata isolation with an intentionally unknown command. When a plugin has no root commands but its normal `register()` touches runtime, add a dedicated no-op `cli-metadata.js` entry; an empty manifest `cliCommands` array alone does not prevent the loader from falling back to the runtime entry. Make the repair generation-path-aware and idempotent, then verify the unknown command reports only “unknown command” and refresh the persisted registry. If registry remains `source-changed`, compare actual differences and workspace provenance before treating it as runtime drift. Complete when CLI discovery is clean and runtime plugin loading still passes.

## Pitfalls

- An empty `cliCommands` declaration does not replace a dedicated metadata entry for a runtime-touching plugin.
- A green channel summary can coexist with a provider process that repeatedly exits.
- An interactive OAuth-backed model can work in WebChat while the same model is unusable by an isolated automation.
- A successful pre-start hook can be fail-open and perform no patch.
- Updating a patched plugin can fix compatibility while silently deleting local behavior.
- A stale systemd description is cosmetic only after the live command path and runtime version are verified.
- Do not print credentials or read secret values during the audit.
