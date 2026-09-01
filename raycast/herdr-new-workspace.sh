#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Herdr Workspace
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Herdr

/Users/jordan.chase/.local/bin/herdr workspace create --focus --cwd "${HERDR_PROJECT_ROOT:-$HOME/projects}"
osascript -e 'tell application "System Events" to set frontmost of (first process whose name contains "herdr") to true' 2>/dev/null || true
