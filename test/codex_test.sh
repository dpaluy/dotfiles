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
    "model_reasoning_effort": "medium",
    "service_tier": "default",
}
for key, expected in expected_defaults.items():
    actual = config.get(key)
    assert actual == expected, f"codex config {key}: expected {expected!r}, got {actual!r}"

assert config.get("sandbox_mode") == "workspace-write", (
    "codex config sandbox_mode must be workspace-write"
)
assert config.get("approval_policy") == "on-request", (
    "codex config approval_policy must be on-request"
)
assert "model_catalog_json" not in config, "Codex model catalog override must stay machine-local"
agent_defaults = config["agents"]
assert agent_defaults.get("default_subagent_model") == "gpt-5.6-sol"
assert "default_subagent_reasoning_effort" not in agent_defaults, (
    "default_subagent_reasoning_effort was removed from the codex config"
)
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
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "low",
        "service_tier": "default",
        "sandbox_mode": "read-only",
    },
    "routine_worker": {
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "medium",
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
        'sandbox_mode = "danger-full-access"' \
        'approval_policy = "never"' \
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
assert config["sandbox_mode"] == "workspace-write"
assert config["approval_policy"] == "on-request"
PY
}

check_cdx_wrapper() {
    make_temp_dir
    HOME="$TEST_TEMP_DIR" zsh -f -c '
        codex() { captured=("$@"); }
        source "$1"

        cdx exec --json
        [[ "${(F)captured}" == $'\''--search\nexec\n--json'\'' ]] || exit 1

        cdx -r
        [[ "${(F)captured}" == $'\''--search\nresume\n--last'\'' ]] || exit 1

        cdx --resume session-123
        [[ "${(F)captured}" == $'\''--search\nresume\nsession-123'\'' ]]
    ' _ "$ROOT_DIR/zsh/ai-tools/codex" || fail "cdx argument forwarding changed"
}

check_codex_hook() {
    [[ -x "$ROOT_DIR/codex/hooks/block-destructive-commands.py" ]] \
        || fail "Codex destructive-command hook is not executable"
    python3 "$ROOT_DIR/test/test_codex_hook.py"
}

trap cleanup EXIT

run_check "Codex configuration" check_codex_configuration
run_check "Codex installer migration" check_codex_installer_migration
run_check "cdx argument forwarding" check_cdx_wrapper
run_check "Codex destructive-command hook" check_codex_hook

echo "codex behavior checks passed"
