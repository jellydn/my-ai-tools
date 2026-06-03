#!/usr/bin/env bats
# Tests for configs/copilot/mcp-config.json

load helpers

COPILOT_MCP="$REPO_ROOT/configs/copilot/mcp-config.json"

@test "configs/copilot/mcp-config.json is valid JSON" {
    require_jq
    run jq empty "$COPILOT_MCP"
    [ "$status" -eq 0 ]
}

@test "configs/copilot/mcp-config.json agentmemory server exists" {
    require_jq
    run jq -e '.mcpServers | has("agentmemory")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_URL" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_URL")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_SECRET" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_SECRET")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_TOOLS" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_TOOLS")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory AGENTMEMORY_TOOLS default contains all" {
    require_jq
    run jq -r '.mcpServers.agentmemory.env.AGENTMEMORY_TOOLS' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"all"* ]]
}

@test "configs/copilot/mcp-config.json agentmemory AGENTMEMORY_URL default contains localhost:3111" {
    require_jq
    run jq -r '.mcpServers.agentmemory.env.AGENTMEMORY_URL' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"localhost:3111"* ]]
}

@test "configs/copilot/mcp-config.json all pre-existing servers still present" {
    require_jq
    run jq -e '
        (.mcpServers | keys) |
        contains(["context7", "sequential-thinking", "fff", "qmd", "react-grab-mcp", "logpilot", "agentmemory"])
    ' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json every server has a type field" {
    require_jq
    run jq -e '[.mcpServers[] | select(.type == null or .type == "")] | length == 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json every server has a tools field" {
    require_jq
    run jq -e '[.mcpServers[] | select(.tools == null)] | length == 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# Regression: agentmemory env must not be an empty object (was {} before PR)
@test "configs/copilot/mcp-config.json agentmemory env is not empty" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | length > 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
