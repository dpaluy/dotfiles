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

trap cleanup EXIT

run_check "OMP installer selection" check_omp_install_selection
run_check "qmd skill install" check_qmd_skill_install
run_check "installer helpers" check_install_helpers
run_check "skills installer help" check_skills_help
run_check "zsh PATH setup" check_zsh_path_setup
run_check "Claude environment hook" check_claude_environment_hook

echo "dotfiles behavior checks passed"
