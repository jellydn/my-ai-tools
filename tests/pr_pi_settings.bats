#!/usr/bin/env bats
# Tests for configs/pi/settings.json

load helpers

PI_SETTINGS="$REPO_ROOT/configs/pi/settings.json"

@test "configs/pi/settings.json is valid JSON" {
    require_jq
    run jq empty "$PI_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/settings.json defaultModel is grok-composer-2.5-fast" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "grok-composer-2.5-fast" ]
}

@test "configs/pi/settings.json defaultModel is not gemini-3.5-flash" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" != "gemini-3.5-flash" ]
}

@test "configs/pi/settings.json defaultProvider is xai-auth" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "xai-auth" ]
}

@test "configs/pi/settings.json defaultProvider is not google-antigravity" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" != "google-antigravity" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/gemini-3-flash-agent" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/gemini-3-flash-agent")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/claude-opus-4-6-thinking" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/claude-opus-4-6-thinking")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/claude-sonnet-4-6" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/claude-sonnet-4-6")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains xai-auth/grok-composer-2.5-fast" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "xai-auth/grok-composer-2.5-fast")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/gemini-pro-agent" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/gemini-pro-agent")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains commandcode models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("commandcode/"))] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/glm-5.1" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/glm-5.1")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/kimi-k2.6" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/kimi-k2.6")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/deepseek-v4-flash" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/deepseek-v4-flash")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/deepseek-v4-pro" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/deepseek-v4-pro")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-dynamic-workflows" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-dynamic-workflows")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-commandcode-provider" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-commandcode-provider")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-xai-oauth" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-xai-oauth")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels is a non-empty array" {
    require_jq
    run jq -e '.enabledModels | type == "array" and length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json defaultThinkingLevel is high" {
    require_jq
    run jq -r '.defaultThinkingLevel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "high" ]
}

# Boundary: defaultModel must match a provider/model pair in enabledModels
@test "configs/pi/settings.json defaultModel is listed in enabledModels as provider entry" {
    require_jq
    local default_model
    default_model=$(jq -r '.defaultModel' "$PI_SETTINGS")
    local default_provider
    default_provider=$(jq -r '.defaultProvider' "$PI_SETTINGS")
    run jq -e --arg model "${default_provider}/${default_model}" \
        '[.enabledModels[] | select(. == $model)] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
