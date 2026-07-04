#!/usr/bin/env bats
# Tests for ctx scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/ctx/config.toml exists" {
	[ -f "$REPO_ROOT/configs/ctx/config.toml" ]
}

@test "lib/install.sh defines install_ctx()" {
	run grep -E '^install_ctx\(\)' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "lib/install.sh install_ctx() uses ctx.rs installer" {
	run grep -E 'ctx\.rs/install' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "lib/install.sh install_ctx() handles Windows PowerShell install" {
	run grep -E 'ctx\.rs/install\.ps1' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh main() installs ctx" {
	run grep -E '^[[:space:]]*install_ctx' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh defines copy_ctx_configs()" {
	run grep -E '^copy_ctx_configs\(\)' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_ctx_configs" {
	run grep -E '^[[:space:]]*copy_ctx_configs' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh backup_configs() includes ~/.ctx/" {
	run grep -E '\.ctx.*BACKUP_DIR' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh banner advertises ctx" {
	run grep -E '\bctx\b' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh defines generate_ctx_configs()" {
	run grep -E '^generate_ctx_configs\(\)' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh main() invokes generate_ctx_configs" {
	run grep -E '^[[:space:]]*generate_ctx_configs' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md references ctx in supported tools" {
	run grep -E '\bctx\b' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md has a ctx section with installer reference" {
	run grep -E 'ctx\.rs/install' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md ctx section includes config.toml reference" {
	run grep -E 'configs/ctx/config\.toml' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md ctx section links to ctxrs GitHub" {
	run grep -E 'github\.com/ctxrs/ctx' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "ctx MCP server registered in mcp-registry.json" {
	# jq check: .mcpServers.ctx.name exists
	run jq -r '.mcpServers.ctx.name' "$REPO_ROOT/configs/mcp-registry.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in claude mcp-servers.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/claude/mcp-servers.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in cursor mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/cursor/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in cline mcp-settings.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/cline/mcp-settings.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in factory mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/factory/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in kimi-code mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/kimi-code/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in commandcode mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/commandcode/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in kiro mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/kiro/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in copilot mcp-config.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/copilot/mcp-config.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in qodercli settings.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/qodercli/settings.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in pi mcp.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/pi/mcp.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in antigravity-migration mcp_config.json" {
	run jq -r '.mcpServers.ctx.command' "$REPO_ROOT/configs/antigravity-cli/plugins/my-ai-tools-gemini-migration/mcp_config.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in opencode opencode.json (mcp.ctx path)" {
	run jq -r '.mcp.ctx.command[0]' "$REPO_ROOT/configs/opencode/opencode.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in kilo config.json (mcp.ctx path)" {
	run jq -r '.mcp.ctx.command[0]' "$REPO_ROOT/configs/kilo/config.json"
	[ "$status" -eq 0 ]
	[ "$output" = "ctx" ]
}

@test "ctx MCP server in codex config.toml" {
	run grep -c '\[mcp_servers.ctx\]' "$REPO_ROOT/configs/codex/config.toml"
	[ "$status" -eq 0 ]
}

@test "ctx MCP server in grok config.toml" {
	run grep -c '\[mcp_servers.ctx\]' "$REPO_ROOT/configs/grok/config.toml"
	[ "$status" -eq 0 ]
}
