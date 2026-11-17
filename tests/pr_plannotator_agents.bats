#!/usr/bin/env bats
# Plannotator plan-review and manual-command coverage for agents other than OpenCode.

load helpers

CLI_SH="$REPO_ROOT/cli.sh"

@test "Kilo and MiMo keep the Plannotator workflow tuple and CLI stubs" {
	require_jq
	local config
	for config in "$REPO_ROOT/configs/kilo/config.json" "$REPO_ROOT/configs/mimo/mimocode.jsonc"; do
		run jq -e '
			.plugin[0] == [
				"@plannotator/opencode@latest",
				{ "workflow": "plan-agent", "planningAgents": ["plan"] }
			]
		' "$config"
		[ "$status" -eq 0 ]
	done

	local dir
	for dir in "$REPO_ROOT/configs/kilo/command" "$REPO_ROOT/configs/mimo/command"; do
		run grep -F 'plannotator review $ARGUMENTS' "$dir/plannotator-review.md"
		[ "$status" -eq 0 ]
		run grep -F 'plannotator annotate $ARGUMENTS' "$dir/plannotator-annotate.md"
		[ "$status" -eq 0 ]
		run grep -F 'plannotator last $ARGUMENTS' "$dir/plannotator-last.md"
		[ "$status" -eq 0 ]
	done
}

@test "Codex Stop hook runs plannotator and the installer copies it" {
	require_jq
	run jq -e '.hooks.Stop[0].hooks[0] == { "type": "command", "command": "plannotator", "timeout": 345600 }' \
		"$REPO_ROOT/configs/codex/hooks.json"
	[ "$status" -eq 0 ]
	run grep -F 'copy_config_file "$SCRIPT_DIR/configs/codex/hooks.json" "$HOME/.codex/"' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "Kilo and MiMo command stubs are copied into commands/" {
	run grep -F 'copy_opencode_commands "$SCRIPT_DIR/configs/kilo/command" "$HOME/.config/kilo/commands"' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'copy_opencode_commands "$SCRIPT_DIR/configs/mimo/command" "$HOME/.config/mimocode/commands"' "$CLI_SH"
	[ "$status" -eq 0 ]
}

@test "Copilot and Droid Plannotator plugins install when Claude Code is absent" {
	require_jq
	run grep -F 'plannotator-copilot|plannotator-copilot@plannotator|backnotprop/plannotator|copilot' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'plannotator-droid|plannotator@plannotator|https://github.com/backnotprop/plannotator|droid' "$CLI_SH"
	[ "$status" -eq 0 ]
	run grep -F 'handle_no_claude_cli' "$CLI_SH"
	[ "$status" -eq 0 ]
	run awk '
		/if ! command -v claude/,/install_plugins_if_marketplace_available/ {
			print
		}
	' "$CLI_SH"
	[[ "$output" == *"install_local_community_plugins"* ]]
	run jq -e '.enabledPlugins["plannotator@plannotator"] == true' "$REPO_ROOT/configs/factory/settings.json"
	[ "$status" -eq 0 ]
}
