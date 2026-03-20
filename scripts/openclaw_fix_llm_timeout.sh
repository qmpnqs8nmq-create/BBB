#!/bin/zsh
set -euo pipefail

MODE="auto"
case "${1:-}" in
  --check) MODE="check" ;;
  --repair) MODE="repair" ;;
  "") MODE="auto" ;;
  *) echo "Usage: $0 [--check|--repair]"; exit 1 ;;
esac

LOG_DIR="$HOME/.openclaw/workspace/logs"
mkdir -p "$LOG_DIR"
RUN_TS="$(date +%F-%H%M%S)"
RUN_LOG="$LOG_DIR/openclaw_fix_llm_timeout_$RUN_TS.log"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$RUN_LOG"
}

capture() {
  log "> $*"
  local out
  out="$($@ 2>&1 || true)"
  print -r -- "$out" >> "$RUN_LOG"
  print -r -- "$out"
}

log "Starting LLM timeout triage (mode=$MODE)"

HEALTH_JSON="$(capture openclaw health --json)"
GW_STATUS="$(capture openclaw gateway status)"

LOCAL_BAD=0
if [[ -z "$HEALTH_JSON" ]] || ! echo "$HEALTH_JSON" | grep -q '"ok"[[:space:]]*:[[:space:]]*true'; then
  LOCAL_BAD=1
  log "Health check is not clearly OK"
fi
if echo "$GW_STATUS" | grep -qiE 'Runtime:[[:space:]]+unknown|not loaded|unreachable|not running|state inactive'; then
  LOCAL_BAD=1
  log "Gateway status looks unhealthy"
fi

if [[ "$MODE" == "check" ]]; then
  echo
  echo "OpenClaw timeout triage: CHECK_ONLY"
  if [[ "$LOCAL_BAD" -eq 0 ]]; then
    echo "- Local OpenClaw looks healthy"
    echo "- Most likely cause: network slowness / upstream LLM slowness / provider jitter / transient UI state"
    echo "- Recommended action: wait 10-30s, refresh page, retry once"
    echo "- Do NOT restart Gateway by default"
  else
    echo "- Local OpenClaw may be unhealthy"
    echo "- Recommended action: run this script with default mode or --repair"
  fi
  echo "- Log: $RUN_LOG"
  exit 0
fi

STATUS_DEEP="$(capture openclaw status --deep)"
CONFIG_BAD=0
if echo "$STATUS_DEEP" | grep -qi 'Config invalid'; then
  CONFIG_BAD=1
  log "Config invalid detected"
fi

SHOULD_REPAIR=0
if [[ "$MODE" == "repair" ]]; then
  SHOULD_REPAIR=1
fi
if [[ "$MODE" == "auto" && ( "$LOCAL_BAD" -eq 1 || "$CONFIG_BAD" -eq 1 ) ]]; then
  SHOULD_REPAIR=1
fi

if [[ "$SHOULD_REPAIR" -eq 0 ]]; then
  echo
  echo "OpenClaw timeout triage: AUTO_NO_REPAIR"
  echo "- Local OpenClaw looks healthy"
  echo "- Most likely cause: network slowness / upstream LLM slowness / provider jitter / transient UI state"
  echo "- Best action: wait 10-30s, refresh page, retry once"
  echo "- No restart performed (intentionally conservative)"
  echo "- Log: $RUN_LOG"
  exit 0
fi

if [[ "$CONFIG_BAD" -eq 1 ]]; then
  log "Running openclaw doctor --fix"
  openclaw doctor --fix 2>&1 | tee -a "$RUN_LOG" || true
fi

log "Restarting gateway"
openclaw gateway restart 2>&1 | tee -a "$RUN_LOG" || true
sleep 3

POST_HEALTH="$(capture openclaw health --json)"
if echo "$POST_HEALTH" | grep -q '"ok"[[:space:]]*:[[:space:]]*true'; then
  echo
  echo "OpenClaw timeout triage: AUTO_REPAIRED"
  echo "- Local repair completed"
  echo "- Gateway health: OK"
  echo "- Next step: retry the same request once"
  echo "- Log: $RUN_LOG"
  exit 0
fi

echo
echo "OpenClaw timeout triage: UNRESOLVED"
echo "- Local repair path did not fully recover the system"
echo "- Upstream/network issues remain likely, or deeper local diagnosis is needed"
echo "- Log: $RUN_LOG"
exit 2
