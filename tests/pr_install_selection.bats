#!/usr/bin/env bats

load helpers

@test "yes mode runs only four core installers and leaves configurations and integrations alone" {
    for dry_run in true false; do
        run bash -c '
            source "$1/cli.sh"
            YES_TO_ALL=true DRY_RUN="$2" MIGRATE_GEMINI=false
            git() { :; }; node() { echo test; }; npm() { echo /tmp/npm-prefix; }; bun() { echo test; }
            cygpath() { echo "$2"; }
            for entry in "${INSTALL_SEQUENCE[@]}"; do
                eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
            done
            backup_configs() { echo UNEXPECTED:backup; return 99; }
            copy_configurations() { echo UNEXPECTED:config; return 99; }
            enable_plugins() { echo UNEXPECTED:plugins; return 99; }
            main
        ' _ "$REPO_ROOT" "$dry_run"
        [ "$status" -eq 0 ]
        [ "$(printf '%s\n' "$output" | grep '^ATTEMPT:' | sort)" = "$(printf '%s\n' ATTEMPT:amp ATTEMPT:codex ATTEMPT:opencode ATTEMPT:pi)" ]
        [[ "$output" != *UNEXPECTED:* ]]
    done
}

@test "optional installers require explicit selection in yes mode and prompt interactively" {
    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true
        TOOL_ALLOWLIST_YES+=(qmd plannotator ctx)
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        run_install_sequence
        echo INTERACTIVE
        YES_TO_ALL=false
        prompt_yn() { [ "$1" = "Install optional ctx" ]; }
        run_install_sequence
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^ATTEMPT:qmd$' <<<"$output")" -eq 1 ]
    [ "$(grep -c '^ATTEMPT:plannotator$' <<<"$output")" -eq 1 ]
    [ "$(grep -c '^ATTEMPT:ctx$' <<<"$output")" -eq 2 ]
    [[ "$output" != *ATTEMPT:global-tools* ]]
}

@test "integration bundle opt-in includes prerequisites without selecting unrelated catalog CLIs" {
    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true DRY_RUN=true MIGRATE_GEMINI=false WITH_INTEGRATIONS=true
        preflight_check() { :; }; check_prerequisites() { :; }
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        backup_configs() { echo BUNDLE:backup; }
        copy_configurations() { echo BUNDLE:config; }
        enable_plugins() { echo BUNDLE:plugins; }
        main
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^ATTEMPT:' | sort)" = "$(printf '%s\n' ATTEMPT:amp ATTEMPT:codex ATTEMPT:global-tools ATTEMPT:opencode ATTEMPT:pi ATTEMPT:plannotator ATTEMPT:qmd ATTEMPT:rtk)" ]
    [ "$(printf '%s\n' "$output" | grep '^BUNDLE:')" = "$(printf '%s\n' BUNDLE:backup BUNDLE:config BUNDLE:plugins)" ]
}

@test "optional tool arguments reject unknown names before installation" {
    run bash "$REPO_ROOT/cli.sh" --yes --with-tools=qmd,not-a-tool --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown optional tool: not-a-tool"* ]]
    [[ "$output" != *"AI Tools Setup"* ]]
    run bash "$REPO_ROOT/cli.sh" --with-tools= --dry-run
    [ "$status" -ne 0 ]
}
