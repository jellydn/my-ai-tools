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

@test "-y allowlist runs the Delta install and config flow" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		export HOME="$home" DELTA_CONFIG_DIR="$home/custom delta"
		export DRY_RUN=false YES_TO_ALL=true VERBOSE=false
		unset XDG_CONFIG_HOME
		source "$1"

		tool_allowed delta
		INSTALL_SEQUENCE=("delta:install_delta")
		install_delta() { touch "$home/install-delta-called"; }
		run_install_sequence >/dev/null

		mkdir -p "$home/.local/delta.app"
		copy_delta_configs >/dev/null
		[ -f "$home/install-delta-called" ]
		cmp "$2/configs/delta/settings.json" "$DELTA_CONFIG_DIR/settings.json"
		cmp "$2/configs/delta/AGENTS.md" "$home/.config/delta/AGENTS.md"
	' _ "$CLI_SH" "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "copy_delta_configs installs settings and personal rules for detected Delta" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.local/delta.app"
		export HOME="$home" DELTA_CONFIG_DIR="$home/custom delta"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		unset XDG_CONFIG_HOME
		source "$1"
		copy_delta_configs
		cmp "$2/configs/delta/settings.json" "$DELTA_CONFIG_DIR/settings.json"
		cmp "$2/configs/delta/AGENTS.md" "$home/.config/delta/AGENTS.md"
	' _ "$CLI_SH" "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "copy_delta_configs reports managed file copy failures" {
	run bash -c '
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.local/delta.app"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		unset DELTA_CONFIG_DIR XDG_CONFIG_HOME
		source "$1"
		copy_config_file() { return 1; }
		copy_delta_configs
	' _ "$CLI_SH"
	[ "$status" -ne 0 ]
	[[ "$output" == *"Failed to copy Delta settings"* ]]
	[[ "$output" != *"Delta configs copied"* ]]

	run bash -c '
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.local/delta.app"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		unset DELTA_CONFIG_DIR XDG_CONFIG_HOME
		source "$1"
		copy_config_file() { [ "${1##*/}" != "AGENTS.md" ]; }
		copy_delta_configs
	' _ "$CLI_SH"
	[ "$status" -ne 0 ]
	[[ "$output" == *"Failed to copy Delta personal rules"* ]]
	[[ "$output" != *"Delta configs copied"* ]]
}

@test "Delta backup excludes credentials and reverse sync honors DELTA_CONFIG_DIR" {
	run bash -c '
		set -e
		temp_home=$(mktemp -d)
		temp_repo=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_repo"'\'' EXIT
		export HOME="$temp_home" DELTA_CONFIG_DIR="$temp_home/custom delta"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		unset XDG_CONFIG_HOME
		mkdir -p "$DELTA_CONFIG_DIR" "$HOME/.config/delta"
		cp "$1/configs/delta/settings.json" "$DELTA_CONFIG_DIR/settings.json"
		cp "$1/configs/delta/AGENTS.md" "$HOME/.config/delta/AGENTS.md"
		printf '\''DELTA_SECRET=do-not-copy\n'\'' >"$DELTA_CONFIG_DIR/.env"
		printf '\''OTHER_SECRET=do-not-copy\n'\'' >"$HOME/.config/delta/.env"

		source "$1/cli.sh"
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$temp_home/backup"
		backup_configs >/dev/null
		cmp "$1/configs/delta/settings.json" "$BACKUP_DIR/delta/settings.json"
		cmp "$1/configs/delta/AGENTS.md" "$BACKUP_DIR/delta/AGENTS.md"
		[ ! -e "$BACKUP_DIR/delta/.env" ]
		! grep -R -F '\''do-not-copy'\'' "$BACKUP_DIR"

		source "$1/generate.sh"
		SCRIPT_DIR="$temp_repo"
		generate_delta_configs >/dev/null
		cmp "$1/configs/delta/settings.json" "$temp_repo/configs/delta/settings.json"
		cmp "$1/configs/delta/AGENTS.md" "$temp_repo/configs/delta/AGENTS.md"
		[ ! -e "$temp_repo/configs/delta/.env" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Delta reverse sync warns without claiming success when a managed file is missing" {
	run bash -c '
		temp_home=$(mktemp -d)
		temp_repo=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_repo"'\'' EXIT
		export HOME="$temp_home" DELTA_CONFIG_DIR="$temp_home/custom-delta"
		export DRY_RUN=false VERBOSE=false
		mkdir -p "$DELTA_CONFIG_DIR" "$HOME/.config/delta"
		cp "$1/configs/delta/settings.json" "$DELTA_CONFIG_DIR/settings.json"
		source "$1/generate.sh"
		SCRIPT_DIR="$temp_repo"
		generate_delta_configs
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Delta managed config files not found"* ]]
	[[ "$output" == *"AGENTS.md"* ]]
	[[ "$output" != *"Delta configs generated"* ]]
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
	run grep -F 'delta-windows-<architecture>-setup.exe' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'Expand-Archive .\delta-windows-<architecture>.zip' "$README"
	[ "$status" -eq 0 ]
	run awk '/^## 🔺 Delta \(Optional\)/,/^## 🎨 Codiff \(Optional\)/' "$README"
	[ "$status" -eq 0 ]
	[[ "$output" == *"./cli.sh --dry-run"* ]]
	[[ "$output" == *$'./cli.sh --dry-run\n./cli.sh'* ]]
}

@test "Delta support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-delta-support.md" ]
}
