#!/usr/bin/env bats
# Tests for Kimi Code scaffolding (issue #274)

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/kimi-code/AGENTS.md exists" {
    [ -f "$REPO_ROOT/configs/kimi-code/AGENTS.md" ]
}

@test "configs/kimi-code/config.toml exists" {
    [ -f "$REPO_ROOT/configs/kimi-code/config.toml" ]
}

@test "configs/kimi-code/mcp.json exists" {
    [ -f "$REPO_ROOT/configs/kimi-code/mcp.json" ]
}

@test "configs/kimi-code/mcp.json contains mcpServers key" {
    require_jq
    run jq -e '.mcpServers | type == "object"' "$REPO_ROOT/configs/kimi-code/mcp.json"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "lib/install.sh defines install_kimi_code()" {
    run grep -E '^install_kimi_code\(\)' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_kimi_code() uses the official kimi installer" {
    run grep -E 'code\.kimi\.com/kimi-code/install' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh defines copy_kimi_code_configs()" {
    run grep -E '^copy_kimi_code_configs\(\)' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_kimi_code_configs" {
    run grep -E 'copy_kimi_code_configs' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh main() installs kimi code" {
    run grep -E '^\s*install_kimi_code\b' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh banner advertises Kimi Code" {
    run grep -E 'Kimi Code' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_kimi_code_configs() targets ~/.kimi-code/" {
    run grep -E 'HOME/\.kimi-code' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh defines generate_kimi_code_configs()" {
    run grep -E '^generate_kimi_code_configs\(\)' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh main() invokes generate_kimi_code_configs" {
    run grep -E '^\s*generate_kimi_code_configs\b' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md mentions Kimi Code in the supported-tools list" {
    run grep -E 'Kimi Code' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has a Kimi Code section with install script example" {
    run grep -E 'code\.kimi\.com/kimi-code/install\.sh' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test ".changeset has an entry for kimi code support" {
    run bash -c "ls -1 $REPO_ROOT/.changeset/ | grep -Ei 'kimi'"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
