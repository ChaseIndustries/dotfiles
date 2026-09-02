# --- Functions ---

# Resolve a tool's absolute path once at shell startup instead of hardcoding
# an install location, so this works across homebrew (arm/intel), cargo,
# ~/.local/bin, or wherever else it happens to live on a given machine.
function _dotfiles_resolve_bin() {
  local name="$1"; shift
  # whence -p forces a PATH-only lookup, unlike `command -v`, which in zsh
  # also reports shell functions/aliases of the same name — a real problem
  # once a wrapper function shadows the binary it needs to call (e.g. herdr()
  # below), since re-sourcing this file would then resolve to itself.
  local resolved
  resolved="$(whence -p "$name" 2>/dev/null)"
  if [[ -n "$resolved" ]]; then
    echo "$resolved"
    return
  fi
  local candidate
  for candidate in "$@"; do
    [[ -x "$candidate" ]] && { echo "$candidate"; return; }
  done
}

HERDR_BIN="$(_dotfiles_resolve_bin herdr "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr /usr/local/bin/herdr "$HOME/.cargo/bin/herdr")"
CODE_BIN="$(_dotfiles_resolve_bin code /usr/local/bin/code /opt/homebrew/bin/code "$HOME/.local/bin/code" /Applications/Cursor.app/Contents/Resources/app/bin/code)"

# Bare `herdr` (no args, i.e. launching/attaching the session) auto-opens the
# herdr-deck picker shortly after so it's the landing point instead of a
# blank pane. `herdr <subcommand>` (workspace create, plugin install, etc.)
# passes straight through untouched. `~/.zshenv` sources this unconditionally
# (login or not, interactive or not), so this also intercepts the Cursor
# "herdr" terminal profile's `exec herdr` — zsh resolves shell functions
# before falling back to the PATH binary, even under `exec`.
function herdr() {
  if [[ $# -eq 0 ]]; then
    (sleep 0.6; "$HERDR_BIN" plugin action invoke open --plugin herdr-deck >/dev/null 2>&1) &!
  fi
  "$HERDR_BIN" "$@"
}

# Run `code <path>` only when inside Cursor's wrapped terminal
# (GIT_WRAPPER_CONTEXT set). Outside that context, do nothing so running these
# aliases from a native terminal doesn't spawn an editor unexpectedly.
function _code_if_wrapped() {
  local path="$1"
  if [[ -f "$path" ]]; then
    PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" "$path"
  elif [[ -n "$GIT_WRAPPER_CONTEXT" && -n "$CODE_BIN" ]]; then
    PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" "$path"
  else
    cd "$path"
  fi
}

# Navigate to a path: open in Cursor when inside its terminal, otherwise cd.
# Uses an absolute path + explicit PATH so a restricted direnv/nix shell PATH
# doesn't break the `code` launcher's `#!/usr/bin/env bash` shebang.
function _worktree_navigate() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Not a directory: $path" >&2
    return 1
  fi
  # Claude Code: cd, open in Cursor, and sync herdr — all three.
  # Must come before HERDR_ENV check because HERDR_ENV=1 is inherited from Cursor.
  if [[ "$GIT_WRAPPER_CONTEXT" == "claude" ]]; then
    echo "Changing directory to $path..."
    cd "$path"
    if [[ -n "$CODE_BIN" ]]; then
      /usr/bin/env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
        PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" "$path" &!
    fi
    if [[ -S "$HOME/.config/herdr/herdr.sock" ]]; then
      "$HERDR_BIN" worktree open --path "$path" --focus 2>/dev/null &!
    fi
    return 0
  fi
  if [[ -n "$HERDR_ENV" ]]; then
    local label="${path:t}"
    local existing_workspace
    # Use worktree list (authoritative open_workspace_id) instead of pane CWD scan,
    # which was unreliable and caused duplicate workspace creation.
    existing_workspace=$("$HERDR_BIN" worktree list 2>/dev/null \
      | python3 -c "
import json, sys
data = json.load(sys.stdin)
target = sys.argv[1]
for wt in data.get('result', {}).get('worktrees', []):
    if wt.get('path') == target:
        ws = wt.get('open_workspace_id', '')
        if ws:
            print(ws)
        break
" "$path" 2>/dev/null)
    if [[ -n "$existing_workspace" ]]; then
      echo "Focusing existing herdr workspace $existing_workspace for $path..."
      "$HERDR_BIN" workspace focus "$existing_workspace"
    else
      echo "Opening $path in new herdr workspace + Cursor..."
      "$HERDR_BIN" workspace create --cwd "$path" --label "$label" --focus
      /usr/bin/env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
        PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" --new-window "$path"
    fi
  elif [[ -n "$CODE_BIN" ]]; then
    echo "Opening $path in Cursor..."
    PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" "$path"
    # Keep herdr command center in sync when navigating from Cursor terminal.
    if [[ -S "$HOME/.config/herdr/herdr.sock" ]]; then
      "$HERDR_BIN" worktree open --path "$path" --no-focus 2>/dev/null &!
    fi
  else
    echo "Changing directory to $path..."
    cd "$path"
  fi
}

# Run a checkout-style command (`git checkout <branch>` or `gh pr checkout <N>`) from
# the main repo root when invoked inside a worktree. If the target branch is already
# used by another worktree, navigate there instead of erroring out.
#
# Usage: _worktree_checkout <description> <cmd> [args...]
function _worktree_checkout() {
  local description="$1"
  shift

  local main_git main_root toplevel
  main_git=$(command git rev-parse --git-common-dir 2>/dev/null)
  if [[ -z "$main_git" ]]; then
    command "$@"
    return $?
  fi
  # --git-common-dir can be relative (e.g. ".git") when run from the repo root;
  # resolve to an absolute path so comparisons with --show-toplevel work.
  main_root=$(cd "$(dirname "$main_git")" && pwd)
  toplevel=$(command git rev-parse --show-toplevel 2>/dev/null)

  local in_main_repo=false
  if [[ "$toplevel" == "$main_root" ]]; then
    in_main_repo=true
  fi

  if [[ "$in_main_repo" == false ]]; then
    # Pre-flight check for `git checkout <branch>`: if the branch doesn't exist
    # locally or on any remote, fail fast in the current directory instead of
    # detouring through the main workspace.
    if [[ "$1" == "git" && "$2" == "checkout" && -n "$3" ]]; then
      local branch="$3"
      if ! command git -C "$main_root" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null \
        && ! command git -C "$main_root" rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null \
        && ! command git -C "$main_root" show-ref --verify --quiet "refs/tags/$branch"; then
        command git checkout "$branch"
        return $?
      fi
    fi

    # If the target branch is already checked out in another worktree, jump there
    # directly instead of detouring through the main workspace.
    if [[ "$1" == "git" && "$2" == "checkout" && -n "$3" ]]; then
      local existing_worktree
      existing_worktree=$(command git -C "$main_root" worktree list --porcelain 2>/dev/null \
        | command awk -v want="refs/heads/$3" 'BEGIN{wt=""} /^worktree / {wt=$2} /^branch / {if ($2==want) {print wt; exit}}')
      if [[ -n "$existing_worktree" && -d "$existing_worktree" ]]; then
        _worktree_navigate "$existing_worktree"
        return 0
      fi
    fi

    echo "Running '$description' in main workspace at $main_root..."
  fi

  local tmpfile exit_code
  tmpfile=$(mktemp -t worktree_checkout.XXXXXX)
  # Stream output live to the user while also capturing it for pattern matching.
  (cd "$main_root" && command "$@" 2>&1) | tee "$tmpfile"
  exit_code=${pipestatus[1]}
  local output
  output=$(<"$tmpfile")
  rm -f "$tmpfile"

  # Branch already used by another worktree — navigate there instead.
  if [[ $exit_code -ne 0 && "$output" =~ "is already used by worktree at" ]]; then
    local worktree_path
    worktree_path=$(echo "$output" | grep -o "is already used by worktree at .*" | sed "s/is already used by worktree at //" | tr -d "'")
    if [[ -n "$worktree_path" ]]; then
      if [[ -d "$worktree_path" ]]; then
        _worktree_navigate "$worktree_path"
        return 0
      fi
      echo "Worktree path $worktree_path is missing from disk — pruning stale entry and retrying..." >&2
      (cd "$main_root" && command git worktree prune -v)
      echo "Retrying '$description'..." >&2
      tmpfile=$(mktemp -t worktree_checkout.XXXXXX)
      (cd "$main_root" && command "$@" 2>&1) | tee "$tmpfile"
      exit_code=${pipestatus[1]}
      output=$(<"$tmpfile")
      rm -f "$tmpfile"
    fi
  fi

  if [[ $exit_code -eq 0 && "$in_main_repo" == false ]]; then
    _worktree_navigate "$main_root"
  fi
  return $exit_code
}

function git() {
  if [[ "$1" == "worktree" && "$2" == "add" ]]; then
    # When inside herdr, redirect relative worktree paths to herdr's shared directory.
    # Absolute paths (e.g. already pointing at .herdr-worktrees) pass through unchanged.
    if [[ -n "$HERDR_ENV" && -n "$3" && "$3" != /* && "$3" != ~* ]]; then
      local herdr_dir="$HOME/Repos/.herdr-worktrees"
      local repo_name wt_name new_path
      repo_name=$(basename "$(command git rev-parse --show-toplevel 2>/dev/null)")
      wt_name="${3:t}"  # basename of the requested path
      new_path="$herdr_dir/${repo_name}-${wt_name}"
      echo "herdr: redirecting worktree to $new_path"
      command git worktree add "$new_path" "${@:4}"
      local exit_code=$?
      [[ $exit_code -eq 0 ]] && _worktree_navigate "$new_path"
      return $exit_code
    fi
    command git "$@"
    return $?
  fi

  if [[ "$1" == "checkout" && $# -eq 2 ]]; then
    # For `main`/`master`, never switch another worktree's branch — navigate to the
    # main workspace instead. If we're already in the main workspace, fall through
    # to a normal checkout.
    if [[ "$2" == "main" || "$2" == "master" ]]; then
      local main_git main_root toplevel
      main_git=$(command git rev-parse --git-common-dir 2>/dev/null)
      if [[ -n "$main_git" ]]; then
        main_root=$(cd "$(dirname "$main_git")" && pwd)
        toplevel=$(command git rev-parse --show-toplevel 2>/dev/null)
        if [[ "$toplevel" != "$main_root" ]]; then
          echo "Skipping checkout — navigating to main workspace at $main_root..."
          _worktree_navigate "$main_root"
          return 0
        fi
      fi
      command git checkout "$2"
      return $?
    fi
    _worktree_checkout "git checkout $2" git checkout "$2"
    return $?
  fi

  command git "$@"
}

function _gh_repo_to_path() {
  echo "$HOME/Repos/$1"
}

# Check out a PR from any directory, routing through the main repo workspace.
# Usage: ghco-pr <pr-number-or-url> [repo-path]
function ghco-pr() {
  local pr="${1:?Usage: ghco-pr <pr-number-or-url> [repo-path]}"
  local repo_path="$2"
  local -a gh_extra=()

  if [[ "$pr" =~ 'github\.com/([^/]+)/([^/]+)/pull/' ]]; then
    gh_extra=(-R "${match[1]}/${match[2]}")
    [[ -z "$repo_path" ]] && repo_path="$(_gh_repo_to_path "${match[2]}")"
  fi

  repo_path="${repo_path:?Usage: ghco-pr <pr-number-or-url> [repo-path]}"

  local main_git main_root
  main_git=$(command git -C "$repo_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    echo "Not a git repository: $repo_path" >&2
    return 1
  }
  main_root="${main_git:h}"

  local branch existing_worktree
  branch=$(command gh pr view "$pr" "${gh_extra[@]}" --json headRefName -q .headRefName) || {
    echo "Could not find pull request: $pr" >&2
    return 1
  }

  existing_worktree=$(command git -C "$main_root" worktree list --porcelain 2>/dev/null \
    | command awk -v want="refs/heads/$branch" 'BEGIN{wt=""} /^worktree / {wt=$2} /^branch / {if ($2==want) {print wt; exit}}')
  if [[ -n "$existing_worktree" && -d "$existing_worktree" ]]; then
    echo "PR branch already checked out in worktree at $existing_worktree"
    _worktree_navigate "$existing_worktree"
    return 0
  fi

  if [[ "$PWD" != "$main_root" ]]; then
    echo "Checking out PR from $main_root..."
  fi

  cd "$main_root" || return 1
  gh pr checkout "$pr" "${gh_extra[@]}"
}

function gh() {
  if [[ "$1" == "pr" && "$2" == "checkout" ]]; then
    _worktree_checkout "gh pr checkout $3" gh "$@"
    return $?
  fi

  command gh "$@"
}

function ibrew() {
  arch --x86_64 brew "$@"
}

# Show all worktrees with their herdr workspace status.
# Green = has an open workspace, dim = not tracked in herdr.
function wts() {
  local raw
  raw=$("$HERDR_BIN" worktree list 2>/dev/null) || { git worktree list; return; }
  echo "$raw" | python3 -c "
import json, sys, os

data = json.loads(sys.stdin.read())
worktrees = data.get('result', {}).get('worktrees', [])

GREEN  = '\033[32m'
DIM    = '\033[90m'
RESET  = '\033[0m'
BOLD   = '\033[1m'

# Sort: open workspaces first, then alphabetically by branch
worktrees.sort(key=lambda w: (not bool(w.get('open_workspace_id')), w.get('branch', '')))

for wt in worktrees:
    branch = wt.get('branch', '?')
    ws     = wt.get('open_workspace_id', '')
    path   = wt.get('path', '')
    label  = os.path.basename(path)

    if ws:
        status = f'{GREEN}[{ws:>4}]{RESET}'
        print(f'{status} {BOLD}{branch}{RESET}')
    else:
        print(f'{DIM}[    ] {branch}{RESET}')
"
}

# Open a worktree by branch name in herdr (focused) and Cursor.
# Works from any context: herdr terminal, Cursor terminal, or plain shell.
function wto() {
  local branch="${1:?Usage: wto <branch>}"
  local path
  path=$(command git worktree list --porcelain 2>/dev/null \
    | awk -v want="refs/heads/$branch" 'BEGIN{wt=""} /^worktree / {wt=$2} /^branch / {if ($2==want) {print wt; exit}}')

  if [[ -z "$path" || ! -d "$path" ]]; then
    echo "No worktree found for branch: $branch" >&2
    return 1
  fi

  if [[ -S "$HOME/.config/herdr/herdr.sock" ]]; then
    "$HERDR_BIN" worktree open --path "$path" --focus 2>/dev/null
  fi

  if [[ "$GIT_WRAPPER_CONTEXT" != "claude" && -n "$CODE_BIN" ]]; then
    PATH="$(dirname "$CODE_BIN"):/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:$PATH" "$CODE_BIN" "$path"
  fi
}

# Close the herdr workspace for a given branch (doesn't remove the worktree).
function wtclose() {
  local branch="${1:?Usage: wtclose <branch>}"
  local ws_id
  ws_id=$("$HERDR_BIN" worktree list 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for wt in data.get('result', {}).get('worktrees', []):
    if wt.get('branch') == sys.argv[1]:
        ws = wt.get('open_workspace_id', '')
        if ws:
            print(ws)
        break
" "$branch" 2>/dev/null)

  if [[ -z "$ws_id" ]]; then
    echo "No open herdr workspace for branch: $branch" >&2
    return 1
  fi

  echo "Closing herdr workspace $ws_id for $branch..."
  "$HERDR_BIN" workspace close "$ws_id"
}

alias ghco=ghco-pr