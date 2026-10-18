#!/usr/bin/env bats
# Tests for configs/reasonix/ and Reasonix CLI integration

load helpers

REASONIX_CONFIG_DIR="$REPO_ROOT/configs/reasonix"

@test "configs/reasonix/AGENTS.md exists" {
	[ -f "$REASONIX_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/reasonix/config.toml exists" {
	[ -f "$REASONIX_CONFIG_DIR/config.toml" ]
}

@test "configs/reasonix/themes/kanagawa/theme.json exists" {
	[ -f "$REASONIX_CONFIG_DIR/themes/kanagawa/theme.json" ]
}

@test "configs/reasonix/themes/kanagawa/theme.json uses Kanagawa Wave palette" {
	run jq -r '.id' "$REASONIX_CONFIG_DIR/themes/kanagawa/theme.json"
	[ "$output" = "kanagawa" ]
	run jq -r '.schemaVersion' "$REASONIX_CONFIG_DIR/themes/kanagawa/theme.json"
	[ "$output" = "2" ]
	run jq -r '.tokens.dark.bg' "$REASONIX_CONFIG_DIR/themes/kanagawa/theme.json"
	[ "$output" = "#1F1F28" ]
	run jq -r '.tokens.dark.fg' "$REASONIX_CONFIG_DIR/themes/kanagawa/theme.json"
	[ "$output" = "#DCD7BA" ]
}

@test "cli.sh has copy_reasonix_configs function" {
	run grep -F "copy_reasonix_configs()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh copies reasonix themes directory" {
	run grep -F 'configs/reasonix/themes' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh has generate_reasonix_configs function" {
	run grep -F "generate_reasonix_configs()" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports reasonix themes" {
	run grep -F 'configs/reasonix/themes' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "configs/reasonix/statusline.sh exists and is executable" {
	[ -f "$REASONIX_CONFIG_DIR/statusline.sh" ]
	[ -x "$REASONIX_CONFIG_DIR/statusline.sh" ]
}

@test "configs/reasonix/hooks scripts exist and are executable" {
	[ -f "$REASONIX_CONFIG_DIR/hooks/setup-hook.sh" ]
	[ -x "$REASONIX_CONFIG_DIR/hooks/setup-hook.sh" ]
	[ -f "$REASONIX_CONFIG_DIR/hooks/git-guard.sh" ]
	[ -x "$REASONIX_CONFIG_DIR/hooks/git-guard.sh" ]
}

@test "cli.sh copies reasonix statusline.sh and hooks" {
	run grep -F 'configs/reasonix/statusline.sh' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'configs/reasonix/hooks' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports reasonix statusline.sh and hooks" {
	run grep -F 'configs/reasonix/statusline.sh' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
	run grep -F 'configs/reasonix/hooks' "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}
