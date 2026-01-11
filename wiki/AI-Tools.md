# AI Tools

Configuration for AI coding assistants, defined in `zsh/ai`.

## Claude Code

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cly` | `claude --dangerously-skip-permissions` | Run without permission prompts |

### Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `ENABLE_BACKGROUND_TASKS` | `1` | Enable background task execution |
| `FORCE_AUTO_BACKGROUND_TASKS` | `1` | Auto-run eligible tasks in background |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | `1` | Keep bash in project directory |

### Usage

```bash
# Normal usage (with permission prompts)
claude

# Skip permissions for trusted projects
cly
```

### When to Use `cly`

Use `cly` (skip permissions) when:
- Working on personal/trusted projects
- Running repetitive tasks
- You trust the operations being performed

Use regular `claude` when:
- Working with unfamiliar codebases
- Running operations that could be destructive
- You want to review each action

## Local AI Configuration

Add machine-specific AI settings to `~/.local/dotfiles/ai.local`:

```bash
# API keys (keep private!)
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."

# Custom model preferences
export CLAUDE_MODEL="claude-3-opus-20240229"

# Project-specific aliases
alias ai-review='claude "Review this code for bugs and improvements"'
alias ai-test='claude "Write tests for the selected code"'
```

## Other AI Tools

### GitHub Copilot

If using Copilot with Neovim, it's configured separately in your nvim config.

### Aider

If using [Aider](https://aider.chat/):

```bash
# Add to ~/.local/dotfiles/ai.local
export AIDER_MODEL="claude-3-opus-20240229"
alias aider='aider --no-auto-commits'
```

### Continue.dev

For VS Code/Cursor Continue extension, configuration goes in:
```
~/.continue/config.json
```

## Tips

### Project-Specific Instructions

Create a `CLAUDE.md` file in your project root with:
- Project overview
- Code style guidelines
- Important patterns
- Commands to run

Claude Code will read this automatically.

### Memory Files

Claude Code can remember context across sessions. Use:
- `CLAUDE.md` for project instructions
- Comments in code for inline guidance

### Effective Prompts

```bash
# Be specific
claude "Add error handling to the fetchUser function in src/api.ts"

# Reference files
claude "Update the styles in components/Button.tsx to match Header.tsx"

# Ask for explanations
claude "Explain how the authentication flow works in this codebase"
```
