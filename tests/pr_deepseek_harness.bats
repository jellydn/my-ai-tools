#!/usr/bin/env bats
# Tests for DeepSeek Harness integration

load helpers

LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
CONFIG_DIR="$REPO_ROOT/configs/deepseek-harness"
README="$REPO_ROOT/README.md"

@test "DeepSeek Harness managed configs exist and are valid YAML" {
	[ -f "$CONFIG_DIR/AGENTS.md" ]
	for config in settings.yaml cordis.patch.yml; do
		run bash -c 'source "$1/lib/common.sh"; validate_config "$2/$3"' _ "$REPO_ROOT" "$CONFIG_DIR" "$config"
		[ "$status" -eq 0 ]
	done
}

@test "DeepSeek Harness settings reference environment credentials" {
	run grep -F 'apiKeyEnv: DEEPSEEK_API_KEY' "$CONFIG_DIR/settings.yaml"
	[ "$status" -eq 0 ]
	run grep -R -E 'sk-[A-Za-z0-9]' "$CONFIG_DIR"
	[ "$status" -ne 0 ]
}

@test "DeepSeek Harness Cordis patch configures MCP tools" {
	run grep -F 'name: "@deepseek-ai/dsh-mcp-client"' "$CONFIG_DIR/cordis.patch.yml"
	[ "$status" -eq 0 ]
	run grep -F 'serverName: context7' "$CONFIG_DIR/cordis.patch.yml"
	[ "$status" -eq 0 ]
	run grep -F 'args: ["mcp", "serve"]' "$CONFIG_DIR/cordis.patch.yml"
	[ "$status" -eq 0 ]
}

@test "DeepSeek Harness uses the official npm package and dsh binary" {
	run grep -F 'install_npm_tool "DeepSeek Harness" "dsh" "@deepseek-ai/dsh"' "$LIB_INSTALL"
	[ "$status" -eq 0 ]
	run grep -F '"deepseek_harness:install_deepseek_harness"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run bash -c '
		export HOME="$(mktemp -d)" DRY_RUN=true YES_TO_ALL=true VERBOSE=false
		trap '\''rm -rf "$HOME"'\'' EXIT
		source "$1/cli.sh"
		tool_allowed deepseek_harness
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "DeepSeek Harness installer requires the official Node.js toolchain" {
	run bash -c '
		export DRY_RUN=false YES_TO_ALL=true IS_WINDOWS=false VERBOSE=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		command() {
			if [ "$1" = "-v" ] && [ "$2" = "npx" ]; then
				return 1
			fi
			builtin command "$@"
		}
		install_deepseek_harness
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"requires Node.js with npm and npx"* ]]
}

@test "DeepSeek Harness install honors DSH_HOME" {
	run bash -c '
		set -e
		temp_home=$(mktemp -d)
		trap '\''rm -rf "$temp_home"'\'' EXIT
		export HOME="$temp_home" DSH_HOME="$temp_home/custom-dsh"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$DSH_HOME"
		source "$1/cli.sh"
		copy_deepseek_harness_configs >/dev/null
		for config in AGENTS.md settings.yaml cordis.patch.yml; do
			cmp "$1/configs/deepseek-harness/$config" "$DSH_HOME/$config"
		done
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "DeepSeek Harness backup and export include only managed files" {
	run bash -c '
		set -e
		temp_home=$(mktemp -d)
		temp_repo=$(mktemp -d)
		trap '\''rm -rf "$temp_home" "$temp_repo"'\'' EXIT
		export HOME="$temp_home" DSH_HOME="$temp_home/custom-dsh"
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		mkdir -p "$DSH_HOME"
		cp "$1"/configs/deepseek-harness/* "$DSH_HOME/"
		touch "$DSH_HOME/.credentials.yaml" "$DSH_HOME/.env"
		mkdir -p "$DSH_HOME/sessions"

		source "$1/cli.sh"
		BACKUP=true
		PROMPT_BACKUP=false
		BACKUP_DIR="$temp_home/backup"
		backup_configs >/dev/null

		source "$1/generate.sh"
		SCRIPT_DIR="$temp_repo"
		generate_deepseek_harness_configs >/dev/null

		for config in AGENTS.md settings.yaml cordis.patch.yml; do
			cmp "$1/configs/deepseek-harness/$config" "$BACKUP_DIR/deepseek-harness/$config"
			cmp "$1/configs/deepseek-harness/$config" "$temp_repo/configs/deepseek-harness/$config"
		done
		[ ! -e "$BACKUP_DIR/deepseek-harness/.credentials.yaml" ]
		[ ! -e "$temp_repo/configs/deepseek-harness/.credentials.yaml" ]
		[ ! -e "$temp_repo/configs/deepseek-harness/.env" ]
		[ ! -e "$temp_repo/configs/deepseek-harness/sessions" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "README documents DeepSeek Harness setup and sensitive-file exclusions" {
	run grep -F 'npm install --global @deepseek-ai/dsh' "$README"
	[ "$status" -eq 0 ]
	run grep -F '${DSH_HOME:-$HOME/.dsh}' "$README"
	[ "$status" -eq 0 ]
	run grep -F './cli.sh --dry-run' "$README"
	[ "$status" -eq 0 ]
	run grep -F '.credentials.yaml' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'dsh web' "$README"
	[ "$status" -eq 0 ]
}

@test "DeepSeek Harness support has a changeset" {
	[ -f "$REPO_ROOT/.changeset/add-deepseek-harness-support.md" ]
}
