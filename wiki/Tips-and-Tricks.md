# Tips and Tricks

Useful tips for getting the most out of these dotfiles.

## Oh My Zsh Plugins

These plugins are enabled by default:

| Plugin | Description |
|--------|-------------|
| `1password` | 1Password CLI integration |
| `gitfast` | Fast git completion |
| `git-extras` | Extra git commands |
| `z` | Jump to frequently used directories |
| `zsh-autosuggestions` | Fish-like autosuggestions |
| `zsh-syntax-highlighting` | Syntax highlighting as you type |
| `fzf` | Fuzzy finder integration |
| `history-substring-search` | Search history by substring |
| `docker` | Docker command completion |
| `bundler` | Bundler shortcuts |
| `rails` | Rails shortcuts |

### Using `z` for Quick Navigation

After visiting directories a few times, `z` learns them:

```bash
z proj     # Jump to ~/projects
z dot      # Jump to ~/dotfiles
z down     # Jump to ~/Downloads
```

### History Substring Search

Press `Up`/`Down` after typing to search history:

```bash
git com    # Then press Up to find "git commit -m ..."
docker     # Then press Up to find docker commands
```

## Keyboard Shortcuts

### fzf Shortcuts

| Shortcut | Description |
|----------|-------------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Search files in current directory |
| `Alt+C` | Change to a subdirectory |

### Zsh Shortcuts

| Shortcut | Description |
|----------|-------------|
| `Ctrl+A` | Go to beginning of line |
| `Ctrl+E` | Go to end of line |
| `Ctrl+U` | Clear line before cursor |
| `Ctrl+K` | Clear line after cursor |
| `Ctrl+W` | Delete word before cursor |
| `Alt+D` | Delete word after cursor |
| `Ctrl+L` | Clear screen |

## Global Pipe Aliases

Use these anywhere in a command:

```bash
# Count files
ls | wc -l        # Old way
ls L              # New way

# Search output
ps aux | grep nginx    # Old way
ps aux G nginx         # New way

# Get first/last lines
cat log | head         # Old way
cat log H              # New way

# Combine them
ps aux G node H        # Find node processes, show first few
```

## Port Debugging

```bash
# What's using port 3000?
wtf3000

# What's using port 8080?
wtf 8080

# Kill whatever's on port 3000
killport 3000
```

## Quick Directory Creation

```bash
# Old way
mkdir -p path/to/new/dir
cd path/to/new/dir

# New way
mkcd path/to/new/dir
```

## Archive Handling

Never remember tar flags again:

```bash
extract file.tar.gz
extract archive.zip
extract package.7z
```

## Quick HTTP Server

Share files from any directory:

```bash
cd ~/Documents
serve
# Now accessible at http://localhost:8000
```

## Git Workflows

### Amend Without Editing

```bash
# Made a typo? Add the fix:
git add .
git amend
# Amends last commit without changing message
```

### Undo Last Commit

```bash
git undo
# Commit is gone but changes remain staged
```

### Clean Up Old Branches

```bash
# Delete merged branches
git cleanup

# Delete branches with deleted remotes
git gone
```

### Check All Project Branches

```bash
cd ~/projects
gbranches
# Shows current branch for each subdirectory
```

## Atuin Shell History

If Atuin is installed, you get:

- **Sync across machines** - Same history everywhere
- **Better search** - Full-text search with context
- **Statistics** - See your most used commands

Press `Ctrl+R` for the enhanced history search.

## Starship Prompt

The Starship prompt shows:

- Current directory
- Git branch and status
- Language versions (when in project)
- Command duration (for slow commands)
- Exit code (when non-zero)

Customize in `~/.config/starship.toml`.

## Performance Tips

### Faster Startup

If shell startup is slow:

1. Check what's loading:
   ```bash
   time zsh -i -c exit
   ```

2. Profile startup:
   ```bash
   zsh -xv 2>&1 | head -100
   ```

### Faster Directory Search

Install `fd` for faster file finding:

```bash
# Arch Linux
sudo pacman -S fd

# macOS
brew install fd
```

The fzf commands will automatically use it.

## Troubleshooting

### Reload After Changes

```bash
reload
# or
source ~/.zshrc
```

### Check What's Defined

```bash
# List all aliases
alias

# Check specific alias
alias gs

# List all functions
functions

# Check specific function
which extract
```

### Fix Permission Issues

```bash
# If you see "permission denied" on .local files
chmod 600 ~/.local/dotfiles/*.local
```
