# Dotfiles Wiki

Welcome to the dotfiles wiki! This documentation covers all the shortcuts, aliases, and tips for getting the most out of these cross-platform dotfiles.

**Supported Platforms:** macOS, Linux (Debian/Ubuntu, Fedora, Arch)

## Quick Start

```bash
git clone https://github.com/dpaluy/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
source ~/.zshrc
```

## Contents

### Reference

- **[Shell Aliases](Shell-Aliases)** - Navigation, git, safety, and utility shortcuts
- **[Shell Functions](Shell-Functions)** - Helper functions for common tasks
- **[Git Configuration](Git-Configuration)** - Git aliases and settings
- **[Rails Aliases](Rails-Aliases)** - Ruby on Rails development shortcuts
- **[AI Tools](AI-Tools)** - Claude Code configuration

### Guides

- **[Tips and Tricks](Tips-and-Tricks)** - Useful tips for daily usage
- **[Customization](Customization)** - How to add your own settings

## Architecture

```
~/dotfiles/                        # Public (version controlled)
├── zsh/
│   ├── zshrc                      # Main zsh config
│   ├── aliases                    # Command aliases
│   ├── functions                  # Shell functions
│   ├── exports                    # Environment variables
│   ├── path                       # PATH configuration
│   ├── ai                         # AI tools config
│   ├── rails                      # Rails aliases
│   ├── macos                      # macOS-specific (Finder, DNS, etc.)
│   └── linux                      # Linux-specific (xdg-open, systemd, etc.)
├── git/
│   ├── config                     # Git configuration
│   └── ignore                     # Global gitignore
├── ghostty/
│   └── config                     # Terminal config
├── starship/
│   └── starship.toml              # Prompt config
├── hypr/                          # Hyprland (Linux only)
├── Brewfile                       # Homebrew packages (macOS only)
└── install.sh                     # Cross-platform installer

~/.local/dotfiles/                 # Private (not tracked)
├── *.local                        # Machine-specific overrides
└── *.local                        # Private shell/tool overrides
```

## Loading Order

1. Oh My Zsh loads with plugins
2. Public configs sourced: `path` → `exports` → `aliases` → `functions` → `ai` → `rails`
3. OS-specific config loaded: `macos` (on macOS) or `linux` (on Linux)
4. Local configs sourced (if exist): `*.local` versions from `~/.local/dotfiles/`
5. Starship prompt initialized
6. Atuin shell history initialized

## Key Features

- **Public/Local Split** - Share configs while keeping secrets private
- **Oh My Zsh** - Rich plugin ecosystem
- **Starship** - Fast, customizable prompt
- **Atuin** - Enhanced shell history with sync
- **fzf** - Fuzzy finding everywhere
