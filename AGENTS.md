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
| `cursor/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/keybindings.json` | `~/Library/Application Support/Cursor/User/keybindings.json` |
| `bin/herdr-new-pane` | `~/bin/herdr-new-pane` |
| `raycast/herdr-new-workspace.sh` | `~/raycast-scripts/herdr-new-workspace.sh` |

`install.sh` also writes a marked block into the live `~/.zshrc` (not itself
tracked in this repo) that puts `~/bin` on `PATH` and sources
`functions.zsh`. It's idempotent, re-running `install` just says "already
wired," and `uninstall` strips the block cleanly.

## Gotchas learned the hard way

- **herdr lives at `~/.local/bin/herdr`, not a Homebrew path.** It used to
  be a Homebrew install at `/opt/homebrew/bin/herdr`, but that binary is
  gone — it migrated to `~/.local/bin/herdr` (confirmed 2026-09-01).
  Scripts that shell out to it hardcode the absolute path rather than
  trusting `PATH`, because Cursor terminal profiles and Raycast's
  silent-mode scripts don't reliably inherit a normal shell `PATH`. Before
  assuming any tool's location, run `which <tool>` on the actual machine
  rather than guessing — this exact assumption going stale is what broke
  `functions.zsh`, `bin/herdr-new-pane`, and `raycast/herdr-new-workspace.sh`
  all at once.
- **No personal/company paths baked into scripts.** Project-root defaults
  read from `HERDR_PROJECT_ROOT`, falling back to `~/projects`, not a
  hardcoded work directory. Keep it that way for any new default paths.
- **`~/.zshrc` holds live secrets** (API keys as plain `export` lines).
  It's not tracked here. Only ever touch the marked
  `dotfiles managed block`, never anything else in that file.
- **Raycast scripts run in `silent` mode** — no attached terminal, so no
  interactive prompts (`gum`, `read`, etc.) will work there. Interactivity
  belongs in scripts launched from an actual terminal (e.g. the Cursor
  `herdr-new-pane` profile).
- **`gum` is a runtime dependency** for interactive prompts. `install.sh`
  brew-installs it if missing, keep that check if you add more `gum` usage.

## Checklist before changing this repo

- [ ] New managed dotfile? Add matching `link` (install) and `unlink_file`
      (uninstall) calls, and confirm the destination is actually where that
      app reads its config from.
- [ ] Script calls an external binary? Verify its real path on this machine
      instead of assuming `~/.local/bin`, `/usr/local/bin`, etc.
- [ ] Re-run `bash install.sh install` twice, second run should be a no-op
      ("already linked" / "already wired" for everything).
- [ ] Don't touch anything in `~/.zshrc` outside the managed block.
- [ ] `README.md`'s file table only lists the first three entries above —
      it's stale. Worth fixing next time you're in there.
