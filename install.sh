#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  local dir
  dir="$(dirname "$dst")"

  mkdir -p "$dir"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      echo "  already linked: $dst"
      return
    fi
    echo "  replacing stale link: $dst -> $current"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "  backing up: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -s "$src" "$dst"
  echo "  linked: $dst -> $src"
}

ZSHRC="$HOME/.zshrc"
ZSHRC_MARKER_START="# >>> dotfiles managed block >>>"
ZSHRC_MARKER_END="# <<< dotfiles managed block <<<"

ensure_zshrc_block() {
  if [[ -f "$ZSHRC" ]] && grep -qF "$ZSHRC_MARKER_START" "$ZSHRC"; then
    sed -i '' "/^${ZSHRC_MARKER_START}\$/,/^${ZSHRC_MARKER_END}\$/d" "$ZSHRC"
  fi

  {
    echo ""
    echo "$ZSHRC_MARKER_START"
    echo 'export PATH="$HOME/bin:$PATH"'
    echo '[ -f "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"'
    echo 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"'
    echo "$ZSHRC_MARKER_END"
  } >> "$ZSHRC"
  echo "  wired: $ZSHRC (PATH + functions.zsh + zoxide)"
}

remove_zshrc_block() {
  if [[ -f "$ZSHRC" ]] && grep -qF "$ZSHRC_MARKER_START" "$ZSHRC"; then
    sed -i '' "/^${ZSHRC_MARKER_START}\$/,/^${ZSHRC_MARKER_END}\$/d" "$ZSHRC"
    echo "  unwired: $ZSHRC"
  fi
}

ensure_repos_root_symlink() {
  local target="${REPOS_ROOT:-}"
  local link_path="$HOME/Repos"

  # Unset or pointing at the default itself: nothing to do, tools already
  # hardcode ~/Repos as their literal default.
  [[ -z "$target" || "$target" == "$link_path" ]] && return

  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" == "$target" ]]; then
      echo "  already linked: $link_path -> $target"
    else
      echo "  replacing stale symlink: $link_path -> $current"
      rm "$link_path"
      ln -s "$target" "$link_path"
      echo "  linked: $link_path -> $target"
    fi
  elif [[ -e "$link_path" ]]; then
    echo "  skipping: $link_path already exists as a real directory."
    echo "    herdr/worktrunk hardcode ~/Repos/... as their worktree pool; REPOS_ROOT=$target won't take effect there"
    echo "    until you migrate its contents (e.g. via 'git worktree move' for each worktree) and replace it with a symlink yourself."
  else
    ln -s "$target" "$link_path"
    echo "  linked: $link_path -> $target"
  fi
}

install_herdr_plugin() {
  local repo="$1"
  if ! command -v herdr >/dev/null 2>&1; then
    echo "  skipping herdr plugin $repo (herdr not installed)"
    return
  fi
  echo "  installing herdr plugin: $repo"
  herdr plugin install "$repo" --yes >/dev/null
}

# Register a plugin we keep a patched local copy of, instead of pulling it from
# GitHub. `herdr plugin link` points herdr straight at the checkout, so nothing
# can quietly overwrite the patch the way a plugin update would.
link_herdr_plugin() {
  local path="$1" plugin_id="$2"
  if ! command -v herdr >/dev/null 2>&1; then
    echo "  skipping herdr plugin $plugin_id (herdr not installed)"
    return
  fi
  # Capture before grepping: piping into `grep -q` can SIGPIPE herdr mid-write,
  # which pipefail then reports as a failure even though grep matched.
  local installed
  installed="$(herdr plugin list 2>/dev/null || true)"
  if grep -q "local:$path" <<< "$installed"; then
    echo "  herdr plugin already linked: $plugin_id"
    return
  fi
  # A GitHub-installed copy claims the same plugin id and blocks the link.
  if grep -q "^- $plugin_id " <<< "$installed"; then
    echo "  replacing github copy of herdr plugin: $plugin_id"
    herdr plugin uninstall "$plugin_id" >/dev/null || true
  fi
  echo "  linking herdr plugin: $plugin_id -> $path"
  herdr plugin link "$path" --enabled >/dev/null
}

unlink_file() {
  local dst="$1"

  if [[ -L "$dst" ]]; then
    rm "$dst"
    echo "  removed: $dst"
    if [[ -e "${dst}.bak" ]]; then
      mv "${dst}.bak" "$dst"
      echo "  restored: ${dst}.bak"
    fi
  elif [[ -e "$dst" ]]; then
    echo "  skipping (not a symlink): $dst"
  else
    echo "  not found: $dst"
  fi
}

cmd_install() {
  echo "Installing dotfiles from $DOTFILES_DIR..."

  if ! command -v gum >/dev/null 2>&1; then
    echo "  installing dep: gum"
    brew install gum
  fi

  if ! command -v op >/dev/null 2>&1; then
    echo "  installing dep: 1password-cli"
    brew install --cask 1password-cli
  fi
  if ! op account list >/dev/null 2>&1; then
    echo "  1Password CLI isn't signed in yet."
    echo "    -> 1Password app > Settings > Developer > enable 'Integrate with 1Password CLI'"
    echo "    -> then run: op signin"
  fi

  for dep in nvim wt zoxide eza lazygit; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "  installing dep: $dep"
      case "$dep" in
        wt) brew install worktrunk ;;
        nvim) brew install neovim ;;
        *) brew install "$dep" ;;
      esac
    fi
  done
  if ! command -v cargo >/dev/null 2>&1; then
    echo "  installing dep: rust (cargo)"
    brew install rust
  fi

  ensure_repos_root_symlink

  # Patched fork of danbuhler/herdr-pane-topic-sync, not the upstream install:
  # it splits `respect_manual_names` per kind. See AGENTS.md.
  link_herdr_plugin "$DOTFILES_DIR/herdr/plugins/pane-topic-sync-fork" "dan.pane-topic-sync"
  install_herdr_plugin "T0mSIlver/herdr-title-wrap"
  # nengqi/herdr-session-sync is deliberately NOT installed -- it renamed every
  # pane from the PTY title with no manual-name check, clobbering hand-named
  # panes. See AGENTS.md.
  install_herdr_plugin "ubuntudroid/herdr-git-stack"
  install_herdr_plugin "cloudmanic/herdr-plus"
  install_herdr_plugin "thuanlm215/herdr-grid"

  link "$DOTFILES_DIR/zsh/functions.zsh"              "$HOME/.config/zsh/functions.zsh"
  link "$DOTFILES_DIR/claude/settings.json"           "$HOME/.claude/settings.json"
  link "$DOTFILES_DIR/herdr/config.toml"                          "$HOME/.config/herdr/config.toml"
  link "$DOTFILES_DIR/herdr/plugins/dan.pane-topic-sync/config.toml" "$HOME/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml"
  link "$DOTFILES_DIR/herdr/plugins/cloudmanic.herdr-plus/worktrees/dual-pane.toml" "$HOME/.config/herdr/plugins/config/cloudmanic.herdr-plus/worktrees/dual-pane.toml"
  link "$DOTFILES_DIR/herdr/scripts/new-dual-workspace.sh" "$HOME/.local/bin/herdr-new-dual-workspace"
  link "$DOTFILES_DIR/cursor/settings.json"           "$HOME/Library/Application Support/Cursor/User/settings.json"
  link "$DOTFILES_DIR/cursor/keybindings.json"        "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  link "$DOTFILES_DIR/raycast/herdr-new-workspace.sh" "$HOME/raycast-scripts/herdr-new-workspace.sh"
  link "$DOTFILES_DIR/nvim/init.lua"                  "$HOME/.config/nvim/init.lua"
  link "$DOTFILES_DIR/worktrunk/config.toml"          "$HOME/.config/worktrunk/config.toml"
  ensure_zshrc_block

  # Capture output before grepping: piping directly into `grep -q` can SIGPIPE
  # `herdr` mid-write once grep finds its match, and with pipefail that
  # registers as pipeline failure even though the match succeeded.
  installed_plugins="$(herdr plugin list 2>/dev/null || true)"
  if ! grep -q "herdr-deck" <<< "$installed_plugins"; then
    echo "  installing herdr plugin: ctbaum/herdr-deck"
    herdr plugin install ctbaum/herdr-deck --yes || echo "  (run manually once herdr is running: herdr plugin install ctbaum/herdr-deck)"
  fi

  if command -v herdr >/dev/null 2>&1 && [[ -S "$HOME/.config/herdr/herdr.sock" ]]; then
    echo "  reloading herdr config"
    herdr server reload-config >/dev/null || true
  fi
  echo "Done."
}

cmd_uninstall() {
  echo "Uninstalling dotfiles..."
  remove_zshrc_block
  unlink_file "$HOME/.config/zsh/functions.zsh"
  unlink_file "$HOME/.claude/settings.json"
  unlink_file "$HOME/.config/herdr/config.toml"
  unlink_file "$HOME/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml"
  unlink_file "$HOME/.config/herdr/plugins/config/cloudmanic.herdr-plus/worktrees/dual-pane.toml"
  unlink_file "$HOME/.local/bin/herdr-new-dual-workspace"
  unlink_file "$HOME/Library/Application Support/Cursor/User/settings.json"
  unlink_file "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  unlink_file "$HOME/raycast-scripts/herdr-new-workspace.sh"
  unlink_file "$HOME/.config/nvim/init.lua"
  unlink_file "$HOME/.config/worktrunk/config.toml"
  if command -v herdr >/dev/null 2>&1; then
    herdr plugin unlink dan.pane-topic-sync >/dev/null 2>&1 || true
  fi
  echo "Done."
}

case "${1:-}" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  *)
    echo "Usage: $(basename "$0") <install|uninstall>"
    exit 1
    ;;
esac
