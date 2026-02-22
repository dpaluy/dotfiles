#!/usr/bin/env bash
#
# Claude Code configuration
#

header "Claude Code"

if ! command -v claude &> /dev/null; then
    info "Claude Code not installed, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.claude"

# CLAUDE.md (global instructions)
create_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Hooks (optional)
hooks_installed=true
if [[ -d "$DOTFILES_DIR/claude/hooks" ]]; then
    # Check symlinks
    for hook in "$DOTFILES_DIR/claude/hooks/"*.sh; do
        [[ -f "$hook" ]] || continue
        dest="$HOME/.claude/hooks/$(basename "$hook")"
        if [[ ! -L "$dest" ]] || [[ "$(readlink "$dest")" != "$hook" ]]; then
            hooks_installed=false
            break
        fi
    done
    # Check settings.json registration
    if $hooks_installed && command -v jq &>/dev/null; then
        settings="$HOME/.claude/settings.json"
        if [[ ! -f "$settings" ]] \
            || ! jq -e '.hooks.PostToolUse // [] | .[] | .hooks[]? | select(.command | contains("count-tools.sh"))' "$settings" &>/dev/null \
            || ! jq -e '.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | select(.command | contains("optimization-hint.sh"))' "$settings" &>/dev/null \
            || ! jq -e '.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | select(.command | contains("clarify-long-prompt.sh"))' "$settings" &>/dev/null; then
            hooks_installed=false
        fi
    fi
fi

if [[ -d "$DOTFILES_DIR/claude/hooks" ]] && $hooks_installed; then
    info "Claude Code hooks already installed"
elif [[ -d "$DOTFILES_DIR/claude/hooks" ]] && ask_yes_no "Install Claude Code hooks?"; then
    mkdir -p "$HOME/.claude/hooks"
    for hook in "$DOTFILES_DIR/claude/hooks/"*.sh; do
        [[ -f "$hook" ]] && create_symlink "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
    done

    # Register hooks in settings.json
    settings="$HOME/.claude/settings.json"
    if command -v jq &> /dev/null; then
        [[ -f "$settings" ]] || echo '{}' > "$settings"

        # PostToolUse: count tool calls per turn
        if ! jq -e '.hooks.PostToolUse // [] | .[] | .hooks[]? | select(.command | contains("count-tools.sh"))' "$settings" &>/dev/null; then
            jq --arg cmd "$HOME/.claude/hooks/count-tools.sh" \
                '.hooks.PostToolUse = (.hooks.PostToolUse // []) + [{"matcher":"","hooks":[{"type":"command","command":$cmd,"timeout":500}]}]' \
                "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
            info "Registered hook: count-tools.sh (PostToolUse)"
        fi

        # UserPromptSubmit: optimization hint when previous turn had 8+ tool calls
        if ! jq -e '.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | select(.command | contains("optimization-hint.sh"))' "$settings" &>/dev/null; then
            jq --arg cmd "$HOME/.claude/hooks/optimization-hint.sh" \
                '.hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + [{"matcher":"","hooks":[{"type":"command","command":$cmd,"timeout":1000}]}]' \
                "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
            info "Registered hook: optimization-hint.sh (UserPromptSubmit)"
        fi

        # UserPromptSubmit: confirm intent on long prompts (>50 words)
        if ! jq -e '.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | select(.command | contains("clarify-long-prompt.sh"))' "$settings" &>/dev/null; then
            jq --arg cmd "$HOME/.claude/hooks/clarify-long-prompt.sh" \
                '.hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + [{"matcher":"","hooks":[{"type":"command","command":$cmd,"timeout":1000}]}]' \
                "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
            info "Registered hook: clarify-long-prompt.sh (UserPromptSubmit)"
        fi
    else
        warn "jq not found — hooks symlinked but not registered in settings.json"
    fi
fi
