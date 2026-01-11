# Shell Functions

Helper functions defined in `zsh/functions`.

## Directory Operations

### `mkcd` - Create and enter directory

Creates a directory and immediately changes into it.

```bash
mkcd my-new-project
# Creates ./my-new-project/ and cd's into it
```

## Archive Extraction

### `extract` - Universal archive extractor

Extracts any common archive format automatically.

```bash
extract archive.tar.gz
extract file.zip
extract package.7z
```

**Supported formats:**
- `.tar.bz2`, `.tar.gz`, `.tar.xz`, `.tar`
- `.bz2`, `.gz`, `.Z`
- `.zip`, `.rar`, `.7z`
- `.tbz2`, `.tgz`
- `.zst` (Zstandard)

## Search & Navigation

### `fcd` - Fuzzy directory change

Uses fzf to interactively select and change to a directory.

```bash
fcd           # Search from current directory
fcd ~/projects  # Search from specific directory
```

### `ff` - Find files by name

Searches for files matching a pattern (case-insensitive).

```bash
ff config     # Find files containing "config"
ff "*.json"   # Find JSON files
```

### `fd` - Find directories by name

Searches for directories matching a pattern (case-insensitive).

```bash
fd node_modules  # Find node_modules directories
fd src           # Find directories containing "src"
```

## Git Helpers

### `gclone` - Clone and enter repository

Clones a repository and automatically changes into it.

```bash
gclone https://github.com/user/repo.git
# Clones and cd's into ./repo/

gclone git@github.com:user/repo.git
# Same for SSH URLs
```

### `gbranches` - Show branches in subdirectories

Lists the current branch for all git repositories in subdirectories.

```bash
cd ~/projects
gbranches
# Output:
# project-a/                      main
# project-b/                      feature/new-ui
# project-c/                      develop
```

## Process Management

### `psg` - Find process by name

Searches running processes by name.

```bash
psg nginx      # Find nginx processes
psg python     # Find Python processes
```

### `killport` - Kill process by port

Kills whatever is running on a specified port.

```bash
killport 3000  # Kill process on port 3000
killport 8080  # Kill process on port 8080
```

## Network

### `myip` - Show public IP

Displays your public IP address.

```bash
myip
# Output: 203.0.113.42
```

### `serve` - Quick HTTP server

Starts a Python HTTP server in the current directory.

```bash
serve         # Start on port 8000
serve 3000    # Start on port 3000
```

Then open `http://localhost:8000` in your browser.

## Adding Custom Functions

Add machine-specific functions to `~/.local/dotfiles/functions.local`:

```bash
# Quick project starter
newproject() {
    mkcd "$1"
    git init
    echo "# $1" > README.md
    git add .
    git commit -m "Initial commit"
}

# Docker cleanup
docker-clean() {
    docker system prune -af
    docker volume prune -f
}

# Quick notes
note() {
    local file="$HOME/notes/$(date +%Y-%m-%d).md"
    mkdir -p "$(dirname "$file")"
    echo "## $(date +%H:%M) - $*" >> "$file"
    ${EDITOR:-vim} "$file"
}
```
