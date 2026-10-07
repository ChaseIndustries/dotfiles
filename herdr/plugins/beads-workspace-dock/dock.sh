#!/usr/bin/env bash
# workspace.created hook: dock herdr-beads in the new workspace's first tab.
# Borrows herdr-beads' own helpers so the dock lands exactly where its
# toggle would put it (left edge, narrowed, focus left alone).
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

HERDR="${HERDR_BIN_PATH:-$(command -v herdr || true)}"
[ -n "$HERDR" ] || exit 0

# herdr-beads lives under plugins/github/herdr-beads-<hash>/, and the hash
# changes on update. Find it from its config dir's parent rather than pinning it.
cfg="$("$HERDR" plugin config-dir herdr-beads 2>/dev/null)" || exit 0
lib="$(ls -d "$(dirname "$(dirname "$cfg")")"/*/herdr-beads*/scripts/lib.sh 2>/dev/null | head -n1)"
[ -n "$lib" ] || exit 0
# shellcheck source=/dev/null
. "$lib"

read -r WS TAB <<<"$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for src in (d.get("data") or {}, d):
    w = src.get("workspace") or {}
    if w.get("workspace_id"):
        print(w["workspace_id"], w.get("active_tab_id") or "")
        break
' 2>/dev/null)"
[ -n "${WS:-}" ] && [ -n "${TAB:-}" ] || exit 0

# Never a second dock, e.g. if herdr-beads' own auto-dock is also on.
mapfile -t _open < <(HERDR_TAB_ID="$TAB" beads_panes_by_title herdr-beads-dock tab)
[ "${#_open[@]}" -gt 0 ] && exit 0

read -r ROOT CWD <<<"$(first_pane_in_tab "$TAB")"
[ -n "${ROOT:-}" ] || exit 0

# Splitting and swapping drag focus into the new workspace even with
# --no-focus. A `worktree create --no-focus` should stay unfocused, so put the
# user back wherever they were.
WAS="$("$HERDR" workspace list 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for w in (d.get("result") or {}).get("workspaces") or []:
    if w.get("focused") and w.get("workspace_id"):
        print(w["workspace_id"])
        break
' 2>/dev/null)"

open_dock_at "$ROOT" "${CWD:-}" nofocus

if [ -n "$WAS" ] && [ "$WAS" != "$WS" ]; then
  "$HERDR" workspace focus "$WAS" >/dev/null 2>&1
fi
