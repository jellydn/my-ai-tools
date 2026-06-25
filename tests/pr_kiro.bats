#!/usr/bin/env bats
# Tests for Kiro CLI scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/kiro/AGENTS.md exists" {
    [ -f "$REPO_ROOT/configs/kiro/AGENTS.md" ]
}

@test "lib/install.sh defines install_kiro()" {
    run grep -E '^install_kiro\(\)' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_kiro() uses the official cli.kiro.dev installer" {
    run grep -E 'cli\.kiro\.dev/install' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_kiro() handles Windows PowerShell install" {
    run grep -E 'kiro\.dev/install\.ps1' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh defines copy_kiro_configs()" {
    run grep -E '^copy_kiro_configs\(\)' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_kiro_configs" {
    run grep -E 'copy_kiro_configs' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh main() installs kiro" {
    run grep -E '^[[:space:]]*install_kiro' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh banner advertises Kiro CLI" {
    run grep -E 'Kiro' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_kiro_configs() targets ~/.kiro/" {
    run grep -E 'HOME/\.kiro' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh defines generate_kiro_configs()" {
    run grep -E '^generate_kiro_configs\(\)' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh main() invokes generate_kiro_configs" {
    run grep -E '^[[:space:]]*generate_kiro_configs' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md mentions Kiro CLI in the supported-tools list" {
    run grep -E 'Kiro CLI' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has a Kiro CLI section with a curl installer example" {
    run grep -E 'cli\.kiro\.dev/install' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "configs/kiro/settings.json exists and is valid JSON" {
    require_jq
    [ -f "$REPO_ROOT/configs/kiro/settings.json" ]
    run jq '.' "$REPO_ROOT/configs/kiro/settings.json"
    [ "$status" -eq 0 ]
}

@test "configs/kiro/settings.json has mcpServers key" {
    require_jq
    run jq -e '.mcpServers' "$REPO_ROOT/configs/kiro/settings.json"
    [ "$status" -eq 0 ]
}

@test "configs/kiro/settings.json includes context7 server" {
    require_jq
    run jq -e '.mcpServers.context7' "$REPO_ROOT/configs/kiro/settings.json"
    [ "$status" -eq 0 ]
}

@test "cli.sh copy_kiro_configs() copies settings.json" {
    run grep -E 'kiro/settings\.json.*kiro/' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh generate_kiro_configs() exports settings.json" {
    run grep -E 'kiro/settings\.json' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test ".changeset has an entry for Kiro CLI support" {
    run bash -c "ls -1 $REPO_ROOT/.changeset/ | grep -i kiro"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
