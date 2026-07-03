#!/usr/bin/env bats
# Tests for ctx scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
README="$REPO_ROOT/README.md"

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

@test "cli.sh banner advertises ctx" {
	run grep -E '\bctx\b' "$CLI_SH"
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

@test "README.md ctx section links to ctxrs GitHub" {
	run grep -E 'github\.com/ctxrs/ctx' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}
