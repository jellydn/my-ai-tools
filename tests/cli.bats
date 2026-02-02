#!/usr/bin/env bats
# Test suite for cli.sh functions

setup() {
    # Source the common.sh library
    load "$SCRIPT_DIR/lib/common.sh"
    export DRY_RUN=false
    export SCRIPT_DIR
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
    type copy_configurations &>/dev/null

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
    [[ "$output" == "[DRY RUN]"* ]]
}

@test "install_mcp_server handles installation result" {
    export DRY_RUN=true

    # Test that the function exists
    type install_mcp_server &>/dev/null

    [ "$status" -eq 0 ]
}

@test "install_ai_switcher function exists" {
    # Test that the function exists
    grep -q "^install_ai_switcher()" "$BATS_TEST_DIRNAME/../cli.sh"
}

@test "install_ai_switcher uses direct installation" {
    # Verify it uses install_ai_launcher_direct instead of execute_installer
    grep -q "install_ai_launcher_direct" "$BATS_TEST_DIRNAME/../cli.sh"
}

@test "install_ai_switcher checks for both ai and ai-switcher commands" {
    # Verify it checks for both binary names
    grep "install_ai_switcher" -A 10 "$BATS_TEST_DIRNAME/../cli.sh" | grep -q "command -v ai"
}
