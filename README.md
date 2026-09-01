# dotfiles

Personal shell config and utilities. No credentials — those live separately.

## Files

| File                                            | Target                                                           |
| ----------------------------------------------- | ---------------------------------------------------------------- |
| `zsh/functions.zsh`                             | `~/.config/zsh/functions.zsh`                                    |
| `claude/settings.json`                          | `~/.claude/settings.json`                                        |
| `herdr/config.toml`                             | `~/.config/herdr/config.toml`                                    |
| `herdr/plugins/dan.pane-topic-sync/config.toml` | `~/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml` |
| `cursor/settings.json`                          | `~/Library/Application Support/Cursor/User/settings.json`        |
| `cursor/keybindings.json`                       | `~/Library/Application Support/Cursor/User/keybindings.json`     |
| `bin/herdr-new-pane`                            | `~/bin/herdr-new-pane`                                           |
| `raycast/herdr-new-workspace.sh`                | `~/raycast-scripts/herdr-new-workspace.sh`                       |

Herdr plugins themselves are installed via `herdr plugin install <owner/repo>`. The plugin config files in `herdr/plugins/` are symlinked so the plugin picks them up.

`install.sh` also adds a marked block to `~/.zshrc` that puts `~/bin` on
`PATH` and sources `functions.zsh` (not itself a tracked file, edited in
place).

Herdr plugins themselves are installed via `herdr plugin install <owner/repo>`. The plugin config files in `herdr/plugins/` are symlinked so the plugin picks them up.

## Install

Creates symlinks from target locations to this repo (backs up existing files as `<file>.bak`):

```bash
bash ~/dotfiles/install.sh install
```

## Uninstall

Removes the symlinks and restores any `.bak` files:

```bash
bash ~/dotfiles/install.sh uninstall
```

## Sync

Since files are symlinked, edits in the repo are live. To commit and push:

```bash
cd ~/dotfiles && git add -A && git commit -m "sync" && git push
```
