# Shell Aliases

All shell aliases defined in `zsh/aliases`.

## Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `....` | `cd ../../..` | Go up three directories |
| `.....` | `cd ../../../..` | Go up four directories |
| `~` | `cd ~` | Go to home directory |
| `-` | `cd -` | Go to previous directory |

## Listing Files

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `ls --color=auto` | List with colors |
| `ll` | `ls -lah` | Long list, all files, human-readable |
| `la` | `ls -A` | List all except . and .. |
| `l` | `ls -CF` | Compact list with indicators |
| `lt` | `ls -lahtr` | List sorted by time, newest last |

## Git

| Alias | Command | Description |
|-------|---------|-------------|
| `g` | `git` | Git shortcut |
| `ga` | `git add` | Stage files |
| `gaa` | `git add --all` | Stage all changes |
| `gc` | `git commit` | Commit |
| `gcm` | `git commit -m` | Commit with message |
| `gcam` | `git commit -am` | Add all and commit with message |
| `gcad` | `git commit -a --amend` | Amend last commit with all changes |
| `gco` | `git checkout` | Checkout |
| `gd` | `git diff` | Show diff |
| `gds` | `git diff --staged` | Show staged diff |
| `gl` | `git log --oneline -20` | Show last 20 commits |
| `glog` | (pretty format) | Show graph log with colors |
| `gp` | `git push` | Push to remote |
| `gpl` | `git pull` | Pull from remote |
| `gs` | `git status` | Show status |
| `gst` | `git status -sb` | Short status with branch |
| `gb` | `git branch` | List branches |
| `gf` | `git fetch` | Fetch from remote |
| `gwc` | `git whatchanged -p` | Show what changed with patches |
| `ghistory` | `git log --follow -p` | Show file history |

## Safety Aliases

These aliases add confirmation prompts to destructive commands:

| Alias | Command | Description |
|-------|---------|-------------|
| `rm` | `rm -i` | Remove with confirmation |
| `mv` | `mv -i` | Move with confirmation |
| `cp` | `cp -i` | Copy with confirmation |

## Utilities

| Alias | Command | Description |
|-------|---------|-------------|
| `grep` | `grep --color=auto` | Grep with colors |
| `fgrep` | `fgrep --color=auto` | Fixed grep with colors |
| `egrep` | `egrep --color=auto` | Extended grep with colors |
| `mkdir` | `mkdir -pv` | Make dirs (create parents, verbose) |
| `df` | `df -h` | Disk free (human-readable) |
| `du` | `du -h` | Disk usage (human-readable) |
| `free` | `free -h` | Memory info (human-readable) |

## Editor

| Alias | Command | Description |
|-------|---------|-------------|
| `v` | `nvim` | Neovim |
| `vi` | `nvim` | Neovim |
| `vim` | `nvim` | Neovim |

## Miscellaneous

| Alias | Command | Description |
|-------|---------|-------------|
| `c` | `clear` | Clear terminal |
| `h` | `history` | Show history |
| `j` | `jobs -l` | List jobs |
| `path` | (echo PATH) | Show PATH, one per line |
| `reload` | `source ~/.zshrc` | Reload shell config |
| `tlf` | `tail -f` | Follow file |

## Global Pipe Aliases (Zsh only)

These can be used anywhere in a command:

| Alias | Expands to | Example |
|-------|------------|---------|
| `G` | `\| grep` | `ls G txt` |
| `L` | `\| wc -l` | `ls L` |
| `H` | `\| head` | `cat file H` |
| `T` | `\| tail` | `cat file T` |

**Example:**
```bash
# Instead of:
ps aux | grep nginx | head

# You can write:
ps aux G nginx H
```

## Debug

| Alias | Command | Description |
|-------|---------|-------------|
| `wtf3000` | `lsof -i tcp:3000` | Show what's using port 3000 |
| `wtf` | `lsof -i tcp:` | Show what's using a port (usage: `wtf 8080`) |

## Adding Custom Aliases

Add machine-specific aliases to `~/.local/dotfiles/aliases.local`:

```bash
# Work shortcuts
alias work='cd ~/work/projects'
alias vpn='sudo openvpn ~/work/config.ovpn'

# Personal shortcuts
alias blog='cd ~/projects/blog && code .'
```
