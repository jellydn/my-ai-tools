#!/usr/bin/env bats
# Tests for configs/ai-launcher/config.json

load helpers

AI_LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"

@test "configs/ai-launcher/config.json is valid JSON" {
    require_jq
    run jq empty "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand uses opencode/big-pickle" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand does not reference deepseek-v4-flash-free" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
}

@test "configs/ai-launcher/config.json review template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "review")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-zen template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-zen")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-staged template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-staged")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-atomic template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-atomic")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json architecture-explanation template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "architecture-explanation")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json draft-pull-request template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "draft-pull-request")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json has no remaining deepseek-v4-flash-free references" {
    run grep -F "deepseek-v4-flash-free" "$AI_LAUNCHER_CONFIG"
    [ "$status" -ne 0 ]
}

@test "configs/ai-launcher/config.json has a tools array" {
    require_jq
    run jq -e '.tools | type == "array"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/ai-launcher/config.json has a templates array" {
    require_jq
    run jq -e '.templates | type == "array"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
