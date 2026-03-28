#!/bin/bash
# 检查 152 上是否有 autossh，没有则安装；然后用 autossh 替代 ssh
ssh bruce@192.168.0.152 '
# 检查 autossh
which autossh 2>/dev/null && echo "✅ autossh found" || {
  echo "Installing autossh..."
  which brew >/dev/null 2>&1 && brew install autossh || echo "NO_BREW"
}
which autossh 2>/dev/null && echo "PATH: $(which autossh)"'
