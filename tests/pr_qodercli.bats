#!/usr/bin/env bats
# Tests for Qoder CLI scaffolding (issue #264)

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
LIB_INSTALL="$REPO_ROOT/lib/install.sh"
CLI_SH="$REPO_ROOT/cli.sh"
GENERATE_SH="$REPO_ROOT/generate.sh"
README="$REPO_ROOT/README.md"

@test "configs/qodercli/AGENTS.md exists" {
    [ -f "$REPO_ROOT/configs/qodercli/AGENTS.md" ]
}

@test "lib/install.sh defines install_qodercli()" {
    run grep -E '^install_qodercli\(\)' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_qodercli() uses the official qoder.com installer" {
    run grep -E 'qoder\.com/install' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "lib/install.sh install_qodercli() handles Windows PowerShell install" {
    run grep -E 'qoder\.com/install\.ps1' "$LIB_INSTALL"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh defines copy_qodercli_configs()" {
    run grep -E '^copy_qodercli_configs\(\)' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_configurations() calls copy_qodercli_configs" {
    run grep -E 'copy_qodercli_configs' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh main() installs qodercli" {
    run grep -E '^\s*install_qodercli\b' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh banner advertises Qoder CLI" {
    run grep -E 'Qoder CLI' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "cli.sh copy_qodercli_configs() targets ~/.qoder/" {
    run grep -E 'HOME/\.qoder' "$CLI_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh defines generate_qodercli_configs()" {
    run grep -E '^generate_qodercli_configs\(\)' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "generate.sh main() invokes generate_qodercli_configs" {
    run grep -E '^\s*generate_qodercli_configs\b' "$GENERATE_SH"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md mentions Qoder CLI in the supported-tools list" {
    run grep -E 'Qoder CLI' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "README.md has a Qoder CLI section with a curl installer example" {
    run grep -E 'qoder\.com/install' "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test ".changeset has an entry for qodercli support" {
    run bash -c "ls -1 $REPO_ROOT/.changeset/ | grep -i qoder"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
