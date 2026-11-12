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
    mkdir -p "$sandbox/nobin"
    for tool in bash mkdir dirname; do
        ln -s "$(command -v "$tool")" "$sandbox/nobin/$tool"
    done
    printf '5\n' | HOME="$sandbox/home" PATH="$sandbox/nobin" \
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
    printf '10\n' | HOME="$sandbox/home" PATH="$sandbox/nobin" \
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


check_pi_global_install() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local wrapper="$sandbox/home/.local/bin/pi"
    mkdir -p "$fake_bin" "$(dirname "$wrapper")"
    printf '%s\n' '#!/bin/bash' 'package="@earendil-works/pi-coding-agent"' > "$wrapper"
    chmod +x "$wrapper"
    cat > "$fake_bin/gum" <<'SH'
#!/usr/bin/env bash
[[ "$1" != "choose" ]] || printf '%s\n' 'pi (coding agent)'
SH
    cat > "$fake_bin/npm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$PI_NPM_INVOCATION"
SH
    chmod +x "$fake_bin/gum" "$fake_bin/npm"

    HOME="$sandbox/home" PATH="$fake_bin:$sandbox/home/.local/bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" PI_NPM_INVOCATION="$sandbox/npm-invocation" \
        bash -c '
            source "$1/install/lib.sh"
            ensure_node() { return 0; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$sandbox/npm-invocation")" == "install -g --ignore-scripts @earendil-works/pi-coding-agent" ]] \
        || fail "Pi installer did not use the global npm install"
    [[ ! -e "$wrapper" ]] || fail "Pi installer left the Omarchy npx wrapper in PATH"
}

check_collie_install_selection() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local invocation="$sandbox/collie-invocation"

    mkdir -p "$fake_bin"
    cat > "$fake_bin/gum" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == "choose" ]]; then
    for option in "$@"; do
        [[ "$option" != "Collie (mobile agent dashboard)" ]] || printf '%s\n' "$option"
    done
fi
SH
    chmod +x "$fake_bin/gum"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" COLLIE_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() { printf "%s %s\n" "$@" > "$COLLIE_INVOCATION"; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "sh https://colliepwa.dev/install.sh" ]] \
        || fail "Collie was not installed from the gum selection"

    rm -f "$invocation"
    mkdir -p "$sandbox/nobin"
    for tool in bash mkdir dirname; do
        ln -s "$(command -v "$tool")" "$sandbox/nobin/$tool"
    done
    printf '11\n' | HOME="$sandbox/home" PATH="$sandbox/nobin" \
        DOTFILES_DIR="$ROOT_DIR" COLLIE_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() { printf "%s %s\n" "$@" > "$COLLIE_INVOCATION"; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "sh https://colliepwa.dev/install.sh" ]] \
        || fail "numeric AI tool selection did not install Collie"

    rm -f "$invocation"
    printf '#!/usr/bin/env bash\n' > "$fake_bin/collie"
    chmod +x "$fake_bin/collie"
    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" COLLIE_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            run_remote_script() { printf "%s %s\n" "$@" > "$COLLIE_INVOCATION"; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null
    [[ ! -e "$invocation" ]] || fail "Collie installer ran when already installed"
}

check_ocr_install_selection() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local invocation="$sandbox/ocr-invocation"

    mkdir -p "$fake_bin"
    cat > "$fake_bin/gum" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == "choose" ]]; then
    for option in "$@"; do
        [[ "$option" != "Open Code Review (ocr)" ]] || printf '%s\n' "$option"
    done
fi
SH
    cat > "$fake_bin/npm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OCR_NPM_INVOCATION"
SH
    chmod +x "$fake_bin/gum" "$fake_bin/npm"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" OCR_NPM_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            ensure_node() { return 0; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "install -g @alibaba-group/open-code-review" ]] \
        || fail "Open Code Review was not installed from the gum selection"

    rm -f "$invocation"
    mkdir -p "$sandbox/nobin"
    for tool in bash mkdir dirname; do
        ln -s "$(command -v "$tool")" "$sandbox/nobin/$tool"
    done
    cp "$fake_bin/npm" "$sandbox/nobin/npm"
    printf '12\n' | HOME="$sandbox/home" PATH="$sandbox/nobin" \
        DOTFILES_DIR="$ROOT_DIR" OCR_NPM_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            ensure_node() { return 0; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "install -g @alibaba-group/open-code-review" ]] \
        || fail "numeric AI tool selection did not install Open Code Review"

    rm -f "$invocation"
    printf '#!/usr/bin/env bash\n' > "$fake_bin/ocr"
    chmod +x "$fake_bin/ocr"
    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" OCR_NPM_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            ensure_node() { return 0; }
            ask_yes_no() { return 1; }
            source "$1/install/ai-tools.sh"
        ' _ "$ROOT_DIR" >/dev/null
    [[ ! -e "$invocation" ]] || fail "Open Code Review installer ran when already installed"

    grep -q 'npm install -g @alibaba-group/open-code-review' "$ROOT_DIR/update.sh" \
        || fail "update.sh does not update Open Code Review"
    if grep 'open-code-review' "$ROOT_DIR/update.sh" | grep -q -- '--ignore-scripts'; then
        fail "update.sh updates Open Code Review with --ignore-scripts"
    fi
}

check_herdr_ohmyzsh_plugin_install() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local fake_bin="$sandbox/bin"
    local invocation="$sandbox/herdr-invocation"

    mkdir -p "$fake_bin" "$sandbox/home"
    touch "$sandbox/home/.tmux.conf"

    for tool in tmux sesh gitmux; do
        printf '#!/usr/bin/env bash\n' > "$fake_bin/$tool"
        chmod +x "$fake_bin/$tool"
    done

    cat > "$fake_bin/herdr" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HERDR_INVOCATION"
if [[ "$*" == "plugin list" ]]; then
    [[ -n "${HERDR_PLUGIN_LIST:-}" ]] && printf '%s\n' "$HERDR_PLUGIN_LIST"
fi
SH
    chmod +x "$fake_bin/herdr"

    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" HERDR_INVOCATION="$invocation" \
        bash -c '
            source "$1/install/lib.sh"
            source "$1/install/multiplexer.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == $'plugin list\nplugin install robbyrussell/herdr-ohmyzsh -y' ]] \
        || fail "herdr-ohmyzsh plugin was not installed"

    rm -f "$invocation"
    HOME="$sandbox/home" PATH="$fake_bin:/usr/bin:/bin" \
        DOTFILES_DIR="$ROOT_DIR" HERDR_INVOCATION="$invocation" \
        HERDR_PLUGIN_LIST='- ohmyzsh.shell (Oh My Zsh) enabled [github:robbyrussell/herdr-ohmyzsh@abc]' \
        bash -c '
            source "$1/install/lib.sh"
            source "$1/install/multiplexer.sh"
        ' _ "$ROOT_DIR" >/dev/null

    [[ "$(<"$invocation")" == "plugin list" ]] \
        || fail "herdr-ohmyzsh plugin was reinstalled when already present"
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

check_remote_script_failure_handling() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"

    HOME="$sandbox/home" PATH="/usr/bin:/bin" bash -c '
        set -Eeuo pipefail
        source "$1"
        download_status=22
        interpreter_status=0
        interpreter_called=false
        downloaded_script=""

        download_file() {
            downloaded_script="$2"
            printf "partial download\n" > "$2"
            return "$download_status"
        }
        test_interpreter() {
            interpreter_called=true
            [[ -f "$1" && "$2" == "--example" ]] || return 99
            return "$interpreter_status"
        }

        if run_remote_script test_interpreter https://example.invalid/install.sh --example; then
            echo "Failed download was reported as successful" >&2
            exit 1
        else
            [[ "$?" == 22 ]]
        fi
        [[ "$interpreter_called" == false && ! -e "$downloaded_script" ]]

        download_status=0
        interpreter_status=7
        if run_remote_script test_interpreter https://example.invalid/install.sh --example; then
            exit 1
        else
            [[ "$?" == 7 ]]
        fi
        [[ "$interpreter_called" == true && ! -e "$downloaded_script" ]]

        interpreter_status=0
        run_remote_script test_interpreter https://example.invalid/install.sh --example
        [[ ! -e "$downloaded_script" ]]
    ' _ "$ROOT_DIR/install/lib.sh"
}

check_wrapper_and_pi_settings_preservation() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    mkdir -p "$sandbox/home/.config/git" "$sandbox/home/.pi/agent" "$sandbox/bin"
    ln -s "$ROOT_DIR" "$sandbox/renamed-checkout"
    printf '#!/bin/sh\nexit 1\n' > "$sandbox/bin/gh"
    chmod +x "$sandbox/bin/gh"
    printf 'export LOCAL_ENV=keep\n' > "$sandbox/home/.zshenv"
    printf 'export LOCAL_PROFILE=keep\n' > "$sandbox/profile"
    ln -s "$sandbox/profile" "$sandbox/home/.zprofile"
    printf 'export DOTFILES_DIR="/old/checkout"\nsource "/old/checkout/zsh/zshrc"\nexport LOCAL_RC=keep\n' > "$sandbox/home/.zshrc"
    printf '[user]\n\tname = Local Name\n[include]\n\tpath = /private/gitconfig\n' > "$sandbox/home/.config/git/config"
    printf '{"theme":"local-old"}\n' > "$sandbox/home/.pi/agent/settings.json"

    HOME="$sandbox/home" PATH="$sandbox/bin:/usr/bin:/bin" \
        DOTFILES_DIR="$sandbox/renamed-checkout" bash -c '
        set -Eeuo pipefail
        source "$1/install/lib.sh"
        OS=macos
        source "$1/install/symlinks.sh" >/dev/null
        for name in zshenv zprofile zshrc; do
            [[ ! -L "$HOME/.$name" ]]
            cp "$HOME/.$name" "$HOME/.$name.expected"
        done
        cp "$HOME/.config/git/config" "$HOME/git.expected"
        source "$1/install/symlinks.sh" >/dev/null
        for name in zshenv zprofile zshrc; do
            cmp "$HOME/.$name" "$HOME/.$name.expected"
            grep -qF "source \"$DOTFILES_DIR/zsh/$name\"" "$HOME/.$name"
        done
        grep -q "LOCAL_ENV=keep" "$HOME/.zshenv"
        grep -q "LOCAL_PROFILE=keep" "$HOME/.zprofile"
        grep -q "LOCAL_RC=keep" "$HOME/.zshrc"
        ! grep -q /old/checkout "$HOME/.zshrc"
        cmp "$HOME/.config/git/config" "$HOME/git.expected"
        [[ "$(git config --file "$HOME/.config/git/config" user.name)" == "Local Name" ]]
        [[ "$(git config --file "$HOME/.config/git/config" --get-all include.path)" == "$DOTFILES_DIR/git/config"$'\''\n'\''/private/gitconfig ]]
        [[ -L "$HOME/.pi/agent/settings.json" ]]
        [[ "$HOME/.pi/agent/settings.json" -ef "$DOTFILES_DIR/pi/settings.json" ]]
        grep -q "local-old" "$HOME/.pi/agent/"settings.json.backup.*
    ' _ "$ROOT_DIR"
    [[ "$(<"$sandbox/profile")" == "export LOCAL_PROFILE=keep" ]]
}

check_pi_package_sources() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    mkdir -p "$sandbox/pi/agents" "$sandbox/pi/durable-subagents" \
        "$sandbox/home/.pi/agent/agents" "$sandbox/home/.pi/agent/subagent-manager"
    printf '%s\n' '{"packages":["npm:pi-durable-subagents","git:github.com/example/provider@pinned"]}' > "$sandbox/pi/settings.json"
    printf '%s\n' '{"onQuit":"pause","pools":{"coder":["provider/model:medium"]}}' > "$sandbox/pi/durable-subagents/config.json"
    printf '%s\n' 'Pi instructions' > "$sandbox/pi/AGENTS.md"
    printf '%s\n' 'durable coder' > "$sandbox/pi/agents/coder.md"
    printf '%s\n' 'shared designer' > "$sandbox/pi/agents/designer.md"
    printf '%s\n' 'local designer' > "$sandbox/home/.pi/agent/agents/designer.md"
    printf '%s\n' 'legacy settings' > "$sandbox/home/.pi/agent/subagent-manager/settings.json"
    HOME="$sandbox/home" DSA_HOME="$sandbox/state" DOTFILES_DIR="$sandbox" PI_INVOCATION="$sandbox/invocation" bash -c '
        set -Eeuo pipefail
        create_symlink() { ln -s "$1" "$2"; }
        ask_yes_no() { return 0; }
        spin() { shift; "$@"; }
        pi() { printf "%s\n" "$*" >> "$PI_INVOCATION"; }
        source "$1/install/pi.sh"
    ' _ "$ROOT_DIR"
    [[ "$(<"$sandbox/invocation")" == $'install npm:pi-durable-subagents\ninstall git:github.com/example/provider@pinned' ]] \
        || fail "pi installer did not install only declared sources"
    cmp "$sandbox/pi/durable-subagents/config.json" "$sandbox/state/config.json" \
        || fail "durable config was not installed into DSA_HOME"
    [[ "$sandbox/home/.pi/agent/agents/coder.md" -ef "$sandbox/pi/agents/coder.md" ]] \
        || fail "durable agent was not linked"
    [[ "$(<"$sandbox/home/.pi/agent/agents/designer.md")" == 'local designer' ]] \
        || fail "existing agent was overwritten"

    # Repeat with a redirected runtime config and legacy files; preserve both.
    printf '%s\n' 'user config' > "$sandbox/local-config"
    rm "$sandbox/state/config.json"
    ln -s "$sandbox/local-config" "$sandbox/state/config.json"
    cp -R "$sandbox/home/.pi/agent" "$sandbox/before"
    HOME="$sandbox/home" DSA_HOME="$sandbox/state" DOTFILES_DIR="$sandbox" bash -c '
        set -Eeuo pipefail
        create_symlink() { :; }
        ask_yes_no() { return 1; }
        pi() { echo "Unexpected pi invocation: $*" >&2; return 1; }
        source "$1/install/pi.sh"
    ' _ "$ROOT_DIR"
    diff -r "$sandbox/before" "$sandbox/home/.pi/agent" \
        || fail "installer changed existing Pi files"
    [[ -L "$sandbox/state/config.json" && "$(<"$sandbox/local-config")" == 'user config' ]] \
        || fail "installer changed redirected durable configuration"

    # Default state location is independent of the Pi agent directory.
    HOME="$sandbox/default-home" DSA_HOME="" DOTFILES_DIR="$sandbox" bash -c '
        set -Eeuo pipefail
        create_symlink() { :; }
        ask_yes_no() { return 1; }
        pi() { return 1; }
        source "$1/install/pi.sh"
    ' _ "$ROOT_DIR"
    cmp "$sandbox/pi/durable-subagents/config.json" "$sandbox/default-home/.pi/durable-subagents/config.json" \
        || fail "default durable config location was incorrect"
    node -e '
        const {packages} = require(process.argv[1]);
        if (!packages.includes("npm:pi-durable-subagents") ||
            packages.some(p => /pi-subagent-manager|pi-subagents$/.test(p))) process.exit(1);
    ' "$ROOT_DIR/pi/settings.json" || fail "shared settings must load only the durable subagent provider"
}

check_opencode_install() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"
    local live="$sandbox/home/.config/opencode"
    mkdir -p "$sandbox/bin" "$live" "$sandbox/home/.local/dotfiles"
    : > "$sandbox/bin/opencode2"
    chmod +x "$sandbox/bin/opencode2"
    printf '%s\n' '{"plugin":["oh-my-openagent","oh-my-opencode@3.1.0","local-plugin",["./p.ts",{"a":1}],"oh-my-opencode-slim"],"theme":"local","mcp":{"qmd":{"type":"remote","url":"http://old","enabled":false},"mine":{"type":"local","command":["x"]}}}' \
        > "$live/opencode.json"
    printf '%s\n' '{"plugin":["oh-my-openagent","other-tui"]}' > "$live/tui.json"
    printf '%s\n' '{"agents":{}}' > "$live/oh-my-openagent.json"
    printf '%s\n' '{"preset":"old"}' > "$live/oh-my-opencode-slim.json"
    printf '%s\n' '{"presets":{"openai":{"explorer":{"variant":"low"}}}}' \
        > "$sandbox/home/.local/dotfiles/oh-my-opencode-slim.local.json"

    run_opencode_installer() {
        HOME="$sandbox/home" PATH="$sandbox/bin:/usr/bin:/bin" bash -c '
            set -Eeuo pipefail
            header() { :; }
            info() { :; }
            warn() { :; }
            create_symlink() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; }
            DOTFILES_DIR="$1"
            source "$1/install/opencode.sh"
        ' _ "$ROOT_DIR"
    }

    run_opencode_installer
    local pinned
    pinned="$(jq -r '.plugin[0]' "$ROOT_DIR/opencode/opencode.json")"
    [[ "$pinned" == oh-my-opencode-slim@* ]] || fail "shared OpenCode config must pin oh-my-opencode-slim"
    jq -e --arg pinned "$pinned" '
        .plugin == ["local-plugin", ["./p.ts", {"a": 1}], $pinned]
        and .theme == "local"
        and .mcp.qmd.url == "http://localhost:8181/mcp"
        and .mcp.mine.command == ["x"]
    ' "$live/opencode.json" > /dev/null || fail "OpenCode config merge lost local settings or kept a retired plugin"
    jq -e '.plugin == ["other-tui"]' "$live/tui.json" > /dev/null \
        || fail "retired plugin was not removed from tui.json"
    [[ ! -e "$live/oh-my-openagent.json" ]] || fail "retired plugin config is still live"
    compgen -G "$live/oh-my-openagent.json.retired.*" > /dev/null \
        || fail "retired plugin config was deleted instead of kept"
    jq -e '
        .preset == "openai"
        and .presets.openai.explorer.variant == "low"
        and .presets.openai.explorer.model == "openai/gpt-6-luna"
        and (.presets.openai | keys) == ["designer", "explorer", "fixer", "oracle", "orchestrator"]
    ' "$live/oh-my-opencode-slim.json" > /dev/null || fail "slim config did not merge shared defaults with the local override"
    compgen -G "$live/oh-my-opencode-slim.json.backup.*" > /dev/null \
        || fail "replaced slim config was not backed up"
    [[ "$live/AGENTS.md" -ef "$ROOT_DIR/opencode/AGENTS.md" ]] || fail "OpenCode AGENTS.md was not linked"
    [[ ! -e "$ROOT_DIR/opencode/oh-my-openagent.json" ]] || fail "retired plugin config is still in dotfiles"

    # A second run changes nothing and creates no further backups.
    local before after
    before="$(cd "$live" && ls -1 | sort && cat opencode.json tui.json oh-my-opencode-slim.json)"
    sleep 1
    run_opencode_installer
    after="$(cd "$live" && ls -1 | sort && cat opencode.json tui.json oh-my-opencode-slim.json)"
    [[ "$before" == "$after" ]] || fail "OpenCode installer is not idempotent"
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

check_hunk_path_setup() {
    make_temp_dir
    local sandbox="$TEST_TEMP_DIR"

    mkdir -p "$sandbox/.hunk/bin"
    HOME="$sandbox" PATH="/usr/bin:/bin" zsh -f -c '
        source "$1"
        [[ ":$PATH:" == *":$HOME/.hunk/bin:"* ]] || exit 1
    ' _ "$ROOT_DIR/zsh/path" \
        || fail "zsh/path did not prepend ~/.hunk/bin"
}

check_hunk_install_contract() {
    grep -q '^brew "hunk"' "$ROOT_DIR/Brewfile" \
        || fail "Brewfile is missing hunk"
    grep -q 'https://hunk.dev/install.sh --no-modify-path' "$ROOT_DIR/install/linux.sh" \
        || fail "linux installer is missing hunk"
    grep -q 'hunk update' "$ROOT_DIR/update.sh" \
        || fail "update.sh does not update hunk"
    grep -q '^mode = "split"' "$ROOT_DIR/hunk/config.toml" \
        || fail "hunk config is missing split view"
    grep -q 'hunk/config.toml' "$ROOT_DIR/install/symlinks.sh" \
        || fail "symlinks installer does not link hunk config"
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

trap cleanup EXIT

run_check "OMP installer selection" check_omp_install_selection
run_check "Collie installer selection" check_collie_install_selection
run_check "Open Code Review installer selection" check_ocr_install_selection
run_check "Pi global install replaces npx wrapper" check_pi_global_install
run_check "herdr-ohmyzsh plugin install" check_herdr_ohmyzsh_plugin_install
run_check "qmd skill install" check_qmd_skill_install
run_check "installer helpers" check_install_helpers
run_check "remote script failure handling" check_remote_script_failure_handling
run_check "wrapper and Pi settings preservation" check_wrapper_and_pi_settings_preservation
run_check "Pi package sources" check_pi_package_sources
run_check "OpenCode config and plugin migration" check_opencode_install
run_check "skills installer help" check_skills_help
run_check "zsh PATH setup" check_zsh_path_setup
run_check "hunk PATH setup" check_hunk_path_setup
run_check "hunk install contract" check_hunk_install_contract
run_check "Claude environment hook" check_claude_environment_hook

echo "dotfiles behavior checks passed"
