#!/bin/bash
# patch-openclaw.sh — Auto-apply monkey-patches after OpenClaw upgrade
# Patches: (1) MRU sticky auth sort  (2) Extended 402 regex
# Run after: npm update -g openclaw
# Rollback: restore from patch-backup/ or npm install -g openclaw@<version>

set -e

# Auto-detect: macOS homebrew vs Linux global npm
if [ -d "/opt/homebrew/lib/node_modules/openclaw/dist" ]; then
  DIST="/opt/homebrew/lib/node_modules/openclaw/dist"
elif [ -d "/usr/lib/node_modules/openclaw/dist" ]; then
  DIST="/usr/lib/node_modules/openclaw/dist"
else
  echo "❌ Cannot find openclaw dist directory"
  exit 1
fi

# sed -i portability: macOS needs '', Linux does not
if [[ "$OSTYPE" == darwin* ]]; then
  SED_I=("${SED_I[@]}")
else
  SED_I=(sed -i)
fi

BACKUP="$HOME/.openclaw/workspace/patch-backup"
mkdir -p "$BACKUP"

# Find current files (hash in filename changes each version)
AUTH=$(ls "$DIST"/auth-profiles-*.js 2>/dev/null | head -1)
# 402 regex moved from pi-embedded to reply-payloads-dedupe in 2026.3.28+
DEDUPE=$(ls "$DIST"/reply-payloads-dedupe-*.js 2>/dev/null | head -1)
# Fallback to pi-embedded for older versions
if [ -z "$DEDUPE" ]; then
  DEDUPE=$(ls "$DIST"/pi-embedded-*.js 2>/dev/null | head -1)
fi

if [ -z "$AUTH" ]; then
  echo "❌ Cannot find auth-profiles in $DIST"
  exit 1
fi

echo "=== Files ==="
echo "auth-profiles: $(basename $AUTH)"
[ -n "$DEDUPE" ] && echo "402-regex file: $(basename $DEDUPE)" || echo "402-regex file: (not found)"

# Backup
cp "$AUTH" "$BACKUP/$(basename $AUTH).bak.$(date +%Y%m%d%H%M%S)"
[ -n "$DEDUPE" ] && cp "$DEDUPE" "$BACKUP/$(basename $DEDUPE).bak.$(date +%Y%m%d%H%M%S)"
echo "✅ Backed up to $BACKUP/"

# --- Patch 1: MRU sticky sort (auth-profiles) ---
if grep -q "return a\.lastUsed - b\.lastUsed" "$AUTH"; then
  "${SED_I[@]}" 's/return a\.lastUsed - b\.lastUsed/return b.lastUsed - a.lastUsed/' "$AUTH"
  echo "✅ Patch 1 applied: MRU sticky sort"
elif grep -q "return b\.lastUsed - a\.lastUsed" "$AUTH"; then
  echo "⏭️  Patch 1 already applied: MRU sticky sort"
else
  echo "⚠️  Patch 1: cannot find lastUsed sort line — manual check needed"
  grep -n "lastUsed" "$AUTH" | head -5
fi

# --- Patch 2: Extended 402 regex ---
if [ -z "$DEDUPE" ]; then
  echo "⚠️  Patch 2: No 402 regex file found — skipping"
else
  if grep -qF '402\s*[\{\[]' "$DEDUPE"; then
    echo "⏭️  Patch 2 already applied: Extended 402 regex"
  elif grep -q "RAW_402_MARKER_RE" "$DEDUPE"; then
    # Append our pattern before the closing /i;
    "${SED_I[@]}" 's#used up your points\\b/i;#used up your points\\b|^\\s*402\\s*[\\{\\[]/i;#' "$DEDUPE"
    if grep -qF '402\s*[\{\[]' "$DEDUPE"; then
      echo "✅ Patch 2 applied: Extended 402 regex"
    else
      echo "⚠️  Patch 2: auto-apply failed — apply manually"
      grep -n "RAW_402_MARKER_RE" "$DEDUPE" | head -1
    fi
  else
    echo "⚠️  Patch 2: RAW_402_MARKER_RE not found in $(basename $DEDUPE) — manual check needed"
  fi
fi

echo ""
echo "=== Verification ==="
echo "--- Patch 1 (should show b.lastUsed - a.lastUsed): ---"
grep -n "lastUsed - [ab]\.lastUsed" "$AUTH" || echo "(not found)"
echo "--- Patch 2 (should contain 402\\s*[{[]): ---"
[ -n "$DEDUPE" ] && (grep -n "RAW_402_MARKER_RE" "$DEDUPE" | head -1 | cut -c1-140) || echo "(skipped)"

echo ""
echo "=== Done ==="
echo "Next: openclaw gateway restart"
