#!/usr/bin/env bats
# The local user-preference server is opt-in, not another default memory service.

load helpers

@test "default registry keeps existing memory choices without user-memory" {
	require_jq
	run jq -e '.mcpServers | has("qmd") and has("codebase-memory-mcp") and has("agentmemory") and (has("user-memory") | not)' "$REPO_ROOT/configs/mcp-registry.json"
	[ "$status" -eq 0 ]
}

@test "default assistant configurations do not register user-memory" {
	run grep -rl 'user-memory-mcp' "$REPO_ROOT/configs"
	[ "$status" -eq 1 ]
}

@test "noninteractive installer preview does not install or configure user-memory" {
	run bash -c '
		H=$(mktemp -d)
		trap '\''rm -rf "$H"'\'' EXIT
		export HOME="$H"
		bash "$1/cli.sh" --dry-run --yes
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"DRY RUN MODE"* ]]
	[[ "$output" != *"user-memory"* ]]
}
