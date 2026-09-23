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
    mkdir -p "$sandbox/pi"
    printf '%s\n' '{"packages":["git:github.com/example/provider@pinned","https://github.com/majesticlabs-dev/pi-fusion"]}' > "$sandbox/pi/settings.json"
    HOME="$sandbox/home" DOTFILES_DIR="$sandbox" PI_INVOCATION="$sandbox/invocation" bash -c '
        set -Eeuo pipefail
        create_symlink() { :; }
        ask_yes_no() { return 0; }
        spin() { shift; "$@"; }
        pi() {
            if [[ "$1" == list ]]; then
                printf "%s\n" "https://github.com/majesticlabs-dev/pi-fusion"
            else
                printf "%s\n" "$*" >> "$PI_INVOCATION"
            fi
        }
        source "$1/install/pi.sh"
    ' _ "$ROOT_DIR"
    [[ "$(<"$sandbox/invocation")" == $'install git:github.com/example/provider@pinned\ninstall https://github.com/majesticlabs-dev/pi-fusion' ]]
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
run_check "herdr-ohmyzsh plugin install" check_herdr_ohmyzsh_plugin_install
run_check "qmd skill install" check_qmd_skill_install
run_check "installer helpers" check_install_helpers
run_check "remote script failure handling" check_remote_script_failure_handling
run_check "wrapper and Pi settings preservation" check_wrapper_and_pi_settings_preservation
run_check "Pi package sources" check_pi_package_sources
run_check "skills installer help" check_skills_help
run_check "zsh PATH setup" check_zsh_path_setup
run_check "hunk PATH setup" check_hunk_path_setup
run_check "hunk install contract" check_hunk_install_contract
run_check "Claude environment hook" check_claude_environment_hook

echo "dotfiles behavior checks passed"
