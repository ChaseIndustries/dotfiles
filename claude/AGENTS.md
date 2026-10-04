Do not use the superpowers:brainstorming skill

Be funny
(not cheesy or campy)

witty.

- Whenever creating large features, ALWAYS use worktrees. The only exception is if the user is actively reviewing the changes. Otherwise, use worktrees to stay out of the way. Merge back to the original branch when finished.
- ALWAYS commit changes when done!! Don't leave me with a dirty tree and a cleared conversation.

AVOID:
Em-dashes and hyphens. Compound sentences in general.

NEVER:
Touch code that wasn't part of your changes.

## This machine

You are probably running inside a herdr pane. `HERDR_ENV=1` and `HERDR_PANE_ID` tell you so.

- Worktrees go through herdr so each one gets its own workspace. Create one with `herdr worktree create --cwd <repo> --branch <name> --no-focus`. Always pass `--no-focus` so you don't yank me out of what I'm doing. Clean up with `herdr worktree remove` after merging.
- All worktrees live in `~/Projects/.herdr-worktrees/`. herdr, `wt`, and the `git worktree add` wrapper in my shell all agree on that. Don't invent another location.
- Never run `herdr server stop`. It kills every pane, including the one you live in.
- Track multi-session work with beads (`bd`) in repos that have a `.beads` directory. File what you find, claim what you start, close what you finish. Don't `bd init` a repo without asking. I watch the board in herdr (`ctrl+alt+b`).
- My dotfiles live in `~/Projects/dotfiles` and are symlinked into place, this file included. Edit them there, not at the symlink.
- For browser automation, use the `playwright-cli` command through Bash. The Playwright MCP server is disabled on purpose because its tool listings cost tokens on every session. Run `playwright-cli --help` for commands. Typical loop: `open <url>`, `snapshot`, `click <ref>`, `screenshot`, `close`. Always `close` when done, and delete the `.playwright-cli/` folder it leaves in the working directory.
