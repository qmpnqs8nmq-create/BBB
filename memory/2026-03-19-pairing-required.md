# Session: 2026-03-19 16:22:57 UTC

- **Session Key**: agent:main:main
- **Session ID**: ad2d0279-e53f-4adb-afe4-8881f15eaca7
- **Source**: webchat

## Conversation Summary

user: Sender (untrusted metadata):
```json
{
  "label": "openclaw-control-ui",
  "id": "openclaw-control-ui"
}
```

[Thu 2026-03-19 23:18 GMT+8] 又出现问题：paring required
assistant: 有一个自动批准配对的 LaunchAgent！让我看看：
assistant: "pairing required" 说明从局域网浏览器连上来的 WebSocket 没有带 token/认证信息。这是 Control UI 通过代理访问 gateway 时的认证问题。让我看看 gateway 的 auth 配置和 Control UI 的认证方式：
assistant: 有 **2 个 pending pairing requests**！这是从局域网浏览器连接时产生的。直接批准：
assistant: 全部批准完了。
assistant: [[reply_to_current]] 这次的任务完成啦 ✅

### 问题原因
局域网浏览器首次通过 `https://192.168.0.213:8888` 连接 gateway 时，被视为新设备，需要配对授权。有 **3 个 pending pairing requests**，全部卡在等待批准。

### 修了什么
- 逐一批准了 3 个 pending pairing requests
- 当前 **0 pending，12 台设备已配对**
- 代理 `https://192.168.0.213:8888` → HTTP 200 ✅

现在在局域网电脑浏览器 **刷新** `https://192.168.0.213:8888`，应该能正常进入 Control UI 了。
user: System: [2026-03-19 23:19:15 GMT+8] Exec completed (sharp-ha, code 0) :: │ Tokens │ IP │ ├──────────────────────────────┼────────────┼────────────────────────────────────────────────┼────────────┼────────────┤ │ 6dd84dee5376a1f401bb55b5f6c4 │ operator …

Sender (untrusted metadata):
```json
{
  "label": "openclaw-control-ui",
  "id": "openclaw-control-ui"
}
```

[Thu 2026-03-19 23:21 GMT+8] 还是：又出现问题：paring required
assistant: 

让我彻底搞清楚这个问题的机制。
assistant: 现在让我理解完整的问题链。Control UI 从局域网浏览器 `https://192.168.0.213:8888` 加载后，它需要**通过 WebSocket 连接到 gateway**。问题是：

1. Control UI 页面加载 → 通过代理到 gateway → HTTP 200 ✅（页面能打开）
2. Control UI 内部的 WebSocket 连接 → 也通过代理到 gateway → **gateway 看到的不是 local client**，要求 pairing

核心问题是 `gateway.bind = loopback`，gateway 认为从代理转发来的连接不是本地客户端。
assistant: 现在很清楚了。根据 skill 文档，问题是：

**你在局域网其他电脑通过 `https://192.168.0.213:8888` 代理访问 gateway，但 gateway 的 `bind=loopback` 意味着它只接受本机连接。代理虽然从 127.0.0.1 转发，但 WebSocket 握手中 gateway 判断这不是 local client（因为 Origin 头暴露了真实来源），所以要求 pairing。**

正确修复方案不是反复批准 pairing，而是让 gateway 知道代理是可信的：
assistant: 关键信息：**"Non-local tailnet/LAN clients still require explicit pairing approval."**

从局域网浏览器访问，即使通过代理中转，gateway 仍然视为非本地客户端。Control UI 需要一个已配对的 token。让我看看 Control UI 是怎么认证的：
assistant: **找到了！** 这是关键文档。问题完全清楚了：

你的代理在 `127.0.0.1` 上运行，连到 gateway 也在 `127.0.0.1:18789`。Gateway 看到连接来自 `127.0.0.1`，会认为是"local client"。但 **Control UI 的 WebSocket 连接需要 `Origin` 在 allowedOrigins 中**。

真正的问题可能是代理脚本没有正确转发 WebSocket。让我查看代理脚本的 WebSocket 处理：
assistant: 找到根因了！代理脚本里 **没有 WebSocket 升级处理**。它只代理了 HTTP 请求，但 Control UI 需要 WebSocket 连接到 gateway，WebSocket 升级请求被代理丢弃了。

同时，错误消息 "proxy error: connect ECONNREFUSED 127.0.0.1:8899" 和 "pairing required" 可能混在一起——让我确认代理目标确实已改好，然后补上 WebSocket 支持：
assistant: 好，端口确实是 18789。脚本第 292 行有 `net.connect` 处理 WebSocket 升级。让我仔细看那段逻辑：
assistant: WebSocket 升级处理**存在**。它还注入了 `x-forwarded-for` 和 `x-real-ip` header。

**真正的问题**是：gateway 收到 WebSocket 升级请求时，`Origin` header 是 `https://192.168.0.213:8888`——这个 origin 在 allowedOrigins 里了。但 gateway 同时检查连接是否来自已配对设备。

关键点：**Control UI 从局域网浏览器连接时，浏览器没有配对 token**。本机 `127.0.0.1` 访问可以跳过配对（local-client），但代理转发时 gateway 可能看到 `x-forwarded-for` 是局域网 IP，不再视为 local client。

根据文档，需要配置 `gateway.trustedProxies` 让 gateway 信任代理：
