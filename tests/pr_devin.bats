#!/usr/bin/env bats
# Tests for Devin CLI support

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
README="$REPO_ROOT/README.md"
CONFIG_DIR="$REPO_ROOT/configs/devin"

@test "README.md mentions Devin CLI in the supported-tools list" {
    run grep -F "Devin CLI" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has a Devin CLI section with the official installer" {
    run grep -F "https://cli.devin.ai/install.sh" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md shows the devin command example" {
    run grep -F 'devin -- "check out this code and suggest a feasible, helpful feature"' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has Devin MCP servers section" {
    run grep -F "configs/devin/config.json" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "configs/devin/config.json exists and is valid JSON" {
    run jq empty "$CONFIG_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "configs/devin/config.json has mcpServers" {
    run jq -e '.mcpServers' "$CONFIG_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "configs/devin/AGENTS.md exists" {
    [ -f "$CONFIG_DIR/AGENTS.md" ]
}

@test "configs/devin/AGENTS.md references best-practices" {
    run grep -F "best-practices.md" "$CONFIG_DIR/AGENTS.md"
    [ "$status" -eq 0 ]
}
