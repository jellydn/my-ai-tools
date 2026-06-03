#!/usr/bin/env bats
# Tests for configs/claude/settings.json

load helpers

CLAUDE_SETTINGS="$REPO_ROOT/configs/claude/settings.json"

@test "configs/claude/settings.json is valid JSON" {
    require_jq
    run jq empty "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/claude/settings.json hooks object contains StopFailure key" {
    require_jq
    run jq -e '.hooks | has("StopFailure")' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure is a non-empty array" {
    require_jq
    run jq -e '.hooks.StopFailure | type == "array" and length > 0' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure first entry has hooks array" {
    require_jq
    run jq -e '.hooks.StopFailure[0].hooks | type == "array" and length > 0' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure hook type is command" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].type' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "command" ]
}

@test "configs/claude/settings.json StopFailure hook command references orca agent-hooks" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [[ "$output" == *".orca/agent-hooks"* ]]
}

@test "configs/claude/settings.json StopFailure hook command references claude-hook.sh" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude-hook.sh"* ]]
}

@test "configs/claude/settings.json still has Stop hook" {
    require_jq
    run jq -e '.hooks | has("Stop")' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json hooks has all expected top-level event keys" {
    require_jq
    run jq -e '(.hooks | keys) | (contains(["StopFailure"]) and contains(["Stop"]) and contains(["PostToolUse"]))' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# Boundary: StopFailure hook must not be accidentally empty string
@test "configs/claude/settings.json StopFailure hook command is non-empty" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
