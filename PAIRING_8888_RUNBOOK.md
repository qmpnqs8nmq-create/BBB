# 8888 Pairing 自动处理链路说明与验证机制

目标：
- 不再靠“感觉自动程序在跑”
- 明确输入、动作、验证、证据四段闭环
- 避免反复出现“用户说有 pending，但后台查不到”

---

## 一、完整链条

### 输入
监听并读取：
- `~/.openclaw/devices/pending.json`
- `~/.openclaw/devices/paired.json`

### 动作
当 `pending.json` 中存在待配对请求时：
1. 执行：
   ```bash
   openclaw devices approve --latest
   ```
2. 立即执行 browser scope 修复：
   - 把 `openclaw-control-ui / webchat` 设备修成完整 operator scopes

### 验证
批准后立即核对：
- `pending.json` 数量是否减少
- `paired.json` 数量是否增加
- `paired.json` 指纹是否变化

只要三者之一变化，就说明动作落地了。

### 证据
独立日志文件：
- `~/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.log`

独立状态文件：
- `~/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.state.json`

日志会记录：
- 观察到的 pending/paired 状态
- 是否检测到 pending
- 是否执行 approve
- approve 后是否验证成功
- scope repair 是否修改了 paired 设备

---

## 二、为什么之前会重复出问题

旧方案的问题：
1. 过度依赖 gateway 日志命中
2. watcher 在跑，但没有留下稳定的批准证据
3. 浏览器 8888 入口可能保留旧 device pairing 状态
4. 导致：用户看到 `pairing required`，但后台未必正好看到一个可批准的 pending

新方案改为：
- **直接读状态文件**
- **直接批准**
- **直接验证**

---

## 三、当前自动程序文件

脚本：
- `~/.openclaw/workspace/scripts/watch_8888_pairing_autoapprove.sh`

LaunchAgent：
- `~/Library/LaunchAgents/ai.openclaw.watch-8888-pairing-autoapprove.plist`

---

## 四、人工核查方法

### 看当前 pending / paired
```bash
openclaw devices list --json
```

### 看自动程序日志
```bash
tail -n 100 ~/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.log
```

### 看自动程序状态快照
```bash
cat ~/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.state.json
```

### 看进程是否在跑
```bash
ps -ax | grep '[w]atch_8888_pairing_autoapprove.sh'
```

---

## 五、验证标准

以后如果再有人说 8888 访问出现 `pairing required`，检查时要能明确回答：

1. `pending.json` 当时有没有出现请求？
2. 自动程序有没有记录到 pending？
3. 有没有执行 `approve --latest`？
4. 执行后 `paired.json` 有没有变化？
5. paired 设备 scopes 是否完整？

如果答不出这 5 个问题，就说明链条还不完整。

---

## 六、当前设计原则

- 先批准，再验证
- 不靠“猜”
- 不靠“看起来在跑”
- 每一步都必须有证据
