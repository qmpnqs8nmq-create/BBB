# LLM request timed out：自动判断、保守执行

目标：
- 不把判断工作留给人
- 默认按最合理、最保守的方法自动执行
- 只有本地 OpenClaw 明显异常时才自动修
- 本地正常时不做重动作

---

## 默认用法

```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh
```

这是**自动判断模式**：
- 如果本地 OpenClaw 正常：
  - 不重启
  - 不 doctor
  - 结论会指向：更像网络慢 / 上游 LLM 慢 / 提供商抖动
- 如果本地 OpenClaw 异常：
  - 自动执行必要的本地修复
  - 可能包括 `openclaw doctor --fix` 和 `openclaw gateway restart`

---

## 可选模式

### 只检查，不修
```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh --check
```

### 强制走本地修复
```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh --repair
```

---

## 核心原则

1. Timeout 大多数是外部原因，不是 OpenClaw 本地坏了
2. 所以默认不乱重启
3. 只有在本地健康信号不正常时，才自动修
4. 修不了的，不伪装成已修好

---

## 最短记忆版

以后默认直接运行：

```bash
~/.openclaw/workspace/scripts/openclaw_fix_llm_timeout.sh
```

它会自己判断：
- 该不该动 OpenClaw
- 该不该重启
- 该不该 doctor
