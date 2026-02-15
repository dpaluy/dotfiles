# install/ Directory

Modular installation scripts for cross-platform dotfiles setup.

## Structure

```
install.sh          ← Main orchestrator (run this)
install/
├── lib.sh          ← Shared utilities (colors, helpers, prompts)
├── macos.sh        ← macOS: Homebrew, fonts, Raycast, LazyVim, fzf
├── linux.sh        ← Linux: packages, gum, fonts (Debian/Fedora/Arch)
├── common.sh       ← Cross-platform: Oh My Zsh, plugins, Atuin, shell
├── ai-tools.sh     ← Optional: Claude Code, Codex CLI, OpenCode
├── symlinks.sh     ← Config symlinks (zsh, git, ghostty, etc.)
├── claude.sh       ← Claude Code config (CLAUDE.md, hooks, settings.json)
├── opencode.sh     ← OpenCode config (AGENTS.md, opencode.json)
└── local-config.sh ← Template creation in ~/.local/dotfiles/
```

## How It Works

1. `install.sh` sources `lib.sh` first (utilities available to all modules)
2. OS detection routes to `macos.sh` or `linux.sh`
3. Remaining modules source in order: common → ai-tools → symlinks → claude → opencode → local-config
4. Each module executes on source (not function-based)

## Adding New Modules

1. Create `install/newmodule.sh`
2. Use functions from `lib.sh`: `header()`, `info()`, `warn()`, `spin()`, `ask_yes_no()`, `create_symlink()`
3. Source it in `install.sh` at the appropriate point
4. Variables `$OS`, `$DOTFILES_DIR`, `$DOTFILES_LOCAL` are available

## Available Utilities (lib.sh)

| Function | Purpose |
|----------|---------|
| `info "msg"` | Green success message |
| `warn "msg"` | Yellow warning |
| `error "msg"` | Red error |
| `header "title"` | Section header with border |
| `spin "title" cmd args` | Run command with spinner |
| `ask_yes_no "question" [default]` | Y/N prompt (default: n) |
| `create_symlink src dest` | Safe symlink with backup |
| `create_local_template file comment` | Create template in ~/.local/dotfiles |
| `has_gum` | Check if gum TUI is available |
| `detect_os` | Returns: macos, arch, debian, fedora, or unknown |

## Design Principles

- **Idempotent**: Safe to run multiple times
- **Modular**: Each file handles one concern
- **Cross-platform**: OS conditionals use `$OS` variable
- **Mirrors zsh pattern**: `macos.sh`/`linux.sh` like `zsh/macos`/`zsh/linux`
