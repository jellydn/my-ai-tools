#!/usr/bin/env bats
# Tests for MCP registry parsing and installation

setup() {
    # Create a unique temp directory for mocks and files
    TEST_TEMP_DIR="$(mktemp -d -t mcp-reg-test-XXXXXX)"
    export TEST_TEMP_DIR

    # Create the log file path
    LOG_FILE="$TEST_TEMP_DIR/claude_calls.log"
    export LOG_FILE
    touch "$LOG_FILE"

    # Prepend temp directory to PATH so our fake commands are found first
    export ORIGINAL_PATH="$PATH"
    export PATH="$TEST_TEMP_DIR:$PATH"

    # Write a fake claude command in PATH
    cat << 'EOF' > "$TEST_TEMP_DIR/claude"
#!/usr/bin/env bash
echo "$@" >> "$LOG_FILE"
EOF
    chmod +x "$TEST_TEMP_DIR/claude"

    # Write mock prerequisites (e.g. fff-mcp, sem-mcp) as executables so command -v succeeds
    touch "$TEST_TEMP_DIR/test-prereq"
    chmod +x "$TEST_TEMP_DIR/test-prereq"
    touch "$TEST_TEMP_DIR/fff-mcp"
    chmod +x "$TEST_TEMP_DIR/fff-mcp"
    touch "$TEST_TEMP_DIR/qmd"
    chmod +x "$TEST_TEMP_DIR/qmd"

    # Source the library and configuration scripts
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    source "$BATS_TEST_DIRNAME/../lib/install.sh"
    source "$BATS_TEST_DIRNAME/../cli.sh"

    export DRY_RUN=false
    export YES_TO_ALL=true  # Force auto-installation
    export VERBOSE=false
}

teardown() {
    # Restore original path and clean up temp files
    export PATH="$ORIGINAL_PATH"
    rm -rf "$TEST_TEMP_DIR"
}

@test "registry MCP installation parses args and prereqs without shifting on empty fields" {
    # Generate a temporary registry file with missing/empty fields to check for shifting
    cat << 'EOF' > "$TEST_TEMP_DIR/test-registry.json"
{
  "mcpServers": {
    "server-with-args": {
      "name": "server-with-args",
      "description": "server with args",
      "command": "npx",
      "args": [
        "-y",
        "@scope/package-1"
      ],
      "requires": [],
      "category": "category-1"
    },
    "server-empty-args-with-prereq": {
      "name": "server-empty-args-with-prereq",
      "description": "server with empty args but having prereq",
      "command": "test-prereq",
      "args": [],
      "requires": [
        "test-prereq"
      ],
      "category": "category-2"
    }
  }
}
EOF

    # First verify that claude is in the allowlist
    run tool_allowed "claude"
    [ "$status" -eq 0 ]

    # Run the registry installation
    run install_mcp_servers_from_registry "claude" "$TEST_TEMP_DIR/test-registry.json"
    [ "$status" -eq 0 ]

    # Verify the commands appended in the log file
    run cat "$LOG_FILE"
    [ "$status" -eq 0 ]

    # Confirm the first server registered with both arguments
    [[ "$output" == *"mcp add --scope user --transport stdio server-with-args -- npx -y @scope/package-1"* ]]

    # Confirm the second server resolved prerequisites and registered correctly with empty args
    [[ "$output" == *"mcp add --scope user --transport stdio server-empty-args-with-prereq -- test-prereq"* ]]
    # Ensure there was no "test-prereq" args appended (it should have empty args)
    [[ "$output" != *"server-empty-args-with-prereq -- test-prereq test-prereq"* ]]
}

@test "registry MCP installation preserves zero, one, and multiple arguments case-by-case" {
    cat << 'EOF' > "$TEST_TEMP_DIR/test-registry-shapes.json"
{
  "mcpServers": {
    "context7": {
      "name": "context7",
      "description": "documentation lookup",
      "command": "npx",
      "args": [
        "-y",
        "@upstash/context7-mcp@latest"
      ],
      "requires": [],
      "category": "documentation"
    },
    "qmd": {
      "name": "qmd",
      "description": "knowledge management",
      "command": "qmd",
      "args": [
        "mcp"
      ],
      "requires": [
        "qmd"
      ],
      "category": "knowledge"
    },
    "fff": {
      "name": "fff",
      "description": "fast file search with frecency ranking",
      "command": "fff-mcp",
      "args": [],
      "requires": [
        "fff-mcp"
      ],
      "category": "search"
    }
  }
}
EOF

    # Run the registry installation
    run install_mcp_servers_from_registry "claude" "$TEST_TEMP_DIR/test-registry-shapes.json"
    [ "$status" -eq 0 ]

    # Verify the commands appended in the log file
    run cat "$LOG_FILE"
    [ "$status" -eq 0 ]

    # Multiple args check: context7
    [[ "$output" == *"mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest"* ]]

    # One arg check: qmd
    [[ "$output" == *"mcp add --scope user --transport stdio qmd -- qmd mcp"* ]]

    # Zero args check: fff
    [[ "$output" == *"mcp add --scope user --transport stdio fff -- fff-mcp"* ]]
    [[ "$output" != *"fff -- fff-mcp fff-mcp"* ]]
}

@test "registry MCP installation survives newlines and empty-string args" {
    cat << 'EOF' > "$TEST_TEMP_DIR/claude"
#!/usr/bin/env bash
# Record argc and each argv with %q so empty-string args stay visible.
{
	printf 'argc=%s' "$#"
	for arg in "$@"; do
		printf ' %q' "$arg"
	done
	printf '\n'
} >> "$LOG_FILE"
EOF
    chmod +x "$TEST_TEMP_DIR/claude"

    cat << 'EOF' > "$TEST_TEMP_DIR/test-registry-lossy.json"
{
  "mcpServers": {
    "newline-desc": {
      "name": "newline-desc",
      "description": "first\nsecond",
      "command": "npx",
      "args": ["-y", "@scope/pkg"],
      "requires": [],
      "category": "test"
    },
    "empty-string-arg": {
      "name": "empty-string-arg",
      "description": "single empty arg",
      "command": "npx",
      "args": [""],
      "requires": [],
      "category": "test"
    }
  }
}
EOF

    run install_mcp_servers_from_registry "claude" "$TEST_TEMP_DIR/test-registry-lossy.json"
    [ "$status" -eq 0 ]

    run cat "$LOG_FILE"
    [ "$status" -eq 0 ]

    [[ "$output" == *"mcp add --scope user --transport stdio newline-desc -- npx -y @scope/pkg"* ]]
    [[ "$output" == *"empty-string-arg -- npx ''"* ]]
    # mcp add --scope user --transport stdio <name> -- <cmd> [args...]
    # empty-string-arg keeps a distinct empty argv entry (argc=10 with the empty arg).
    [[ "$output" == *"argc=10 mcp add --scope user --transport stdio empty-string-arg -- npx ''"* ]]
}
