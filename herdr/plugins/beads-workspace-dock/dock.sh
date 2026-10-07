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
# user back wherever they were. Agents often create several worktrees at once,
# and each hook then sees a sibling's fresh workspace as "focused". So hooks
# take turns under a lock, remember which workspaces are brand new, and never
# treat one of those as home.
STATE="${TMPDIR:-/tmp}/beads-workspace-dock"
mkdir -p "$STATE"
for _ in $(seq 100); do
  mkdir "$STATE/lock" 2>/dev/null && break
  # A crashed hook can leave the lock behind. Steal it once it's stale.
  [ -n "$(find "$STATE/lock" -maxdepth 0 -mmin +1 2>/dev/null)" ] && rmdir "$STATE/lock"
  sleep 0.1
done
trap 'rmdir "$STATE/lock" 2>/dev/null' EXIT

now="$(date +%s)"
touch "$STATE/fresh"
awk -v now="$now" '$1 > now - 60' "$STATE/fresh" >"$STATE/fresh.tmp"
echo "$now $WS" >>"$STATE/fresh.tmp"
mv "$STATE/fresh.tmp" "$STATE/fresh"

focused() {
  "$HERDR" workspace list 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for w in (d.get("result") or {}).get("workspaces") or []:
    if w.get("focused") and w.get("workspace_id"):
        print(w["workspace_id"])
        break
' 2>/dev/null
}
is_fresh() { awk -v id="$1" '$2 == id { f = 1 } END { exit !f }' "$STATE/fresh"; }

WAS="$(focused)"
if [ -n "$WAS" ] && ! is_fresh "$WAS"; then
  echo "$WAS" >"$STATE/home"
else
  WAS="$(cat "$STATE/home" 2>/dev/null)"
fi

open_dock_at "$ROOT" "${CWD:-}" nofocus

# Other plugins (herdr-plus layouts) can yank focus a beat later, so check twice.
if [ -n "$WAS" ]; then
  for _ in 1 2; do
    cur="$(focused)"
    [ -n "$cur" ] && [ "$cur" != "$WAS" ] && is_fresh "$cur" &&
      "$HERDR" workspace focus "$WAS" >/dev/null 2>&1
    sleep 0.3
  done
fi
