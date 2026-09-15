# OpenClaw 2026.9.4 pre-upgrade rollback set

- Created: 2026-09-14 Asia/Shanghai
- Core/CLI/Gateway baseline: 2026.8.2
- Service: systemd user unit `openclaw-gateway.service`, Node entrypoint `/usr/lib/node_modules/openclaw/dist/index.js`
- Enabled global plugins: Codex 2026.8.2; Feishu 2026.8.2; Perplexity 2026.8.2; Weixin 2.4.8 (local warm-up/ret=-2 and CLI metadata patches); WeCom 2026.5.7
- Local plugin: contact-delivery

## Archives

- `openclaw-core-2026.8.2.tgz`
  - SHA-256: `15179747fe025addcf261796e3ed8e9e8f69e105ee1e6cce85e83401c1cf7cd8`
- `plugin-projects-2026.8.2.tgz`
  - SHA-256: `d7023ee1126ebd839e9c2be4d6618cef8232c130813a54eae9df46ef304e0b08`
- `config-service-local-2026.8.2.tgz`
  - SHA-256: `9d933873be6ab2afee67c76751d859563dd43a247aaf316eaff43968a503e766`

All archives passed `gzip -t` and `tar -tf`; directory mode is 700 and archive modes are 600.

## Recovery outline

1. Stop the user Gateway service.
2. Move the failed core/plugin directories aside to a dated recovery location.
3. Extract the core archive under `/usr/lib/node_modules`, plugin archive under `/root/.openclaw`, and config/service/local archive under `/`.
4. Run both local patch scripts, refresh the plugin registry, validate config, then restart the Gateway.
5. Verify CLI/npm/runtime agreement at 2026.8.2, one Gateway PID, channel probes, plugins doctor, memory search, and security audit.
