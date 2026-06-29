#!/usr/bin/env bats
# Tests for configs/cline/ and Cline CLI integration

load helpers

CLINE_CONFIG_DIR="$REPO_ROOT/configs/cline"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/cline/AGENTS.md exists" {
	[ -f "$CLINE_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/cline/AGENTS.md references tmux" {
	run grep -F "tmux" "$CLINE_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/cline/AGENTS.md references best-practices" {
	run grep -F "best-practices.md" "$CLINE_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/cline/AGENTS.md references the fff MCP tools" {
	run grep -F "fff" "$CLINE_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/cline/mcp-settings.json exists and is valid JSON" {
	require_jq
	[ -f "$CLINE_CONFIG_DIR/mcp-settings.json" ]
	run jq '.' "$CLINE_CONFIG_DIR/mcp-settings.json"
	[ "$status" -eq 0 ]
}

@test "configs/cline/mcp-settings.json has mcpServers key" {
	require_jq
	run jq -e '.mcpServers' "$CLINE_CONFIG_DIR/mcp-settings.json"
	[ "$status" -eq 0 ]
}

@test "configs/cline/mcp-settings.json includes context7 server via stdio command" {
	require_jq
	run jq -e '.mcpServers.context7.command' "$CLINE_CONFIG_DIR/mcp-settings.json"
	[ "$status" -eq 0 ]
}

@test "configs/cline/mcp-settings.json does not use VS Code-only 'type: local' transport" {
	run grep -F '"type": "local"' "$CLINE_CONFIG_DIR/mcp-settings.json"
	[ "$status" -ne 0 ]
}

@test "configs/cline/mcp-settings.json does not use URL-only context7 without a transport" {
	run grep -F '"url": "https://mcp.context7.com/mcp"' "$CLINE_CONFIG_DIR/mcp-settings.json"
	[ "$status" -ne 0 ]
}

@test "configs/cline/models.json exists and is valid JSON" {
	require_jq
	[ -f "$CLINE_CONFIG_DIR/models.json" ]
	run jq '.' "$CLINE_CONFIG_DIR/models.json"
	[ "$status" -eq 0 ]
}

@test "cli.sh defines copy_cline_configs()" {
	run grep -E '^copy_cline_configs\(\)' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_cline_configs" {
	run grep -E 'copy_cline_configs' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_cline_configs() installs AGENTS.md to ~/.cline/rules/" {
	run grep -F 'configs/cline/AGENTS.md' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F '.cline/rules/01-guidelines.md' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "cli.sh copy_cline_configs() publishes AGENTS.md to ~/.agents/AGENTS.md" {
	run grep -F '.agents/AGENTS.md' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "cli.sh installs MCP settings to the Cline CLI settings path" {
	run grep -F 'cline_mcp_settings.json' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "cli.sh validates cline mcp-settings.json and models.json" {
	run grep -F 'configs/cline/mcp-settings.json' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'configs/cline/models.json' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "cli.sh create_tool_skills_symlinks() includes ~/.cline/skills" {
	run grep -F '$HOME/.cline/skills' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "cli.sh universal skills usage log mentions Cline" {
	run grep -F 'Cline, and more' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "generate.sh defines generate_cline_configs()" {
	run grep -E '^generate_cline_configs\(\)' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh generate_cline_configs() exports AGENTS.md" {
	run grep -F 'configs/cline/AGENTS.md' "$GENERATE_SH"
	[ "$status" -eq 0 ]
}

@test "generate.sh main() invokes generate_cline_configs" {
	run grep -E '^[[:space:]]*generate_cline_configs' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md mentions Cline in the supported-tools list" {
	run grep -F 'Cline' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}
