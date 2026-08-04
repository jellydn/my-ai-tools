#!/usr/bin/env bats
# Tests for Oh My Pi (omp) CLI scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"
AI_LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"

@test "configs/omp/settings.json exists and is valid JSON" {
    require_jq
    [ -f "$REPO_ROOT/configs/omp/settings.json" ]
    run jq empty "$REPO_ROOT/configs/omp/settings.json"
    [ "$status" -eq 0 ]
}

@test "configs/omp/AGENTS.md exists" {
    [ -f "$REPO_ROOT/configs/omp/AGENTS.md" ]
}

@test "lib/install.sh defines install_omp()" {
    run grep -E '^install_omp\(\)' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_omp() uses @oh-my-pi/pi-coding-agent package" {
    run grep -E '@oh-my-pi/pi-coding-agent' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh defines copy_omp_configs()" {
    run grep -E '^copy_omp_configs\(\)' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh includes omp in TOOL_ALLOWLIST_YES" {
    run grep -E 'TOOL_ALLOWLIST_YES=.*omp' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh includes omp in INSTALL_SEQUENCE" {
    run grep -E '"omp:install_omp"' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh defines generate_omp_configs()" {
    run grep -E '^generate_omp_configs\(\)' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "configs/ai-launcher/config.json has omp tool registered" {
    require_jq
    run jq -e '.tools[] | select(.name == "omp")' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
}
