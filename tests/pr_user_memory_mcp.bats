#!/usr/bin/env bats
# Regression tests for the user-memory MCP server.

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
REGISTRY="$REPO_ROOT/configs/mcp-registry.json"

@test "registry defines the user-memory MCP server" {
	require_jq
	run jq -r '[.mcpServers["user-memory"].name, .mcpServers["user-memory"].command, (.mcpServers["user-memory"].args | join(" ")), .mcpServers["user-memory"].category] | @tsv' "$REGISTRY"
	[ "$status" -eq 0 ]
	[ "$output" = $'user-memory\tnpx\t-y @jellydn/user-memory-mcp@latest\tknowledge' ]
}

@test "every MCP config containing agentmemory also contains user-memory" {
	while IFS= read -r config; do
		run grep -F '@jellydn/user-memory-mcp@latest' "$config"
		[ "$status" -eq 0 ]
	done < <(grep -rl '@agentmemory/mcp' "$REPO_ROOT/configs")
}

@test "JSON config uses npx command with user-memory args" {
	require_jq
	run jq -r '.mcpServers["user-memory"] | [.command, (.args | join(" "))] | @tsv' "$REPO_ROOT/configs/claude/mcp-servers.json"
	[ "$status" -eq 0 ]
	[ "$output" = $'npx\t-y @jellydn/user-memory-mcp@latest' ]
}

@test "OpenCode config uses the local command-array form" {
	require_jq
	run jq -r '.mcp["user-memory"] | [(.command | join(" ")), (.enabled | tostring), .type] | @tsv' "$REPO_ROOT/configs/opencode/opencode.json"
	[ "$status" -eq 0 ]
	[ "$output" = $'npx -y @jellydn/user-memory-mcp@latest\ttrue\tlocal' ]
}

@test "TOML config uses the stdio npx form" {
	run grep -A3 -F '[mcp_servers.user-memory]' "$REPO_ROOT/configs/codex/config.toml"
	[ "$status" -eq 0 ]
	[[ "$output" == *$'type = "stdio"\ncommand = "npx"\nargs = ["-y", "@jellydn/user-memory-mcp@latest"]'* ]]
}
