#!/usr/bin/env bats
# Tests for ctx scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/TOOL_REFERENCE.md"

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
	run grep -F '"ctx:install_ctx"' "$CLI_SH"
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

@test "ctx keeps a verified install when optional setup fails but rejects binary installation failures" {
	cat > "$BATS_TEST_TMPDIR/ctx-fixture" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = --version ]; then
    [ "$MODE" != binary-fails ] || exit 1
    echo "ctx 2.2.8"
elif [ "$1" = setup ]; then
    if [ "$MODE" = setup-fails ] || [ "$MODE" = setup-skipped ]; then
        echo "all_provider_terminal_coverage_unavailable: use an exact --path" >&2
        exit 1
    fi
    if [ "$MODE" = no-daemon ]; then
        [ "$2" = --no-daemon ] || exit 1
    fi
    echo "Index ready"
fi
EOF
	for mode in ready setup-fails setup-skipped no-daemon binary-fails install-fails; do
		run env PATH="/usr/bin:/bin" MODE="$mode" bash -c '
			export HOME="$2/$MODE" DRY_RUN=false YES_TO_ALL=true
			[ "$MODE" != setup-skipped ] || export CTX_INSTALL_NO_SETUP=1
			[ "$MODE" != no-daemon ] || export CTX_INSTALL_NO_DAEMON=1
			source "$1/lib/common.sh"
			source "$1/lib/install.sh"
			IS_WINDOWS=true
			fixture="$2/ctx-fixture"
			powershell.exe() { :; }
			execute() {
				if [[ "$1" == powershell.exe* ]]; then
					[ "$MODE" != install-fails ] || return 1
					mkdir -p "$HOME/.local/bin"
					cp "$fixture" "$HOME/.local/bin/ctx"
					chmod +x "$HOME/.local/bin/ctx"
					# Simulate the upstream installer bundling a fatal initial setup unless opted out.
					[ "${CTX_INSTALL_NO_SETUP:-0}" = 1 ] || "$HOME/.local/bin/ctx" setup
				else
					eval "$1"
				fi
			}
			install_ctx
		' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR"
		if [[ "$mode" == *-fails && "$mode" != setup-fails ]]; then
			[ "$status" -ne 0 ]
			[[ "$output" != *"ctx installed"* ]]
		else
			[ "$status" -eq 0 ]
			[[ "$output" == *"ctx installed"* ]]
			if [ "$mode" = setup-fails ]; then
				[[ "$output" == *"all_provider_terminal_coverage_unavailable"* ]]
				[[ "$output" == *"optional history setup failed"* ]]
				[[ "$output" == *"Retry: ctx setup"* ]]
				[[ "$output" == *"ctx import --provider pi --path"* ]]
			elif [ "$mode" = setup-skipped ]; then
				[[ "$output" != *"all_provider_terminal_coverage_unavailable"* ]]
			else
				[[ "$output" == *"Index ready"* ]]
			fi
		fi
	done
}
