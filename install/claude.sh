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

# Output styles
if [[ -d "$DOTFILES_DIR/claude/styles" ]]; then
    mkdir -p "$HOME/.claude/output-styles"
    for style in "$DOTFILES_DIR/claude/styles/"*.md; do
        [[ -f "$style" ]] || continue
        create_symlink "$style" "$HOME/.claude/output-styles/$(basename "$style")"
    done
fi

# Retired hooks: remove stale symlinks and settings.json registrations.
# clarify-long-prompt, optimization-hint, and count-tools pushed current models
# toward confirmation stops and per-turn noise.
retired_hooks=(clarify-long-prompt.sh optimization-hint.sh count-tools.sh)
for name in "${retired_hooks[@]}"; do
    dest="$HOME/.claude/hooks/$name"
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$DOTFILES_DIR/claude/hooks/$name" ]]; then
        rm -f "$dest"
        info "Removed retired hook symlink: $name"
    fi
done
settings="$HOME/.claude/settings.json"
if [[ -f "$settings" ]] && command -v jq &>/dev/null \
    && jq -e '[.hooks // {} | .[]? | .[]? | .hooks[]? | .command // ""
        | select(test("clarify-long-prompt\\.sh|optimization-hint\\.sh|count-tools\\.sh"))] | length > 0' "$settings" &>/dev/null; then
    jq '.hooks |= with_entries(
            .value |= (map(.hooks |= map(select((.command // "")
                | test("clarify-long-prompt\\.sh|optimization-hint\\.sh|count-tools\\.sh") | not)))
                | map(select((.hooks | length) > 0)))
        | select((.value | length) > 0))' \
        "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
    info "Unregistered retired hooks from settings.json"
fi

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
            || ! jq -e '.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command | contains("mise-environment.sh"))' "$settings" &>/dev/null; then
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

        # SessionStart: persist mise shims for Claude's non-interactive Bash tools
        if ! jq -e '.hooks.SessionStart // [] | .[] | .hooks[]? | select(.command | contains("mise-environment.sh"))' "$settings" &>/dev/null; then
            jq --arg cmd "$HOME/.claude/hooks/mise-environment.sh" \
                '.hooks.SessionStart = (.hooks.SessionStart // []) + [{"matcher":"startup|resume|clear|compact","hooks":[{"type":"command","command":$cmd,"timeout":5}]}]' \
                "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
            info "Registered hook: mise-environment.sh (SessionStart)"
        fi
    else
        warn "jq not found — hooks symlinked but not registered in settings.json"
    fi
fi

# Claude Code settings
# Policy: stay on Claude Code defaults so new models and features are picked up.
#   - Main model is the "opus" alias, so it follows new Opus releases.
#   - Advisor is pinned to claude-fable-5-2 (consulted when choosing an approach,
#     on recurring errors, and before declaring work done). Needs Claude Code
#     v2.1.321+ and stays off if CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC is set.
#   - No effort env var: CLAUDE_CODE_EFFORT_LEVEL overrides /effort and per-model
#     modelSettings. Use /effort, which saves a level per model.
#   - No context or compaction env vars: current models default to the 1M window
#     and CLAUDE_CODE_AUTO_COMPACT_WINDOW overrides /autocompact.
# Values an earlier version of this installer wrote are removed below, but only
# when they still hold that exact value, so deliberate local changes survive.
if command -v jq &>/dev/null; then
    settings="$HOME/.claude/settings.json"
    legacy_env='{
        "CLAUDE_CODE_EFFORT_LEVEL": "xhigh",
        "CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING": "1",
        "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1",
        "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "200000",
        "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
        "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY": "6",
        "ENABLE_LSP_TOOL": "1"
    }'
    already_configured=false
    if [[ -f "$settings" ]] && jq -e --argjson legacy "$legacy_env" '
            ([(.env // {}) | to_entries[] | select($legacy[.key] == .value)] | length == 0)
            and .model == "opus"
            and .advisorModel == "claude-fable-5-2"
            and .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS == "1"
            and (.attribution | type == "object" and has("sessionUrl"))' "$settings" &>/dev/null; then
        already_configured=true
    fi

    if $already_configured; then
        info "Claude Code settings already configured"
    elif ask_yes_no "Apply recommended Claude Code settings (Opus with Fable 5.2 advisor, remove outdated env overrides, enable agent teams, no commit attribution)?"; then
        [[ -f "$settings" ]] || echo '{}' > "$settings"
        jq --argjson legacy "$legacy_env" '
            .env = ((.env // {}) | with_entries(select($legacy[.key] != .value)))
            | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
            | .model = "opus"
            | .advisorModel = "claude-fable-5-2"
            | .attribution = ((.attribution // {}) | if type == "object" then . else {} end
                | .commit //= "" | .pr //= ""
                | if has("sessionUrl") then . else .sessionUrl = false end)' \
            "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
        info "Claude Code settings applied"
    fi
else
    warn "jq not found — skipping Claude Code settings"
fi
