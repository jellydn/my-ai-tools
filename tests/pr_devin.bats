#!/usr/bin/env bats
# Tests for Devin CLI support

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
README="$REPO_ROOT/TOOL_REFERENCE.md"
CONFIG_DIR="$REPO_ROOT/configs/devin"

@test "tool reference mentions Devin CLI in the supported-tools list" {
    run grep -F "Devin CLI" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference has a Devin CLI section with the official installer" {
    run grep -F "https://cli.devin.ai/install.sh" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference shows the devin command example" {
    run grep -F 'devin -- "check out this code and suggest a feasible, helpful feature"' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference links the managed Devin configuration" {
    run grep -F "configs/devin/config.json" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference places one Devin section in the tool sequence" {
    local codiff_line devin_line ctx_line
    codiff_line=$(grep -n '^## .*Codiff (Optional)$' "$README" | cut -d: -f1)
    devin_line=$(grep -n '^## .*Devin CLI (Optional)$' "$README" | cut -d: -f1)
    ctx_line=$(grep -n '^## .*ctx (Optional)$' "$README" | cut -d: -f1)

    [ "$(grep -c '^## .*Devin CLI (Optional)$' "$README")" -eq 1 ]
    [ "$codiff_line" -lt "$devin_line" ]
    [ "$devin_line" -lt "$ctx_line" ]
}

@test "configs/devin/config.json exists and is valid JSON" {
    run jq empty "$CONFIG_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "configs/devin/config.json ships without legacy mcpServers" {
    run jq -e '.mcpServers' "$CONFIG_DIR/config.json"
    [ "$status" -ne 0 ]
}

@test "configs/devin/config.json has hooks" {
    run jq -e '.hooks' "$CONFIG_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "configs/devin/AGENTS.md exists" {
    [ -f "$CONFIG_DIR/AGENTS.md" ]
}

@test "configs/devin/AGENTS.md references best-practices" {
    run grep -F "best-practices.md" "$CONFIG_DIR/AGENTS.md"
    [ "$status" -eq 0 ]
}
