#!/usr/bin/env bats
# Tests for configs/amp/plugins/external-provider.ts

load helpers

PLUGIN_FILE="$REPO_ROOT/configs/amp/plugins/external-provider.ts"

@test "external-provider plugin file exists" {
	[ -f "$PLUGIN_FILE" ]
}

@test "external-provider plugin has @amp-plugin marker" {
	run grep -F "// @amp-plugin" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin imports PluginAPI type" {
	run grep -F "import type { PluginAPI } from" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin exports default function" {
	run grep -E '^export default function' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers external_ask tool" {
	run grep -F "name: \"external_ask\"" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers external_code_review tool" {
	run grep -F "name: \"external_code_review\"" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers external_implement tool" {
	run grep -F "name: \"external_implement\"" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers select-provider command" {
	run grep -F '"external-provider:select-provider"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers select-model command" {
	run grep -F '"external-provider:select-model"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers test-connection command" {
	run grep -F '"external-provider:test-connection"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin registers show-usage command" {
	run grep -F '"external-provider:show-usage"' "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin defines provider presets" {
	run grep -F "PROVIDER_PRESETS" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin includes OpenRouter preset" {
	run grep -F "openrouter" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin includes Cline preset" {
	run grep -F "cline" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin uses fetch for HTTP requests" {
	run grep -F "fetch(" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin reads API keys from env" {
	run grep -F "EXTERNAL_API_KEY" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin uses amp.configuration for config" {
	run grep -F "amp.configuration" "$PLUGIN_FILE"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin .env.example documents EXTERNAL vars" {
	run grep -F "EXTERNAL_API_KEY" "$REPO_ROOT/.env.example"
	[ "$status" -eq 0 ]
}

@test "external-provider plugin README table entry exists" {
	run grep -F "external-provider.ts" "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}
