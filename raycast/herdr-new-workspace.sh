#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Herdr Workspace
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Herdr

SCRIPT_BIN=$(command -v herdr-new-dual-workspace)
for candidate in "$HOME/.local/bin/herdr-new-dual-workspace"; do
  [ -z "$SCRIPT_BIN" ] && [ -x "$candidate" ] && SCRIPT_BIN="$candidate"
done
[ -z "$SCRIPT_BIN" ] && { echo "herdr-new-dual-workspace not found" >&2; exit 1; }

"$SCRIPT_BIN" "${HERDR_PROJECT_ROOT:-$HOME/projects}"
osascript -e 'tell application "System Events" to set frontmost of (first process whose name contains "herdr") to true' 2>/dev/null || true
