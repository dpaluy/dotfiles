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
    "model_reasoning_effort": "xhigh",
    "service_tier": "default",
}
for key, expected in expected_defaults.items():
    actual = config.get(key)
    assert actual == expected, f"codex config {key}: expected {expected!r}, got {actual!r}"

assert "model_catalog_json" not in config, "Codex model catalog override must stay machine-local"
multi_agent_v2 = config["features"]["multi_agent_v2"]
assert multi_agent_v2.get("hide_spawn_agent_metadata") is False
assert multi_agent_v2.get("tool_namespace") == "agents"
assert "enabled" not in multi_agent_v2, "Sol selects multi-agent v2 through model metadata"

agent_names = set()
for path in sorted((root / "codex/agents").glob("*.toml")):
    agent = tomllib.loads(path.read_text())
    name = agent.get("name")
    assert name == path.stem, f"{path}: agent name must match the filename"
    assert name not in agent_names, f"duplicate Codex agent name: {name}"
    assert agent.get("description"), f"{path}: missing description"
    assert agent.get("developer_instructions", "").strip(), f"{path}: missing instructions"
    agent_names.add(name)

fast_scan = tomllib.loads((root / "codex/agents/fast_scan.toml").read_text())
assert fast_scan.get("sandbox_mode") == "read-only", "fast_scan must remain read-only"

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

run_check "Codex configuration" check_codex_configuration
run_check "installer helpers" check_install_helpers
run_check "skills installer help" check_skills_help
run_check "zsh PATH setup" check_zsh_path_setup
run_check "Claude environment hook" check_claude_environment_hook
run_check "cdx argument forwarding" check_cdx_wrapper
run_check "Codex destructive-command hook" check_codex_hook

echo "dotfiles behavior checks passed"
