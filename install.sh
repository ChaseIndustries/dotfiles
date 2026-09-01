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
    echo "  already wired: $ZSHRC"
    return
  fi

  {
    echo ""
    echo "$ZSHRC_MARKER_START"
    echo 'export PATH="$HOME/bin:$PATH"'
    echo '[ -f "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"'
    echo "$ZSHRC_MARKER_END"
  } >> "$ZSHRC"
  echo "  wired: $ZSHRC (PATH + functions.zsh)"
}

remove_zshrc_block() {
  if [[ -f "$ZSHRC" ]] && grep -qF "$ZSHRC_MARKER_START" "$ZSHRC"; then
    sed -i '' "/^${ZSHRC_MARKER_START}\$/,/^${ZSHRC_MARKER_END}\$/d" "$ZSHRC"
    echo "  unwired: $ZSHRC"
  fi
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

  link "$DOTFILES_DIR/zsh/functions.zsh"              "$HOME/.config/zsh/functions.zsh"
  link "$DOTFILES_DIR/claude/settings.json"           "$HOME/.claude/settings.json"
  link "$DOTFILES_DIR/herdr/config.toml"                          "$HOME/.config/herdr/config.toml"
  link "$DOTFILES_DIR/herdr/plugins/dan.pane-topic-sync/config.toml" "$HOME/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml"
  link "$DOTFILES_DIR/cursor/settings.json"           "$HOME/Library/Application Support/Cursor/User/settings.json"
  link "$DOTFILES_DIR/cursor/keybindings.json"        "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  link "$DOTFILES_DIR/bin/herdr-new-pane"             "$HOME/bin/herdr-new-pane"
  link "$DOTFILES_DIR/raycast/herdr-new-workspace.sh" "$HOME/raycast-scripts/herdr-new-workspace.sh"
  ensure_zshrc_block
  echo "Done."
}

cmd_uninstall() {
  echo "Uninstalling dotfiles..."
  remove_zshrc_block
  unlink_file "$HOME/.config/zsh/functions.zsh"
  unlink_file "$HOME/.claude/settings.json"
  unlink_file "$HOME/.config/herdr/config.toml"
  unlink_file "$HOME/.config/herdr/plugins/config/dan.pane-topic-sync/config.toml"
  unlink_file "$HOME/Library/Application Support/Cursor/User/settings.json"
  unlink_file "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  unlink_file "$HOME/bin/herdr-new-pane"
  unlink_file "$HOME/raycast-scripts/herdr-new-workspace.sh"
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
