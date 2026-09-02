#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Herdr Workspace
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Herdr

HERDR_BIN=$(command -v herdr)
for candidate in "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr /usr/local/bin/herdr "$HOME/.cargo/bin/herdr"; do
  [ -z "$HERDR_BIN" ] && [ -x "$candidate" ] && HERDR_BIN="$candidate"
done
[ -z "$HERDR_BIN" ] && { echo "herdr not found" >&2; exit 1; }

"$HERDR_BIN" workspace create --focus --cwd "${HERDR_PROJECT_ROOT:-$HOME/projects}"
osascript -e 'tell application "System Events" to set frontmost of (first process whose name contains "herdr") to true' 2>/dev/null || true
