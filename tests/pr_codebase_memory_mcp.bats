#!/usr/bin/env bats
# Tests for the codebase-memory-mcp MCP server integration

REPO_ROOT="$BATS_TEST_DIRNAME/.."
MCP_REGISTRY="$REPO_ROOT/configs/mcp-registry.json"
README_FILE="$REPO_ROOT/README.md"

@test "configs/mcp-registry.json contains codebase-memory-mcp server entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '.mcpServers | has("codebase-memory-mcp")' "$MCP_REGISTRY"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "codebase-memory-mcp entry uses the local binary command" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '.mcpServers["codebase-memory-mcp"].command' "$MCP_REGISTRY"
    [ "$status" -eq 0 ]
    [ "$output" = "codebase-memory-mcp" ]
}

@test "codebase-memory-mcp entry requires the local binary" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '.mcpServers["codebase-memory-mcp"].requires[0]' "$MCP_REGISTRY"
    [ "$status" -eq 0 ]
    [ "$output" = "codebase-memory-mcp" ]
}

@test "README.md mentions codebase-memory-mcp in the MCP server overview" {
    # Extract the overview section and check for codebase-memory-mcp
    overview_content="$(sed -n '/^## 🔌 MCP Servers & Plugins Overview$/,/^## /p' "$README_FILE")"
    run grep -F 'codebase-memory-mcp' <<<"$overview_content"
    [ "$status" -eq 0 ]
}

@test "README.md MCP server details include codebase-memory-mcp" {
    run grep -F '| `codebase-memory-mcp` | High-performance code intelligence and structural search' "$README_FILE"
    [ "$status" -eq 0 ]
}
