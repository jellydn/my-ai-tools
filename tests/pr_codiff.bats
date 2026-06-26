#!/usr/bin/env bats
# Tests for Codiff scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/codiff/codiff.jsonc exists" {
	[ -f "$REPO_ROOT/configs/codiff/codiff.jsonc" ]
}

@test "lib/install.sh defines install_codiff()" {
	run grep -E '^install_codiff\(\)' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "lib/install.sh install_codiff() uses nkzw-tech/tap/codiff" {
	run grep -E 'nkzw-tech/tap/codiff' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "lib/install.sh install_codiff() handles macOS vs other platforms" {
	run grep -E 'IS_LINUX|brew install --cask' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh defines copy_codiff_configs()" {
	run grep -E '^copy_codiff_configs\(\)' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_codiff_configs" {
	run grep -E 'copy_codiff_configs' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh main() installs codiff" {
	run grep -E '^[[:space:]]*install_codiff' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh banner advertises Codiff" {
	run grep -E 'Codiff' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_codiff_configs() targets ~/.codiff/" {
	run grep -E 'HOME/\.codiff' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh backup_configs() includes ~/.codiff/" {
	run grep -E '\.codiff.*BACKUP_DIR' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh defines generate_codiff_configs()" {
	run grep -E '^generate_codiff_configs\(\)' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh main() invokes generate_codiff_configs" {
	run grep -E '^[[:space:]]*generate_codiff_configs' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md mentions Codiff in the supported-tools list" {
	run grep -E 'Codiff' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "README.md has a Codiff section with brew install example" {
	run grep -E 'brew install.*codiff|cask.*nkzw-tech' "$README"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "configs/codiff/codiff.jsonc has settings key" {
	run grep -E '"settings"' "$REPO_ROOT/configs/codiff/codiff.jsonc"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "configs/codiff/codiff.jsonc has agentBackend set to pi" {
	run grep -E '"agentBackend".*"pi"' "$REPO_ROOT/configs/codiff/codiff.jsonc"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "configs/codiff/codiff.jsonc has theme set to dark" {
	run grep -E '"theme".*"dark"' "$REPO_ROOT/configs/codiff/codiff.jsonc"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "cli.sh copy_codiff_configs() copies codiff.jsonc" {
	run grep -E 'codiff\.jsonc' "$CLI_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "generate.sh generate_codiff_configs() exports codiff.jsonc" {
	run grep -E 'codiff\.jsonc' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test ".changeset has an entry for Codiff support" {
	run bash -c "ls -1 $REPO_ROOT/.changeset/ | grep -i codiff"
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}
