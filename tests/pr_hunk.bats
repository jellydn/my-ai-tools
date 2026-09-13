#!/usr/bin/env bats
# Tests for Hunk integration

load helpers

LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
CONFIG="$REPO_ROOT/configs/hunk/config.toml"
README="$REPO_ROOT/README.md"

@test "Hunk config exists and is valid TOML" {
	[ -f "$CONFIG" ]
	run bash -c 'source "$1/lib/common.sh"; validate_config "$1/configs/hunk/config.toml"' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Hunk config enables the built-in Kanagawa theme and disables agent notes" {
	run grep -F 'theme = "kanagawa-wave"' "$CONFIG"
	[ "$status" -eq 0 ]
	run grep -F 'agent_notes = false' "$CONFIG"
	[ "$status" -eq 0 ]
}

@test "Hunk uses the official hunkdiff npm package" {
	run grep -F 'install -g hunkdiff' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F '"hunk:install_hunk"' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "Hunk installer rejects Node.js older than 18" {
	run bash -c '
		export DRY_RUN=false YES_TO_ALL=true IS_WINDOWS=false VERBOSE=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		node() {
			if [ "$1" = "-p" ]; then
				echo 17
			else
				echo v17.9.1
			fi
		}
		install_hunk
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"requires Node.js 18 or newer"* ]]
}

@test "Hunk installer fails when the installed binary cannot start" {
	run bash -c '
		export DRY_RUN=false YES_TO_ALL=true IS_WINDOWS=false VERBOSE=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		node() {
			if [ "$1" = "-p" ]; then
				echo 18
			else
				echo v18.0.0
			fi
		}
		_verify_package_manager() { echo npm; }
		execute() {
			[ "$1" != "hunk --version >/dev/null" ]
		}
		install_hunk
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"installed but could not start"* ]]
}

@test "Hunk config install honors XDG_CONFIG_HOME" {
	run bash -c '
		set -e
		temp_home=$(mktemp -d)
		temp_xdg=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_xdg"'\'' EXIT
		export HOME="$temp_home" XDG_CONFIG_HOME="$temp_xdg"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$XDG_CONFIG_HOME/hunk"
		source "$1/cli.sh"
		copy_hunk_configs >/dev/null
		cmp "$1/configs/hunk/config.toml" "$XDG_CONFIG_HOME/hunk/config.toml"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Hunk config copy failures are reported" {
	run bash -c '
		temp_home=$(mktemp -d)
		trap '\''rm -rf "$temp_home"'\'' EXIT
		export HOME="$temp_home" XDG_CONFIG_HOME="$temp_home/xdg"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$XDG_CONFIG_HOME/hunk"
		source "$1/cli.sh"
		copy_config_file() { return 1; }
		copy_hunk_configs
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"Failed to copy Hunk config"* ]]
	[[ "$output" != *"Hunk configs copied"* ]]
}

@test "Hunk config is backed up and reverse-synced at runtime" {
	run grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/hunk' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'generate_hunk_configs' "$GENERATE_SH"
	[ "$status" -eq 0 ]

	run bash -c '
		set -e
		temp_home=$(mktemp -d)
		temp_repo=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_repo"'\'' EXIT
		export HOME="$temp_home" XDG_CONFIG_HOME="$temp_home/xdg"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$XDG_CONFIG_HOME/hunk"
		cp "$1/configs/hunk/config.toml" "$XDG_CONFIG_HOME/hunk/config.toml"

		source "$1/cli.sh"
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$temp_home/backup"
		backup_configs >/dev/null
		cmp "$1/configs/hunk/config.toml" "$BACKUP_DIR/hunk/config.toml"

		source "$1/generate.sh"
		SCRIPT_DIR="$temp_repo"
		generate_hunk_configs >/dev/null
		cmp "$1/configs/hunk/config.toml" "$temp_repo/configs/hunk/config.toml"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Hunk export does not report success without config.toml" {
	run bash -c '
		temp_home=$(mktemp -d)
		temp_repo=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_repo"'\'' EXIT
		export HOME="$temp_home" XDG_CONFIG_HOME="$temp_home/xdg"
		export DRY_RUN=false VERBOSE=false
		mkdir -p "$XDG_CONFIG_HOME/hunk"
		source "$1/generate.sh"
		SCRIPT_DIR="$temp_repo"
		generate_hunk_configs
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Hunk config not found"* ]]
	[[ "$output" != *"Hunk configs generated"* ]]
}

@test "README documents Hunk installation, config, and review usage" {
	run grep -F 'npm install --global hunkdiff' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'configs/hunk/config.toml' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'hunk diff --watch' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'https://www.hunk.dev/docs/reference/config' "$README"
	[ "$status" -eq 0 ]
}

@test "Hunk support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-hunk-support.md" ]
}
