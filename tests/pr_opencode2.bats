#!/usr/bin/env bats
# OpenCode 2 beta compatibility checks.

load helpers

CLI_SH="$REPO_ROOT/cli.sh"
INSTALL_SH="$REPO_ROOT/lib/install.sh"
LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"

@test "OpenCode 2 installer is registered alongside OpenCode 1" {
	run grep -F '"opencode:install_opencode"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F '"opencode:install_opencode2"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'install_opencode2()' "$INSTALL_SH"
	[ "$status" -eq 0 ]
}

@test "OpenCode 2 installer uses its separate beta binary and package" {
	run grep -F 'command -v opencode2' "$INSTALL_SH"
	[ "$status" -eq 0 ]
	run grep -F '@opencode-ai/cli@next' "$INSTALL_SH"
	[ "$status" -eq 0 ]
	run grep -F -- '--trust @opencode-ai/cli@next' "$INSTALL_SH"
	[ "$status" -eq 0 ]
	run grep -F -- '--allow-build=@opencode-ai/cli @opencode-ai/cli@next' "$INSTALL_SH"
	[ "$status" -eq 0 ]
}

@test "OpenCode config installation accepts either binary while sharing the v1 config path" {
	run grep -F 'command -v opencode2' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'command -v opencode' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F '$HOME/.config/opencode' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "OpenCode config copy detects opencode2 without requiring opencode1" {
	local test_home="$BATS_TEST_TMPDIR/opencode2-home"
	local fake_bin="$BATS_TEST_TMPDIR/opencode2-bin"
	mkdir -p "$test_home/.config/opencode" "$fake_bin"
	printf '#!/bin/sh\n' >"$fake_bin/opencode2"
	chmod +x "$fake_bin/opencode2"

	run env HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=true YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_opencode_configs
	'
	[ "$status" -eq 0 ]
	[[ "$output" == *"Detected OpenCode (via command-v2)"* ]]
}

@test "AI launcher exposes OpenCode 2 without replacing OpenCode 1" {
	require_jq
	run jq -e '[.tools[] | select(.name == "opencode")][0].command == "opencode"' "$LAUNCHER_CONFIG"
	[ "$status" -eq 0 ]
	run jq -e '[.tools[] | select(.name == "opencode2")][0].command == "opencode2"' "$LAUNCHER_CONFIG"
	[ "$status" -eq 0 ]
}
