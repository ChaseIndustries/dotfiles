# AGENTS.md

Personal macOS dotfiles for Jordan Chase. `install.sh` symlinks tracked files
into their real locations, so editing a file in this repo changes the live
config immediately. No build step, no deploy step.

## What's here and where it lands

| Repo file | Symlinked to |
|---|---|
| `zsh/functions.zsh` | `~/.config/zsh/functions.zsh` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `herdr/plugins/dan.pane-topic-sync/config.toml` | `~/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml` |
| `cursor/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/keybindings.json` | `~/Library/Application Support/Cursor/User/keybindings.json` |
| `raycast/herdr-new-workspace.sh` | `~/raycast-scripts/herdr-new-workspace.sh` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `worktrunk/config.toml` | `~/.config/worktrunk/config.toml` |

`install.sh` also writes a marked block into the live `~/.zshrc` (not itself
tracked in this repo) that puts `~/bin` on `PATH`, sources `functions.zsh`,
and initializes `zoxide`. It's idempotent: it deletes and rewrites its own
marked block every run, so editing the block's contents in `install.sh`
takes effect on existing machines too, not just fresh ones.

## Gotchas learned the hard way

- **Never hardcode a tool's install path — resolve it.** A tool's absolute
  path varies by machine and install method (Homebrew arm vs intel, cargo,
  `~/.local/bin`, etc). `herdr` on this machine turned out to live at
  `~/.local/bin/herdr`, not `/opt/homebrew/bin/herdr` — a script that
  hardcoded the homebrew path was silently broken. Resolve via
  `command -v <tool>` (PATH) first, then fall back through known install
  locations, the way `zsh/functions.zsh`'s `_dotfiles_resolve_bin` and
  `raycast/herdr-new-workspace.sh` do it. Cursor terminal profiles and
  Raycast's silent-mode scripts don't reliably inherit a full shell `PATH`,
  which is exactly why the fallback list matters, not why hardcoding does.
- **No personal/company paths baked into scripts.** Project-root defaults
  read from `HERDR_PROJECT_ROOT`, falling back to `~/projects`, not a
  hardcoded work directory. Keep it that way for any new default paths.
- **`~/.zshrc` holds live secrets** (API keys as plain `export` lines).
  It's not tracked here. Only ever touch the marked
  `dotfiles managed block`, never anything else in that file.
- **Raycast scripts run in `silent` mode** — no attached terminal, so no
  interactive prompts (`gum`, `read`, etc.) will work there. Interactivity
  belongs in scripts launched from an actual terminal.
- **`gum` is a runtime dependency** for interactive prompts. `install.sh`
  brew-installs it if missing, keep that check if you add more `gum` usage.
- **`herdr plugin list | grep -q pattern` under `set -o pipefail` is racy.**
  `grep -q` closes its input as soon as it matches, which can SIGPIPE a
  still-writing producer; `pipefail` then reports that as pipeline failure
  even though grep matched. Capture the output into a variable first
  (`out="$(cmd)"; grep -q pattern <<< "$out"`) instead of piping straight
  into `grep -q`.
- **herdr-deck (and anything else that talks to Herdr's socket) only works
  inside an actual Herdr-managed pane.** It exits immediately if launched
  from a bare Cursor/Terminal.app shell with no `HERDR_SOCKET_PATH`. Reach
  it by first entering herdr (the Cursor `herdr` terminal profile, or a
  native terminal) and using its keybinding (`prefix+o`), not by wiring a
  separate terminal profile to launch it directly.

## Checklist before changing this repo

- [ ] New managed dotfile? Add matching `link` (install) and `unlink_file`
      (uninstall) calls, update `README.md`'s file table, and confirm the
      destination is actually where that app reads its config from.
- [ ] Script calls an external binary? Resolve it via `command -v` with a
      fallback list (see the gotcha above) instead of assuming any one
      fixed path.
- [ ] Re-run `bash install.sh install` twice, second run should be a no-op
      ("already linked" / "already wired" for everything).
- [ ] Don't touch anything in `~/.zshrc` outside the managed block.
