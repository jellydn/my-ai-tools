#!/usr/bin/env bats
# Tests for configs/pool/ and Pool CLI integration

load helpers

POOL_CONFIG_DIR="$REPO_ROOT/configs/pool"

@test "configs/pool/AGENTS.md exists" {
	[ -f "$POOL_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/pool/AGENTS.md references tmux" {
	run grep -F "tmux" "$POOL_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/pool/AGENTS.md references best-practices" {
	run grep -F "best-practices.md" "$POOL_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/pool/AGENTS.md references git safety" {
	run grep -F "git-guidelines.md" "$POOL_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/pool/AGENTS.md references fff MCP" {
	run grep -F "fff MCP" "$POOL_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/pool/mcp.json exists" {
	[ -f "$POOL_CONFIG_DIR/mcp.json" ]
}

@test "configs/pool/mcp.json is valid JSON" {
	require_jq
	run jq empty "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
}

@test "configs/pool/mcp.json has mcpServers object" {
	require_jq
	run jq -e '.mcpServers | type == "object"' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json has context7 server" {
	require_jq
	run jq -e '.mcpServers | has("context7")' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json has qmd server" {
	require_jq
	run jq -e '.mcpServers | has("qmd")' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json has fff server" {
	require_jq
	run jq -e '.mcpServers | has("fff")' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json has sem server" {
	require_jq
	run jq -e '.mcpServers | has("sem")' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json every server has transport field" {
	require_jq
	run jq -e '[.mcpServers[] | select(.transport == null)] | length == 0' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "configs/pool/mcp.json every server has enabled field" {
	require_jq
	run jq -e '[.mcpServers[] | select(.enabled == null)] | length == 0' "$POOL_CONFIG_DIR/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "cli.sh has install_pool function" {
	run grep -F "install_pool()" "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh has copy_pool_configs function" {
	run grep -F "copy_pool_configs()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh calls install_pool in main" {
	run grep -F "install_pool" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh calls copy_pool_configs in copy_configurations" {
	run grep -F "copy_pool_configs" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh backs up pool configs" {
	run grep -F '$HOME/.config/poolside' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh banner mentions Pool CLI" {
	run grep -F "Pool CLI" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh next steps mentions pool" {
	run grep -F "'pool'" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh has generate_pool_configs function" {
	run grep -F "generate_pool_configs()" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh calls generate_pool_configs in main" {
	run grep -c "generate_pool_configs" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
	[ "$output" -ge 2 ]
}

@test "AGENTS.md references Pool CLI" {
	run grep -F "Pool CLI" "$REPO_ROOT/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "cli.sh copies pool mcp.json" {
	run grep -F 'configs/pool/mcp.json' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F '$HOME/.config/poolside/' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports pool mcp.json" {
	run grep -F '$HOME/.config/poolside/mcp.json' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh creates poolside skills symlink" {
	run grep -F '$HOME/.config/poolside/skills' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}
