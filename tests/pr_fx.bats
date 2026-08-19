#!/usr/bin/env bats
# Tests for configs/fx/ and fx CLI integration

load helpers

FX_CONFIG_DIR="$REPO_ROOT/configs/fx"

@test "configs/fx/AGENTS.md exists" {
	[ -f "$FX_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/fx/AGENTS.md references tmux" {
	run grep -F "tmux" "$FX_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "cli.sh installs fx through the official setup script" {
	run grep -F 'https://fx.sh/setup.sh' "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh has copy_fx_configs function" {
	run grep -F "copy_fx_configs()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh copies fx AGENTS.md without managing private MCP state" {
	run grep -F 'configs/fx/AGENTS.md' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'configs/fx/mcp.json' "$REPO_ROOT/cli.sh"
	[ "$status" -ne 0 ]
}

@test "generate.sh has generate_fx_configs function" {
	run grep -F "generate_fx_configs()" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports only fx AGENTS.md" {
	run grep -F '$HOME/.fx/AGENTS.md' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
	run grep -F '$HOME/.fx/mcp.json' "$REPO_ROOT/generate.sh"
	[ "$status" -ne 0 ]
}
