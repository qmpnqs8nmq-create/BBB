#!/bin/zsh
set -euo pipefail

PENDING_JSON="$HOME/.openclaw/devices/pending.json"
PAIRED_JSON="$HOME/.openclaw/devices/paired.json"
RUN_LOG="$HOME/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.log"
STATE_JSON="$HOME/.openclaw/workspace/logs/watch_8888_pairing_autoapprove.state.json"
mkdir -p "$(dirname "$RUN_LOG")"

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$RUN_LOG"
}

json_count() {
  local path="$1"
  JSON_COUNT_PATH="$path" /usr/bin/python3 - <<'PY'
import json, pathlib, os
p = pathlib.Path(os.environ['JSON_COUNT_PATH'])
if not p.exists():
    print(0)
else:
    try:
        data = json.loads(p.read_text())
        print(len(data) if isinstance(data, dict) else 0)
    except Exception:
        print(-1)
PY
}

paired_fingerprint() {
  /usr/bin/python3 - <<'PY'
import json, hashlib, pathlib
p = pathlib.Path(pathlib.Path.home() / '.openclaw/devices/paired.json')
if not p.exists():
    print('missing')
else:
    raw = p.read_text()
    print(hashlib.sha1(raw.encode()).hexdigest())
PY
}

repair_browser_scopes() {
  /usr/bin/python3 - <<'PY' >> "$RUN_LOG" 2>&1
import json
from pathlib import Path
p = Path.home() / '.openclaw/devices/paired.json'
if not p.exists():
    print('paired.json missing')
    raise SystemExit(0)
try:
    data = json.loads(p.read_text())
except Exception as e:
    print('failed to read paired.json', e)
    raise SystemExit(0)
TARGET_CLIENT_ID = 'openclaw-control-ui'
TARGET_MODE = 'webchat'
FULL = [
  'operator.admin',
  'operator.read',
  'operator.write',
  'operator.approvals',
  'operator.pairing',
]
changed = []
for device_id, dev in data.items():
    if dev.get('clientId') != TARGET_CLIENT_ID or dev.get('clientMode') != TARGET_MODE:
        continue
    merged = []
    seen = set()
    for s in (dev.get('approvedScopes') or dev.get('scopes') or []) + FULL:
        if s and s not in seen:
            seen.add(s)
            merged.append(s)
    token_changed = False
    if dev.get('approvedScopes') != merged or dev.get('scopes') != merged:
        dev['approvedScopes'] = merged
        dev['scopes'] = merged
        token_changed = True
    tokens = dev.get('tokens') or {}
    token = tokens.get('operator')
    if isinstance(token, dict):
        merged_token = []
        seen2 = set()
        for s in (token.get('scopes') or []) + FULL:
            if s and s not in seen2:
                seen2.add(s)
                merged_token.append(s)
        if token.get('scopes') != merged_token:
            token['scopes'] = merged_token
            tokens['operator'] = token
            token_changed = True
    dev['tokens'] = tokens
    data[device_id] = dev
    if token_changed:
        changed.append(device_id)
if changed:
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print('scope repair changed', len(changed), 'devices')
    for x in changed:
        print('  ', x)
else:
    print('scope repair no changes')
PY
}

record_state() {
  local pending_count="$1"
  local paired_count="$2"
  local fingerprint="$3"
  cat > "$STATE_JSON" <<EOF
{"pending_count": $pending_count, "paired_count": $paired_count, "paired_fingerprint": "$fingerprint", "updated_at": "$(date '+%F %T')"}
EOF
}

approve_and_verify() {
  local before_pending before_paired before_fp after_pending after_paired after_fp
  before_pending="$(json_count "$PENDING_JSON")"
  before_paired="$(json_count "$PAIRED_JSON")"
  before_fp="$(paired_fingerprint)"
  log "approve_and_verify start pending=$before_pending paired=$before_paired fp=$before_fp"

  if [[ "$before_pending" -le 0 ]]; then
    return 0
  fi

  if /opt/homebrew/bin/openclaw devices approve --latest >> "$RUN_LOG" 2>&1; then
    log "approve --latest command succeeded"
  else
    log "approve --latest command failed"
  fi

  sleep 1
  repair_browser_scopes

  after_pending="$(json_count "$PENDING_JSON")"
  after_paired="$(json_count "$PAIRED_JSON")"
  after_fp="$(paired_fingerprint)"
  log "approve_and_verify end pending=$after_pending paired=$after_paired fp=$after_fp"

  if [[ "$after_pending" -lt "$before_pending" || "$after_paired" -gt "$before_paired" || "$after_fp" != "$before_fp" ]]; then
    log "verification: state changed as expected"
  else
    log "verification: no state change detected after approve attempt"
  fi

  record_state "$after_pending" "$after_paired" "$after_fp"
}

main_loop() {
  log "watcher start"
  repair_browser_scopes
  local last_pending=-999 last_fp=''
  while true; do
    local pcount paired_count fp
    pcount="$(json_count "$PENDING_JSON")"
    paired_count="$(json_count "$PAIRED_JSON")"
    fp="$(paired_fingerprint)"

    if [[ "$pcount" != "$last_pending" || "$fp" != "$last_fp" ]]; then
      log "state observed pending=$pcount paired=$paired_count fp=$fp"
      record_state "$pcount" "$paired_count" "$fp"
      last_pending="$pcount"
      last_fp="$fp"
    fi

    if [[ "$pcount" -gt 0 ]]; then
      log "pending detected directly from pending.json"
      approve_and_verify
      last_pending="$(json_count "$PENDING_JSON")"
      last_fp="$(paired_fingerprint)"
    else
      repair_browser_scopes
    fi

    sleep 1
  done
}

main_loop
