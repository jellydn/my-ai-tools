#!/usr/bin/env bats
# Cross-tool token-efficiency configuration tests

load helpers

CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
SYNC_SH="$REPO_ROOT/scripts/sync-token-efficiency.sh"

@test "managed global instruction profiles share the canonical Token Efficiency section" {
	run bash "$SYNC_SH" --check
	[ "$status" -eq 0 ]
}

@test "managed global instruction profiles do not eagerly import supplemental markdown" {
	local file
	while IFS= read -r file; do
		if grep -Eq '@[^[:space:]]+\.(md|mdx)([[:space:]]|$)' "$file"; then
			echo "eager import: $file"
			return 1
		fi
	done < <(find "$REPO_ROOT/configs" -type f \( -name AGENTS.md -o -name GEMINI.md \))
}

@test "OpenCode-family configs do not eagerly load shared guidance" {
	run grep -E '"instructions".*\.ai-tools/(best-practices|MEMORY|agent-memory)' \
		"$REPO_ROOT/configs/opencode/opencode.json" \
		"$REPO_ROOT/configs/kilo/config.json" \
		"$REPO_ROOT/configs/mimo/mimocode.jsonc"
	[ "$status" -eq 1 ]
}

@test "OpenCode installs its token-efficient global AGENTS.md" {
	[ -f "$REPO_ROOT/configs/opencode/AGENTS.md" ]
	run grep -F 'configs/opencode/AGENTS.md' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F '$HOME/.config/opencode/' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'configs/opencode/AGENTS.md' "$GENERATE_SH"
	[ "$status" -eq 0 ]
}

@test "INSTALL_SEQUENCE lists RTK once as an ungated dependency" {
	run bash -c 'source "$1/cli.sh"; printf "%s\n" "${INSTALL_SEQUENCE[@]}"' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$(grep -c 'install_rtk$' <<<"$output")" -eq 1 ]
	[[ "$output" == *"always:install_rtk"* ]]
}

@test "RTK still installs when no tool is in the -y allowlist" {
	run bash -c '
		source "$1/cli.sh"
		YES_TO_ALL=true
		TOOL_ALLOWLIST_YES=()
		for entry in "${INSTALL_SEQUENCE[@]}"; do
			eval "${entry#*:}() { echo \"ran ${entry#*:}\"; }"
		done
		run_install_sequence
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$(grep -c '^ran install_rtk$' <<<"$output")" -eq 1 ]
	[[ "$output" != *"ran install_claude_code"* ]]
}

@test "every INSTALL_SEQUENCE entry resolves to a defined installer" {
	run bash -c '
		source "$1/cli.sh"
		missing=0
		for entry in "${INSTALL_SEQUENCE[@]}"; do
			declare -F "${entry#*:}" >/dev/null || {
				echo "missing installer: ${entry#*:}"
				missing=1
			}
		done
		exit "$missing"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}
