#!/usr/bin/env bats
# Tests for OpenMausBot support.

load helpers

CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
LIB_OPENMAUSBOT="$REPO_ROOT/lib/install-openmausbot.sh"
README="$REPO_ROOT/TOOL_REFERENCE.md"

setup() {
	# A developer's real OMB_DATA_DIR must never leak into the fixtures.
	unset OMB_DATA_DIR
}

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

@test "install_openmausbot refuses Node.js older than 24 and reports the failure" {
	run bash -c '
		bin=$(mktemp -d)
		trap '\''rm -rf "$bin"'\'' EXIT
		printf "#!/bin/sh\necho 22\n" >"$bin/node"
		chmod +x "$bin/node"
		PATH="$bin:/usr/bin:/bin"
		source "$1/cli.sh"
		install_npm_tool() { echo NPM_INSTALL_ATTEMPTED; }
		install_openmausbot
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"requires Node.js 24 or newer"* ]]
	[[ "$output" != *"NPM_INSTALL_ATTEMPTED"* ]]
}

@test "install_openmausbot returns the npm install failure" {
	run bash -c '
		bin=$(mktemp -d)
		trap '\''rm -rf "$bin"'\'' EXIT
		printf "#!/bin/sh\necho 24\n" >"$bin/node"
		chmod +x "$bin/node"
		PATH="$bin:/usr/bin:/bin"
		source "$1/cli.sh"
		install_npm_tool() { return 1; }
		# run_install_sequence calls installers as a condition, where set -e
		# does not apply, so the status must come from the return value.
		if install_openmausbot; then exit 0; else exit 1; fi
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
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

@test "generate_openmausbot_configs refuses a data directory inside the export directory" {
	run bash -c '
		set -e
		repo=$(mktemp -d)
		link=$(mktemp -d)
		trap '\''rm -rf "$repo" "$link"'\'' EXIT
		live="$repo/configs/openmausbot"
		mkdir -p "$live/bots/live-bot"
		printf '\''[{"id":"live-bot"}]\n'\'' >"$live/bots.json"
		printf '\''history\n'\'' >"$live/bots/live-bot/history.ndjson"
		ln -s "$live" "$link/omb"
		export DRY_RUN=false OPENMAUSBOT_EXPORT=1
		source "$1/generate.sh"
		SCRIPT_DIR="$repo"
		for dir in "$live" "$link/omb"; do
			OMB_DATA_DIR="$dir" generate_openmausbot_configs
			[ -f "$live/bots/live-bot/history.ndjson" ]
		done
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$(grep -c "must not be inside" <<<"$output")" -eq 2 ]
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

@test "README documents OpenMausBot support" {
	run grep -F '## 🦊 OpenMausBot (Optional)' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'OPENMAUSBOT_EXPORT=1 ./generate.sh' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'Settings → Import & export → Export full backup' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'https://github.com/milind-soni/OpenMausBot/releases/latest' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'OpenMausBot' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}

@test "OpenMausBot support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-openmausbot-support.md" ]
}
