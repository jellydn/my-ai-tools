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
        [[ "$output" == *"Skipping opencode"*"continuing with remaining tools"* ]]
        [[ "$output" == *"INSTALLED:codex"* ]]
        [[ "$output" == *"Setup complete with optional components skipped"* ]]
        [[ "$output" == *"Failed/skipped optional components: opencode"* ]]
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
    for component in qmd claude amp codex ctx plannotator prerequisite integration; do
        run bash -c '
            source "$1/cli.sh"
            YES_TO_ALL=true DRY_RUN=false MIGRATE_GEMINI=false WITH_INTEGRATIONS=true
            preflight_check() { :; }; check_prerequisites() { :; }; backup_configs() { :; }
            install_integration_dependencies() { :; }
            fail_component() { return 1; }
            remaining_tool() { echo UNEXPECTED:remaining; }
            INSTALL_SEQUENCE=("$2:fail_component" pi:remaining_tool)
            case "$2" in
                prerequisite) check_prerequisites() { return 1; }; INSTALL_SEQUENCE=(pi:remaining_tool) ;;
                integration) install_integration_dependencies() { return 1; }; INSTALL_SEQUENCE=() ;;
            esac
            main
        ' _ "$REPO_ROOT" "$component"
        [ "$status" -ne 0 ]
        [[ "$output" != *UNEXPECTED:* ]]
        [[ "$output" != *"Setup complete"* ]]
    done
}

@test "AI Launcher never reports success after download, installer, or health failure" {
    for failure in download installer health empty success; do
        run env PATH="/usr/bin:/bin" bash -c '
            export HOME="$2/User With Spaces"
            source "$1/cli.sh"
            IS_WINDOWS=false YES_TO_ALL=true DRY_RUN=false FAILURE="$3"
            mkdir -p "$HOME/.local/bin"
            ai() {
                [ "$FAILURE" != health ] || return 1
                [ "$FAILURE" = empty ] || echo ai-test-version
                return 0
            }
            curl() {
                [ "$FAILURE" != download ] || { echo "curl: (56) connection reset" >&2; return 56; }
                while [ "$#" -gt 0 ]; do
                    if [ "$1" = -o ]; then shift; target="$1"; fi
                    shift
                done
                if [ "$FAILURE" = installer ]; then
                    printf "#!/bin/sh\nexit 56\n" > "$target"
                else
                    printf "#!/bin/sh\nexit 0\n" > "$target"
                fi
            }
            install_ai_switcher
        ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/$failure" "$failure"
        if [ "$failure" = success ]; then
            [ "$status" -eq 0 ]
            [[ "$output" == *"AI Launcher installed"* ]]
        else
            [ "$status" -ne 0 ]
            [[ "$output" != *"AI Launcher installed/upgraded"* ]]
            [[ "$output" != *"AI Launcher installed"* ]]
        fi
    done
}

@test "Windows launcher retries reset downloads, preserves the old binary on failure, and never reruns a script" {
    for result in recovered exhausted checksum health http tls; do
        run env PATH="/usr/bin:/bin" bash -c '
            export HOME="$2/User With Spaces" TMPDIR="$2/Temp With Spaces"
            source "$1/cli.sh"
            IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=false RESULT="$3"
            mkdir -p "$HOME/.local/bin" "$TMPDIR"
            printf "#!/bin/sh\necho old-launcher\n" > "$HOME/.local/bin/ai.exe"
            chmod +x "$HOME/.local/bin/ai.exe"
            ai() { "$HOME/.local/bin/ai.exe" "$@"; }
            cp "$HOME/.local/bin/ai.exe" "$HOME/original"
            printf "#!/bin/sh\necho new-launcher\n" > "$HOME/release"
            [ "$RESULT" != health ] || printf "#!/bin/sh\nexit 1\n" > "$HOME/release"
            fixture_sha=$(sha256sum "$HOME/release"); fixture_sha="${fixture_sha%% *}"
            [ "$RESULT" != checksum ] || fixture_sha=$(printf wrong | sha256sum | cut -d" " -f1)
            uname() { [ "$1" != -m ] || { echo x86_64; return; }; builtin command uname "$@"; }
            sleep() { :; }
            curl() {
                target="" url=""
                while [ "$#" -gt 0 ]; do
                    case "$1" in
                        -o) shift; target="$1" ;;
                        https:*) url="$1" ;;
                    esac
                    shift
                done
                case "$url" in
                    */releases/latest)
                        printf "{\"assets\":[{\"name\":\"ai-windows-x64.exe\",\"browser_download_url\":\"https://github.com/fixture/ai.exe\"},{\"name\":\"checksums.txt\",\"browser_download_url\":\"https://github.com/fixture/checksums.txt\"}]}" > "$target" ;;
                    */checksums.txt) printf "%s  ai-windows-x64.exe\n" "$fixture_sha" > "$target" ;;
                    */ai.exe)
                        count=0; [ ! -e "$HOME/attempts" ] || read -r count < "$HOME/attempts"
                        count=$((count + 1)); echo "$count" > "$HOME/attempts"
                        [ "$RESULT" != http ] || return 22
                        [ "$RESULT" != tls ] || return 60
                        if [ "$RESULT" = exhausted ] || { [ "$RESULT" = recovered ] && [ "$count" -eq 1 ]; }; then
                            echo partial > "$target"; return 56
                        fi
                        cp "$HOME/release" "$target" ;;
                    *) echo UNEXPECTED:script >&2; return 99 ;;
                esac
            }
            result=0; install_ai_switcher || result=$?
            if [ "$RESULT" = recovered ]; then
                [ "$result" -eq 0 ] || exit 81
                [ "$(cat "$HOME/attempts")" -eq 2 ] || exit 82
                cmp "$HOME/release" "$HOME/.local/bin/ai.exe" || exit 83
            else
                [ "$result" -ne 0 ] || exit 84
                cmp "$HOME/original" "$HOME/.local/bin/ai.exe" || exit 85
                [ "$RESULT" != exhausted ] || [ "$(cat "$HOME/attempts")" -eq 3 ] || exit 86
                case "$RESULT" in http|tls) [ "$(cat "$HOME/attempts")" -eq 1 ] || exit 88 ;; esac
            fi
            [ -z "$(ls -A "$TMPDIR")" ] || exit 87
            test "$(ls -A "$HOME/.local/bin")" = ai.exe || exit 89
            echo PASS:staged-download
        ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/$result" "$result"
        [ "$status" -eq 0 ]
        [[ "$output" == *PASS:staged-download* ]]
        [[ "$output" != *UNEXPECTED:* ]]
    done
}

@test "Windows launcher dry-run makes no downloads or staging directories" {
    run bash -c '
        export HOME="$2"
        source "$1/cli.sh"
        IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=true
        curl() { echo UNEXPECTED:curl; return 99; }
        install_ai_switcher
        test ! -e "$HOME/.local/bin"
    ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/home"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
    [[ "$output" != *UNEXPECTED:* ]]
}

@test "Pi failure offers targeted recovery without replaying npm install or cleanup" {
    run env PATH="/usr/bin:/bin" bash -c '
        source "$1/cli.sh"
        IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=false
        node() { :; }
        count_file="$2"
        npm() {
            [ "$1" = install ] || { echo UNEXPECTED:config-or-cleanup; return 99; }
            echo attempt >> "$count_file"
            echo "ECONNRESET; EPERM cleanup warning" >&2
            return 1
        }
        result=0; install_pi || result=$?
        [ "$result" -ne 0 ] || exit 81
        [ "$(wc -l < "$count_file")" -eq 1 ] || exit 82
    ' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/attempts"
    [ "$status" -eq 0 ]
    [[ "$output" == *"npm already retries eligible registry downloads"* ]]
    [[ "$output" == *"EPERM"*"README"* ]]
    [[ "$output" != *UNEXPECTED:* ]]
}

@test "optional Pi and launcher failures continue setup and appear in the final summary" {
    run env PATH="/usr/bin:/bin" bash -c '
        source "$1/cli.sh"
        IS_WINDOWS=true YES_TO_ALL=true DRY_RUN=false MIGRATE_GEMINI=false WITH_INTEGRATIONS=true
        preflight_check() { :; }; check_prerequisites() { :; }; backup_configs() { :; }
        INSTALL_SEQUENCE=(ai-switcher:install_ai_switcher pi:install_pi codex:install_codex)
        install_ai_launcher_windows() { return 56; }
        node() { :; }
        npm() { echo "ECONNRESET; EPERM cleanup warning" >&2; return 1; }
        install_codex() { echo INSTALLED:codex; }
        install_integration_dependencies() { echo REQUIRED:dependencies; }
        copy_configurations() {
            tool_allowed pi && { echo UNEXPECTED:pi-config; return 1; }
            echo COPIED:remaining-config
        }
        enable_plugins() { echo ENABLED:remaining-plugins; }
        main
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"INSTALLED:codex"*"COPIED:remaining-config"*"ENABLED:remaining-plugins"* ]]
    [[ "$output" == *"Failed/skipped optional components: ai-switcher pi"* ]]
    [[ "$output" != *UNEXPECTED:* ]]
    [[ "$output" != *"Core agents, shared skills, and selected MCP/plugin configurations installed."* ]]
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
