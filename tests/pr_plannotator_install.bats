#!/usr/bin/env bats

load helpers

setup() {
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
}

# Keep the real sequence, prerequisite, config copiers, and execute wrappers.
# Replace unrelated system installers and the network installer boundary only.
install_for_tool() {
	bash -c '
		source "$1/cli.sh"
		DRY_RUN=false YES_TO_ALL=true IS_WINDOWS=false
		TOOL_ALLOWLIST_YES=("$2" plannotator)
		command() {
			if [ "$1" = -v ]; then
				case "$2" in
				claude|copilot|droid|codex|agent|gemini) return 1 ;;
				plannotator) [ -x "$HOME/.local/bin/plannotator" ]; return ;;
				esac
			fi
			builtin command "$@"
		}
		for entry in "${INSTALL_SEQUENCE[@]}"; do
			fn=${entry#*:}
			[ "$fn" = install_plannotator_if_needed ] || eval "$fn() { :; }"
		done
		resolve_installer_checksum() { echo test-checksum; }
		execute_installer() {
			[ "$1" = https://plannotator.ai/install.sh ] || exit 90
			[ "${FAIL_INSTALL:-false}" = false ] || return 1
			mkdir -p "$HOME/.local/bin"
			printf "#!/bin/sh\nexit 0\n" > "$HOME/.local/bin/plannotator"
			chmod +x "$HOME/.local/bin/plannotator"
		}
		run_install_sequence
		case "$2" in
		codex) mkdir -p "$HOME/.codex"; copy_codex_configs ;;
		cursor) mkdir -p "$HOME/.cursor"; copy_cursor_configs ;;
		gemini) mkdir -p "$HOME/.gemini"; copy_gemini_configs ;;
		esac
	' _ "$REPO_ROOT" "$1"
}

@test "Codex with optional Plannotator provisions CLI and copies Stop hook and inbox MCP" {
	run install_for_tool codex
	[ "$status" -eq 0 ]
	[ -x "$HOME/.local/bin/plannotator" ]
	jq -e '.hooks.Stop[0].hooks[0].command == "plannotator"' "$HOME/.codex/hooks.json"
	grep -F '[mcp_servers.plannotator-inbox]' "$HOME/.codex/config.toml"
}

@test "Cursor with optional Plannotator provisions CLI and copies inbox MCP" {
	run install_for_tool cursor
	[ "$status" -eq 0 ]
	[ -x "$HOME/.local/bin/plannotator" ]
	jq -e '.mcpServers["plannotator-inbox"] == {command: "plannotator", args: ["inbox", "mcp"]}' "$HOME/.cursor/mcp.json"
}

@test "Gemini with optional Plannotator provisions CLI and copies inbox MCP" {
	run install_for_tool gemini
	[ "$status" -eq 0 ]
	[ -x "$HOME/.local/bin/plannotator" ]
	jq -e '.mcpServers["plannotator-inbox"].command == "plannotator"' "$HOME/.gemini/settings.json"
}

@test "Kilo and MiMo install real manual command definitions" {
	run bash -c '
		source "$1/cli.sh"
		DRY_RUN=false
		mkdir -p "$HOME/.config/kilo" "$HOME/.config/mimocode"
		copy_kilo_configs
		copy_mimo_configs
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	for tool in kilo mimocode; do
		for action in review annotate last; do
			grep -F "plannotator $action" "$HOME/.config/$tool/commands/plannotator-$action.md"
		done
	done
}

@test "existing Plannotator CLI skips network installation" {
	run bash -c '
		source "$1/cli.sh"
		command() { if [ "$1" = -v ] && [ "$2" = plannotator ]; then return 0; fi; builtin command "$@"; }
		execute_installer() { echo unexpected-network; return 99; }
		DRY_RUN=false
		install_plannotator_if_needed
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" != *unexpected-network* ]]
}

@test "failed prerequisite stops sequence before enabled Codex configs are copied" {
	export FAIL_INSTALL=true
	run install_for_tool codex
	[ "$status" -ne 0 ]
	[[ "$output" == *"Plannotator installation failed"* ]]
	[ ! -e "$HOME/.codex/hooks.json" ]
}

@test "Plannotator dry-run is side-effect free and missing binary after installer is an error" {
	run bash -c '
		source "$1/cli.sh"
		IS_WINDOWS=false
		command() { [ "$1" != -v ] || [ "$2" != plannotator ] || return 1; builtin command "$@"; }
		resolve_installer_checksum() { echo test; }
		DRY_RUN=true
		install_plannotator_if_needed
		[ ! -d "$HOME/.local" ]
		DRY_RUN=false
		execute_installer() { return 0; }
		install_plannotator_if_needed
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"[DRY RUN] Would execute installer"* ]]
	[[ "$output" == *"CLI was not found"* ]]
}

@test "Windows Plannotator uses a verified binary-only install and discovers it without restarting" {
	run env PATH="/usr/bin:/bin" bash -c '
		set -e
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		IS_WINDOWS=true DRY_RUN=false LOCALAPPDATA="$HOME/Local AppData" PROCESSOR_ARCHITECTURE=AMD64
		cygpath() { printf "%s\n" "$2"; }
		execute_installer() { echo unexpected-unix-installer; return 99; }
		download_and_verify_file() {
			printf "%s\n" "#!/bin/sh" "echo plannotator-test-version" >"$HOME/installer"
			echo "$HOME/installer"
		}
		plannotator() { bash "$LOCALAPPDATA/plannotator/plannotator.exe" "$@"; }
		DRY_RUN=true
		install_plannotator_if_needed
		[ ! -e "$HOME/installer" ] && [ ! -d "$LOCALAPPDATA" ]
		DRY_RUN=false
		install_plannotator_if_needed
		[ ! -e "$HOME/installer" ]
		[ "${PATH%%:*}" = "$LOCALAPPDATA/plannotator" ]
		plannotator --version
		download_and_verify_file() { echo unexpected-reinstall; return 99; }
		install_plannotator_if_needed
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"binary only"* ]]
	[[ "$output" == *"plannotator-test-version"* ]]
	[[ "$output" != *unexpected-* ]]
}

@test "Windows Plannotator fails closed on checksum failure or unsupported architecture" {
	for failure in checksum architecture; do
		run env PATH="/usr/bin:/bin" bash -c '
			source "$1/lib/common.sh"
			source "$1/lib/install.sh"
			IS_WINDOWS=true DRY_RUN=false LOCALAPPDATA="$HOME/Local AppData" PROCESSOR_ARCHITECTURE=ARM64
			unset PROCESSOR_ARCHITEW6432
			cygpath() { printf "%s\n" "$2"; }
			curl() { printf tampered >"${@: -1}"; }
			[ "$2" != architecture ] || PROCESSOR_ARCHITECTURE=x86
			install_plannotator_if_needed
		' _ "$REPO_ROOT" "$failure"
		[ "$status" -ne 0 ]
		[ ! -d "$HOME/Local AppData" ]
	done
}

@test "enable_plugins installs Copilot and Droid plugins without Claude in dry-run and real execution" {
	for dry_run in true false; do
		run bash -c '
			source "$1/cli.sh"
			DRY_RUN="$2" YES_TO_ALL=true
			command() {
				if [ "$1" = -v ]; then
					case "$2" in claude) return 1 ;; copilot|droid|plannotator) return 0 ;; esac
				fi
				builtin command "$@"
			}
			copilot() { echo "copilot $*"; }
			droid() { echo "droid $*"; }
			install_local_skills() { :; }
			install_recommended_skills() { :; }
			enable_plugins
		' _ "$REPO_ROOT" "$dry_run"
		[ "$status" -eq 0 ]
		[[ "$output" == *"copilot plugin marketplace add"* ]]
		[[ "$output" == *"copilot plugin install"*"plannotator-copilot@plannotator"* ]]
		[[ "$output" == *"droid plugin marketplace add"* ]]
		[[ "$output" == *"droid plugin install"*"plannotator@plannotator"* ]]
	done
}
