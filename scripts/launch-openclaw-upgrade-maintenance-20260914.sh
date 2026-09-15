#!/usr/bin/env bash
set -uo pipefail

ONCE=/root/.openclaw/workspace/memory/tasks/.openclaw-upgrade-20260914-launched

if mkdir "$ONCE" 2>/dev/null; then
  systemd-run --user --unit=openclaw-upgrade-complete-20260914 --collect /usr/bin/bash /root/.openclaw/workspace/scripts/complete-openclaw-upgrade-20260914.sh
fi
