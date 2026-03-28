#!/bin/bash
ssh bruce@192.168.0.152 '
echo "=== Plist valid? ==="
plutil -lint ~/Library/LaunchAgents/com.openclaw.tunnel.plist

echo ""
echo "=== LaunchAgent state ==="
launchctl print gui/$(id -u)/com.openclaw.tunnel 2>&1 | head -30'
