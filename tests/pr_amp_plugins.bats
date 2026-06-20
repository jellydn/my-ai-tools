#!/usr/bin/env bats
# Tests for AMP plugins: cursor-composer-2.5.ts and others

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
CLI_FILE="$REPO_ROOT/cli.sh"
GENERATE_FILE="$REPO_ROOT/generate.sh"
README_FILE="$REPO_ROOT/README.md"
PLUGINS_DIR="$REPO_ROOT/configs/amp/plugins"

@test "AMP plugins directory exists" {
	[ -d "$PLUGINS_DIR" ]
}

@test "Cursor Composer 2.5 AMP plugin file exists" {
	[ -f "$PLUGINS_DIR/cursor-composer-2.5.ts" ]
}

@test "GLM 5.2 AMP plugin file exists" {
	[ -f "$PLUGINS_DIR/glm-52-mode.ts" ]
}

@test "cli.sh installs AMP .ts plugin files" {
	# Check that cli.sh handles .ts files (not just directories) in the AMP plugins loop
	run grep -F 'Installing plugin:' "$CLI_FILE"
	[ "$status" -eq 0 ]
}

@test "cli.sh copies cursor-composer .ts file to AMP plugins" {
	# Verify cli.sh handles .ts files in the AMP plugins install loop
	run grep -E 'Installing plugin:|\\.ts"' "$CLI_FILE"
	[ "$status" -eq 0 ]
}

@test "generate.sh exports AMP plugins" {
	run grep -F 'copy_directory' "$GENERATE_FILE"
	[ "$status" -eq 0 ]
	echo "$output" | grep -F 'amp/plugins'
}

@test "cli.sh AMP plugin install creates plugins directory" {
	run grep -E 'mkdir.*amp/plugins' "$CLI_FILE"
	[ "$status" -eq 0 ]
}

@test "README.md documents Cursor Composer AMP plugin" {
	run grep -F 'cursor-composer-2.5' "$README_FILE"
	[ "$status" -eq 0 ]
}

@test "README.md AMP plugins section documents Cursor Composer" {
	# Check the AMP Plugins section specifically (AMP section starts at line 1029, plugins at 1085)
	run grep -A 80 '## 🎯 Amp' "$README_FILE"
	[ "$status" -eq 0 ]
	echo "$output" | grep -F 'cursor-composer-2.5'
}
