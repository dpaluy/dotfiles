# Git Configuration

Git aliases and settings defined in `git/config`.

## Git Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `git co` | `checkout` | Checkout shortcut |
| `git br` | `branch` | Branch shortcut |
| `git ci` | `commit` | Commit shortcut |
| `git st` | `status` | Status shortcut |
| `git last` | `log -1 HEAD` | Show last commit |
| `git unstage` | `reset HEAD --` | Unstage files |
| `git amend` | `commit --amend --no-edit` | Amend without editing message |
| `git lg` | (graph log) | Pretty graph log of all branches |
| `git glog` | (pretty format) | Colored graph log |
| `git pf` | `push --force-with-lease` | Safe force push |
| `git cleanup` | (script) | Delete merged branches |
| `git gone` | (script) | Delete branches with deleted remote |
| `git stash-all` | `stash save --include-untracked` | Stash including untracked files |
| `git undo` | `reset --soft HEAD^` | Undo last commit (keep changes) |
| `git branches` | (script) | List branches by recent activity |

## Useful Git Commands

### Undo Last Commit (Keep Changes)

```bash
git undo
# Changes are now unstaged but preserved
```

### Safe Force Push

```bash
git pf
# Only force-pushes if no one else has pushed
```

### Clean Up Merged Branches

```bash
git cleanup
# Deletes local branches already merged to master
```

### Delete Branches with Gone Remotes

```bash
git gone
# Deletes local branches whose remote was deleted
```

### Pretty Log

```bash
git lg
# Shows colored graph of all branches

git glog
# Similar with more details
```

### List Branches by Activity

```bash
git branches
# Shows branches sorted by last commit date
```

## Git Settings

### Pull Behavior

```ini
[pull]
    rebase = true
```

Always rebase when pulling (keeps history linear).

### Push Behavior

```ini
[push]
    autoSetupRemote = true
```

Automatically set upstream when pushing new branches.

### Fetch Behavior

```ini
[fetch]
    prune = true
```

Automatically remove deleted remote branches on fetch.

### Diff Algorithm

```ini
[diff]
    algorithm = histogram
    colorMoved = plain
```

Uses histogram algorithm (better for refactoring) and highlights moved lines.

### Commit Settings

```ini
[commit]
    verbose = true
```

Shows diff in commit message editor.

### Merge/Rebase Settings

```ini
[rerere]
    enabled = true
    autoupdate = true

[merge]
    conflictstyle = diff3

[rebase]
    autoStash = true
    autosquash = true
```

- **rerere**: Remembers conflict resolutions
- **diff3**: Shows original in merge conflicts
- **autoStash**: Stashes changes before rebase
- **autosquash**: Honors fixup!/squash! prefixes

### Branch Sorting

```ini
[branch]
    sort = -committerdate
```

Shows most recently used branches first.

### Help Autocorrect

```ini
[help]
    autocorrect = 1
```

Runs suggested command after typo (e.g., `git stauts` runs `git status`).

## Local Git Configuration

Add machine-specific settings to `~/.local/dotfiles/gitconfig.local`:

```ini
# User info
[user]
    name = Your Name
    email = your.email@example.com

# GPG signing (optional)
[user]
    signingkey = YOUR_KEY_ID

[commit]
    gpgsign = true

# Work-specific settings
[url "git@github-work:"]
    insteadOf = git@github.com:work-org/
```

## GPG Commit Signing

To sign your commits:

1. Generate a GPG key:
   ```bash
   gpg --full-generate-key
   ```

2. Get your key ID:
   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

3. Add to `~/.local/dotfiles/gitconfig.local`:
   ```ini
   [user]
       signingkey = YOUR_KEY_ID
   [commit]
       gpgsign = true
   ```

4. Add your public key to GitHub under Settings > SSH and GPG keys.
