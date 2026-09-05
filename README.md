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

`install.sh` also installs the herdr plugins this config depends on
(`danbuhler/herdr-pane-topic-sync`, `T0mSIlver/herdr-title-wrap`,
`nengqi/herdr-session-sync`, `ubuntudroid/herdr-git-stack`,
`cloudmanic/herdr-plus`, `thuanlm215/herdr-grid`) via
`herdr plugin install <owner/repo>`, skipped gracefully if herdr isn't
installed yet. The plugin config files in `herdr/plugins/` are symlinked
so the plugin picks them up.

`nvim/init.lua` is a minimal config whose main job is powering the editor pane in [herdr-deck](https://github.com/ctbaum/herdr-deck) (bootstraps lazy.nvim + herdr-agents.nvim so Claude/Codex auto-start inside Herdr-managed decks). Day-to-day editing still happens in Cursor. `install.sh` installs herdr-deck's dependencies (`nvim`, `worktrunk`, `zoxide`, `eza`, `lazygit`, `rust`) and the plugin itself.

Open herdr-deck explicitly with `prefix+o` or `ctrl+alt+o`; `alt+o` toggles between the last two projects. It's not the default for new tabs/splits/launch — its binary has no headless mode (only `--open-link`/`--restore-editors`/`--toggle-project`/`--record-workspace-focus`; anything else always launches its interactive picker), so forcing it onto every new pane means an unavoidable popup + manual pick every time. `new_tab`/`split_vertical`/`split_horizontal` stay plain blank panes.

`prefix+t` (or `ctrl+alt+g`) opens [herdr-grid](https://github.com/thuanlm215/herdr-grid), a popup layout editor for the active tab: drag a pane onto another to swap them, drop on an edge to create a split, drag dividers to resize. Herdr itself only does border-drag resizing and a right-click `Split right`/`Split down` menu, so this covers the mouse gestures it lacks. The preview is committed on `Enter`, so live PTYs and scrollback survive.

The herdr prefix is `ctrl+space`, not the default `ctrl+b`, because Claude Code binds `ctrl+b` to background a running Bash tool call and Claude runs in most panes here. This needs exactly one macOS keyboard layout enabled: with two or more, the system's "select previous input source" shortcut is also `ctrl+space` and swallows it before herdr sees it. Every frequently used action also has a direct `ctrl+alt+*` chord (`w` workspace picker, `s` settings, `r` resize mode, `o` herdr-deck, `g` herdr-grid, plus the existing split/focus/tab chords), so prefix mode is a convenience rather than the only way in.

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
