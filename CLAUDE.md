# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Cross-platform dotfiles repository (macOS + Linux) using a public/private configuration split pattern. Public configs are version-controlled here; private configs (API keys, machine-specific settings) go in `~/.local/dotfiles/` and are never committed.

## Commands

```bash
# Install/update dotfiles (creates symlinks, installs packages)
./install.sh

# Test zsh config changes without restarting terminal
source ~/.zshrc

# Update Homebrew packages (macOS)
brew bundle --file=~/dotfiles/Brewfile
```

## Architecture

**Install Script Structure**: Modular design in `install/` directory:
```
install.sh              ← Orchestrator
install/
├── lib.sh              ← Utilities (colors, helpers, prompts)
├── macos.sh            ← Homebrew, fonts, Raycast, LazyVim
├── linux.sh            ← System packages, fonts
├── common.sh           ← Oh My Zsh, Atuin, shell setup
├── ai-tools.sh         ← Claude Code, Codex, OpenCode
├── symlinks.sh         ← Config symlinks
└── local-config.sh     ← Template creation
```
See `install/AGENTS.md` for module details.

**Cross-Platform Strategy**: OS-specific code uses `$OSTYPE` conditionals:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific
elif [[ "$OSTYPE" == "linux"* ]]; then
    # Linux specific
fi
```

**Symlink Strategy**: `install/symlinks.sh` creates symlinks to expected locations:
- `git/config` → `~/.config/git/config` (XDG style)
- `ghostty/config` → `~/.config/ghostty/config`
- `tmux/tmux.conf` → `~/.tmux.conf`
- `starship/starship.toml` → `~/.config/starship.toml`
- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `codex/config.toml` → `~/.codex/config.toml`

**Special Case - ~/.zshrc**: Uses wrapper pattern instead of symlink.
- `~/.zshrc` (local file) sources `~/dotfiles/zsh/zshrc`
- External tools can safely append their initialization lines
- This prevents tool-added lines from polluting version-controlled files

**Zsh Loading Order** (`zsh/zshrc`):
1. Oh My Zsh initialization
2. Public modules: `zsh/{path,exports,aliases,functions,ai,rails}`
3. OS-specific: `zsh/macos` (darwin) or `zsh/linux` (linux)
4. Local overrides: `~/.local/dotfiles/*.local`
5. Tool initializations: mise, starship, atuin

**Public/Private Split**:
- Public (this repo): Shareable configurations
- Private (`~/.local/dotfiles/`): `gitconfig.local`, `exports.local`, `ai.local`, etc.

**PATH Management** (`zsh/path`): Uses `path_prepend()` and `path_append()` helpers to avoid duplicates. Never hardcode version-specific paths—mise handles language versions.

## Key Design Decisions

- **Single repo** for both macOS and Linux (OS conditionals, not separate repos)
- **mise** over asdf for version management (faster, simpler)
- **Oh My Zsh** with z plugin for directory jumping
- **LazyVim** for neovim configuration (installed separately to ~/.config/nvim)
- **XDG-style paths** for git config (`~/.config/git/`)

## OS-Specific Files

- `zsh/macos` - macOS-only shell settings (Finder aliases, etc.)
- `zsh/linux` - Linux-only shell settings (xclip aliases, xdg-open, etc.)
- `install/macos.sh` - macOS installation (Homebrew, fonts, LazyVim)
- `install/linux.sh` - Linux installation (packages, fonts)
- `Brewfile` - macOS Homebrew packages
