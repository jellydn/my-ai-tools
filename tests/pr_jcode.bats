#!/usr/bin/env bats
# Tests for jcode scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/jcode/AGENTS.md exists" {
    [ -f "$REPO_ROOT/configs/jcode/AGENTS.md" ]
}

@test "configs/jcode/mcp.json exists" {
    [ -f "$REPO_ROOT/configs/jcode/mcp.json" ]
}

@test "configs/jcode/config.toml exists" {
    [ -f "$REPO_ROOT/configs/jcode/config.toml" ]
}

@test "configs/jcode/mcp.json contains mcpServers key" {
    require_jq
    run jq -e '.mcpServers | type == "object"' "$REPO_ROOT/configs/jcode/mcp.json"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/jcode/mcp.json mcpServers includes context7" {
    require_jq
    run jq -e '.mcpServers.context7.command == "npx"' "$REPO_ROOT/configs/jcode/mcp.json"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/jcode ships curated skills" {
    [ -f "$REPO_ROOT/configs/jcode/skills/code-reviewer/SKILL.md" ]
    [ -f "$REPO_ROOT/configs/jcode/skills/test-generator/SKILL.md" ]
}

@test "lib/install.sh defines install_jcode()" {
    run grep -E '^install_jcode\(\)' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_jcode() prefers Homebrew tap when brew is available" {
    run grep -E '1jehuang/jcode' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_jcode() uses the official jcode.sh installer" {
    run grep -E 'jcode\.sh/install' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_jcode() handles Windows PowerShell install" {
    run grep -E 'jcode\.sh/install\.ps1' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh defines copy_jcode_configs()" {
    run grep -E '^copy_jcode_configs\(\)' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_jcode_configs" {
    run grep -E 'copy_jcode_configs' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh main() installs jcode" {
    run grep -F '"jcode:install_jcode"' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh banner advertises jcode" {
    run grep -E 'jcode' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_jcode_configs() installs ~/AGENTS.md" {
    run grep -E 'copy_config_file.*configs/jcode/AGENTS\.md.*HOME/' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_jcode_configs() copies mcp.json into ~/.jcode/" {
    run grep -E "copy_config_file.*configs/jcode/mcp\.json" "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_jcode_configs() targets ~/.jcode/" {
    run grep -E 'HOME/\.jcode' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh defines generate_jcode_configs()" {
    run grep -E '^generate_jcode_configs\(\)' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh generate_jcode_configs() exports mcp.json" {
    run grep -E 'copy_single.*jcode/mcp\.json' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh generate_jcode_configs() exports ~/AGENTS.md" {
    run grep -E 'copy_single.*HOME/AGENTS\.md.*configs/jcode/AGENTS\.md' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh main() invokes generate_jcode_configs" {
    run grep -E '^\s*generate_jcode_configs\b' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md mentions jcode in the supported-tools list" {
    run grep -E '\bjcode\b' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has a jcode section with a curl installer example" {
    run grep -E 'jcode\.sh/install' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md jcode section documents ~/AGENTS.md" {
    run grep -E '~/AGENTS\.md' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
