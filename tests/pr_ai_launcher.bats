#!/usr/bin/env bats
# Tests for configs/ai-launcher/config.json

load helpers

AI_LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"

@test "configs/ai-launcher/config.json is valid JSON" {
    require_jq
    run jq empty "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand no longer uses --model flag" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run" ]]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand no longer references big-pickle" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"big-pickle"* ]]
}

@test "configs/ai-launcher/config.json ccs tool is registered" {
    require_jq
    run jq -r '[.tools[] | select(.name == "ccs")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == "ccs" ]]
}

@test "configs/ai-launcher/config.json review template is read-only" {
    require_jq
    run jq -r '[.templates[] | select(.name == "review")][0] | "\(.mode) \(.requiresConfirmation)"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == "read-only false" ]]
}

@test "configs/ai-launcher/config.json commit-atomic template requires confirmation" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-atomic")][0] | "\(.mode) \(.requiresConfirmation)"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == "write true" ]]
}

@test "configs/ai-launcher/config.json all templates declare mode metadata" {
    require_jq
    run jq -e 'all(.templates[]; has("mode") and has("requiresConfirmation"))' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/ai-launcher/config.json template aliases are unique" {
    require_jq
    run jq -e '
      [
        .templates[]
        | .aliases[]?
      ]
      | group_by(.)
      | map(select(length > 1))
      | length == 0
    ' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/ai-launcher/config.json review template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "review")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent plan"* ]]
}

@test "configs/ai-launcher/config.json commit-zen template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-zen")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent plan"* ]]
}

@test "configs/ai-launcher/config.json commit-staged template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-staged")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent build"* ]]
}

@test "configs/ai-launcher/config.json commit-atomic template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-atomic")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent build"* ]]
}

@test "configs/ai-launcher/config.json architecture-explanation template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "architecture-explanation")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent plan"* ]]
}

@test "configs/ai-launcher/config.json draft-pull-request template command no longer uses --model flag" {
    require_jq
    run jq -r '[.templates[] | select(.name == "draft-pull-request")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"--model"* ]]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
    [[ "$output" == "opencode run --agent build"* ]]
}

@test "configs/ai-launcher/config.json no longer references deepseek-v4-flash-free" {
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
