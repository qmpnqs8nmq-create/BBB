#!/bin/bash
# patch-openclaw.sh — Auto-apply monkey-patches after OpenClaw upgrade
# Patches: (1) MRU sticky auth sort  (2) Extended 402 regex
# Run after: npm update -g openclaw
# Rollback: restore from patch-backup/ or npm install -g openclaw@<version>

set -e

DIST="/opt/homebrew/lib/node_modules/openclaw/dist"
BACKUP="$HOME/.openclaw/workspace/patch-backup"
mkdir -p "$BACKUP"

# Find current files (hash in filename changes each version)
AUTH=$(ls "$DIST"/auth-profiles-*.js 2>/dev/null | head -1)
PI=$(ls "$DIST"/pi-embedded-*.js 2>/dev/null | head -1)

if [ -z "$AUTH" ] || [ -z "$PI" ]; then
  echo "❌ Cannot find auth-profiles or pi-embedded in $DIST"
  exit 1
fi

echo "=== Files ==="
echo "auth-profiles: $(basename $AUTH)"
echo "pi-embedded:   $(basename $PI)"

# Backup
cp "$AUTH" "$BACKUP/$(basename $AUTH).bak.$(date +%Y%m%d%H%M%S)"
cp "$PI" "$BACKUP/$(basename $PI).bak.$(date +%Y%m%d%H%M%S)"
echo "✅ Backed up to $BACKUP/"

# --- Patch 1: MRU sticky sort (auth-profiles) ---
# Change: a.lastUsed - b.lastUsed → b.lastUsed - a.lastUsed
# This makes /new prefer the most recently successful key

if grep -q "return a\.lastUsed - b\.lastUsed" "$AUTH"; then
  sed -i '' 's/return a\.lastUsed - b\.lastUsed/return b.lastUsed - a.lastUsed/' "$AUTH"
  echo "✅ Patch 1 applied: MRU sticky sort"
elif grep -q "return b\.lastUsed - a\.lastUsed" "$AUTH"; then
  echo "⏭️  Patch 1 already applied: MRU sticky sort"
else
  echo "⚠️  Patch 1: cannot find lastUsed sort line — manual check needed"
  echo "   File: $AUTH"
  grep -n "lastUsed" "$AUTH" | head -5
fi

# --- Patch 2: Extended 402 regex (pi-embedded) ---
# Add pattern to catch bare "402 {..." responses: ^\s*402\s*[\{\[]
# Detection: check if the RAW_402_MARKER_RE line contains "402\s*[" (our addition)

LINENUM=$(grep -n "^const RAW_402_MARKER_RE" "$PI" | head -1 | cut -d: -f1)

if [ -z "$LINENUM" ]; then
  echo "⚠️  Patch 2: RAW_402_MARKER_RE not found — manual check needed"
elif sed -n "${LINENUM}p" "$PI" | grep -qF '402\s*[\{\[]/i;'; then
  echo "⏭️  Patch 2 already applied: Extended 402 regex"
elif sed -n "${LINENUM}p" "$PI" | grep -qF 'used up your points'; then
  # Append our pattern before the closing /i;
  sed -i '' "${LINENUM}s|/i;|\\\\|^\\\\s*402\\\\s*[\\\\{\\\\[]/i;|" "$PI"
  # Verify
  if sed -n "${LINENUM}p" "$PI" | grep -qF '402\s*[\{\[]/i;'; then
    echo "✅ Patch 2 applied: Extended 402 regex"
  else
    echo "⚠️  Patch 2: sed may have failed — check line $LINENUM manually"
  fi
else
  echo "⚠️  Patch 2: RAW_402_MARKER_RE pattern differs from expected — manual check needed"
  echo "   Line $LINENUM:"
  sed -n "${LINENUM}p" "$PI" | tail -c 120
fi

echo ""
echo "=== Verification ==="
echo "--- Patch 1 (should show b.lastUsed - a.lastUsed): ---"
grep -n "lastUsed - [ab]\.lastUsed" "$AUTH" || echo "(not found)"
echo "--- Patch 2 (should contain 402\\s*[{[]): ---"
grep -n "RAW_402_MARKER_RE" "$PI" | head -1 | cut -c1-120
echo "..."

echo ""
echo "=== Done ==="
echo "Next: openclaw gateway restart"
