# macOS Dotfiles

Modern dotfiles for macOS development environment.

## Features

- **Oh My Zsh** with curated plugins
- **mise** for language version management (Ruby, Node, Go, Python)
- **Neovim** with LazyVim configuration
- **LazyGit** for terminal-based git UI
- **Starship** cross-shell prompt
- **Atuin** for shell history sync
- **Ghostty** terminal configuration
- **Delta** for beautiful git diffs

## Quick Start

```bash
# Clone the repository
git clone https://github.com/dpaluy/dotfile-mac.git ~/dotfile-mac

# Run the installer
cd ~/dotfile-mac
./install.sh
```

## What Gets Installed

### Core Packages (via Homebrew)

- Development: git, neovim, tmux, lazygit, gh
- Search: fzf, fd, ripgrep
- Shell: starship, atuin
- Utilities: jq, gum, git-delta

### Shell Configuration

The zsh configuration is modular:

| File | Purpose |
|------|---------|
| `zsh/zshrc` | Main entry point |
| `zsh/path` | PATH management (no duplicates) |
| `zsh/exports` | Environment variables |
| `zsh/aliases` | Command shortcuts |
| `zsh/functions` | Shell functions |
| `zsh/macos` | macOS-specific settings |
| `zsh/rails` | Rails development |
| `zsh/ai` | AI tool configs |

## Local Customization

Machine-specific settings go in `~/.local/dotfiles/` (not version controlled):

```
~/.local/dotfiles/
├── aliases.local       # Local aliases
├── exports.local       # API keys, tokens
├── functions.local     # Local functions
├── path.local          # Local PATH additions
├── gitconfig.local     # Git name, email, signing
├── ghostty.local       # Terminal overrides
├── ai.local            # AI API keys
└── rails.local         # Rails settings
```

### Git Configuration

Edit `~/.local/dotfiles/gitconfig.local`:

```ini
[user]
    name = Your Name
    email = your.email@example.com
```

## Key Features

### Git Aliases

| Alias | Command |
|-------|---------|
| `g` | git |
| `gst` | git status -sb |
| `lg` | lazygit |
| `glog` | Pretty git log graph |
| `git pf` | Push with force-with-lease |
| `git undo` | Soft reset last commit |
| `git amend` | Amend without editing message |
| `git cleanup` | Delete merged branches |

### Shell Functions

| Function | Description |
|----------|-------------|
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Universal archive extractor |
| `killport <port>` | Kill process on port |
| `myip` | Show public IP |
| `gwa <branch>` | Create git worktree |
| `gwd` | Remove current worktree |

### macOS Shortcuts

| Alias | Description |
|-------|-------------|
| `flushdns` | Flush DNS cache |
| `showfiles` | Show hidden files in Finder |
| `hidefiles` | Hide hidden files in Finder |
| `localip` | Get local IP address |
| `wtf3000` | What's using port 3000? |

## Updating

```bash
cd ~/dotfile-mac
git pull
./install.sh
```

## Structure

```
~/dotfile-mac/
├── install.sh          # Bootstrap script
├── Brewfile            # Homebrew packages
├── zsh/                # Shell configuration
├── git/                # Git configuration
├── ghostty/            # Terminal config
├── tmux/               # Tmux config
├── starship/           # Prompt config
├── claude/             # Claude Code config
└── raycast/            # Raycast scripts (optional)
```

## Credits

Inspired by:
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
- [dpaluy/dotfiles-linux](https://github.com/dpaluy/dotfiles-linux)
