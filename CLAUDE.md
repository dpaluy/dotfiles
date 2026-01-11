# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

macOS dotfiles repository using a public/private configuration split pattern. Public configs are version-controlled here; private configs (API keys, machine-specific settings) go in `~/.local/dotfiles/` and are never committed.

## Commands

```bash
# Install/update dotfiles (creates symlinks, installs packages)
./install.sh

# Test zsh config changes without restarting terminal
source ~/.zshrc

# Update Homebrew packages
brew bundle --file=~/dotfiles/Brewfile
```

## Architecture

**Symlink Strategy**: `install.sh` symlinks configs to their expected locations:
- `zsh/zshrc` → `~/.zshrc`
- `git/config` → `~/.config/git/config` (XDG style)
- `ghostty/config` → `~/.config/ghostty/config`
- `tmux/tmux.conf` → `~/.tmux.conf`
- `starship/starship.toml` → `~/.config/starship.toml`

**Zsh Loading Order** (`zsh/zshrc`):
1. Oh My Zsh initialization
2. Public modules: `zsh/{path,exports,aliases,functions,ai,rails,macos}`
3. Local overrides: `~/.local/dotfiles/*.local`
4. Tool initializations: mise, starship, atuin

**Public/Private Split**:
- Public (this repo): Shareable configurations
- Private (`~/.local/dotfiles/`): `gitconfig.local`, `exports.local`, `ai.local`, etc.

**PATH Management** (`zsh/path`): Uses `path_prepend()` and `path_append()` helpers to avoid duplicates. Never hardcode version-specific paths—mise handles language versions.

## Key Design Decisions

- **mise** over asdf for version management (faster, simpler)
- **Oh My Zsh** with z plugin for directory jumping
- **LazyVim** for neovim configuration (installed separately to ~/.config/nvim)
- **Delta** as git pager with line numbers
- **XDG-style paths** for git config (`~/.config/git/`)
