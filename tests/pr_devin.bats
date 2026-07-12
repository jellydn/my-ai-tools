#!/usr/bin/env bats
# Tests for Devin CLI support

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
README="$REPO_ROOT/README.md"

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
