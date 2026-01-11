# Customization

How to add your own settings without modifying version-controlled files.

## The Local Config Pattern

Every public config file has a `.local` counterpart in `~/.local/dotfiles/`:

| Public Config | Local Override |
|---------------|----------------|
| `zsh/aliases` | `~/.local/dotfiles/aliases.local` |
| `zsh/functions` | `~/.local/dotfiles/functions.local` |
| `zsh/exports` | `~/.local/dotfiles/exports.local` |
| `zsh/path` | `~/.local/dotfiles/path.local` |
| `zsh/ai` | `~/.local/dotfiles/ai.local` |
| `zsh/rails` | `~/.local/dotfiles/rails.local` |
| `git/config` | `~/.local/dotfiles/gitconfig.local` |

Local files are:
- **Sourced after** public configs (can override)
- **Not version controlled** (keep secrets safe)
- **Created as templates** by `install.sh`

## Adding Aliases

Edit `~/.local/dotfiles/aliases.local`:

```bash
# Work shortcuts
alias work='cd ~/work/company'
alias vpn='sudo openvpn ~/work/vpn.conf'

# Personal projects
alias blog='cd ~/projects/blog && code .'
alias notes='cd ~/notes && nvim .'

# Override defaults
alias ls='exa --icons'  # Use exa instead of ls
alias cat='bat'         # Use bat instead of cat
```

## Adding Functions

Edit `~/.local/dotfiles/functions.local`:

```bash
# Quick project setup
newproject() {
    mkcd "$1"
    git init
    echo "# $1" > README.md
    echo "node_modules/" > .gitignore
    npm init -y
}

# Work-specific deployment
deploy() {
    local env="${1:-staging}"
    echo "Deploying to $env..."
    kubectl apply -f "k8s/$env/"
}

# Open PR in browser
pr() {
    local url=$(gh pr view --web 2>/dev/null || gh pr create --web)
}
```

## Adding Environment Variables

Edit `~/.local/dotfiles/exports.local`:

```bash
# API keys (KEEP PRIVATE!)
export GITHUB_TOKEN="ghp_..."
export ANTHROPIC_API_KEY="sk-..."
export AWS_PROFILE="personal"

# Work settings
export COMPANY_API_URL="https://api.company.com"
export SLACK_WEBHOOK="https://hooks.slack.com/..."

# Tool preferences
export BAT_THEME="Catppuccin-mocha"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --color=16"
```

## Adding PATH Entries

Edit `~/.local/dotfiles/path.local`:

```bash
# Custom tools
path_prepend "$HOME/.local/custom/bin"

# Work tools
path_prepend "/opt/company/bin"

# Language version managers
path_prepend "$HOME/.rbenv/bin"
path_prepend "$HOME/.nvm/versions/node/v20/bin"
```

## Git Configuration

Edit `~/.local/dotfiles/gitconfig.local`:

```ini
# Identity
[user]
    name = Your Name
    email = your.email@company.com

# GPG signing
[user]
    signingkey = ABC123DEF456

[commit]
    gpgsign = true

# Work GitHub account
[url "git@github-work:"]
    insteadOf = git@github.com:company/
```

## Adding Oh My Zsh Plugins

Edit `~/.local/dotfiles/zshrc.local` (sourced before OMZ):

```bash
# Add more plugins
plugins+=(
    kubectl
    terraform
    aws
)
```

## Overriding Defaults

Local files are sourced after public ones, so you can override:

```bash
# In aliases.local - override the default
alias ls='exa --icons --group-directories-first'

# In exports.local - change default editor
export EDITOR='code --wait'

# In functions.local - replace a function
extract() {
    # Custom implementation using different tools
    atool -x "$1"
}
```

## Tips

### Keep Secrets Safe

Never put secrets in public dotfiles. Use local files for:
- API keys and tokens
- Passwords
- Private URLs
- Work-specific configs

### Backup Local Files

While local files aren't in the dotfiles repo, consider:

```bash
# Private dotfiles repo
cd ~/.local/dotfiles
git init
git remote add origin git@github.com:you/private-dotfiles.git
```

### Test Changes

After editing local files:

```bash
reload
# or
source ~/.zshrc
```

### Check What's Loaded

```bash
# See all aliases
alias | grep myalias

# See all functions
functions | grep myfunction

# See all exports
env | grep MYVAR
```

## Directory Structure

After customization, your setup might look like:

```
~/.local/dotfiles/
├── aliases.local      # Custom aliases
├── functions.local    # Custom functions
├── exports.local      # API keys, tokens
├── path.local         # Custom PATH entries
├── ai.local          # AI tool configs
├── rails.local       # Rails overrides
├── gitconfig.local   # Git identity, signing
└── zshrc.local       # Plugin extensions
```
