#!/usr/bin/env python3
"""
Idempotent re-patch for OpenClaw 402-failover bug.

Background (2026-06-12, Bruce / Kaopuge):
  ZenMux returns errors with a STRING-quoted status code, e.g. {"code":"402"}.
  OpenClaw's RAW_402_MARKER_RE only matches an UNQUOTED value (402), so the
  whole failover path is blind to these errors and sub-agents die on the
  exhausted key (0 token, no retry). We widen the regex value to tolerate an
  optional quote:  [:=]\\s*402\\b  ->  [:=]\\s*["']?402\\b

Why this script exists:
  The fix lives inside node_modules (dist/errors-<hash>.js). The hash changes
  per release and any OpenClaw upgrade overwrites it. This script is run as an
  ExecStartPre hook by the gateway systemd unit (via a drop-in), so the patch
  is re-applied automatically on every (re)start, including right after an
  upgrade. It is idempotent and safe to run repeatedly.

Decision: do NOT submit upstream issue (Bruce, 2026-06-12). Self-heal locally.
"""
import glob
import os
import re
import sys

DIST_DIR = "/usr/lib/node_modules/openclaw/dist"
MARKER = "RAW_402_MARKER_RE"

# Unpatched substring (value not quote-tolerant) and its patched form.
# Matching on the raw file text, not a compiled regex.
NEEDLE = "[:=]\\s*402\\b"
FIXED = "[:=]\\s*[\"']?402\\b"


def main() -> int:
    files = glob.glob(os.path.join(DIST_DIR, "errors-*.js"))
    targets = []
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as fh:
                txt = fh.read()
        except Exception:
            continue
        if MARKER in txt:
            targets.append((f, txt))

    if not targets:
        print(f"[patch-402] no file containing {MARKER} found in {DIST_DIR}; nothing to do")
        # Not fatal: gateway must still start.
        return 0

    changed = 0
    for f, txt in targets:
        if FIXED in txt:
            print(f"[patch-402] already patched: {os.path.basename(f)}")
            continue
        if NEEDLE not in txt:
            print(f"[patch-402] WARN: marker present but expected needle not found in {os.path.basename(f)}; "
                  f"regex shape may have changed upstream — skipping (review manually)")
            continue
        # Backup once (never overwrite an existing .orig backup).
        bak = f + ".orig-402patch"
        if not os.path.exists(bak):
            try:
                with open(bak, "w", encoding="utf-8") as bh:
                    bh.write(txt)
            except Exception as e:
                print(f"[patch-402] WARN: could not write backup {bak}: {e}")
        new = txt.replace(NEEDLE, FIXED, 1)
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(new)
        changed += 1
        print(f"[patch-402] patched {os.path.basename(f)} (backup: {os.path.basename(bak)})")

    print(f"[patch-402] done: {changed} file(s) patched, {len(targets)} candidate(s) total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
