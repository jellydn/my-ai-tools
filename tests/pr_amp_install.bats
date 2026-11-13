#!/usr/bin/env bats

load helpers

setup() {
    export AMP_TEST_HOME="$BATS_TEST_TMPDIR/home with spaces"
    mkdir -p "$AMP_TEST_HOME/stale/npm" "$AMP_TEST_HOME/.amp/bin"
    export AMP_TEST_LOG="$BATS_TEST_TMPDIR/install.log"
}

# GNU util-linux and BSD script(1) take the command differently.
run_pty_script() {
    local script_file="$1"
    if script --version </dev/null 2>&1 | grep -q "util-linux"; then
        printf 'n\n' | script -q -e -c "bash \"$script_file\"" /dev/null
        return $?
    fi
    # BSD script(1) has no -c/-e and does not return the child exit status.
    printf 'n\n' | script -q /dev/null bash "$script_file" || true
}

amp_install() {
    bash -c '
        source "$1/lib/common.sh"
        source "$1/lib/install.sh"
        export HOME="$AMP_TEST_HOME" PATH="$AMP_TEST_HOME/stale/npm:/usr/bin:/bin"
        export IS_WINDOWS="$2" DRY_RUN="$3" YES_TO_ALL=true AMP_INSTALLED=false
        if [ "${OFFICIAL_LATE:-false}" = true ]; then
            export PATH="$HOME/stale/npm:$HOME/.amp/bin:$HOME/.amp/bin:/usr/bin:/bin"
        fi
        if [ "${CUSTOM_PREFIX:-false}" = true ]; then
            export PATH="$HOME/custom-prefix/bin:/usr/bin:/bin"
        fi
        if [ "${LOCAL_LINK:-false}" = true ]; then
            export PATH="$HOME/.local/bin:/usr/bin:/bin"
        fi
        unset AMP_HOME USERPROFILE
        if [ "${CUSTOM_HOME:-false}" = true ]; then
            export AMP_HOME="$HOME/custom amp"
        fi
        execute_installer() {
            echo "$1" >> "$AMP_TEST_LOG"
            [ "${FAIL_INSTALL:-false}" != true ] || return 1
            [ "${NO_BINARY:-false}" != true ] || return 0
            local bin_dir="${AMP_HOME:-$HOME/.amp}/bin"
            bin_dir=$(cygpath -u "$bin_dir")
            mkdir -p "$bin_dir"
            printf "#!/bin/sh\n[ \"\$1\" = version ] || exit 7\necho fixture-version\nexit %s\n" "${BINARY_EXIT:-0}" > "$bin_dir/amp"
            chmod +x "$bin_dir/amp"
        }
        powershell.exe() {
            printf "%s\n" "$*" >> "$AMP_TEST_LOG"
            printf "AMP_HOME=%s\n" "${AMP_HOME:-}" >> "$AMP_TEST_LOG"
            execute_installer https://ampcode.com/install.ps1
        }
        cygpath() {
            local flag="${1:-}" path="${2:-}"
            case "$flag" in
            -w)
                case "$path" in
                /*) printf "C:%s\n" "${path//\//\\}" ;;
                *) printf "%s\n" "$path" ;;
                esac
                ;;
            -u)
                case "$path" in
                C:*)
                    local stripped="${path#C:}"
                    printf "/%s\n" "${stripped//\\//}"
                    ;;
                *) printf "%s\n" "$path" ;;
                esac
                ;;
            *) printf "%s\n" "$path" ;;
            esac
        }
        install_amp
        result=$?
        echo "AMP_INSTALLED=$AMP_INSTALLED"
        exit "$result"
    ' _ "$REPO_ROOT" "$1" "${2:-false}"
}

@test "Amp replaces a broken PATH command using the official Unix installer" {
    printf '#!/bin/sh\nexit 9\n' > "$AMP_TEST_HOME/stale/npm/amp"
    chmod +x "$AMP_TEST_HOME/stale/npm/amp"
    run amp_install false
    [ "$status" -eq 0 ]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
    [[ "$output" == *"npm"* ]]
    [ "$(cat "$AMP_TEST_LOG")" = 'https://ampcode.com/install.sh' ]
}

@test "Amp native Windows uses PowerShell without execution policy bypass" {
    run amp_install true
    [ "$status" -eq 0 ]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
    run cat "$AMP_TEST_LOG"
    [[ "$output" == *"-NoProfile -Command"*"https://ampcode.com/install.ps1"* ]]
    [[ "$output" != *"install.sh"* ]]
    [[ "$output" != *"Bypass"* ]]
}

@test "Amp passes a Windows AMP_HOME to the official Windows installer" {
    run amp_install true
    [ "$status" -eq 0 ]
    run cat "$AMP_TEST_LOG"
    [[ "$output" == *"AMP_HOME=C:"* ]]
    [[ "$output" == *"AMP_HOME=C:"*".amp"* ]]
}

@test "Amp does not accept a working npm shim as the official install" {
    printf '#!/bin/sh\necho fixture-version\nexit 0\n' > "$AMP_TEST_HOME/stale/npm/amp"
    chmod +x "$AMP_TEST_HOME/stale/npm/amp"
    run amp_install false
    [ "$status" -eq 0 ]
    [ -s "$AMP_TEST_LOG" ]
}

@test "Amp rejects a custom-prefix shim without an official binary" {
    mkdir -p "$AMP_TEST_HOME/custom-prefix/bin"
    printf '#!/bin/sh\necho npm-shim-version\n' > "$AMP_TEST_HOME/custom-prefix/bin/amp"
    chmod +x "$AMP_TEST_HOME/custom-prefix/bin/amp"
    export CUSTOM_PREFIX=true NO_BINARY=true
    run amp_install false
    [ "$status" -ne 0 ]
    [ -s "$AMP_TEST_LOG" ]
    [[ "$output" == *"AMP_INSTALLED=false"* ]]
}

@test "Amp reuses a working official binary and warns about PATH shadowing" {
    printf '#!/bin/sh\necho fixture-version\nexit 0\n' > "$AMP_TEST_HOME/.amp/bin/amp"
    printf '#!/bin/sh\nexit 9\n' > "$AMP_TEST_HOME/stale/npm/amp"
    chmod +x "$AMP_TEST_HOME/.amp/bin/amp" "$AMP_TEST_HOME/stale/npm/amp"
    run amp_install true
    [ "$status" -eq 0 ]
    [ ! -e "$AMP_TEST_LOG" ]
    [[ "$output" == *"takes priority"* ]]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
}

@test "Amp promotes an existing official PATH entry ahead of a stale command on Unix" {
    printf '#!/bin/sh\necho official-version\n' > "$AMP_TEST_HOME/.amp/bin/amp"
    printf '#!/bin/sh\nexit 9\n' > "$AMP_TEST_HOME/stale/npm/amp"
    chmod +x "$AMP_TEST_HOME/.amp/bin/amp" "$AMP_TEST_HOME/stale/npm/amp"
    export OFFICIAL_LATE=true
    run amp_install false
    [ "$status" -eq 0 ]
    [ ! -e "$AMP_TEST_LOG" ]
    [[ "$output" == *"official-version"* ]]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
}

@test "Amp fails when the installer succeeds but amp version fails" {
    export BINARY_EXIT=8
    run amp_install false
    [ "$status" -ne 0 ]
    [[ "$output" == *"AMP_INSTALLED=false"* ]]
}

@test "Amp supports AMP_HOME with spaces" {
    export CUSTOM_HOME=true
    run amp_install false
    [ "$status" -eq 0 ]
    [ -x "$AMP_TEST_HOME/custom amp/bin/amp" ]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
}

@test "Amp does not verify a stale working shim when the installer leaves no binary" {
    printf '#!/bin/sh\necho stale-version\nexit 0\n' > "$AMP_TEST_HOME/stale/npm/amp"
    chmod +x "$AMP_TEST_HOME/stale/npm/amp"
    export NO_BINARY=true
    run amp_install false
    [ "$status" -ne 0 ]
    [[ "$output" == *"AMP_INSTALLED=false"* ]]
}

@test "Amp propagates installer failure" {
    export FAIL_INSTALL=true
    run amp_install false
    [ "$status" -ne 0 ]
    [[ "$output" == *"AMP_INSTALLED=false"* ]]
}

@test "Amp reports participation to the PowerShell wrapper" {
    export MY_AI_TOOLS_AMP_STATUS_FILE="$BATS_TEST_TMPDIR/amp-selection"
    run amp_install false
    [ "$status" -eq 0 ]
    [ "$(head -n 1 "$MY_AI_TOOLS_AMP_STATUS_FILE")" = selected ]
}

@test "Amp accepts the official installer's own symlink as the official install" {
    mkdir -p "$AMP_TEST_HOME/.local/bin"
    printf '#!/bin/sh\necho official-version\n' > "$AMP_TEST_HOME/.amp/bin/amp"
    chmod +x "$AMP_TEST_HOME/.amp/bin/amp"
    ln -s "$AMP_TEST_HOME/.amp/bin/amp" "$AMP_TEST_HOME/.local/bin/amp"
    export LOCAL_LINK=true
    run amp_install false
    [ "$status" -eq 0 ]
    [ ! -e "$AMP_TEST_LOG" ]
    [[ "$output" != *"takes priority"* ]]
    [[ "$output" == *"official-version"* ]]
    [[ "$output" == *"AMP_INSTALLED=true"* ]]
}

@test "Amp decline leaves PowerShell participation unset" {
    command -v script >/dev/null || skip "A pseudo-terminal is required"
    export REPO_ROOT MY_AI_TOOLS_AMP_STATUS_FILE="$BATS_TEST_TMPDIR/amp-declined"
    : > "$MY_AI_TOOLS_AMP_STATUS_FILE"
    cat > "$BATS_TEST_TMPDIR/decline.sh" <<'BASH'
source "$REPO_ROOT/lib/common.sh"
source "$REPO_ROOT/lib/install.sh"
export DRY_RUN=false YES_TO_ALL=false AMP_INSTALLED=false
install_amp
BASH
    run run_pty_script "$BATS_TEST_TMPDIR/decline.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping Amp installation"* ]]
    [ ! -s "$MY_AI_TOOLS_AMP_STATUS_FILE" ]
}

@test "Amp installer stays in the documented per-tool module" {
    run bash -c '
        source "$1/lib/common.sh"
        source "$1/lib/install.sh"
        shopt -s extdebug
        declare -F install_amp
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *" $REPO_ROOT/lib/install.sh" ]]
}

@test "PowerShell checks selected Amp even when the official binary is missing" {
    command -v pwsh >/dev/null || skip "PowerShell is required (also tested in Windows CI)"
    run pwsh -NoProfile -File "$REPO_ROOT/tests/windows_amp_handoff.ps1" -Case selected-missing
    [ "$status" -eq 1 ]
    [[ "$output" == *"Official Amp binary not found"* ]]
}

@test "PowerShell does not fail other setup when Amp was declined" {
    command -v pwsh >/dev/null || skip "PowerShell is required (also tested in Windows CI)"
    for scenario in declined-broken declined-shadowed; do
        run pwsh -NoProfile -File "$REPO_ROOT/tests/windows_amp_handoff.ps1" -Case "$scenario"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Installation completed successfully"* ]]
    done
}

@test "Amp dry-run chooses the platform installer without executing or marking installed" {
    for windows in true false; do
        run amp_install "$windows" true
        [ "$status" -eq 0 ]
        [[ "$output" == *"[DRY RUN]"* ]]
        [[ "$output" == *"AMP_INSTALLED=false"* ]]
        [ ! -e "$AMP_TEST_LOG" ]
    done
}
