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
	run grep -E 'copy_ctx_configs' "$CLI_SH"
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
