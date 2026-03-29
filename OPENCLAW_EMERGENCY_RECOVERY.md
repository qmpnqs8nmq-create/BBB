# OpenClaw 应急修复速查

当 Dashboard 打不开、只剩终端可用时的快速恢复指南。

## 原则
**先看状态 → 再备份 → 再修。**

## 核心命令

```bash
# 看状态
openclaw gateway status
openclaw status

# 备份当前配置
openclaw snapshot

# 重启 Gateway
openclaw gateway restart

# 配置损坏修复
openclaw doctor --fix

# 查看/编辑配置
cat ~/.openclaw/openclaw.json
nano ~/.openclaw/openclaw.json
```

## 常见场景

### Gateway 没起来
```bash
openclaw gateway status        # 确认状态
openclaw gateway start         # 启动
openclaw gateway restart       # 或直接重启
```

### Dashboard 打不开
先确认 Gateway 活着，再试 `http://localhost:18789`

### token mismatch
```bash
cat ~/.openclaw/openclaw.json | grep token   # 查看当前 token
openclaw gateway restart                      # 重启让 token 生效
```

### pairing required
```bash
openclaw status    # 查看是否有 pending pairing request
# 如有 pending，在终端或 Dashboard 批准
```

### config invalid
```bash
openclaw snapshot              # 先备份
openclaw doctor --fix          # 自动修复
openclaw gateway restart       # 重启生效
```

### LLM request timed out
通常是上游问题，不需要动本地。参考 WORKING_RULES.md 规则 3。

## 什么时候不该动
- 不确定问题原因时，先 `openclaw status` 看清楚
- 不要手动改 sessions.json
- 不要删 ~/.openclaw/ 下的文件（用 doctor 修）
