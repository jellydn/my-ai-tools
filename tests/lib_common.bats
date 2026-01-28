#!/usr/bin/env bats
# Test suite for lib/common.sh utilities

setup() {
    # Source the common.sh library
    load "$SCRIPT_DIR/lib/common.sh"
    export DRY_RUN=false
}

@test "execute logs in dry-run mode" {
    export DRY_RUN=true
    run execute "echo test"
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}

@test "execute runs command in normal mode" {
    export DRY_RUN=false
    run execute "echo hello"
    [ "$status" -eq 0 ]
    [ "$output" == "hello" ]
}

@test "execute with spaces in command" {
    export DRY_RUN=false
    run execute "echo 'hello world'"
    [ "$status" -eq 0 ]
    [ "$output" == "hello world" ]
}

@test "cleanup_old_backups keeps most recent backups" {
    export DRY_RUN=true
    run cleanup_old_backups 3
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}

@test "validate_json returns 0 for valid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    echo '{"key": "value"}' > /tmp/test_valid.json
    run validate_json /tmp/test_valid.json
    [ "$status" -eq 0 ]
    rm -f /tmp/test_valid.json
}

@test "validate_json returns 1 for invalid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    echo '{invalid json}' > /tmp/test_invalid.json
    run validate_json /tmp/test_invalid.json
    [ "$status" -eq 1 ]
    rm -f /tmp/test_invalid.json
}

@test "validate_json returns 1 for missing file" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run validate_json /tmp/nonexistent.json
    [ "$status" -eq 1 ]
}

@test "log_info outputs with blue color prefix" {
    run log_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "ℹ"* ]]
}

@test "log_success outputs with green checkmark" {
    run log_success "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "✓"* ]]
}

@test "log_warning outputs with yellow warning" {
    run log_warning "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "⚠"* ]]
}

@test "log_error outputs with red X" {
    run log_error "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "✗"* ]]
}
