#!/usr/bin/env bats
# Regression tests for the user-memory MCP server.

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
REGISTRY="$REPO_ROOT/configs/mcp-registry.json"

@test "registry defines the user-memory MCP server" {
	require_jq
	run jq -r '[.mcpServers["user-memory"].name, .mcpServers["user-memory"].command, (.mcpServers["user-memory"].args | join(" ")), (.mcpServers["user-memory"].requires | join(" ")), .mcpServers["user-memory"].category] | @tsv' "$REGISTRY"
	[ "$status" -eq 0 ]
	[ "$output" = $'user-memory\tuser-memory-mcp\t\tuser-memory-mcp\tknowledge' ]
}

@test "every MCP config containing agentmemory also contains user-memory-mcp" {
	while IFS= read -r config; do
		run grep -F 'user-memory-mcp' "$config"
		[ "$status" -eq 0 ]
	done < <(grep -rl '@agentmemory/mcp' "$REPO_ROOT/configs")
}

@test "JSON config uses the linked user-memory-mcp binary" {
	require_jq
	run jq -r '.mcpServers["user-memory"] | [.command, (.args | join(" "))] | @tsv' "$REPO_ROOT/configs/claude/mcp-servers.json"
	[ "$status" -eq 0 ]
	[ "$output" = $'user-memory-mcp\t' ]
}

@test "OpenCode config uses the local command-array form" {
	require_jq
	run jq -r '.mcp["user-memory"] | [(.command | join(" ")), (.enabled | tostring), .type] | @tsv' "$REPO_ROOT/configs/opencode/opencode.json"
	[ "$status" -eq 0 ]
	[ "$output" = $'user-memory-mcp\ttrue\tlocal' ]
}

@test "TOML config uses the stdio linked-binary form" {
	run grep -A3 -F '[mcp_servers.user-memory]' "$REPO_ROOT/configs/codex/config.toml"
	[ "$status" -eq 0 ]
	[[ "$output" == *$'type = "stdio"\ncommand = "user-memory-mcp"\nargs = []'* ]]
}

@test "install.sh can link user-memory-mcp from the monorepo" {
	run grep -F 'install_user_memory_mcp_now' "$REPO_ROOT/lib/install-deps.sh"
	[ "$status" -eq 0 ]
	run grep -F 'npm link --workspace @jellydn/user-memory-mcp' "$REPO_ROOT/lib/install-deps.sh"
	[ "$status" -eq 0 ]
}

@test "local installation installs dependencies before build and link in a disposable HOME" {
	run bash -c '
		H=$(mktemp -d)
		trap '\''rm -rf "$H"'\'' EXIT
		export HOME="$H" DRY_RUN=false YES_TO_ALL=true
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		SCRIPT_DIR="$1"
		npm() {
			if [ "$*" = "prefix -g" ]; then printf "%s\n" "$HOME/prefix"; return; fi
			printf "%s\n" "$*" >> "$HOME/calls"
			if [ "$1" = link ]; then
				mkdir -p "$HOME/prefix/bin"
				printf "#!/bin/sh\nexit 0\n" > "$HOME/prefix/bin/user-memory-mcp"
				chmod +x "$HOME/prefix/bin/user-memory-mcp"
			fi
		}
		install_user_memory_mcp_now || exit 1
		command -v user-memory-mcp || exit 1
		[ "$(cat "$HOME/calls")" = "$(printf "%s\n" "ci" "run build --workspace @jellydn/user-memory-mcp" "link --workspace @jellydn/user-memory-mcp")" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "failed dependency installation stops before build and link" {
	run bash -c '
		export DRY_RUN=false YES_TO_ALL=true
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		SCRIPT_DIR="$1"
		npm() { echo "npm $*"; return 1; }
		install_user_memory_mcp_now
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"npm ci"* ]]
	[[ "$output" != *"npm run build"* ]]
	[[ "$output" != *"npm link --workspace"* ]]
}

@test "missing local binary prevents enabling configurations after installation fails" {
	run bash -c '
		export DRY_RUN=false YES_TO_ALL=true
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		install_user_memory_mcp_now() { return 1; }
		handle_user_memory_mcp_installation_if_needed
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"Stopping before enabling configs"* ]]
}
