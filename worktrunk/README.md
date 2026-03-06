# Worktrunk Configuration

[Worktrunk](https://worktrunk.dev) manages git worktrees for parallel AI agent workflows. The config at `config.toml` is symlinked to `~/.config/worktrunk/config.toml`.

## Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `wts` | `wt switch` | Switch to existing worktree (interactive picker) |
| `wtc` | `wt switch --create` | Create new worktree + branch |
| `wtl` | `wt list` | List all worktrees with status |
| `wtm` | `wt merge` | Squash, rebase, and merge into target |
| `wtr` | `wt remove` | Remove worktree and delete branch if merged |

## Common Workflows

```bash
# Create a worktree and start working
wtc feature-auth

# Launch Claude Code in a new worktree
wt switch -x claude --create feature-auth -- 'Add user authentication'

# Run multiple agents in parallel
wt switch -x claude --create feature-a -- 'Add search'
wt switch -x claude --create feature-b -- 'Add pagination'

# List all active worktrees
wtl

# Merge current worktree into main (squash + rebase + merge + cleanup)
wtm main

# Remove current worktree
wtr
```

## Configured Hooks

### pre-switch — Auto-fetch

Runs `git fetch` before switching if the last fetch was more than 6 hours ago. Keeps branches up to date without fetching on every switch.

### post-switch — Tmux window rename

Renames the current tmux window to the branch name when switching worktrees. Only runs inside a tmux session.

## Available Hook Types

Hooks are shell commands that run at key points in the worktree lifecycle. Define them in `config.toml` (user-wide) or `.config/wt.toml` (per-project).

| Hook | When | Blocking | Use for |
|------|------|----------|---------|
| `pre-switch` | Before every switch | Yes | Fetching, validation |
| `post-create` | After worktree created | Yes | Installing deps, generating .env |
| `post-start` | After worktree created | No (background) | Dev servers, file watchers, builds |
| `post-switch` | After every switch | No (background) | Tmux titles, notifications |
| `pre-commit` | Before commit during merge | Yes | Linting, formatting |
| `pre-merge` | Before merging to target | Yes | Tests, build verification |
| `post-merge` | After successful merge | Yes | Deployment, notifications |
| `pre-remove` | Before worktree removed | Yes | Archiving artifacts |
| `post-remove` | After worktree removed | No (background) | Killing servers, removing containers |

## Adding Project Hooks

Create `.config/wt.toml` in any repository:

```toml
# Install deps when creating a worktree
[post-create]
deps = "npm ci"
env = "cp .env.example .env"

# Dev server on a unique port per branch
[post-start]
server = "npm run dev -- --port {{ branch | hash_port }}"

# Validation before merge
[pre-commit]
lint = "npm run lint"

[pre-merge]
test = "npm test"
build = "npm run build"

# Cleanup after removing worktree
[post-remove]
kill-server = "lsof -ti :{{ branch | hash_port }} -sTCP:LISTEN | xargs kill 2>/dev/null || true"
```

## Template Variables

Hooks support Jinja2-style template variables:

| Variable | Description |
|----------|-------------|
| `{{ branch }}` | Branch name |
| `{{ repo }}` | Repository directory name |
| `{{ worktree_path }}` | Absolute worktree path |
| `{{ default_branch }}` | Default branch (e.g., main) |
| `{{ target }}` | Target branch (merge hooks only) |
| `{{ branch \| sanitize }}` | Branch with `/` replaced by `-` |
| `{{ branch \| hash_port }}` | Deterministic port 10000-19999 |
| `{{ branch \| sanitize_db }}` | Database-safe identifier |

## Configuration Locations

| File | Scope | Approval |
|------|-------|----------|
| `~/.config/worktrunk/config.toml` | All repositories | Not required |
| `.config/wt.toml` (in repo) | Single repository | Required on first run |

Project hooks require approval when first encountered. Manage with `wt hook approvals`.

## Reference

```bash
wt --help                  # Overview
wt switch --help           # Switch/create worktrees
wt merge --help            # Merge workflow
wt hook --help             # Hook system details
wt config create           # Generate user config template
wt config create --project # Generate project config template
```
