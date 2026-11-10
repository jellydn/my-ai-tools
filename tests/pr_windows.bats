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

@test "Claude repairs a broken native shim under a home path with spaces and verifies the repair" {
    for result in repaired broken install-failed; do
        run env PATH="/usr/bin:/bin" bash -c '
            export HOME="$2/User With Spaces" DRY_RUN=false YES_TO_ALL=true
            source "$1/lib/common.sh"
            source "$1/lib/install.sh"
            IS_WINDOWS=true
            node() { return 0; }
            mkdir -p "$HOME/npm prefix"
            PATH="$HOME/npm prefix:$PATH"
            printf "#!/bin/sh\necho native binary missing >&2\nexit 1\n" > "$HOME/npm prefix/claude"
            chmod +x "$HOME/npm prefix/claude"
            cygpath() { printf "%s\n" "$2"; }
            npm() {
                if [ "$1" = prefix ]; then printf "%s\n" "$HOME/npm prefix"; return; fi
                printf "NPM:%s\n" "$*"
                case " $* " in
                    *" --include=optional --ignore-scripts=false --force "*) ;;
                    *) return 91 ;;
                esac
                [ "$REPAIR_RESULT" != install-failed ] || return 1
                if [ "$REPAIR_RESULT" = repaired ]; then
                    printf "#!/bin/sh\necho Claude-test-version\n" > "$HOME/npm prefix/claude"
                fi
            }
            export REPAIR_RESULT="$3"
            install_claude_code
        ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/$result" "$result"
        [[ "$output" == *"NPM:install -g @anthropic-ai/claude-code"* ]]
        [[ "$output" != *"already installed ()"* ]]
        [[ "$output" != *"Auto-skipping"* ]]
        if [ "$result" = repaired ]; then
            [ "$status" -eq 0 ]
            [[ "$output" == *"Claude Code installed (Claude-test-version)"* ]]
        else
            [ "$status" -ne 0 ]
            [[ "$output" != *"Claude Code installed"* ]]
        fi
    done
}

@test "Claude permits only its own lifecycle scripts when npm supports scoped approval" {
    for policy in supported legacy probe-failed; do
        for mode in fresh repair; do
            run env PATH="/usr/bin:/bin" bash -c '
                export HOME="$2/User With Spaces" DRY_RUN=false YES_TO_ALL=true
                source "$1/lib/common.sh"
                source "$1/lib/install.sh"
                IS_WINDOWS=true POLICY="$3" MODE="$4"
                node() { return 0; }
                cygpath() { printf "%s\n" "$2"; }
                mkdir -p "$HOME/npm prefix"
                PATH="$HOME/npm prefix:$PATH"
                if [ "$MODE" = repair ]; then
                    printf "#!/bin/sh\nexit 1\n" > "$HOME/npm prefix/claude"
                    chmod +x "$HOME/npm prefix/claude"
                fi
                npm() {
                    case "$1" in
                        prefix) printf "%s\n" "$HOME/npm prefix"; return ;;
                        config)
                            [ "$*" = "config get allow-scripts" ] || return 98
                            case "$POLICY" in
                                supported) printf "\n" ;;
                                legacy) echo undefined ;;
                                probe-failed) return 1 ;;
                            esac
                            return ;;
                    esac
                    [ "$1" = install ] || return 98
                    case " $* " in
                        *" --dangerously-allow-all-scripts"*|*" --allow-scripts="*","*) return 97 ;;
                    esac
                    case " $* " in
                        *" --allow-scripts=@anthropic-ai/claude-code "*)
                            [ "$POLICY" = supported ] || return 96 ;;
                        *)
                            if [ "$POLICY" = supported ]; then
                                echo "postinstall not covered by allowScripts" >&2
                                return 0
                            fi ;;
                    esac
                    printf "#!/bin/sh\necho Claude-approved-version\n" > "$HOME/npm prefix/claude"
                    chmod +x "$HOME/npm prefix/claude"
                }
                install_claude_code
            ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/$policy-$mode" "$policy" "$mode"
            [ "$status" -eq 0 ]
            [[ "$output" == *"Claude Code installed (Claude-approved-version)"* ]]
            [[ "$output" != *"not covered by allowScripts"* ]]
        done
    done
}

@test "Claude skips a healthy installation and dry-run does not attempt repair" {
    for mode in healthy dry-run; do
        run bash -c '
            source "$1/lib/common.sh"
            source "$1/lib/install.sh"
            YES_TO_ALL=true DRY_RUN=false
            _verify_package_manager() { echo npm; }
            claude() { [ "$MODE" = healthy ] && echo Claude-test-version; }
            npm() { echo UNEXPECTED:npm; return 99; }
            MODE="$2"
            [ "$MODE" != dry-run ] || DRY_RUN=true
            install_claude_code
        ' _ "$REPO_ROOT" "$mode"
        [ "$status" -eq 0 ]
        [[ "$output" != *UNEXPECTED:* ]]
        if [ "$mode" = healthy ]; then
            [[ "$output" == *"already installed (Claude-test-version)"* ]]
        else
            [[ "$output" == *"[DRY RUN]"* ]]
            [[ "$output" != *"Claude Code installed"* ]]
        fi
    done
}

@test "OpenCode installation and verification failures warn and continue to remaining tools" {
    for failure in network verification; do
        run env PATH="/usr/bin:/bin" bash -c '
            source "$1/cli.sh"
            IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=false MIGRATE_GEMINI=false WITH_INTEGRATIONS=false
            preflight_check() { :; }; check_prerequisites() { :; }
            INSTALL_SEQUENCE=(opencode:install_opencode2 codex:install_codex)
            install_codex() { echo INSTALLED:codex; }
            node() { return 0; }
            opencode() { return 1; }
            FAILURE="$2"
            npm() {
                [ "$FAILURE" != network ] || { echo ECONNRESET >&2; return 1; }
                if [ "$1" = prefix ]; then echo "$HOME/npm prefix"; fi
                return 0
            }
            cygpath() { printf "%s\n" "$2"; }
            main
        ' _ "$REPO_ROOT" "$failure"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Skipping OpenCode 2"*"continuing with remaining tools"* ]]
        [[ "$output" == *"INSTALLED:codex"* ]]
        [[ "$output" == *"Setup complete"* ]]
        [[ "$output" != *"OpenCode 2 installed"* ]]
        if [ "$failure" = network ]; then
            [[ "$output" == *ECONNRESET* ]]
            [[ "$output" == *"npm install -g @opencode/cli --include=optional --ignore-scripts=false"* ]]
            [[ "$output" == *"network/proxy"* ]]
        else
            [[ "$output" == *"no working v2 CLI was found"* ]]
        fi
    done
}

@test "failures in other required installers still stop setup" {
    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true DRY_RUN=false MIGRATE_GEMINI=false WITH_INTEGRATIONS=false
        preflight_check() { :; }; check_prerequisites() { :; }
        INSTALL_SEQUENCE=(claude:install_claude_code codex:install_codex)
        install_claude_code() { return 1; }
        install_codex() { echo UNEXPECTED:codex; }
        main
    ' _ "$REPO_ROOT"
    [ "$status" -ne 0 ]
    [[ "$output" != *UNEXPECTED:* ]]
    [[ "$output" != *"Setup complete"* ]]
}

@test "OpenCode requires a working v2 after npm success, not a broken shim or v1" {
    for result in broken v1 repaired; do
        run env PATH="/usr/bin:/bin" bash -c '
            source "$1/lib/common.sh"
            source "$1/lib/install.sh"
            IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=false READY=false
            RESULT="$2"
            node() { return 0; }
            opencode() {
                if [ "$READY" = true ] && [ "$RESULT" = v1 ]; then echo "opencode v1.9.0"; return; fi
                echo "opencode v2.0.0"
                [ "$READY" = true ] && [ "$RESULT" = repaired ]
            }
            npm() {
                if [ "$1" = prefix ]; then echo "$HOME/npm prefix"; else READY=true; fi
                return 0
            }
            cygpath() { printf "%s\n" "$2"; }
            install_opencode2
        ' _ "$REPO_ROOT" "$result"
        [[ "$output" != *"already installed"* ]]
        if [ "$result" = repaired ]; then
            [ "$status" -eq 0 ]
            [[ "$output" == *"installed as opencode"* ]]
        else
            [ "$status" -ne 0 ]
            [[ "$output" != *"installed as opencode"* ]]
        fi
    done
}
