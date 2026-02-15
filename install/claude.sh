#!/usr/bin/env bash
#
# Claude Code configuration
#

header "Claude Code"

mkdir -p "$HOME/.claude"

# CLAUDE.md (global instructions)
create_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Hooks (optional)
if [[ -d "$DOTFILES_DIR/claude/hooks" ]] && ask_yes_no "Install Claude Code hooks?"; then
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
    else
        warn "jq not found — hooks symlinked but not registered in settings.json"
    fi
fi
