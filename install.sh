#!/usr/bin/env bash
# install.sh - Symlink dotfiles from this repo into $HOME
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Top-level entries to link directly into $HOME
TOP_ENTRIES=(".bashrc" ".vimrc")

# Entries under .config to link into $HOME/.config
CONFIG_ENTRIES=("fish" "helix" "lazygit" "nvim" "starship.toml")

info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }

# Replace $dst with a symlink to $src, backing up anything already there.
link_entry() {
    local src="$1" dst="$2"

    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        info "Already linked: $dst"
        return
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        warn "Backing up existing $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    info "Linked: $dst -> $src"
}

info "Dotfiles repo: $DOTFILES_DIR"
info "Target home:   $HOME"

# 1. Top-level files
for entry in "${TOP_ENTRIES[@]}"; do
    if [[ ! -e "$DOTFILES_DIR/$entry" ]]; then
        warn "Missing in repo, skipping: $entry"
        continue
    fi
    link_entry "$DOTFILES_DIR/$entry" "$HOME/$entry"
done

# 2. Entries under .config
for entry in "${CONFIG_ENTRIES[@]}"; do
    if [[ ! -e "$DOTFILES_DIR/.config/$entry" ]]; then
        warn "Missing in repo, skipping: .config/$entry"
        continue
    fi
    link_entry "$DOTFILES_DIR/.config/$entry" "$HOME/.config/$entry"
done

if [[ -d "$BACKUP_DIR" ]]; then
    info "Done. Backups saved in: $BACKUP_DIR"
else
    info "Done. No backups were needed."
fi
