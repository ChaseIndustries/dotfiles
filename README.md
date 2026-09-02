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
| `raycast/herdr-new-workspace.sh`                | `~/raycast-scripts/herdr-new-workspace.sh`                       |
| `nvim/init.lua`                                 | `~/.config/nvim/init.lua`                                        |
| `worktrunk/config.toml`                         | `~/.config/worktrunk/config.toml`                                |

Herdr plugins themselves are installed via `herdr plugin install <owner/repo>`. The plugin config files in `herdr/plugins/` are symlinked so the plugin picks them up.

`nvim/init.lua` is a minimal config whose main job is powering the editor pane in [herdr-deck](https://github.com/ctbaum/herdr-deck) (bootstraps lazy.nvim + herdr-agents.nvim so Claude/Codex auto-start inside Herdr-managed decks). Day-to-day editing still happens in Cursor. `install.sh` installs herdr-deck's dependencies (`nvim`, `worktrunk`, `zoxide`, `eza`, `lazygit`, `rust`) and the plugin itself.

herdr-deck is the default entry point for everything: `prefix+c` (new tab), `prefix+v` / `prefix+minus` (splits), and `prefix+o` all open it; `alt+o` toggles between the last two projects. The `ctrl+alt+c` / `ctrl+alt+d` / `ctrl+alt+shift+d` direct shortcuts still give a raw blank pane/split when that's genuinely what's wanted. Bare `herdr` (launching/attaching, no subcommand) also auto-opens the picker a moment after startup — see the `herdr()` wrapper in `functions.zsh`; `herdr <subcommand>` (workspace create, plugin install, etc.) passes straight through.

`worktrunk/config.toml` pins `wt`'s worktree layout to `~/Repos/.herdr-worktrees/`, matching Herdr's own `[worktrees]` directory and the `git worktree add` wrapper in `functions.zsh` — otherwise worktrees created through herdr-deck (which shells out to `wt`) would land in a different place than everything else.

`install.sh` also adds a marked block to `~/.zshrc` that puts `~/bin` on
`PATH`, sources `functions.zsh`, and initializes `zoxide` (not itself a
tracked file, edited in place).

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
