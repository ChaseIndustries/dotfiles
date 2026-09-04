#!/bin/bash
# Create a new Herdr workspace with a two-pane layout:
#   top (~80%)    - a Claude Code agent
#   bottom (~20%) - a plain zsh shell
#
# Usage: new-dual-workspace.sh [cwd]
set -euo pipefail

HERDR_BIN=$(command -v herdr || true)
for candidate in "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr /usr/local/bin/herdr "$HOME/.cargo/bin/herdr"; do
  [ -z "$HERDR_BIN" ] && [ -x "$candidate" ] && HERDR_BIN="$candidate"
done
[ -z "$HERDR_BIN" ] && { echo "herdr not found" >&2; exit 1; }

JQ_BIN=$(command -v jq || true)
[ -z "$JQ_BIN" ] && { echo "jq not found" >&2; exit 1; }

# Resolve the cwd for the new workspace: explicit arg, else follow the
# calling pane (mirrors herdr's default new_cwd = "follow" behavior), else
# fall back to a sensible default.
CWD="${1:-}"
if [ -z "$CWD" ]; then
  CWD=$("$HERDR_BIN" pane current --current 2>/dev/null | "$JQ_BIN" -r '.result.pane.cwd // empty') || true
fi
CWD="${CWD:-${HERDR_PROJECT_ROOT:-$HOME/projects}}"

created=$("$HERDR_BIN" workspace create --focus --cwd "$CWD")
top_pane=$(echo "$created" | "$JQ_BIN" -r '.result.root_pane.pane_id')

"$HERDR_BIN" pane split "$top_pane" --direction down --ratio 0.8 --no-focus >/dev/null

agent_name="claude-$$"
"$HERDR_BIN" agent start "$agent_name" --kind claude --pane "$top_pane" >/dev/null 2>&1 || true
