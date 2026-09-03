# OpenClaw 8.2 升级后第二批维护

- 目标：备份配置，修复 Google 模型注册与默认 fallback，pin Codex，重启宿主机并复测。
- 用户授权：2026-09-02 WebChat 回复“推荐下一批动作 ok”。
- 当前版本：OpenClaw/Gateway 2026.8.2；Gateway PID 1913334，probe ok。
- 根因 1：Validation Tracker 指定 google/gemini-3.1-flash-image-preview，但 models.providers.google 未登记该模型。
- 根因 2：默认 fallback#1 为 ZenMux key1/Fable 5，真实请求因订阅限制返回 404；key2/Fable 5 可成功。
- 根因 3：Codex 已解析到 2026.8.2，但 install.spec 仍为未 pin 的 @openclaw/codex。
- 宿主机：libc6 更新要求 reboot；重启会中断当前会话，恢复后继续。
- 备份已完成：配置归档 `/root/openclaw-backups/openclaw-post-8.2-config-pre-20260902-101915.tar.gz`（verified）；全局 SQLite 快照仓库 `/root/openclaw-backups/openclaw-post-8.2-sqlite-pre-20260902-101915`；Codex/systemd 元数据目录同名前缀。
- 过宽全状态备份因临时占用 4.9G 主动终止，临时目录已删除，根盘恢复 67%。
- 模型已修：Google provider 补 `api=google-generative-ai` 与官方 v1beta baseUrl；真实请求 HTTP 200/MODEL_OK。
- 默认 fallback 已从 key1+key2 收敛为仅 key2；key2 真实请求 HTTP 200/FALLBACK_OK。
- Codex install.spec/resolvedSpec 已精确 pin 为 `@openclaw/codex@2026.8.2`，integrity 与升级前一致。
- Pre-reboot 门禁：config valid；plugins doctor 12/12 通过；Gateway 2026.8.2/probe ok。
- 重启前 boot_id：`f490d9ac-74c5-4e2c-a878-9fd2306134d2`；系统因 libc6 要求 reboot。
- 自动接续：one-shot job `0fd51ea8-1fb8-4931-a24d-5c7b0366d994`，2026-09-02 10:35 +08:00，成功后自动删除。
- 下一步：执行宿主机 reboot；启动后完成版本、通道、模型、402、安全、内存与日志复测。

## 2026-09-02 10:45 OpenAI 迁移门禁
- 用户明确要求将 `google/gemini-3.1-flash-image-preview` 迁移到 OpenAI。
- 唯一活动引用：chief cron `7f1dacbb-d21b-4e46-9519-47fecef2c516`（Validation Tracker）；任务纯文本，不做图像生成。
- 迁移目标：`openai/gpt-5.6-sol`；当前 WebChat 会话已用该模型与 OAuth 正常运行。
- 保留 Google provider 与 `gemini-3.5-flash`/embedding；仅删除误用的 `gemini-3.1-flash-image-preview` 显式登记。
- 回滚：`openclaw cron edit 7f1dacbb-d21b-4e46-9519-47fecef2c516 --model google/gemini-3.1-flash-image-preview`；并在 `models.providers.google.models[0]` 恢复 `{"id":"gemini-3.1-flash-image-preview","name":"gemini-3.1-flash-image-preview"}`。
- 认证实测：`openai/gpt-5.6-sol` 在 chief 独立执行中无 usable profile；`openai/gpt-5.5` 命中 inactive API account。下一候选为 Codex OAuth 的 `openai-codex/gpt-5.5`。
- allowlist 试验回滚：删除 `openai-codex/gpt-5.5` 的 `agents.defaults.models`/modelPolicy 项，并恢复 Gemini preview 的两项 allowlist 登记。
- 最终：OpenAI-Codex 与 OpenRouter/OpenAI 也均 HTTP 403；所有临时 allowlist/model 项已删除，Validation Tracker 与 Google provider 登记已恢复。
- Post-reboot 闭环：版本/插件/通道/Google/key2/402/security/firewall/reboot marker 全部通过；Google 与 key2 分别返回 `POST_REBOOT_GOOGLE_OK`、`POST_REBOOT_FALLBACK_OK`。
- 资源：cgroup 11.7G 主要是约 10.1G 可回收 file cache，anon 约 1.22G，Gateway RSS 约 956M；event loop healthy、NRestarts=0、无 OOM。
- 未完成唯一项：后台 agent 的 OpenAI 认证修复后，再将 cron `7f1dacbb-d21b-4e46-9519-47fecef2c516` 迁移到可验证成功的 OpenAI 模型。
- 受保护凭据：Secret Store 为空；`OPENAI_API_KEY` 掩码录入本轮 no_answer。后续只能重新发起安全输入，禁止聊天收集。

