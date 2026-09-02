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
  hardcoded the homebrew path was silently broken. Resolve via `whence -p
  <tool>` (zsh; PATH-only, ignores functions/aliases — see next gotcha)
  first, then fall back through known install locations, the way
  `zsh/functions.zsh`'s `_dotfiles_resolve_bin` and
  `raycast/herdr-new-workspace.sh` do it. Cursor terminal profiles and
  Raycast's silent-mode scripts don't reliably inherit a full shell `PATH`,
  which is exactly why the fallback list matters, not why hardcoding does.
- **`command -v <name>` in zsh also matches shell functions/aliases, not
  just PATH binaries.** Hit this when `functions.zsh` briefly had a
  `herdr()` wrapper (since removed): resolving `herdr`'s path with
  `command -v` resolved to the wrapper function itself once it was
  defined, and the wrapper calling that "resolved path" recursed into
  itself (`FUNCNEST` error). Bites only on re-sourcing within an
  already-live shell, since a fresh process hasn't defined the function yet
  at the point the resolution line runs. If you ever wrap a command in a
  same-named function again, resolve its real binary with `whence -p`
  instead — it's PATH-only and immune to this.
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
- **herdr-deck has no headless/no-prompt mode — don't bind it to every
  new-pane action.** Checked its source directly: the binary only accepts
  `--help`, `--open-link`, `--restore-editors`, `--toggle-project`, and
  `--record-workspace-focus`; any other invocation always launches the
  interactive picker. We briefly rebound `new_tab`/`split_vertical`/
  `split_horizontal` to it and reverted after it turned "new tab" into a
  forced popup + manual pick every time. Keep it on an explicit key
  (`prefix+o`) only.
- **herdr-deck's `herdr tab rename` calls fight `pane-topic-sync`'s
  `respect_manual_names`.** Every deck herdr-deck creates renames its own
  tabs explicitly; with `respect_manual_names = true` that permanently
  locks those tabs out of live agent-topic syncing (static "dotfiles"/
  "lazygit" labels instead of the live task title). Set it `false` if you
  want live topics to keep winning even over herdr-deck's renames — the
  trade-off is a tab you rename by hand also gets overwritten on the next
  sync.

## Checklist before changing this repo

- [ ] New managed dotfile? Add matching `link` (install) and `unlink_file`
      (uninstall) calls, update `README.md`'s file table, and confirm the
      destination is actually where that app reads its config from.
- [ ] Script calls an external binary? Resolve it via `whence -p` (zsh) or
      `command -v` (elsewhere) with a fallback list (see the gotcha above)
      instead of assuming any one fixed path.
- [ ] Re-run `bash install.sh install` twice, second run should be a no-op
      ("already linked" / "already wired" for everything).
- [ ] Don't touch anything in `~/.zshrc` outside the managed block.
