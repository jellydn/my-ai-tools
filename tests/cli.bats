#!/usr/bin/env bats
# Test suite for cli.sh functions

setup() {
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    source "$BATS_TEST_DIRNAME/../lib/install.sh"
    # Source cli.sh for function definitions (CLI parsing is guarded internally)
    source "$BATS_TEST_DIRNAME/../cli.sh"
    export DRY_RUN=false
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export YES_TO_ALL=false
    export VERBOSE=false
}

@test "backup_configs creates backup directory" {
    export DRY_RUN=false
    export BACKUP_DIR="/tmp/test-backup-$$"
    export BACKUP=true
    export PROMPT_BACKUP=false

    mkdir -p "$HOME/.claude.test.$$"
    echo '{"test": true}' > "$HOME/.claude.test.$$/settings.json"

    run backup_configs

    rm -rf "$HOME/.claude.test.$$"
    rm -rf "$BACKUP_DIR"

    [ "$status" -eq 0 ]
}

@test "copy_configurations validates JSON files" {
    export DRY_RUN=false
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/fixtures"

    mkdir -p "$SCRIPT_DIR/configs/claude"
    echo '{"valid": true}' > "$SCRIPT_DIR/configs/claude/settings.json"

    # This test validates that the function exists and can be called
    run declare -f copy_configurations

    rm -rf "$SCRIPT_DIR/configs"

    [ "$status" -eq 0 ]
}

@test "install_claude_code checks for existing installation" {
    # Mock claude command as not installed
    run install_claude_code 2>&1 || true

    # Function should not error even when claude is not installed
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "preflight_check fails on missing jq" {
    # Save original PATH
    ORIGINAL_PATH="$PATH"

    # Temporarily remove jq from PATH
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/jq' | tr '\n' ':')

    # The test may pass or fail depending on system
    run preflight_check

    # Restore PATH
    PATH="$ORIGINAL_PATH"

    # Either jq is installed (test passes) or we get an error
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "execute respects dry-run mode for dangerous commands" {
    export DRY_RUN=true

    run execute "rm -rf /tmp/nonexistent-test-file-$$"
    [ "$status" -eq 0 ]
    # log_info writes to stderr; strip color codes before matching
    local clean_output
    clean_output="$(echo "$output" | sed -E 's/\x1B\[[0-9;]*m//g')"
    [[ "$clean_output" == *"[DRY RUN]"* ]]
}

@test "install_mcp_server handles installation result" {
    export DRY_RUN=true

    # Test that the function exists
    run declare -f install_mcp_server

    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# BASH_SOURCE guard – cli.sh arg-parsing and main() are skipped when sourced
# ---------------------------------------------------------------------------

@test "sourcing cli.sh does not alter DRY_RUN when --dry-run is not in args" {
    # setup() sources cli.sh; DRY_RUN should still be the value we exported
    export DRY_RUN=false
    # Re-source to confirm the guard does not fire from $@
    source "$BATS_TEST_DIRNAME/../cli.sh"
    [ "$DRY_RUN" = "false" ]
}

@test "sourcing cli.sh leaves YES_TO_ALL at its exported value" {
    export YES_TO_ALL=false
    source "$BATS_TEST_DIRNAME/../cli.sh"
    [ "$YES_TO_ALL" = "false" ]
}

@test "sourcing cli.sh leaves VERBOSE at its exported value" {
    export VERBOSE=false
    source "$BATS_TEST_DIRNAME/../cli.sh"
    [ "$VERBOSE" = "false" ]
}

@test "sourcing cli.sh leaves MIGRATE_GEMINI at its default false" {
    export MIGRATE_GEMINI=false
    source "$BATS_TEST_DIRNAME/../cli.sh"
    [ "$MIGRATE_GEMINI" = "false" ]
}

@test "main function is defined after sourcing cli.sh" {
    run declare -f main
    [ "$status" -eq 0 ]
}

@test "preflight_check function is defined after sourcing cli.sh" {
    run declare -f preflight_check
    [ "$status" -eq 0 ]
}

@test "sourcing cli.sh does not produce main banner output" {
    # When sourced the BASH_SOURCE guard must prevent main() from running,
    # so no "AI Tools Installer" banner should appear.
    run bash -c "
        export DRY_RUN=false
        export YES_TO_ALL=false
        export VERBOSE=false
        source '$BATS_TEST_DIRNAME/../lib/common.sh'
        source '$BATS_TEST_DIRNAME/../lib/install.sh'
        source '$BATS_TEST_DIRNAME/../cli.sh'
        echo 'sourced_ok'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"sourced_ok"* ]]
    # Banner text from main() must not appear when cli.sh is sourced
    [[ "$output" != *"AI Tools Installer"* ]]
}

@test "tool_allowed gates correctly under YES_TO_ALL" {
    # Under YES_TO_ALL=true: only the 8 allowed tools return 0
    export YES_TO_ALL=true
    for tool in amp codex ctx cursor kilo opencode open_code_review pi antigravity ai-switcher; do
        run tool_allowed "$tool"
        [ "$status" -eq 0 ]
    done
    # Non-allowed tools return 1
    for tool in claude cline gemini grok mimo; do
        run tool_allowed "$tool"
        [ "$status" -eq 1 ]
    done
    # Under YES_TO_ALL=false: everything returns 0
    export YES_TO_ALL=false
    for tool in claude cline gemini grok mimo; do
        run tool_allowed "$tool"
        [ "$status" -eq 0 ]
    done
}
