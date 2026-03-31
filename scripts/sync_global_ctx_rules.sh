#!/bin/zsh
set -euo pipefail

CONFIG="$HOME/.openclaw/openclaw.json"
MAIN_WS="$HOME/.openclaw/workspace"
SOURCE_CTX="$MAIN_WS/CTX-CONTROL-RULES.md"

if [[ ! -f "$CONFIG" ]]; then
  echo "missing config: $CONFIG" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_CTX" ]]; then
  echo "missing source ctx rules: $SOURCE_CTX" >&2
  exit 1
fi

/usr/bin/python3 - <<'PY'
import json
from pathlib import Path

home = Path.home() / '.openclaw'
config = json.loads((home / 'openclaw.json').read_text())
main_ws = home / 'workspace'
section = '''\n\n## Global Context Governance\n\nAll sessions in this workspace must follow the single source of truth at `/root/.openclaw/workspace/CTX-CONTROL-RULES.md`.\n\n### Session Startup addition\nAfter reading the standard startup files, read `/root/.openclaw/workspace/CTX-CONTROL-RULES.md` if it exists, and apply it as a mandatory global rule.\n\n### Scope\nThis rule is global across all Bruce workspaces and sessions, not chief-only. Do not maintain separate divergent copies in this workspace.\n'''

seen = set()
for agent in config.get('agents', {}).get('list', []):
    ws = agent.get('workspace')
    if not ws or ws in seen:
        continue
    seen.add(ws)
    p = Path(ws)
    if not p.exists():
        continue
    agents = p / 'AGENTS.md'
    if agents.exists():
        text = agents.read_text()
        marker = '## Global Context Governance'
        if marker in text:
            text = text.split(marker)[0].rstrip()
        agents.write_text(text.rstrip() + section + '\n')
    ctx = p / 'CTX-CONTROL-RULES.md'
    if p != main_ws and ctx.exists():
        ctx.unlink()
    print(f'normalized {ws}')
PY
