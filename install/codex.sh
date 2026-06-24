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

# Profile configs: copy, not symlink, matching config.toml behavior
for profile_config in "$DOTFILES_DIR/codex/"*.config.toml; do
    [[ -f "$profile_config" ]] || continue
    profile_name="$(basename "$profile_config")"
    profile_dest="$HOME/.codex/$profile_name"

    if [[ ! -f "$profile_dest" ]]; then
        cp "$profile_config" "$profile_dest"
        info "Copied codex profile config to ~/.codex/$profile_name"
    else
        info "Codex profile config already exists at ~/.codex/$profile_name"
    fi
done

# Migrate deprecated hook feature flags while preserving native hook support.
# Keep MCP, skills, prompts, AGENTS.md, and non-OMX hooks intact.
if [[ -f "$HOME/.codex/config.toml" ]]; then
    perl -0pi -e 's/^(\s*)codex_hooks(\s*=\s*true\s*)$/${1}hooks${2}/mg' "$HOME/.codex/config.toml"

    # Default Codex to yolo mode for existing copied configs.
    perl -0pi -e '
        if (!/^sandbox_mode\s*=/m) { s/\A/sandbox_mode = "danger-full-access"\n/ }
        else { s/^sandbox_mode\s*=.*$/sandbox_mode = "danger-full-access"/mg }
        if (!/^approval_policy\s*=/m) { s/\A/approval_policy = "never"\n/ }
        else { s/^approval_policy\s*=.*$/approval_policy = "never"/mg }
        s/^(\s*)guardian_approval\s*=\s*true\s*$/${1}guardian_approval = false/mg;
    ' "$HOME/.codex/config.toml"

    # Prefer ~/.codex/hooks.json over inline global hooks for this layer.
    # This removes the known codebase-memory hook block that triggers Codex's
    # dual-representation warning while preserving hooks.json.
    if [[ -f "$HOME/.codex/hooks.json" ]]; then
        perl -0pi -e 's/\n?# >>> codebase-memory-mcp SessionStart >>>.*?# <<< codebase-memory-mcp SessionStart <<<\n?/\n/sg' "$HOME/.codex/config.toml"
        perl -0pi -e 's/\n?\[hooks\.state\."[^"]*config\.toml:[^"]*"\]\n(?:[^\[]*?)(?=\n\[|\z)/\n/g; s/\n?\[hooks\.state\]\n\s*(?=\[|\z)/\n/g' "$HOME/.codex/config.toml"
    fi
fi

for profile_config in "$HOME/.codex/"*.config.toml; do
    [[ -f "$profile_config" ]] || continue

    case "$(basename "$profile_config")" in
        dev.config.toml|quick.config.toml|research.config.toml)
            perl -0pi -e '
                if (!/^sandbox_mode\s*=/m) { s/\A/sandbox_mode = "danger-full-access"\n/ }
                else { s/^sandbox_mode\s*=.*$/sandbox_mode = "danger-full-access"/mg }
                if (!/^approval_policy\s*=/m) { s/\A/approval_policy = "never"\n/ }
                else { s/^approval_policy\s*=.*$/approval_policy = "never"/mg }
                s/^(\s*)guardian_approval\s*=\s*true\s*$/${1}guardian_approval = false/mg;
            ' "$profile_config"
            ;;
    esac

    perl -0pi -e 's/\n?\[hooks\.state\."[^"]*hooks\.json:[^"]*"\]\n(?:[^\[]*?)(?=\n\[|\z)/\n/g; s/\n?\[hooks\.state\]\n\s*(?=\[|\z)/\n/g' "$profile_config"
done

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

# AGENTS.md: symlink for global instructions
create_symlink "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Skills: symlink each skill directory from dotfiles into ~/.codex/skills/
if [[ -d "$DOTFILES_DIR/codex/skills" ]]; then
    mkdir -p "$HOME/.codex/skills"
    for skill_dir in "$DOTFILES_DIR/codex/skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        create_symlink "$skill_dir" "$HOME/.codex/skills/$skill_name"
    done
fi
