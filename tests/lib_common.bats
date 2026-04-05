#!/usr/bin/env bats
# Test suite for lib/common.sh utilities

setup() {
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    export DRY_RUN=false
}

@test "execute logs in dry-run mode" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; DRY_RUN=true; execute \"echo test\" 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
}

@test "execute runs command in normal mode" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; DRY_RUN=false; execute \"echo hello\""
    [ "$status" -eq 0 ]
    [ "$output" == "hello" ]
}

@test "execute with spaces in command" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; DRY_RUN=false; execute \"echo 'hello world'\""
    [ "$status" -eq 0 ]
    [ "$output" == "hello world" ]
}

@test "cleanup_old_backups keeps most recent backups" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; DRY_RUN=true; cleanup_old_backups 3 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
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
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; log_info \"test message\" 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == "ℹ"* ]]
}

@test "log_success outputs with green checkmark" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; log_success \"test message\" 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == "✓"* ]]
}

@test "log_warning outputs with yellow warning" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; log_warning \"test message\" 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == "⚠"* ]]
}

@test "log_error outputs with red X" {
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; log_error \"test message\" 2>&1 | sed -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == "✗"* ]]
}

@test "normalize_path preserves urls and root paths" {
    run normalize_path "http://example.com//a///b/"
    [ "$status" -eq 0 ]
    [ "$output" = "http://example.com//a///b" ]

    run normalize_path "//server/share//path"
    [ "$status" -eq 0 ]
    [ "$output" = "//server/share//path" ]

    run normalize_path "/"
    [ "$status" -eq 0 ]
    [ "$output" = "/" ]

    run normalize_path "C:/"
    [ "$status" -eq 0 ]
    [ "$output" = "C:/" ]
}

@test "get_temp_dir prefers TMPDIR" {
    export TMPDIR="/tmp/my-ai-tools-tests"
    run get_temp_dir
    [ "$status" -eq 0 ]
    [ "$output" = "/tmp/my-ai-tools-tests" ]
    unset TMPDIR
}

@test "get_temp_dir falls back for Windows TEMP without cygpath" {
    export TMPDIR=""
    export TEMP="C:\\Users\\Test\\Temp"
    IS_WINDOWS=true

    run get_temp_dir
    [ "$status" -eq 0 ]
    [ "$output" = "/tmp" ]

    IS_WINDOWS=false
    unset TEMP
}

@test "detect_tool recognizes config files" {
    local config_file="/tmp/my-ai-tools-detect-tool.json"
    echo '{}' > "$config_file"

    run detect_tool --detailed "definitely-missing-command" "$config_file"
    [ "$status" -eq 0 ]
    [ "$output" = "file" ]

    rm -f "$config_file"
}

@test "validate_yaml fails on invalid yaml with spaces in path" {
    if ! command -v python3 &>/dev/null && ! command -v yq &>/dev/null && ! command -v ruby &>/dev/null; then
        skip "no YAML validator available"
    fi

    local yaml_file="/tmp/my ai tools invalid.yaml"
    printf 'key: [1, 2\n' > "$yaml_file"

    run validate_yaml "$yaml_file"
    [ "$status" -eq 1 ]

    rm -f "$yaml_file"
}

@test "validate_yaml skips when python3 exists but PyYAML is unavailable and no fallback validator exists" {
    local fake_bin_dir="/tmp/my-ai-tools-fake-bin-$$"
    local yaml_file="/tmp/my-ai-tools-valid.yaml"
    local sed_bin
    sed_bin=$(command -v sed)

    mkdir -p "$fake_bin_dir"
    cat > "$fake_bin_dir/python3" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$fake_bin_dir/python3"
    printf 'key: value\n' > "$yaml_file"

    # Only the stub python3 on PATH so yq/ruby cannot mask the skip; use absolute sed for ANSI strip
    run bash -c "source \"$BATS_TEST_DIRNAME/../lib/common.sh\"; PATH=\"$fake_bin_dir\"; validate_yaml \"$yaml_file\" 2>&1 | \"$sed_bin\" -E 's/\x1B\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No YAML validator available"* ]]

    rm -f "$fake_bin_dir/python3" "$yaml_file"
    rmdir "$fake_bin_dir"
}

@test "validate_config_with_schema fails when schema mismatches" {
    if ! command -v python3 &>/dev/null || ! python3 -c "import jsonschema" &>/dev/null; then
        skip "python jsonschema not available"
    fi

    local schema_file="/tmp/my-ai-tools-schema.json"
    local data_file="/tmp/my-ai-tools-data.json"

    cat > "$schema_file" <<'EOF'
{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","required":["name"],"properties":{"name":{"type":"string"}}}
EOF

    local schema_url="file://$schema_file"
    cat > "$data_file" <<EOF
{"$schema":"$schema_url","name": 123}
EOF

    run validate_config_with_schema "$data_file"
    [ "$status" -ne 0 ]

    rm -f "$schema_file" "$data_file"
}

@test "run_parallel handles empty command list" {
    run run_parallel 2
    [ "$status" -eq 0 ]
}

@test "run_parallel runs commands" {
    run run_parallel 2 "echo one" "echo two"
    [ "$status" -eq 0 ]
    [[ "$output" == *"one"* ]]
    [[ "$output" == *"two"* ]]
}
