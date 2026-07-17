#!/usr/bin/env bats
# Tests for configs/antigravity-cli/settings.json

load helpers

ANTIGRAVITY_SETTINGS="$REPO_ROOT/configs/antigravity-cli/settings.json"

@test "configs/antigravity-cli/settings.json is valid JSON" {
    require_jq
    run jq empty "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/antigravity-cli/settings.json model is Gemini 3.5 Flash (High)" {
    require_jq
    run jq -r '.model' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "Gemini 3.5 Flash (High)" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains codebase-memory-mcp tools" {
    require_jq
    run jq -e '[.permissions.allow[] | select(startswith("mcp(codebase-memory-mcp/"))] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains autoreview script" {
    require_jq
    run jq -e '[.permissions.allow[] | select(contains("autoreview"))] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains unsandboxed(tail)" {
    require_jq
    run jq -e '[.permissions.allow[] | select(. == "unsandboxed(tail)")] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains unsandboxed(bun add)" {
    require_jq
    run jq -e '[.permissions.allow[] | select(. == "unsandboxed(bun add)")] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow is an array" {
    require_jq
    run jq -e '.permissions.allow | type == "array"' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.deny still contains git reset --hard" {
    require_jq
    run jq -e '[.permissions.deny[] | select(contains("git reset --hard"))] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
