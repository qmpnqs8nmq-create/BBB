#!/usr/bin/env python3
"""Make the installed Weixin plugin safe for OpenClaw CLI metadata scans.

OpenClaw 2026.8.2 intentionally withholds runtime services while collecting
CLI command metadata. Weixin 2.4.8 has no root CLI commands, but without a
dedicated cli-metadata entry the loader falls back to dist/index.js; its
register() compatibility check touches the unavailable runtime. Create a
no-op cli-metadata.js entry and retain the empty manifest declaration. The
patch is idempotent and searches generation directories because their hashed
names change on install.
"""

import glob
import json
import os
import shutil
import sys

PATTERN = (
    "/root/.openclaw/npm/projects/*/node_modules/"
    "@tencent-weixin/openclaw-weixin/openclaw.plugin.json"
)

CLI_METADATA = """export default {
  id: \"openclaw-weixin\",
  name: \"Weixin\",
  description: \"Weixin channel (getUpdates long-poll + sendMessage)\",
  register() {},
};
"""


def main() -> int:
    targets = sorted(glob.glob(PATTERN))
    if not targets:
        print("[patch-weixin-cli] ERROR: installed Weixin manifest not found")
        return 2

    changed = 0
    failed = 0
    for path in targets:
        try:
            with open(path, "r", encoding="utf-8") as handle:
                data = json.load(handle)
            if data.get("id") != "openclaw-weixin":
                print(f"[patch-weixin-cli] ERROR: unexpected plugin id in {path}")
                failed += 1
                continue
            commands = data.get("cliCommands")
            if commands not in (None, []):
                print(f"[patch-weixin-cli] ERROR: non-empty cliCommands in {path}; review required")
                failed += 1
                continue
            if commands is None:
                backup = path + ".orig-cli-metadata"
                if not os.path.exists(backup):
                    shutil.copy2(path, backup)
                data["cliCommands"] = []
                temp = path + ".tmp-cli-metadata"
                with open(temp, "w", encoding="utf-8") as handle:
                    json.dump(data, handle, ensure_ascii=False, indent=2)
                    handle.write("\n")
                os.chmod(temp, os.stat(path).st_mode & 0o777)
                os.replace(temp, path)
                changed += 1
                print(f"[patch-weixin-cli] patched manifest: {path}")

            metadata_path = os.path.join(os.path.dirname(path), "cli-metadata.js")
            if os.path.exists(metadata_path):
                with open(metadata_path, "r", encoding="utf-8") as handle:
                    current = handle.read()
                if current != CLI_METADATA:
                    print(
                        f"[patch-weixin-cli] ERROR: unexpected existing metadata entry: "
                        f"{metadata_path}"
                    )
                    failed += 1
                    continue
                print(f"[patch-weixin-cli] already patched: {metadata_path}")
            else:
                temp_metadata = metadata_path + ".tmp-cli-metadata"
                with open(temp_metadata, "w", encoding="utf-8") as handle:
                    handle.write(CLI_METADATA)
                os.chmod(temp_metadata, 0o644)
                os.replace(temp_metadata, metadata_path)
                changed += 1
                print(f"[patch-weixin-cli] created metadata entry: {metadata_path}")
        except Exception as exc:
            print(f"[patch-weixin-cli] ERROR: {path}: {exc}")
            failed += 1

    print(
        f"[patch-weixin-cli] done: {changed} changed, "
        f"{len(targets)} candidate(s), {failed} failure(s)"
    )
    return 0 if failed == 0 else 3


if __name__ == "__main__":
    sys.exit(main())
