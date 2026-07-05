#!/usr/bin/env bats
# Tests for configs/pi/settings.json

load helpers

PI_SETTINGS="$REPO_ROOT/configs/pi/settings.json"

@test "configs/pi/settings.json is valid JSON" {
    require_jq
    run jq empty "$PI_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/settings.json defaultModel is gpt-5.4-mini" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "gpt-5.4-mini" ]
}

@test "configs/pi/settings.json defaultProvider is openai-codex" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "openai-codex" ]
}

@test "configs/pi/settings.json enabledModels no longer contains vibeproxy models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("vibeproxy/"))] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels no longer contains xai-auth/grok-composer-2.5-fast" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "xai-auth/grok-composer-2.5-fast")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains cursor models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("cursor/"))] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains openai-codex models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("openai-codex/"))] | length > 0' "$PI_SETTINGS"
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

@test "configs/pi/settings.json packages contains telepi" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:@futurelab-studio/telepi")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages no longer contains pi-xai-oauth" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-xai-oauth")] | length == 0' "$PI_SETTINGS"
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
