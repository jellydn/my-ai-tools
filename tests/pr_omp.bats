#!/usr/bin/env bats
# Tests for Oh My Pi (omp) CLI scaffolding

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
AI_LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"

setup() {
    source "$REPO_ROOT/lib/common.sh"
    source "$REPO_ROOT/lib/install.sh"
    source "$REPO_ROOT/cli.sh"
    source "$REPO_ROOT/generate.sh"
    export DRY_RUN=false
    export SCRIPT_DIR="$REPO_ROOT"
    export YES_TO_ALL=false
    export VERBOSE=false
}

@test "configs/omp/config.yml exists" {
    [ -f "$REPO_ROOT/configs/omp/config.yml" ]
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

@test "generate.sh generate_omp_configs() exports config.yml and config.yaml" {
    run awk '/^generate_omp_configs\(\)/,/^}/' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [[ "$output" == *"config.yml"* ]]
    [[ "$output" == *"config.yaml"* ]]
}

@test "cli.sh copy_omp_configs() handles config.yml and config.yaml" {
    run awk '/^copy_omp_configs\(\)/,/^}/' "$CLI_SH"
    [ "$status" -eq 0 ]
    [[ "$output" == *"config.yml"* ]]
    [[ "$output" == *"config.yaml"* ]]
}


@test "configs/ai-launcher/config.json has omp tool registered" {
    require_jq
    run jq -e '.tools[] | select(.name == "omp")' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
}

@test "copy_omp_configs installs configs into a detected HOME" {
    export DRY_RUN=false
    FAKE_HOME=$(mktemp -d)
    mkdir -p "$FAKE_HOME/.omp"

    HOME="$FAKE_HOME" copy_omp_configs

    [ -f "$FAKE_HOME/.omp/agent/config.yml" ]
    [ -f "$FAKE_HOME/.omp/agent/AGENTS.md" ]
    rm -rf "$FAKE_HOME"
}

@test "generate_omp_configs exports config.yml from a detected HOME" {
    export DRY_RUN=false
    FAKE_HOME=$(mktemp -d)
    FAKE_SCRIPT_DIR=$(mktemp -d)
    mkdir -p "$FAKE_HOME/.omp/agent"
    echo "setupVersion: 1" > "$FAKE_HOME/.omp/agent/config.yml"
    echo '{"collapseChangelog": true}' > "$FAKE_HOME/.omp/agent/settings.json"

    HOME="$FAKE_HOME" SCRIPT_DIR="$FAKE_SCRIPT_DIR" generate_omp_configs

    [ -f "$FAKE_SCRIPT_DIR/configs/omp/config.yml" ]
    [ ! -f "$FAKE_SCRIPT_DIR/configs/omp/settings.json" ]
    run grep "setupVersion: 1" "$FAKE_SCRIPT_DIR/configs/omp/config.yml"
    [ "$status" -eq 0 ]
    rm -rf "$FAKE_HOME" "$FAKE_SCRIPT_DIR"
}
