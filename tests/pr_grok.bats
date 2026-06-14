#!/usr/bin/env bats
# Tests for configs/grok/ and Grok CLI integration

load helpers

GROK_CONFIG_DIR="$REPO_ROOT/configs/grok"

@test "configs/grok/AGENTS.md exists" {
	[ -f "$GROK_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/grok/config.toml exists" {
	[ -f "$GROK_CONFIG_DIR/config.toml" ]
}

@test "configs/grok/AGENTS.md references tmux" {
	run grep -F "tmux" "$GROK_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/grok/AGENTS.md references best-practices" {
	run grep -F "best-practices.md" "$GROK_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml has mcp_servers section" {
	run grep -F "[mcp_servers." "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml references context7 MCP server" {
	run grep -F "context7" "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml references sequential-thinking MCP server" {
	run grep -F "sequential-thinking" "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml references qmd MCP server" {
	run grep -F "qmd" "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml references fff MCP server" {
	run grep -F "fff" "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "cli.sh has install_grok function" {
	run grep -F "install_grok()" "$REPO_ROOT/cli.sh"
	if [ "$status" -ne 0 ]; then
		run grep -F "install_grok()" "$REPO_ROOT/lib/install.sh"
	fi
	[ "$status" -eq 0 ]
}

@test "cli.sh has copy_grok_configs function" {
	run grep -F "copy_grok_configs()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh calls install_grok in main" {
	run grep -F "install_grok" "$REPO_ROOT/cli.sh"
	if [ "$status" -ne 0 ]; then
		run grep -F "install_grok" "$REPO_ROOT/lib/install.sh"
	fi
	[ "$status" -eq 0 ]
}

@test "cli.sh calls copy_grok_configs in copy_configurations" {
	run grep -F "copy_grok_configs" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh backs up grok configs" {
	run grep -F '$HOME/.grok' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh banner mentions Grok" {
	run grep -F "Grok" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh next steps mentions grok" {
	run grep -F "grok" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh has generate_grok_configs function" {
	run grep -F "generate_grok_configs()" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh calls generate_grok_configs in main" {
	run grep -F "generate_grok_configs" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "AGENTS.md references Grok" {
	run grep -F "Grok" "$REPO_ROOT/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "configs/grok/config.toml configures kanagawa-aligned ui theme" {
	run grep -F "[ui]" "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
	run grep -F 'theme = "auto"' "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
	run grep -F 'auto_dark_theme = "rosepine-moon"' "$GROK_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/grok/themes/kanagawa.toml exists" {
	[ -f "$GROK_CONFIG_DIR/themes/kanagawa.toml" ]
}

@test "configs/grok/themes/kanagawa.tmTheme exists" {
	[ -f "$GROK_CONFIG_DIR/themes/kanagawa.tmTheme" ]
}

@test "configs/grok/themes/kanagawa.toml uses Kanagawa Wave palette" {
	run grep -F "#1F1F28" "$GROK_CONFIG_DIR/themes/kanagawa.toml"
	[ "$status" -eq 0 ]
	run grep -F "#DCD7BA" "$GROK_CONFIG_DIR/themes/kanagawa.toml"
	[ "$status" -eq 0 ]
}

@test "cli.sh copies grok themes directory" {
	run grep -F 'configs/grok/themes' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F '$HOME/.grok/themes' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports grok themes" {
	run grep -F '$HOME/.grok/themes' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}
