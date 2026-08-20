#!/usr/bin/env bats
# Tests for configs/codex/ and Codex CLI integration

load helpers

CODEX_CONFIG_DIR="$REPO_ROOT/configs/codex"
CODEX_CONFIG="$CODEX_CONFIG_DIR/config.toml"
CODEX_1M_PROFILE="$CODEX_CONFIG_DIR/1m.config.toml"
README_FILE="$REPO_ROOT/README.md"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"

toml_keys_before_tables() {
	local file="$1"
	local first_table
	first_table=$(grep -n -E '^\[' "$file" | head -1 | cut -d: -f1)
	[ -z "$first_table" ] && return 0

	local key
	for key in model_context_window model_auto_compact_token_limit; do
		local key_line
		key_line=$(grep -n -E "^${key}[[:space:]]*=" "$file" | head -1 | cut -d: -f1)
		[ -n "$key_line" ]
		[ "$key_line" -lt "$first_table" ]
	done
}

@test "configs/codex/AGENTS.md exists" {
	[ -f "$CODEX_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/codex/config.toml exists and is valid TOML" {
	[ -f "$CODEX_CONFIG" ]
	run bash -c 'source "$1/lib/common.sh"; validate_config "$2"' _ "$REPO_ROOT" "$CODEX_CONFIG"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml selects gpt-5.6-sol" {
	run grep -E '^model[[:space:]]*=[[:space:]]*"gpt-5.6-sol"' "$CODEX_CONFIG"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml does not set a 1M context window" {
	run grep -E '^model_context_window[[:space:]]*=' "$CODEX_CONFIG"
	[ "$status" -ne 0 ]
	run grep -E '^model_auto_compact_token_limit[[:space:]]*=' "$CODEX_CONFIG"
	[ "$status" -ne 0 ]
}

@test "configs/codex/config.toml has mcp_servers section" {
	run grep -F "[mcp_servers." "$CODEX_CONFIG"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml references context7 MCP server" {
	run grep -F "context7" "$CODEX_CONFIG"
	[ "$status" -eq 0 ]
}

@test "configs/codex/1m.config.toml exists and is valid TOML" {
	[ -f "$CODEX_1M_PROFILE" ]
	run bash -c 'source "$1/lib/common.sh"; validate_config "$2"' _ "$REPO_ROOT" "$CODEX_1M_PROFILE"
	[ "$status" -eq 0 ]
}

@test "configs/codex/1m.config.toml uses gpt-5.6-sol input-safe window and compact limits" {
	run grep -E '^model_context_window[[:space:]]*=[[:space:]]*1050000$' "$CODEX_1M_PROFILE"
	[ "$status" -eq 0 ]
	run grep -E '^model_auto_compact_token_limit[[:space:]]*=[[:space:]]*794000$' "$CODEX_1M_PROFILE"
	[ "$status" -eq 0 ]
	toml_keys_before_tables "$CODEX_1M_PROFILE"
}

@test "cli.sh and generate.sh round-trip the 1m Codex profile" {
	run grep -F 'configs/codex/1m.config.toml' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'copy_config_file "$SCRIPT_DIR/configs/codex/1m.config.toml" "$HOME/.codex/"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'copy_single "$HOME/.codex/1m.config.toml" "$SCRIPT_DIR/configs/codex/1m.config.toml"' "$GENERATE_SH"
	[ "$status" -eq 0 ]
}

@test "README.md documents the optional 1m profile and long-context pricing" {
	run grep -F "codex --profile 1m" "$README_FILE"
	[ "$status" -eq 0 ]
	run grep -F "model_context_window = 1050000" "$README_FILE"
	[ "$status" -eq 0 ]
	run grep -F "model_auto_compact_token_limit = 794000" "$README_FILE"
	[ "$status" -eq 0 ]
	run grep -F "model_auto_compact_token_limit=794000" "$README_FILE"
	[ "$status" -eq 0 ]
	run grep -F "272K" "$README_FILE"
	[ "$status" -eq 0 ]
}
