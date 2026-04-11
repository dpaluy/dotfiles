# Dotfiles for Mac and Linux

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
├── cli-tools.sh        ← Optional CLI tools (Google CLI, etc.)
├── ai-tools.sh         ← AI tool selection + installation orchestrator
├── mcp.sh              ← MCP server registration (qmd, Perplexity)
├── skills.sh           ← Agent skills setup (dotfiles + external repos)
├── claude.sh           ← Claude Code config (CLAUDE.md, hooks, settings.json)
├── codex.sh            ← Codex config (AGENTS.md, config.toml)
├── opencode.sh         ← OpenCode config (AGENTS.md, opencode.json)
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

**Symlink Strategy**: `install/symlinks.sh` creates symlinks to expected locations, except where a local wrapper is needed:
- `git/config` → included from `~/.config/git/config` (local wrapper, not symlinked)
- `git/ignore` → `~/.config/git/ignore`
- `ghostty/config` → `~/.config/ghostty/config`
- `tmux/tmux.conf` → `~/.tmux.conf`
- `zellij/config.kdl` → `~/.config/zellij/config.kdl`
- `starship/starship.toml` → `~/.config/starship.toml`
- `ssh/config` → included in `~/.ssh/config` via `Include` (preserves local hosts)
- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` (via `install/claude.sh`)
- `claude/hooks/*.sh` → `~/.claude/hooks/*.sh` (optional, registers in settings.json)
- `codex/config.toml` → `~/.codex/config.toml` (copied, not symlinked)
- `codex/AGENTS.md` → `~/.codex/AGENTS.md` (if codex installed)
- `opencode/AGENTS.md` → `~/.config/opencode/AGENTS.md` (if opencode installed)
- `opencode/opencode.json` → merged into `~/.config/opencode/opencode.json` (local file, shared defaults preserved)
- `gh-dash/config.yml` → `~/.config/gh-dash/config.yml`
- `rtk/config.toml` → `~/.config/rtk/config.toml` (if rtk installed)
- `worktrunk/config.toml` → `~/.config/worktrunk/config.toml` (if wt installed)
- `npm/npmrc` → `~/.npmrc`
- `uv/uv.toml` → `~/.config/uv/uv.toml`
- `pi/models.json` → `~/.pi/agent/models.json`
- `pi/settings.json` → `~/.pi/agent/settings.json`
- `agents/skills/*` → `~/.agents/skills/*` (individual skill symlinks via `install/skills.sh`)
- `~/.claude/shaping-skills/*` → `~/.claude/skills/*` (cloned from github.com/rjs/shaping-skills via `install/skills.sh`)

**Special Case - ~/.zshrc**: Uses wrapper pattern instead of symlink.
- `~/.zshrc` (local file) sources `~/dotfiles/zsh/zshrc`
- External tools can safely append their initialization lines
- This prevents tool-added lines from polluting version-controlled files

**Special Case - Git Config**: Uses a local wrapper instead of a symlink.
- `~/.config/git/config` is the live machine-owned file
- It includes `~/dotfiles/git/config` for shared settings
- Tool-managed auth and machine-local settings live directly in `~/.config/git/config`
- This prevents `gh auth setup-git` and similar commands from dirtying the repo

**Zsh Loading Order** (`zsh/zshrc`):
1. Oh My Zsh initialization (plugins: gitfast, z, fzf, zsh-autosuggestions, etc.)
2. Public modules: `zsh/{path,exports,aliases,functions,ai,rails}`
3. OS-specific: `zsh/macos` (darwin) or `zsh/linux` (linux)
4. Local overrides: `~/.local/dotfiles/*.local`
5. Tool initializations: mise, starship, atuin, fzf

**Public/Private Split**:
- Public (this repo): Shareable configurations
- Private (`~/.local/dotfiles/`): `exports.local`, `ai.local`, etc.

**PATH Management** (`zsh/path`): Uses `path_prepend()` and `path_append()` helpers to avoid duplicates. Never hardcode version-specific paths—mise handles language versions.

## Intent Interpretation

This is a declarative repo. "Add X" (a tool, extension, package) means editing the relevant config or install list — not running the install command. Changes should be reproducible across machines via `install.sh`.

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
