#!/usr/bin/env bats

load helpers

@test "yes without integrations runs only four core installers and leaves configuration alone" {
    for dry_run in true false; do
        run bash -c '
            source "$1/cli.sh"
            YES_TO_ALL=true DRY_RUN="$2" MIGRATE_GEMINI=false WITH_INTEGRATIONS=false
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

@test "default yes categories include integrations and only declared dependencies beyond four core agents" {
    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true DRY_RUN=true MIGRATE_GEMINI=false
        preflight_check() { :; }; check_prerequisites() { :; }
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        install_ctx() { echo ATTEMPT:ctx; echo NO_SETUP:$CTX_INSTALL_NO_SETUP; }
        backup_configs() { echo BUNDLE:backup; }
        copy_configurations() { echo BUNDLE:config; }
        enable_plugins() { echo BUNDLE:plugins; }
        main
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^ATTEMPT:' | sort)" = "$(printf '%s\n' ATTEMPT:amp ATTEMPT:codex ATTEMPT:ctx ATTEMPT:opencode ATTEMPT:pi ATTEMPT:plannotator ATTEMPT:qmd)" ]
    [[ "$output" == *"NO_SETUP:1"* ]]
    [[ "$output" == *"Integration dependency: qmd"* ]]
    [[ "$output" == *"Integration dependency: ctx"* ]]
    [[ "$output" == *"Integration dependency: Plannotator"* ]]
    [ "$(printf '%s\n' "$output" | grep '^BUNDLE:')" = "$(printf '%s\n' BUNDLE:backup BUNDLE:config BUNDLE:plugins)" ]
}

@test "yes copies core MCP plugins and shared skills without touching unrelated agents on rerun" {
    require_jq
    local home_dir
    home_dir=$(mktemp -d)
    run bash -c '
        export HOME="$2"
        source "$1/cli.sh"
        YES_TO_ALL=true DRY_RUN=false MIGRATE_GEMINI=false PROMPT_BACKUP=false BACKUP=false
        # Exercise the real copiers with representative bundled content, not
        # every resource file in the catalog (the full installer is tested separately).
        local_bundle="$HOME/bundle"
        mkdir -p "$local_bundle/configs/amp/plugins" "$local_bundle/configs/codex" \
            "$local_bundle/configs/pi" "$local_bundle/configs/opencode/agent" "$local_bundle/skills"
        cp "$SCRIPT_DIR/configs/amp/settings.json" "$local_bundle/configs/amp/"
        cp "$SCRIPT_DIR/configs/amp/plugins/fusion-agents.ts" "$local_bundle/configs/amp/plugins/"
        cp "$SCRIPT_DIR/configs/codex/config.toml" "$local_bundle/configs/codex/"
        cp "$SCRIPT_DIR/configs/pi/"{settings,mcp}.json "$local_bundle/configs/pi/"
        cp "$SCRIPT_DIR/configs/opencode/opencode.json" "$local_bundle/configs/opencode/"
        cp "$SCRIPT_DIR/configs/"{best-practices,git-guidelines,agent-memory-guidelines,fable-guide}.md "$local_bundle/configs/"
        cp -r "$SCRIPT_DIR/skills/adr" "$local_bundle/skills/"
        SCRIPT_DIR="$local_bundle"
        mkdir -p "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.config/amp" "$HOME/.codex" "$HOME/.pi"
        echo preserve > "$HOME/.claude/sentinel"
        preflight_check() { :; }; check_prerequisites() { :; }
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        install_ctx() { :; }
        claude() { echo UNEXPECTED:claude; return 98; }
        for iteration in 1 2; do
            main
            test -s "$HOME/.config/amp/settings.json"
            test -s "$HOME/.codex/config.toml"
            test -s "$HOME/.pi/agent/mcp.json"
            test -s "$HOME/.config/opencode/opencode.json"
            test -s "$HOME/.config/amp/plugins/fusion-agents.ts"
            test -s "$HOME/.agents/skills/adr/SKILL.md"
            test -s "$HOME/.codex/skills/adr/SKILL.md"
            test ! -d "$HOME/.my-ai-tools-backups/skills"
            test "$(cat "$HOME/.claude/sentinel")" = preserve
            test ! -e "$HOME/.claude/skills"
            test ! -e "$HOME/.claude/settings.json"
        done
        echo PASS:core-config-skills-rerun
    ' _ "$REPO_ROOT" "$home_dir"
    rm -rf "$home_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *PASS:core-config-skills-rerun* ]]
    [[ "$output" != *UNEXPECTED:* ]]
}

@test "optional tool arguments reject unknown names before installation" {
    run bash "$REPO_ROOT/cli.sh" --yes --with-tools=qmd,not-a-tool --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown optional tool: not-a-tool"* ]]
    [[ "$output" != *"AI Tools Setup"* ]]
    run bash "$REPO_ROOT/cli.sh" --with-tools= --dry-run
    [ "$status" -ne 0 ]
}
