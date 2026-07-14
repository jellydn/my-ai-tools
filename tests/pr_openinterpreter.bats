#!/usr/bin/env bats
# Tests for configs/openinterpreter/ and Open Interpreter integration

load helpers

OI_CONFIG_DIR="$REPO_ROOT/configs/openinterpreter"

@test "configs/openinterpreter/AGENTS.md exists" {
	[ -f "$OI_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/openinterpreter/config.toml exists" {
	[ -f "$OI_CONFIG_DIR/config.toml" ]
}

@test "configs/openinterpreter/config.toml has mcp_servers section" {
	run grep -F "[mcp_servers." "$OI_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "configs/openinterpreter/config.toml references context7 MCP server" {
	run grep -F "context7" "$OI_CONFIG_DIR/config.toml"
	[ "$status" -eq 0 ]
}

@test "lib/install.sh has install_openinterpreter function" {
	run grep -F "install_openinterpreter()" "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh calls install_openinterpreter in main" {
	run grep -F "install_openinterpreter" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh has copy_openinterpreter_configs function" {
	run grep -F "copy_openinterpreter_configs()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh calls copy_openinterpreter_configs in copy_configurations" {
	run grep -F "copy_openinterpreter_configs" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh backs up openinterpreter configs" {
	run grep -F '$HOME/.openinterpreter' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh has generate_openinterpreter_configs function" {
	run grep -F "generate_openinterpreter_configs()" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "generate.sh calls generate_openinterpreter_configs in main" {
	run grep -F "generate_openinterpreter_configs" "$REPO_ROOT/generate.sh"
	[ "$status" -eq 0 ]
}

@test "README.md references Open Interpreter" {
	run grep -F "Open Interpreter" "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}

@test "configs/openinterpreter/agents includes code-reviewer" {
	[ -f "$OI_CONFIG_DIR/agents/code-reviewer.toml" ]
}

@test "cli.sh supports migrate-codex flag" {
	run grep -F "migrate-codex" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "cli.sh defines migrate_codex_to_openinterpreter" {
	run grep -F "migrate_codex_to_openinterpreter()" "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}
