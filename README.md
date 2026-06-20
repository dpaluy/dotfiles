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
- **mise** for language version management (Ruby, Node, Bun, Go, Python)
- **Neovim** with LazyVim configuration
- **LazyGit** for terminal-based git UI
- **Starship** cross-shell prompt
- **Atuin** for shell history sync
- **tmux** terminal multiplexer
- **Ghostty** terminal configuration
- **Delta** for beautiful git diffs
- **Worktrunk** for git worktree management (AI agent workflows)

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
├── worktrunk/
│   └── config.toml                    # Worktrunk worktree manager config
├── pi/
│   ├── models.json                    # pi custom models
│   └── settings.json                  # pi defaults + enabled model shortlist
├── claude/                            # Claude Code config
├── codex/                             # OpenAI Codex config
├── raycast/                           # Raycast scripts (macOS only)
├── Brewfile                           # Homebrew packages (macOS)
├── install.sh                         # Cross-platform installer
├── update.sh                          # Update packages and tools
└── harden-mac.sh                      # Interactive macOS security hardening

~/.local/dotfiles/                     # Private (not version controlled)
├── aliases.local                      # Machine-specific aliases
├── functions.local                    # Machine-specific functions
├── exports.local                      # API keys, tokens
├── path.local                         # Machine-specific PATH
├── ghostty.local                      # Terminal overrides
├── ai.local                           # AI API keys
├── rails.local                        # Rails settings
└── projects.local                     # Project-to-theme mappings
```

## What Gets Installed

### macOS (via Homebrew)

- Development: git, neovim, tmux, lazygit, gh, worktrunk
- Search: fzf, fd, ripgrep
- Shell: starship, atuin
- Utilities: jq, gum, git-delta
- Shared runtime via mise: Bun

### Linux

- Core: zsh, git, curl, neovim, tmux
- Search: fzf, fd, ripgrep
- Shell history: atuin
- Shared runtime via mise: Bun

## Local Customization

Machine-specific settings go in `~/.local/dotfiles/` (not version controlled):

```bash
# Private aliases
echo "alias work='cd ~/work/projects'" >> ~/.local/dotfiles/aliases.local

# Private environment variables
echo "export GITHUB_TOKEN=xxx" >> ~/.local/dotfiles/exports.local

# Work git email
cat >> ~/.config/git/config << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com
EOF
```
`~/.config/git/config` is the local live Git config on each machine. It includes the shared [`git/config`](/Users/clawbot/dotfiles/git/config) from dotfiles, and machine-specific or tool-managed settings live directly in `~/.config/git/config`.

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

### Worktrunk (Git Worktrees)

| Alias | Command |
|-------|---------|
| `wts` | `wt switch` — switch to worktree |
| `wtc` | `wt switch --create` — create worktree + branch |
| `wtl` | `wt list` — list worktrees |
| `wtm` | `wt merge` — squash, rebase, merge |
| `wtr` | `wt remove` — remove worktree |

Launch Claude Code in a new worktree:
```bash
wt switch -x claude --create feature-name -- 'Implement the feature'
```

### AI Tools

Optional AI coding assistants (prompted during install):

| Tool | Description |
|------|-------------|
| [Claude Code](https://claude.ai/code) | Anthropic coding CLI |
| [OpenAI Codex CLI](https://github.com/openai/codex) | OpenAI coding CLI |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Google coding CLI |
| [OpenCode](https://opencode.ai/) | Open-source coding CLI |
| [Kimi Code](https://www.kimi.com/code) | Kimi K2.5 coding CLI |
| [Oh My OpenAgent](https://ohmyopenagent.com/) | Multi-agent orchestration plugin for OpenCode |
| [Oh My Codex](https://github.com/Yeachan-Heo/oh-my-codex) | Structured workflows and skills for Codex CLI |
| [pi](https://github.com/mariozechner/pi-coding-agent) | Coding agent |
| [qmd](https://github.com/tobilu/qmd) | Local markdown search (installed with Bun) |

| Function | Description |
|----------|-------------|
| `mirror-skills [src] <dest>` | Mirror Claude Code skill directories |
| `cly` | Claude Code with auto-approve |

`mirror-skills` syncs directories containing `SKILL.md` files. Options: `--dry-run` to preview, `--sync` for full sync with backup.

### AI Skills Installer

Install custom skills to AI CLI tools:

```bash
./install/skills.sh
```

| Target | Path |
|--------|------|
| Codex | `~/.codex/skills/` |
| Claude | `~/.claude/skills/` |
| Custom | User-specified path |

Add public skills by creating a folder in `agents/skills/` with a `SKILL.md` file. Private/local skills can be added directly to `~/.agents/skills/`.

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

**Security Hardening:**

```bash
./harden-mac.sh
```

Interactive script that walks through macOS security settings one by one, showing current status and asking before applying each change.

| Category | Settings |
|----------|----------|
| Network | Application Firewall, Stealth Mode, disable SSH, disable Remote Apple Events |
| Screen Lock | Require password on wake, screensaver timeout, lock message |
| User Accounts | Disable Guest account, disable auto-login |
| System Integrity | Gatekeeper, FileVault (enables via `fdesetup`), SIP status check |
| Software Updates | Auto-checks, security patches, App Store updates |
| Privacy | Siri analytics, crash report submission |

FileVault is handled inline: if off, the script prompts to enable it and prints the recovery key. Save the recovery key in a password manager immediately.

Settings that cannot be scripted (SIP, firmware password) are flagged with instructions at the end.

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

5. Get your key ID and add to `~/.config/git/config`:
   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```
   ```ini
   [user]
       signingkey = YOUR_KEY_ID
   [commit]
       gpgsign = true
   ```

## Supply Chain Security

npm is configured with a 3-day minimum release age (`min-release-age=3` in `.npmrc`) to avoid installing newly published packages before the community has had time to vet them.

To bypass for a specific install:

```bash
npm install -g @openai/codex --min-release-age=0
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
