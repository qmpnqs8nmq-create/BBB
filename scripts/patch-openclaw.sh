#!/bin/bash
# Apply all upgrade-sensitive OpenClaw local patches and fail on drift.

set -euo pipefail

/usr/bin/python3 /root/.openclaw/workspace/scripts/patch-402-failover.py
/usr/bin/python3 /root/.openclaw/workspace/scripts/patch-weixin-cli-metadata.py
