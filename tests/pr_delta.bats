#!/usr/bin/env bats
# Tests for Delta desktop agent support.

load helpers

LIB_COMMON="$REPO_ROOT/lib/common.sh"
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "Delta managed configs exist and settings are valid JSON" {
	[ -f "$REPO_ROOT/configs/delta/AGENTS.md" ]
	[ -f "$REPO_ROOT/configs/delta/settings.json" ]
	require_jq
	run jq -e '
		.send_message_with_modifier == true and
		.cursor_after_send == "next_user_message" and
		.default_diff_base == "uncommitted" and
		.diff_color_scheme == "blue_orange" and
		.diff_signs == true
	' "$REPO_ROOT/configs/delta/settings.json"
	[ "$status" -eq 0 ]
}

@test "Delta provider credentials are not checked in" {
	[ ! -e "$REPO_ROOT/configs/delta/.env" ]
}

@test "get_delta_settings_dir follows documented platform paths and override" {
	run bash -c '
		source "$1"
		HOME=/tmp/delta-home
		IS_WINDOWS=false
		unset DELTA_CONFIG_DIR XDG_CONFIG_HOME
		uname() { echo Darwin; }
		get_delta_settings_dir
	' _ "$LIB_COMMON"
	[ "$status" -eq 0 ]
	[ "$output" = "/tmp/delta-home/Library/Application Support/delta" ]

	run bash -c '
		source "$1"
		HOME=/tmp/delta-home
		IS_WINDOWS=false
		XDG_CONFIG_HOME=/tmp/xdg
		unset DELTA_CONFIG_DIR
		uname() { echo Linux; }
		get_delta_settings_dir
	' _ "$LIB_COMMON"
	[ "$status" -eq 0 ]
	[ "$output" = "/tmp/xdg/delta" ]

	run bash -c '
		source "$1"
		IS_WINDOWS=true
		APPDATA="C:\\Users\\delta\\AppData\\Roaming"
		unset DELTA_CONFIG_DIR
		get_delta_settings_dir
	' _ "$LIB_COMMON"
	[ "$status" -eq 0 ]
	[ "$output" = "C:/Users/delta/AppData/Roaming/delta" ]

	run bash -c '
		source "$1"
		DELTA_CONFIG_DIR=/tmp/custom-delta
		get_delta_settings_dir
	' _ "$LIB_COMMON"
	[ "$status" -eq 0 ]
	[ "$output" = "/tmp/custom-delta" ]
}

@test "Delta installer uses official manual installation guidance" {
	run grep -E '^install_delta\(\)' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F 'https://delta.dev/docs/getting-started' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F 'detect `command -v delta`' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F '"delta:install_delta"' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_delta_configs installs settings and personal rules for detected Delta" {
	run bash -c '
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.local/delta.app"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false
		source "$1"
		copy_delta_configs
		cmp "$2/configs/delta/settings.json" "$home/.config/delta/settings.json"
		cmp "$2/configs/delta/AGENTS.md" "$home/.config/delta/AGENTS.md"
	' _ "$CLI_SH" "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Delta configs participate in backup and reverse sync" {
	run grep -F 'get_delta_settings_dir' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -E '^generate_delta_configs\(\)' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	run grep -F 'configs/delta/settings.json' "$GENERATE_SH"
	[ "$status" -eq 0 ]
	run grep -E '^[[:space:]]*generate_delta_configs' "$GENERATE_SH"
	[ "$status" -eq 0 ]
}

@test "README documents Delta support, paths, and credential exclusion" {
	run grep -F '## 🔺 Delta (Optional)' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'https://delta.dev/docs/getting-started' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'DELTA_CONFIG_DIR' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'does not install, export, or commit' "$README"
	[ "$status" -eq 0 ]
}

@test "Delta support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-delta-support.md" ]
}
