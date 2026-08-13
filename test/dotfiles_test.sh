#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIRS=()
TEST_TEMP_DIR=""

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

make_temp_dir() {
    TEST_TEMP_DIR="$(mktemp -d)"
    TEMP_DIRS+=("$TEST_TEMP_DIR")
}

cleanup() {
    local dir
    for dir in "${TEMP_DIRS[@]}"; do
        [[ ! -d "$dir" ]] || rm -rf "$dir"
    done
}

run_check() {
    local name="$1"
    shift
    "$@"
    echo "ok - $name"
}

check_qmd_skill_install() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local invocation="$sandbox/qmd-invocation"

    mkdir -p "$fake_bin" "$sandbox/dotfiles"
    cat > "$fake_bin/qmd" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$QMD_INVOCATION"
SH
    chmod +x "$fake_bin/qmd"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$sandbox/dotfiles" QMD_INVOCATION="$invocation" \
        "$ROOT_DIR/install/skills.sh" >/dev/null

    [[ "$(<"$invocation")" == "skill install --global --force" ]] \
        || fail "skills installer did not refresh the global qmd skill"
}

check_omp_install_selection() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local invocation="$sandbox/omp-invocation"

    mkdir -p "$fake_bin"
    cat > "$fake_bin/gum" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == "choose" ]]; then
    printf '%s\n' "OMP (Oh My Pi)"
fi
SH
    chmod +x "$fake_bin/gum"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" OMP_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() {
                printf "%s %s\n" "$@" > "$OMP_INVOCATION"
            }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "sh https://omp.sh/install" ]] \
        || fail "OMP was not installed from the gum selection"

    rm -f "$invocation"
    printf '5\n' | HOME="$sandbox/home" PATH="/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" OMP_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() {
                printf "%s %s\n" "$@" > "$OMP_INVOCATION"
            }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "sh https://omp.sh/install" ]] \
        || fail "numeric AI tool selection did not install OMP"

    rm -f "$invocation"
    printf '10\n' | HOME="$sandbox/home" PATH="/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" OMP_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() {
                printf "%s %s\n" "$@" > "$OMP_INVOCATION"
            }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "bash https://code.kimi.com/install.sh" ]] \
        || fail "numeric AI tool selection did not support two-digit options"
}


check_codex_configuration() {
    ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json
import os
from pathlib import Path
import tomllib


root = Path(os.environ["ROOT_DIR"])
config = tomllib.loads((root / "codex/config.toml").read_text())

expected_defaults = {
    "model": "gpt-5.6-sol",
    "model_reasoning_effort": "high",
    "service_tier": "default",
}
for key, expected in expected_defaults.items():
    actual = config.get(key)
    assert actual == expected, f"codex config {key}: expected {expected!r}, got {actual!r}"

assert "model_catalog_json" not in config, "Codex model catalog override must stay machine-local"
agent_defaults = config["agents"]
assert agent_defaults.get("default_subagent_model") == "gpt-5.6-terra"
assert agent_defaults.get("default_subagent_reasoning_effort") == "high"
multi_agent_v2 = config["features"]["multi_agent_v2"]
assert multi_agent_v2.get("hide_spawn_agent_metadata") is False
assert multi_agent_v2.get("tool_namespace") == "agents"
assert "enabled" not in multi_agent_v2, "Sol selects multi-agent v2 through model metadata"

expected_agents = {
    "deep_worker": {
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "high",
        "service_tier": "default",
        "sandbox_mode": "workspace-write",
    },
    "fast_scan": {
        "model": "gpt-5.6-terra",
        "model_reasoning_effort": "medium",
        "service_tier": "default",
        "sandbox_mode": "read-only",
    },
    "routine_worker": {
        "model": "gpt-5.6-terra",
        "model_reasoning_effort": "high",
        "service_tier": "default",
        "sandbox_mode": "workspace-write",
    },
}
agent_names = set()
for path in sorted((root / "codex/agents").glob("*.toml")):
    agent = tomllib.loads(path.read_text())
    name = agent.get("name")
    assert name == path.stem, f"{path}: agent name must match the filename"
    assert name not in agent_names, f"duplicate Codex agent name: {name}"
    assert agent.get("description"), f"{path}: missing description"
    assert agent.get("developer_instructions", "").strip(), f"{path}: missing instructions"
    expected = expected_agents.get(name)
    assert expected is not None, f"unexpected dotfiles-owned Codex agent: {name}"
    for key, expected_value in expected.items():
        actual = agent.get(key)
        assert actual == expected_value, (
            f"{path}: {key} expected {expected_value!r}, got {actual!r}"
        )
    agent_names.add(name)

assert agent_names == set(expected_agents), "dotfiles-owned Codex agent inventory changed"

hooks = json.loads((root / "codex/hooks.json").read_text())
pre_tool_hooks = hooks.get("hooks", {}).get("PreToolUse", [])
commands = [
    hook
    for group in pre_tool_hooks
    for hook in group.get("hooks", [])
    if hook.get("type") == "command"
]
assert any("block-destructive-commands.py" in hook.get("command", "") for hook in commands), (
    "Codex PreToolUse must register the destructive-command hook"
)
PY
}

check_codex_installer_migration() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local live_config="$sandbox/home/.codex/config.toml"

    mkdir -p "$fake_bin" "$(dirname "$live_config")"
    : > "$fake_bin/codex"
    chmod +x "$fake_bin/codex"
    printf '%s\n' \
        'model = "gpt-5.6-sol"' \
        '[features.multi_agent_v2]' \
        'enabled = true' \
        'hide_spawn_agent_metadata = false' \
        'tool_namespace = "agents"' \
        '[mcp_servers.example]' \
        'enabled = true' \
        > "$live_config"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" bash -c '
        set -Eeuo pipefail
        header() { :; }
        info() { :; }
        warn() { :; }
        create_symlink() {
            mkdir -p "$(dirname "$2")"
            ln -s "$1" "$2"
        }
        DOTFILES_DIR="$1"
        source "$1/install/codex.sh"
    ' _ "$ROOT_DIR"

    LIVE_CONFIG="$live_config" python3 - <<'PY'
import os
from pathlib import Path
import tomllib


config = tomllib.loads(Path(os.environ["LIVE_CONFIG"]).read_text())
assert "enabled" not in config["features"]["multi_agent_v2"]
assert config["mcp_servers"]["example"]["enabled"] is True
PY
}

check_install_helpers() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local artifact="$sandbox/artifact.txt"
    local checksums="$sandbox/checksums.txt"
    local bad_checksums="$sandbox/bad-checksums.txt"
    local source_file="$sandbox/source.txt"
    local destination="$sandbox/destination.txt"
    local digest

    mkdir -p "$sandbox/home"
    printf 'verified artifact\n' > "$artifact"
    digest="$(python3 -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$artifact")"
    printf '%s  artifact.txt\n' "$digest" > "$checksums"
    printf '%064d  artifact.txt\n' 0 > "$bad_checksums"
    printf 'new contents\n' > "$source_file"
    printf 'old contents\n' > "$destination"

    HOME="$sandbox/home" PATH="/usr/bin:/bin" bash -c '
        set -Eeuo pipefail
        source "$1"

        [[ "$(normalize_release_arch aarch64)" == "arm64" ]]
        [[ "$(normalize_release_arch arm64)" == "arm64" ]]
        [[ "$(normalize_release_arch amd64)" == "x86_64" ]]
        [[ "$(normalize_release_arch x86_64)" == "x86_64" ]]
        ! normalize_release_arch sparc >/dev/null 2>&1

        verify_sha256_checksum "$2" "$3"
        ! verify_sha256_checksum "$4" "$3" >/dev/null 2>&1

        create_symlink "$5" "$6" >/dev/null
        [[ -L "$6" ]]
        [[ "$(readlink "$6")" == "$5" ]]
        compgen -G "${6}.backup.*" >/dev/null
    ' _ "$ROOT_DIR/install/lib.sh" "$checksums" "$artifact" "$bad_checksums" \
        "$source_file" "$destination"
}

check_skills_help() {
    make_temp_dir
    local output
    output="$(HOME="$TEST_TEMP_DIR" "$ROOT_DIR/install/skills.sh" --help)"
    [[ "$output" == Usage:\ ./install/skills.sh* ]] \
        || fail "install/skills.sh --help is not usable standalone"
}

check_zsh_path_setup() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"

    mkdir -p "$sandbox/.local/share/mise/shims"
    HOME="$sandbox" PATH="/usr/bin:/bin:$sandbox/.local/share/mise/shims" zsh -f -c '
        expected="$2/.local/share/mise/shims:/usr/bin:/bin"
        source "$1"
        source "$1"
        [[ "$PATH" == "$expected" ]] || exit 1

        DOTFILES_DIR="$3"
        source "$4"
        [[ "$PATH" == "$expected" ]]
    ' _ "$ROOT_DIR/zsh/zshenv" "$sandbox" "$ROOT_DIR" "$ROOT_DIR/zsh/zprofile" \
        || fail "zshenv/zprofile did not preserve one mise shim entry"
}

check_claude_environment_hook() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local environment_file="$sandbox/claude-env"
    local expected_line="export PATH=\"\$HOME/.local/share/mise/shims:\$PATH\""

    mkdir -p "$sandbox/.local/share/mise/shims"
    HOME="$sandbox" CLAUDE_ENV_FILE="$environment_file" \
        "$ROOT_DIR/claude/hooks/mise-environment.sh"
    HOME="$sandbox" CLAUDE_ENV_FILE="$environment_file" \
        "$ROOT_DIR/claude/hooks/mise-environment.sh"

    [[ "$(wc -l < "$environment_file" | tr -d ' ')" == "1" ]] \
        || fail "Claude mise hook wrote duplicate exports"
    [[ "$(<"$environment_file")" == "$expected_line" ]] \
        || fail "Claude mise hook wrote an unexpected environment export"
}

check_cdx_wrapper() {
    make_temp_dir
    HOME="$TEST_TEMP_DIR" zsh -f -c '
        codex() { captured=("$@"); }
        source "$1"

        cdx exec --json
        [[ "${(F)captured}" == $'\''--dangerously-bypass-approvals-and-sandbox\n--search\nexec\n--json'\'' ]] || exit 1

        cdx -r
        [[ "${(F)captured}" == $'\''--dangerously-bypass-approvals-and-sandbox\n--search\nresume\n--last'\'' ]] || exit 1

        cdx --resume session-123
        [[ "${(F)captured}" == $'\''--dangerously-bypass-approvals-and-sandbox\n--search\nresume\nsession-123'\'' ]]
    ' _ "$ROOT_DIR/zsh/ai-tools/codex" || fail "cdx argument forwarding changed"
}

check_codex_hook() {
    [[ -x "$ROOT_DIR/codex/hooks/block-destructive-commands.py" ]] \
        || fail "Codex destructive-command hook is not executable"
    python3 "$ROOT_DIR/test/test_codex_hook.py"
}

trap cleanup EXIT

run_check "OMP installer selection" check_omp_install_selection
run_check "qmd skill install" check_qmd_skill_install
run_check "Codex configuration" check_codex_configuration
run_check "Codex installer migration" check_codex_installer_migration
run_check "installer helpers" check_install_helpers
run_check "skills installer help" check_skills_help
run_check "zsh PATH setup" check_zsh_path_setup
run_check "Claude environment hook" check_claude_environment_hook
run_check "cdx argument forwarding" check_cdx_wrapper
run_check "Codex destructive-command hook" check_codex_hook

echo "dotfiles behavior checks passed"
