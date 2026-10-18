#!/usr/bin/env bats

load helpers

INSTALL_PS1="$REPO_ROOT/install.ps1"
TEST_WORKFLOW="$REPO_ROOT/.github/workflows/test.yml"

@test "Windows installer supports PowerShell 5.1 and forwards all shared options" {
    run grep -F '#Requires -Version 5.1' "$INSTALL_PS1"
    [ "$status" -eq 0 ]

    for option in DryRun Backup NoBackup Yes Rollback; do
        run grep -F "[switch]\$$option" "$INSTALL_PS1"
        [ "$status" -eq 0 ]
    done

    run grep -F "ContainsKey('Verbose')" "$INSTALL_PS1"
    [ "$status" -eq 0 ]
}

@test "Windows PowerShell 5.1 installer contains only ASCII source text" {
    run grep -nP '[^\x00-\x7F]' "$INSTALL_PS1"
    [ "$status" -eq 1 ]
}

@test "Windows dry-run does not install a missing jq dependency" {
    run grep -F 'Install-Jq -InstallIfMissing:(-not $DryRun)' "$INSTALL_PS1"
    [ "$status" -eq 0 ]

    run grep -F 'Dry-run mode will not install it.' "$INSTALL_PS1"
    [ "$status" -eq 0 ]
}

@test "Windows prerequisite recovery works with stale PATH and missing tools" {
    # pwsh is also present on Ubuntu runners, but this fixture uses Windows
    # drives, registry paths and semicolon-separated PATH. Native CI runs it too.
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) ;;
        *) skip "Windows prerequisite fixture requires native Windows" ;;
    esac
    command -v pwsh >/dev/null || skip "PowerShell is required (also tested in native Windows CI)"
    run pwsh -NoProfile -File "$REPO_ROOT/tests/windows_installer.ps1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: fresh install, stale PATH, inherited PATH, idempotence"* ]]
    [[ "$output" == *"PASS: failed-winget"* ]]
}

@test "Windows installer uses the checkout when cli.sh is beside it" {
    run grep -F 'Test-Path (Join-Path $PSScriptRoot "cli.sh")' "$INSTALL_PS1"
    [ "$status" -eq 0 ]

    run grep -F '$sourceDir = $PSScriptRoot' "$INSTALL_PS1"
    [ "$status" -eq 0 ]
}

@test "Windows installer preserves the Bash installer exit code" {
    run grep -F '$exitCode = $LASTEXITCODE' "$INSTALL_PS1"
    [ "$status" -eq 0 ]

    run grep -F 'exit $exitCode' "$INSTALL_PS1"
    [ "$status" -eq 0 ]
}

@test "CI parses and dry-runs the installer on native Windows" {
    run grep -F 'runs-on: windows-2025' "$TEST_WORKFLOW"
    [ "$status" -eq 0 ]

    run grep -F 'uses: oven-sh/setup-bun@v2' "$TEST_WORKFLOW"
    [ "$status" -eq 0 ]

    run grep -F 'run: .\install.ps1 -DryRun -Yes' "$TEST_WORKFLOW"
    [ "$status" -eq 0 ]

    run grep -F 'install_stylua_if_needed' "$TEST_WORKFLOW"
    [ "$status" -eq 0 ]

    run grep -F 'stylua --version' "$TEST_WORKFLOW"
    [ "$status" -eq 0 ]
}

@test "Windows installs the official prebuilt stylua package instead of compiling with cargo" {
    run bash -c '
        export DRY_RUN=true IS_WINDOWS=true
        source "$1/lib/common.sh"
        source "$1/lib/install.sh"
        IS_WINDOWS=true
        _verify_package_manager() { echo npm; }
        execute() { echo "$1"; }
        command() {
            if [ "$1" = "-v" ] && [ "$2" = "stylua" ]; then
                return 1
            fi
            builtin command "$@"
        }
        install_stylua_if_needed
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"npm install -g @johnnymorganz/stylua-bin"* ]]
    [[ "$output" != *"cargo install stylua"* ]]
}
