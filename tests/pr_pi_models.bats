#!/usr/bin/env bats
# Tests for configs/pi/models.json

load helpers

PI_MODELS="$REPO_ROOT/configs/pi/models.json"

@test "configs/pi/models.json is valid JSON" {
    require_jq
    run jq empty "$PI_MODELS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/models.json has vibeproxy provider" {
    require_jq
    run jq -e '.providers | has("vibeproxy")' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy api is openai-completions" {
    require_jq
    run jq -r '.providers.vibeproxy.api' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "openai-completions" ]
}

@test "configs/pi/models.json vibeproxy apiKey is vibeproxy" {
    require_jq
    run jq -r '.providers.vibeproxy.apiKey' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "vibeproxy" ]
}

@test "configs/pi/models.json vibeproxy baseUrl is http://127.0.0.1:51200/v1" {
    require_jq
    run jq -r '.providers.vibeproxy.baseUrl' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "http://127.0.0.1:51200/v1" ]
}

@test "configs/pi/models.json vibeproxy has 7 models" {
    require_jq
    run jq -r '.providers.vibeproxy.models | length' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "7" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-3-flash-agent model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent contextWindow is 1048576" {
    require_jq
    run jq -r '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].contextWindow' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "1048576" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent has toolCalling true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].toolCalling == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent has reasoning true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].reasoning == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains claude-opus-4-6-thinking model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy claude-opus-4-6-thinking has reasoning true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")][0].reasoning == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy claude-opus-4-6-thinking contextWindow is 250000" {
    require_jq
    run jq -r '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")][0].contextWindow' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "250000" ]
}

@test "configs/pi/models.json vibeproxy contains claude-sonnet-4-6 model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-sonnet-4-6")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-3-pro-high model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-pro-high")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-pro-agent model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-pro-agent")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model has non-empty id" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == null or .id == "")] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model has positive contextWindow" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.contextWindow <= 0)] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model supports text input" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.input | contains(["text"]) | not)] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json still contains google-antigravity provider" {
    require_jq
    run jq -e '.providers | has("google-antigravity")' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
