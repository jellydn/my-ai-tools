#!/usr/bin/env bats
# Tests for OpenMausBot support.

load helpers

CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
LIB_OPENMAUSBOT="$REPO_ROOT/lib/install-openmausbot.sh"
README="$REPO_ROOT/TOOL_REFERENCE.md"

@test "OpenMausBot scaffold exists and does not ship private state" {
	[ -f "$REPO_ROOT/configs/openmausbot/README.md" ]
	# Credentials, transcripts, and databases must never be committed, even
	# after generate populates the managed roster files.
	[ ! -e "$REPO_ROOT/configs/openmausbot/config.json" ]
	[ ! -e "$REPO_ROOT/configs/openmausbot/providers" ]
	[ ! -e "$REPO_ROOT/configs/openmausbot/messages.db" ]
	[ ! -e "$REPO_ROOT/configs/openmausbot/runtime.db" ]
	[ ! -e "$REPO_ROOT/configs/openmausbot/events" ]
	[ ! -e "$REPO_ROOT/configs/openmausbot/native" ]
}

@test "OpenMausBot installer is registered and documented" {
	run grep -F '"openmausbot:install_openmausbot"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'source "$(dirname "${BASH_SOURCE[0]}")/install-openmausbot.sh"' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F 'OpenMausBot' "$LIB_OPENMAUSBOT"
	[ "$status" -eq 0 ]
	run grep -F 'https://github.com/milind-soni/OpenMausBot/releases/latest' "$LIB_OPENMAUSBOT"
	[ "$status" -eq 0 ]
	run grep -F 'OPENMAUSBOT_EXPORT' "$GENERATE_SH"
	[ "$status" -eq 0 ]
}

@test "the headless CLI and the app data directory are detected independently" {
	# The installer must not treat the data directory as proof that the
	# headless CLI is installed.
	run grep -F 'command -v openmausbot' "$LIB_OPENMAUSBOT"
	[ "$status" -eq 0 ]
	run grep -F '[ -d "$HOME/.openmausbot" ]' "$LIB_OPENMAUSBOT"
	[ "$status" -ne 0 ]

	# The CLI on PATH must not be read as "the app is installed" either.
	run grep -F 'detect_tool --detailed "openmausbot"' "$CLI_SH"
	[ "$status" -ne 0 ]
}

@test "OpenMausBot is off the default -y allowlist and installs only on explicit opt-in" {
	run bash -c '
		source "$1/cli.sh"
		YES_TO_ALL=true
		tool_allowed openmausbot
		' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]

	run bash -c '
		source "$1/cli.sh"
		YES_TO_ALL=true
		TOOL_ALLOWLIST_YES+=(openmausbot)
		tool_allowed openmausbot
		' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]

	# A default -y run must not attempt the installer.
	run bash -c '
		source "$1/cli.sh"
		YES_TO_ALL=true
		for entry in "${INSTALL_SEQUENCE[@]}"; do
			eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
		done
		run_install_sequence
		' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" != *"ATTEMPT:openmausbot"* ]]
	[[ "$output" == *"Skipping openmausbot installer (not in -y allowlist)"* ]]

	# An explicit opt-in runs it.
	run bash -c '
		source "$1/cli.sh"
		YES_TO_ALL=true
		TOOL_ALLOWLIST_YES+=(openmausbot)
		for entry in "${INSTALL_SEQUENCE[@]}"; do
			eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
		done
		run_install_sequence
		' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$(grep -c '^ATTEMPT:openmausbot$' <<<"$output")" -eq 1 ]
}

@test "copy_openmausbot_configs honours OMB_DATA_DIR" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		export HOME="$home" OMB_DATA_DIR="$home/custom-omb" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$home/custom-omb" "$repo/configs/openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"

		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		cmp "$repo/configs/openmausbot/bots.json" "$home/custom-omb/import/bots.json"
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_openmausbot_configs skips when the app data directory is missing" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/bin"
		printf '\''#!/bin/sh\nexit 0\n'\'' >"$home/bin/openmausbot"
		chmod +x "$home/bin/openmausbot"
		export HOME="$home" PATH="$home/bin:$PATH" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$1"
		copy_openmausbot_configs
		[ ! -d "$home/.openmausbot" ]
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
	[[ "$output" == *"OpenMausBot not detected"* ]]
}

@test "copy_openmausbot_configs is dry-run safe and writes nothing" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"
		export HOME="$home" DRY_RUN=true YES_TO_ALL=false VERBOSE=false
		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		[ -z "$(find "$home/.openmausbot" -mindepth 1)" ]
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_openmausbot_configs installs the roster into the app-unowned import directory" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"11111111-1111-1111-1111-111111111111","name":"Fixture Bot","soul":"Be helpful."}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"

		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		cmp "$repo/configs/openmausbot/bots.json" "$home/.openmausbot/import/bots.json"
		cmp "$repo/configs/openmausbot/default-bot.json" "$home/.openmausbot/import/default-bot.json"
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
	[[ "$output" == *"OpenMausBot configs copied"* ]]
}

@test "copy_openmausbot_configs never replaces the app-owned live registry" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"live-bot"}]\n'\'' >"$home/.openmausbot/bots.json"
		printf '\''{"v":1,"places":{"live@example.com":"live-bot"}}\n'\'' >"$home/.openmausbot/default-bot.json"
		printf '\''[{"id":"repo-bot"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"

		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		grep -q "live-bot" "$home/.openmausbot/bots.json"
		grep -q "live@example.com" "$home/.openmausbot/default-bot.json"
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_openmausbot_configs installs owner-only files and directories" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"

		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		[ "$(stat -c %a "$home/.openmausbot/import")" = "700" ]
		[ "$(stat -c %a "$home/.openmausbot/import/bots.json")" = "600" ]
		[ "$(stat -c %a "$home/.openmausbot/import/default-bot.json")" = "600" ]
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_openmausbot_configs preserves existing credentials and runtime state" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$home/.openmausbot/bots/22222222-2222-2222-2222-222222222222" \
			"$repo/configs/openmausbot"
		printf '\''{"secret":"do-not-touch"}\n'\'' >"$home/.openmausbot/config.json"
		printf '\''private transcript\n'\'' >"$home/.openmausbot/bots/22222222-2222-2222-2222-222222222222/history.ndjson"
		printf '\''[{"id":"22222222-2222-2222-2222-222222222222"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"

		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		grep -q "do-not-touch" "$home/.openmausbot/config.json"
		grep -q "private transcript" "$home/.openmausbot/bots/22222222-2222-2222-2222-222222222222/history.ndjson"
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "copy_openmausbot_configs warns instead of failing when a managed file cannot be copied" {
	run bash -c '
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$1"
		SCRIPT_DIR="$repo"
		copy_config_file() { return 1; }
		copy_openmausbot_configs
		echo REACHED_END
		' _ "$CLI_SH"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Failed to copy OpenMausBot bots.json, skipping"* ]]
	[[ "$output" == *"REACHED_END"* ]]
}

@test "a missing managed file does not abort the installer run" {
	run bash -c '
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$repo/configs/openmausbot/bots.json"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		echo REACHED_END
		' _ "$CLI_SH"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Managed OpenMausBot file missing from repo, skipping: default-bot.json"* ]]
	[[ "$output" == *"REACHED_END"* ]]
}

@test "copy_openmausbot_configs skips when the repo has no managed roster yet" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$1"
		SCRIPT_DIR="$repo"
		copy_openmausbot_configs
		[ -z "$(find "$home/.openmausbot" -mindepth 1)" ]
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
	[[ "$output" == *"No managed OpenMausBot roster in repo"* ]]
}

@test "generate_openmausbot_configs requires explicit opt-in and never auto-exports" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot"
		printf '\''[{"id":"x"}]\n'\'' >"$home/.openmausbot/bots.json"
		export HOME="$home" DRY_RUN=false
		unset OPENMAUSBOT_EXPORT
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		generate_openmausbot_configs
		[ ! -d "$repo/configs/openmausbot" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Skipping OpenMausBot export"* ]]

	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot/bots/33333333-3333-3333-3333-333333333333"
		printf '\''[{"id":"33333333-3333-3333-3333-333333333333"}]\n'\'' >"$home/.openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$home/.openmausbot/default-bot.json"
		printf '\''# Soul\n'\'' >"$home/.openmausbot/bots/33333333-3333-3333-3333-333333333333/SOUL.md"
		printf '\''{"apiKey":"do-not-export"}\n'\'' >"$home/.openmausbot/config.json"
		export HOME="$home" DRY_RUN=false OPENMAUSBOT_EXPORT=1
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		generate_openmausbot_configs
		cmp "$home/.openmausbot/bots.json" "$repo/configs/openmausbot/bots.json"
		cmp "$home/.openmausbot/default-bot.json" "$repo/configs/openmausbot/default-bot.json"
		[ ! -e "$repo/configs/openmausbot/config.json" ]
		! grep -R -F "do-not-export" "$repo/configs/openmausbot"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"OpenMausBot configs generated"* ]]
}

@test "generate_openmausbot_configs does not export derived soul mirrors" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot/bots/33333333-3333-3333-3333-333333333333"
		printf '\''[{"id":"33333333-3333-3333-3333-333333333333"}]\n'\'' >"$home/.openmausbot/bots.json"
		printf '\''# Soul\n'\'' >"$home/.openmausbot/bots/33333333-3333-3333-3333-333333333333/SOUL.md"
		export HOME="$home" DRY_RUN=false OPENMAUSBOT_EXPORT=1
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		generate_openmausbot_configs
		[ ! -e "$repo/configs/openmausbot/bots" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "generate_openmausbot_configs prunes a stale export" {
	run bash -c '
		set -e
		home=$(mktemp -d)
		repo=$(mktemp -d)
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot" "$repo/configs/openmausbot/bots/stale-bot"
		printf '\''[{"id":"current-bot"}]\n'\'' >"$home/.openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$repo/configs/openmausbot/default-bot.json"
		printf '\''# Stale soul\n'\'' >"$repo/configs/openmausbot/bots/stale-bot/SOUL.md"
		export HOME="$home" DRY_RUN=false OPENMAUSBOT_EXPORT=1
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		generate_openmausbot_configs
		cmp "$home/.openmausbot/bots.json" "$repo/configs/openmausbot/bots.json"
		[ ! -e "$repo/configs/openmausbot/default-bot.json" ]
		[ ! -e "$repo/configs/openmausbot/bots" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "generate_openmausbot_configs handles paths with spaces" {
	run bash -c '
		set -e
		home=$(mktemp -d "/tmp/openmausbot test home.XXXXXX")
		repo=$(mktemp -d "/tmp/openmausbot repo dir.XXXXXX")
		trap '\''rm -rf "$home" "$repo"'\'' EXIT
		mkdir -p "$home/.openmausbot/bots/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
		printf '\''[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}]\n'\'' >"$home/.openmausbot/bots.json"
		printf '\''{"v":1,"places":{}}\n'\'' >"$home/.openmausbot/default-bot.json"
		export HOME="$home" DRY_RUN=false OPENMAUSBOT_EXPORT=1
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		generate_openmausbot_configs
		cmp "$home/.openmausbot/bots.json" "$repo/configs/openmausbot/bots.json"
		cmp "$home/.openmausbot/default-bot.json" "$repo/configs/openmausbot/default-bot.json"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "the exported roster is gitignored" {
	run git -C "$REPO_ROOT" check-ignore -q configs/openmausbot/bots.json
	[ "$status" -eq 0 ]
	run git -C "$REPO_ROOT" check-ignore -q configs/openmausbot/default-bot.json
	[ "$status" -eq 0 ]
	run git -C "$REPO_ROOT" check-ignore -q configs/openmausbot/bots/some-bot/SOUL.md
	[ "$status" -eq 0 ]
	# The policy README stays tracked.
	run git -C "$REPO_ROOT" check-ignore -q configs/openmausbot/README.md
	[ "$status" -ne 0 ]
}

@test "backup_configs gates OpenMausBot on explicit selection" {
	# Default -y run: the OpenMausBot import snapshot is not backed up.
	run bash -c '
		set -e
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.openmausbot/import"
		printf '\''[{"id":"x"}]\n'\'' >"$home/.openmausbot/import/bots.json"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=true VERBOSE=false
		source "$1"
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$home/backup"
		backup_configs >/dev/null
		[ ! -e "$BACKUP_DIR/openmausbot" ]
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]

	# Explicit opt-in: the installer-owned import snapshot is backed up.
	run bash -c '
		set -e
		home=$(mktemp -d)
		trap '\''rm -rf "$home"'\'' EXIT
		mkdir -p "$home/.openmausbot/import"
		printf '\''[{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}]\n'\'' >"$home/.openmausbot/import/bots.json"
		export HOME="$home" DRY_RUN=false YES_TO_ALL=true VERBOSE=false
		source "$1"
		TOOL_ALLOWLIST_YES+=(openmausbot)
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$home/backup"
		backup_configs >/dev/null
		cmp "$home/.openmausbot/import/bots.json" "$BACKUP_DIR/openmausbot/bots.json"
	' _ "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "README documents OpenMausBot support" {
	run grep -F '## 🦊 OpenMausBot (Optional)' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'OPENMAUSBOT_EXPORT=1 ./generate.sh' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'Settings → Backups → Export full backup' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'https://github.com/milind-soni/OpenMausBot/releases/latest' "$README"
	[ "$status" -eq 0 ]
	run grep -F '~/.openmausbot/import/' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'OpenMausBot' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}

@test "OpenMausBot support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-openmausbot-support.md" ]
}
