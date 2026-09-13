#!/usr/bin/env bats
# Tests for configs/pi/settings.json

load helpers

PI_SETTINGS="$REPO_ROOT/configs/pi/settings.json"

@test "configs/pi/settings.json is valid JSON" {
    require_jq
    run jq empty "$PI_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/settings.json defaultModel is deepseek/deepseek-v4-pro" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "deepseek/deepseek-v4-pro" ]
}

@test "configs/pi/settings.json defaultProvider is commandcode" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "commandcode" ]
}

@test "configs/pi/settings.json enables OmniRoute paid/free/premium models" {
    require_jq
    run jq -e '
        (.enabledModels | index("omniroute/paid") != null) and
        (.enabledModels | index("omniroute/free") != null) and
        (.enabledModels | index("omniroute/premium") != null) and
        ([.enabledModels[] | select(startswith("9router/"))] | length == 0)
    ' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json default provider/model pair is enabled" {
    require_jq
    run jq -e '. as $s | $s.enabledModels | index($s.defaultProvider + "/" + $s.defaultModel) != null' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels no longer contains vibeproxy models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("vibeproxy/"))] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains commandcode/deepseek/deepseek-v4-pro" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "commandcode/deepseek/deepseek-v4-pro")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels no longer contains clinepass or qw models" {
    require_jq
    run jq -e '
        ([.enabledModels[] | select(startswith("clinepass/"))] | length == 0) and
        ([.enabledModels[] | select(startswith("qw/"))] | length == 0)
    ' "$PI_SETTINGS"
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

@test "configs/pi/settings.json packages contains pi-cursor-sdk" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-cursor-sdk")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-commandcode-provider" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-commandcode-provider")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-qwencloud-provider" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-qwencloud-provider")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains @juicesharp/rpiv-todo" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:@juicesharp/rpiv-todo")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages no longer contains pi-manage-todo-list" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-manage-todo-list")] | length == 0' "$PI_SETTINGS"
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
