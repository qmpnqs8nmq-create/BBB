# OpenClaw 应急修复手册（不依赖 Dashboard）

这份文档的目标很简单：

- 当 Dashboard 打不开
- 当网页 UI 卡住
- 当 token / pairing / gateway / 8888 入口出问题
- 当你只剩下 **Mac 本机终端** 可用

你仍然可以靠终端把系统拉回来。

---

## 一、最重要的原则

**不要先乱改。先确认现状，再备份，再修。**

推荐顺序：
1. 看状态
2. 做精简快照
3. 修 Gateway
4. 修连接 / token / pairing
5. 最后才动 8888 代理或更大的系统设置

---

## 二、最重要的两个工具

### 1. Gateway 状态
```bash
openclaw gateway status
```

用途：
- 看 Gateway 是否在运行
- 看监听端口
- 看是不是 LaunchAgent 后台模式
- 看 Dashboard 地址

### 2. OpenClaw 总状态
```bash
openclaw status --deep
```

用途：
- 看 Gateway 是否 reachable
- 看安全提示
- 看 agent / session / channel 状态

---

## 三、先做精简快照（最重要的后悔药）

### 执行命令
```bash
~/.openclaw/workspace/scripts/openclaw_manual_snapshot_lite.sh
```

### 它会备份什么
- `~/.openclaw/openclaw.json`
- `~/Library/LaunchAgents/ai.openclaw.gateway.plist`
- `~/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist`
- `~/.openclaw/workspace/scripts/https_lan_proxy_8888.js`

### 什么时候一定要先做
- 改配置前
- 修 token 前
- 改 Gateway 前
- 改 8888 代理前
- 升级前

---

## 四、最关键的恢复流程

## 场景 A：终端运行 `openclaw gateway` 后看起来“卡住”

### 这通常不是故障
`openclaw gateway` 是前台常驻进程。

表现：
- 终端停在那里
- 没有返回 shell 提示符

这通常表示：
- Gateway 正在前台运行
- 不是卡死

### 正确做法
不要长期手动盯着它，改用后台 LaunchAgent：
```bash
openclaw gateway install
openclaw gateway status
```

常用：
```bash
openclaw gateway restart
openclaw gateway stop
openclaw gateway start
```

---

## 场景 B：Dashboard 打不开 / UI 不正常

### 先查 Gateway 是否活着
```bash
openclaw gateway status
openclaw health --json
openclaw status --deep
```

### 如果 Gateway 没起来
```bash
openclaw gateway start
```

### 如果状态混乱，直接重启
```bash
openclaw gateway restart
```

### 再试本机地址
```text
http://127.0.0.1:18789/
```

---

## 场景 C：出现 `token mismatch`

### 现象
日志里出现：
- `unauthorized`
- `token_mismatch`

### 核心含义
- UI 里保存的旧 token 和当前 Gateway token 不一致

### 先在终端确认配置还在
```bash
openclaw gateway status
openclaw status --deep
```

### 当前 token 的来源
默认在：
- `~/.openclaw/openclaw.json`
- 路径：`gateway.auth.token`

### 修复思路
1. 确认 Gateway 正常
2. 打开本机 Dashboard 或客户端设置
3. 把旧 token 清掉
4. 填入当前 token
5. 不行就清站点缓存后重连

---

## 场景 D：出现 `pairing required`

### 核心含义
这通常表示：
- 网络路由基本通了
- 但设备还没有被批准配对

### 先看有没有待批准请求
```bash
openclaw devices list
```

### 如果有 pending，直接批准最新一个
```bash
openclaw devices approve --latest
```

### 如果没有 pending，但客户端还报 pairing required
说明大概率是：
- 客户端还拿着旧二维码 / 旧 setup code / 旧状态

### 这时应这样做
```bash
openclaw qr --json
```
然后：
- 重新生成二维码 / setup code
- 重新扫码或重新连接
- 再查一次 `openclaw devices list`

---

## 场景 E：LLM request timed out

### 含义
- 大多数情况下是网络慢、上游 LLM 服务慢、提供商抖动
- 不一定是 OpenClaw 坏了

### 默认处理（先轻后重）
1. 等 10~30 秒
2. 刷新页面
3. 重试一次

如果恢复了：
- 到此为止
- 不检查 OpenClaw
- 不重启 Gateway

### 只有在这些情况才检查 OpenClaw
- 连续 2~3 次 timeout
- 页面卡住
- 提交没反应
- 等一阵仍不恢复

### 默认只检查，不修
```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh
```

### 只有确认本地异常时，才进入修复
```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh --repair
```

---

## 场景 F：OpenClaw 配置坏了 / CLI 报 config invalid

### 典型现象
- `openclaw status` 跑不动
- `openclaw security audit` 报配置错误
- 提示某些 key 不被识别

### 修复命令
```bash
openclaw doctor --fix
```

### 修之前建议先做快照
```bash
~/.openclaw/workspace/scripts/openclaw_manual_snapshot_lite.sh
```

### 修完复查
```bash
openclaw status --deep
openclaw security audit --deep
openclaw update status
```

---

## 场景 G：8888 局域网入口异常

### 已知关系
- `8888`：局域网 HTTPS 代理入口
- `8899`：本地 UI 前端
- `18789`：OpenClaw Gateway

链路是：

```text
同事浏览器 -> 8888 -> 8899 -> 18789
```

### 先查 8888 进程是否在
```bash
lsof -nP -iTCP:8888 -sTCP:LISTEN
```

### 查看 8888 的 LaunchAgent
```bash
cat ~/Library/LaunchAgents/ai.openclaw.lan8888-proxy.plist
```

### 查看脚本
```bash
cat ~/.openclaw/workspace/scripts/https_lan_proxy_8888.js
```

### 如果 8888 脚本被改坏
可以从手工快照恢复：
```bash
cp <你的快照目录>/.openclaw/https_lan_proxy_8888.js ~/.openclaw/workspace/scripts/
```

---

## 五、最小恢复动作（优先级顺序）

如果系统不正常，优先按这个顺序操作：

### 第一步：看状态
```bash
openclaw gateway status
openclaw status --deep
openclaw health --json
```

### 第二步：做快照
```bash
~/.openclaw/workspace/scripts/openclaw_manual_snapshot_lite.sh
```

### 第三步：重启 Gateway
```bash
openclaw gateway restart
```

### 第四步：如果是配置问题，跑 doctor
```bash
openclaw doctor --fix
```

### 第五步：如果是配对问题
```bash
openclaw devices list
openclaw devices approve --latest
```

### 第六步：如果是二维码 / 连接状态问题
```bash
openclaw qr --json
```
重新扫码 / 重连

---

## 六、最值得记住的命令

```bash
openclaw gateway status
openclaw gateway restart
openclaw status --deep
openclaw health --json
openclaw doctor --fix
openclaw devices list
openclaw devices approve --latest
openclaw qr --json
~/.openclaw/workspace/scripts/openclaw_manual_snapshot_lite.sh
```

---

## 七、什么时候不该乱动

先别急着改系统防火墙、改端口、改 Tailscale、改代理脚本，如果你还没确认：

- Gateway 是否真的挂了
- 只是 token mismatch 还是整个网关坏了
- 只是 pairing required 还是网络不通
- 只是前端缓存问题还是后端故障

很多问题其实只需要：
- 重启 Gateway
- 批准设备
- 刷新 token
- 重新生成二维码

没必要上来就大修。

---

## 八、结论

**没有 Dashboard，也能修。**

真正最重要的方法不是网页，而是：
- 终端看状态
- 先做精简快照
- 用 `gateway status / restart`
- 用 `devices list / approve`
- 用 `qr --json` 重新建立连接
- 必要时用 `doctor --fix` 修配置

如果你只记住一句话：

> 先看状态，先拍快照，再重启 Gateway，再修 token / pairing / config。
