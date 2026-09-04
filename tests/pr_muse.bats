#!/usr/bin/env bats
# Tests for Meta Muse Code integration

load helpers

CONFIG_DIR="$REPO_ROOT/configs/muse"

@test "Muse settings use schema version 1 and valid MCP entries" {
	run jq -e '
		.schema_version == 1 and
		(.mcpServers | type == "object" and length > 0) and
		([.mcpServers[] |
			.transport == "stdio" and
			(.command | type == "string" and length > 0) and
			((.args // []) | type == "array") and
			.mode == "optional"
		] | all)
	' "$CONFIG_DIR/settings.json"
	[ "$status" -eq 0 ]
}

@test "Muse uses the official installer and muse binary" {
	run grep -F 'execute_installer "https://dev.meta.ai/install.sh"' "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
	run grep -F '"muse:install_muse"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "Muse config install copies managed settings" {
	local test_home="$BATS_TEST_TMPDIR/muse-copy-home"
	mkdir -p "$test_home/.config/muse"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_muse_configs
	'

	[ "$status" -eq 0 ]
	cmp "$CONFIG_DIR/settings.json" "$test_home/.config/muse/settings.json"
}

@test "Muse backup and export include managed settings only" {
	local test_home="$BATS_TEST_TMPDIR/muse-sync-home"
	local output_repo="$BATS_TEST_TMPDIR/muse-output-repo"
	mkdir -p "$test_home/.config/muse/sessions" "$output_repo"
	cp "$CONFIG_DIR/settings.json" "$test_home/.config/muse/settings.json"
	touch "$test_home/.config/muse/credentials.json" "$test_home/.config/muse/sessions/private.json"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" OUTPUT_REPO="$output_repo" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$HOME/backup"
		backup_configs >/dev/null

		source "$REPO_ROOT/generate.sh"
		SCRIPT_DIR="$OUTPUT_REPO"
		generate_muse_configs >/dev/null
	'

	[ "$status" -eq 0 ]
	cmp "$CONFIG_DIR/settings.json" "$test_home/backup/muse/settings.json"
	cmp "$CONFIG_DIR/settings.json" "$output_repo/configs/muse/settings.json"
	[ ! -e "$test_home/backup/muse/credentials.json" ]
	[ ! -e "$output_repo/configs/muse/credentials.json" ]
	[ ! -e "$output_repo/configs/muse/sessions" ]
}

@test "README documents Muse Code and the SDK as separate installs" {
	run grep -F 'curl -fsSL https://dev.meta.ai/install.sh | sh' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
	run grep -F 'npm install @muse-code/sdk' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
	run grep -F 'Node.js 20+' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}

@test "Muse support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-muse-code-support.md" ]
}
