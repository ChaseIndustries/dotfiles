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

Open herdr-deck explicitly with `prefix+o`; `alt+o` toggles between the last two projects. It's not the default for new tabs/splits/launch — its binary has no headless mode (only `--open-link`/`--restore-editors`/`--toggle-project`/`--record-workspace-focus`; anything else always launches its interactive picker), so forcing it onto every new pane means an unavoidable popup + manual pick every time. `new_tab`/`split_vertical`/`split_horizontal` stay plain blank panes.

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
