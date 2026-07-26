#!/usr/bin/env bats
# Tests for configs/amp/plugins/signal-filter.ts

load helpers

PLUGIN_FILE="$REPO_ROOT/configs/amp/plugins/signal-filter.ts"

@test "signal-filter plugin file exists" {
	[ -f "$PLUGIN_FILE" ]
}

@test "signal-filter plugin has @amp-plugin marker" {
	run grep -F "// @amp-plugin" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin imports PluginAPI type" {
	run grep -F "PluginAPI" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
	# Verify it's a type import from @ampcode/plugin
	run grep -F "from \"@ampcode/plugin\"" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin exports default function" {
	run grep -E '^export default function' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers agent.start hook" {
	run grep -F 'amp.on("agent.start"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers tool.call hook" {
	run grep -F 'amp.on("tool.call"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers tool.result hook" {
	run grep -F 'amp.on("tool.result"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers agent.end hook" {
	run grep -F 'amp.on("agent.end"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin returns allow action" {
	run grep -F '{ action: "allow" }' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin returns reject-and-continue action" {
	run grep -F '"reject-and-continue"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin defines FilterRule interface" {
	run grep -F "interface FilterRule" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin has default rules" {
	run grep -F "DEFAULT_CONFIG" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin blocks rm -rf" {
	run grep -F "block-rm-rf" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin blocks force push" {
	run grep -F "block-force-push" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin blocks git reset --hard" {
	run grep -F "block-git-reset-hard" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin supports confirm action" {
	run grep -F '"confirm"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin uses shellCommandFromToolCall helper" {
	run grep -F "shellCommandFromToolCall" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin uses filesModifiedByToolCall helper" {
	run grep -F "filesModifiedByToolCall" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin defines slash commands" {
	run grep -F "SLASH_COMMANDS" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin routes /openrouter" {
	run grep -F '"/openrouter"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin routes /clinepass" {
	run grep -F '"/clinepass"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin routes /opencode" {
	run grep -F '"/opencode"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin uses amp.configuration" {
	run grep -F "amp.configuration" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin defines provider presets" {
	run grep -F "PROVIDER_PRESETS" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers show-rules command" {
	run grep -F '"signal-filter:show-rules"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers toggle-audit command" {
	run grep -F '"signal-filter:toggle-audit"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers add-rule command" {
	run grep -F '"signal-filter:add-rule"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers reset-rules command" {
	run grep -F '"signal-filter:reset-rules"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers select-provider command" {
	run grep -F '"signal-filter:select-provider"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin registers select-model command" {
	run grep -F '"signal-filter:select-model"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin uses activeThread for confirm context" {
	run grep -F "amp.activeThread" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "signal-filter plugin README table entry exists" {
	run grep -F "signal-filter.ts" "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}
