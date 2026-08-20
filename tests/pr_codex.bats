#!/usr/bin/env bats
# Tests for configs/codex/ and Codex CLI integration

load helpers

CODEX_CONFIG_DIR="$REPO_ROOT/configs/codex"
README_FILE="$REPO_ROOT/README.md"

@test "configs/codex/AGENTS.md exists" {
	[ -f "$CODEX_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/codex/config.toml exists" {
	[ -f "$CODEX_CONFIG_DIR/config.toml" ]
}

@test "configs/codex/config.toml selects gpt-5.6-sol" {
	run grep -F 'model = "gpt-5.6-sol"' "$CODEX_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml sets 1M context window" {
	run grep -F "model_context_window = 1000000" "$CODEX_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml sets auto-compact limit" {
	run grep -F "model_auto_compact_token_limit = 900000" "$CODEX_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml has mcp_servers section" {
	run grep -F "[mcp_servers." "$CODEX_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/codex/config.toml references context7 MCP server" {
	run grep -F "context7" "$CODEX_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "README.md Codex section documents 1M context window" {
	run grep -F "model_context_window = 1000000" "$README_FILE"
	[ "$status" -eq 0 ]
}

@test "README.md Codex section documents one-off CLI override" {
	run grep -F "model_auto_compact_token_limit=900000" "$README_FILE"
	[ "$status" -eq 0 ]
}
