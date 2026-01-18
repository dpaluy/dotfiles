# Dotfiles

Cross-platform dotfiles for macOS and Linux with public/private configuration pattern.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/dpaluy/dotfiles.git ~/dotfiles

# Run the installer
cd ~/dotfiles
./install.sh
```

## Features

- **Oh My Zsh** with curated plugins (autosuggestions, syntax-highlighting)
- **mise** for language version management (Ruby, Node, Go, Python)
- **Neovim** with LazyVim configuration
- **LazyGit** for terminal-based git UI
- **Starship** cross-shell prompt
- **Atuin** for shell history sync
- **Ghostty** terminal configuration
- **Delta** for beautiful git diffs

## Structure

```
~/dotfiles/                            # Public (version controlled)
├── zsh/
│   ├── zshrc                          # Main zsh config
│   ├── aliases                        # Command aliases
│   ├── functions                      # Shell functions
│   ├── exports                        # Environment variables
│   ├── path                           # PATH configuration
│   ├── rails                          # Rails development
│   ├── ai                             # AI tool configs
│   ├── macos                          # macOS-specific settings
│   └── linux                          # Linux-specific settings
├── git/
│   ├── config                         # Git configuration
│   └── ignore                         # Global gitignore
├── ghostty/
│   └── config                         # Ghostty terminal config
├── starship/
│   └── starship.toml                  # Prompt configuration
├── tmux/
│   └── tmux.conf                      # Tmux configuration
├── hypr/                              # Hyprland (Linux only)
│   ├── hyprland.conf
│   └── bindings.conf
├── claude/                            # Claude Code config
├── codex/                             # OpenAI Codex config
├── raycast/                           # Raycast scripts (macOS only)
├── Brewfile                           # Homebrew packages (macOS)
└── install.sh                         # Cross-platform installer

~/.local/dotfiles/                     # Private (not version controlled)
├── aliases.local                      # Machine-specific aliases
├── functions.local                    # Machine-specific functions
├── exports.local                      # API keys, tokens
├── path.local                         # Machine-specific PATH
├── gitconfig.local                    # Git name, email, signing
├── ghostty.local                      # Terminal overrides
├── ai.local                           # AI API keys
└── rails.local                        # Rails settings
```

## What Gets Installed

### macOS (via Homebrew)

- Development: git, neovim, tmux, lazygit, gh
- Search: fzf, fd, ripgrep
- Shell: starship, atuin
- Utilities: jq, gum, git-delta

### Linux

- Core: zsh, git, curl, neovim
- Search: fzf, fd, ripgrep
- Shell history: atuin

## Local Customization

Machine-specific settings go in `~/.local/dotfiles/` (not version controlled):

```bash
# Private aliases
echo "alias work='cd ~/work/projects'" >> ~/.local/dotfiles/aliases.local

# Private environment variables
echo "export GITHUB_TOKEN=xxx" >> ~/.local/dotfiles/exports.local

# Work git email
cat >> ~/.local/dotfiles/gitconfig.local << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com
EOF
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

### AI Tools

| Function | Description |
|----------|-------------|
| `mirror-skills [src] <dest>` | Mirror Claude Code skill directories |
| `cly` | Claude Code with auto-approve |

`mirror-skills` syncs directories containing `SKILL.md` files. Options: `--dry-run` to preview, `--sync` for full sync with backup.

### macOS Shortcuts

| Alias | Description |
|-------|-------------|
| `flushdns` | Flush DNS cache |
| `showfiles` | Show hidden files in Finder |
| `hidefiles` | Hide hidden files in Finder |
| `localip` | Get local IP address |
| `wtf3000` | What's using port 3000? |

### Linux Shortcuts

| Alias | Description |
|-------|-------------|
| `update` | Update system packages |
| `install` | Install package |
| `sc` | systemctl |
| `scs` | systemctl status |
| `open` | xdg-open (like macOS open) |

## Platform-Specific

### macOS

**Ghostty keybindings:** Uses `super+` (Cmd) by default. See `ghostty/config`.

### Linux

**Ghostty keybindings:** Comment out macOS section and uncomment Linux section in `ghostty/config`.

**Theme:** Terminal theme is controlled by Omarchy. To override, edit `ghostty/config` and uncomment the theme line.

**Font Size (system-wide):**

```bash
# Scale to 125% (try 1.25, 1.5, or 1.75)
gsettings set org.gnome.desktop.interface text-scaling-factor 1.25
```

**GPG Setup:**

1. Install pinentry:
   ```bash
   sudo pacman -S pinentry  # Arch
   sudo apt install pinentry-gtk2  # Debian/Ubuntu
   ```

2. Configure pinentry in `~/.gnupg/gpg-agent.conf`:
   ```bash
   mkdir -p ~/.gnupg
   echo "pinentry-program /usr/bin/pinentry-gtk" >> ~/.gnupg/gpg-agent.conf
   ```

3. Restart the GPG agent:
   ```bash
   gpgconf --kill gpg-agent
   ```

4. Generate a new GPG key:
   ```bash
   gpg --full-generate-key
   ```

5. Get your key ID and add to `~/.local/dotfiles/gitconfig.local`:
   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```
   ```ini
   [user]
       signingkey = YOUR_KEY_ID
   [commit]
       gpgsign = true
   ```

## Dependencies

- [Oh My Zsh](https://ohmyz.sh/)
- [Starship](https://starship.rs/) - Cross-shell prompt
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [fd](https://github.com/sharkdp/fd) - Faster find
- [Atuin](https://atuin.sh/) - Shell history sync

## Neovim

Neovim config is managed separately at `~/.config/nvim/` using LazyVim. The installer will prompt to set it up on macOS.

## Updating

```bash
cd ~/dotfiles
git pull
./install.sh
```

## Credits

Inspired by [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
