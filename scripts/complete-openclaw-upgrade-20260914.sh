#!/usr/bin/env bash
set -uo pipefail

LOG=/root/.openclaw/workspace/memory/tasks/openclaw-upgrade-2026-09-14-maintenance.log
STATUS=0

exec >>"$LOG" 2>&1

date
echo "Starting isolated OpenClaw 2026.9.4 maintenance completion"

systemctl --user stop openclaw-gateway.service || STATUS=$?

/usr/bin/openclaw update repair --channel stable --no-restart --yes --accept-capabilities --json --timeout 1800 || STATUS=$?

/usr/bin/openclaw plugins update @openclaw/codex@2026.9.4 --accept-capabilities || STATUS=$?
/usr/bin/openclaw plugins update @openclaw/feishu@2026.9.4 --accept-capabilities || STATUS=$?
/usr/bin/openclaw plugins update @openclaw/perplexity-plugin@2026.9.4 --accept-capabilities || STATUS=$?

/usr/bin/python3 /root/.openclaw/workspace/scripts/patch-402-failover.py || STATUS=$?
/usr/bin/python3 /root/.openclaw/workspace/scripts/patch-weixin-cli-metadata.py || STATUS=$?

/usr/bin/openclaw plugins registry --refresh || STATUS=$?
/usr/bin/openclaw config validate || STATUS=$?
/usr/bin/openclaw doctor --post-upgrade --json || STATUS=$?

systemctl --user start openclaw-gateway.service
START_STATUS=$?
if [ "$START_STATUS" -ne 0 ]; then
  STATUS="$START_STATUS"
fi

date
echo "Maintenance completion exit status: $STATUS"
exit "$STATUS"
