#!/usr/bin/env bash
#
# OpenAI Codex configuration
#

header "Codex"

if ! command -v codex &> /dev/null; then
    info "Codex not installed, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.codex"

# config.toml: copy, not symlink - codex doesn't support symlinked config
if [[ ! -f "$HOME/.codex/config.toml" ]]; then
    cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
    info "Copied codex config to ~/.codex/config.toml"
else
    info "Codex config already exists at ~/.codex/config.toml"
fi

# Named profile configs: copy, not symlink, for the same Codex limitation.
for profile_config in "$DOTFILES_DIR/codex/"*.config.toml; do
    [[ -f "$profile_config" ]] || continue
    profile_name="$(basename "$profile_config")"
    if [[ ! -f "$HOME/.codex/$profile_name" ]]; then
        cp "$profile_config" "$HOME/.codex/$profile_name"
        info "Copied Codex profile to ~/.codex/$profile_name"
    fi
done

# Migrate deprecated hook feature flags while preserving native hook support.
# Keep MCP, skills, prompts, AGENTS.md, and non-OMX hooks intact.
if [[ -f "$HOME/.codex/config.toml" ]]; then
    perl -0pi -e 's/^(\s*)codex_hooks(\s*=\s*true\s*)$/${1}hooks${2}/mg' "$HOME/.codex/config.toml"

    # Sol and Terra select multi-agent v2 through model metadata. Remove the
    # obsolete table-local override without touching other enabled settings.
    perl -0pi -e '
        s{(^\[features\.multi_agent_v2\][ \t]*\n)((?:[ \t]*(?:\#.*)?\n)*)[ \t]*enabled[ \t]*=[ \t]*(?:true|false)[ \t]*\n}{$1$2}m;
    ' "$HOME/.codex/config.toml"

    # Use a writable project sandbox and ask before work needs broader access.
    perl -0pi -e '
        if (!/^sandbox_mode\s*=/m) { s/\A/sandbox_mode = "workspace-write"\n/ }
        else { s/^sandbox_mode\s*=.*$/sandbox_mode = "workspace-write"/mg }
        if (!/^approval_policy\s*=/m) { s/\A/approval_policy = "on-request"\n/ }
        else { s/^approval_policy\s*=.*$/approval_policy = "on-request"/mg }
    ' "$HOME/.codex/config.toml"

    # Prefer ~/.codex/hooks.json over inline global hooks for this layer.
    # This removes the known codebase-memory hook block that triggers Codex's
    # dual-representation warning while preserving hooks.json.
    if [[ -f "$HOME/.codex/hooks.json" ]]; then
        perl -0pi -e 's/\n?# >>> codebase-memory-mcp SessionStart >>>.*?# <<< codebase-memory-mcp SessionStart <<<\n?/\n/sg' "$HOME/.codex/config.toml"
        perl -0pi -e 's/\n?\[hooks\.state\."[^"]*config\.toml:[^"]*"\]\n(?:[^\[]*?)(?=\n\[|\z)/\n/g; s/\n?\[hooks\.state\]\n\s*(?=\[|\z)/\n/g' "$HOME/.codex/config.toml"
    fi
fi

if [[ -f "$HOME/.codex/hooks.json" ]]; then
    if command -v jq &>/dev/null; then
        codex_hooks_tmp="$(mktemp)"
        if jq '
            def omx_hook:
                ((.command // "") | contains("codex-native-hook.js"));

            .hooks |= (
                with_entries(
                    .value |= (
                        map(.hooks = ((.hooks // []) | map(select(omx_hook | not))))
                        | map(select(((.hooks // []) | length) > 0))
                    )
                )
                | with_entries(select((.value | length) > 0))
            )
            | if ((.hooks // {}) | length) == 0 then del(.hooks) else . end
        ' "$HOME/.codex/hooks.json" > "$codex_hooks_tmp"; then
            command mv -f "$codex_hooks_tmp" "$HOME/.codex/hooks.json"
            if [[ ! -s "$HOME/.codex/hooks.json" || "$(jq -r 'keys | length' "$HOME/.codex/hooks.json")" == "0" ]]; then
                command rm -f "$HOME/.codex/hooks.json"
            fi
        else
            command rm -f "$codex_hooks_tmp"
            warn "Failed to clean OMX hooks from ~/.codex/hooks.json"
        fi
    else
        warn "jq not found, leaving ~/.codex/hooks.json unchanged"
    fi
fi

# Hooks: symlink scripts and merge portable definitions without replacing
# machine-local or plugin-managed hooks.
if [[ -d "$DOTFILES_DIR/codex/hooks" ]]; then
    mkdir -p "$HOME/.codex/hooks"
    for hook_script in "$DOTFILES_DIR/codex/hooks/"*; do
        [[ -f "$hook_script" ]] || continue
        hook_name="$(basename "$hook_script")"
        create_symlink "$hook_script" "$HOME/.codex/hooks/$hook_name"
    done
fi

if [[ -f "$DOTFILES_DIR/codex/hooks.json" ]]; then
    if [[ ! -f "$HOME/.codex/hooks.json" ]]; then
        cp "$DOTFILES_DIR/codex/hooks.json" "$HOME/.codex/hooks.json"
        info "Copied Codex hooks to ~/.codex/hooks.json"
    elif command -v jq &>/dev/null; then
        codex_hooks_tmp="$(mktemp)"
        if jq --slurpfile managed "$DOTFILES_DIR/codex/hooks.json" '
            ($managed[0].hooks.PreToolUse[0]) as $managed_group
            | def managed_hook:
                ((.command // "") | contains("block-destructive-commands.py"));

            .hooks //= {}
            | .hooks.PreToolUse = (
                ((.hooks.PreToolUse // [])
                    | map(.hooks = ((.hooks // []) | map(select(managed_hook | not))))
                    | map(select(((.hooks // []) | length) > 0)))
                + [$managed_group]
            )
        ' "$HOME/.codex/hooks.json" > "$codex_hooks_tmp"; then
            command mv -f "$codex_hooks_tmp" "$HOME/.codex/hooks.json"
            info "Merged Codex hooks into ~/.codex/hooks.json"
        else
            command rm -f "$codex_hooks_tmp"
            warn "Failed to merge dotfiles hooks into ~/.codex/hooks.json"
        fi
    else
        warn "jq not found, leaving existing ~/.codex/hooks.json unchanged"
    fi
fi

# AGENTS.md: symlink for global instructions
create_symlink "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Agents: symlink each custom agent config from dotfiles into ~/.codex/agents/
if [[ -d "$DOTFILES_DIR/codex/agents" ]]; then
    mkdir -p "$HOME/.codex/agents"
    for agent_config in "$DOTFILES_DIR/codex/agents/"*.toml; do
        [[ -f "$agent_config" ]] || continue
        agent_name="$(basename "$agent_config")"
        create_symlink "$agent_config" "$HOME/.codex/agents/$agent_name"
    done
fi

# Skills: symlink Codex-specific skills into the Agent Skills standard path.
if [[ -d "$DOTFILES_DIR/codex/skills" ]]; then
    mkdir -p "$HOME/.agents/skills"
    for skill_dir in "$DOTFILES_DIR/codex/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_name="$(basename "$skill_dir")"
        legacy_skill="$HOME/.codex/skills/$skill_name"
        if [[ -L "$legacy_skill" ]]; then
            legacy_target="$(readlink "$legacy_skill")"
            if [[ "${legacy_target%/}" == "${skill_dir%/}" ]]; then
                rm -f "$legacy_skill"
                info "Removed legacy Codex skill link at ~/.codex/skills/$skill_name"
            fi
        fi
        create_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
    done
fi
