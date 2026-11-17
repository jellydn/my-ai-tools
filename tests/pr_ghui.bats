#!/usr/bin/env bats
# Regression tests for the ghui companion-tool documentation.

REPO_ROOT="$BATS_TEST_DIRNAME/.."
README_FILE="$REPO_ROOT/README.md"
TOOL_REFERENCE_FILE="$REPO_ROOT/TOOL_REFERENCE.md"

@test "README lists ghui under workflow and desktop tools" {
    run grep -F 'Open Code Review, ghui' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "TOOL_REFERENCE links to the official ghui repository" {
    run grep -F 'https://github.com/kitlangton/ghui' "$TOOL_REFERENCE_FILE"
    [ "$status" -eq 0 ]
}

@test "TOOL_REFERENCE documents upstream ghui install commands" {
    run grep -F 'brew install kitlangton/tap/ghui' "$TOOL_REFERENCE_FILE"
    [ "$status" -eq 0 ]

    run grep -F 'npm install -g @kitlangton/ghui' "$TOOL_REFERENCE_FILE"
    [ "$status" -eq 0 ]
}

@test "TOOL_REFERENCE documents GitHub CLI authentication requirement" {
    run grep -F 'gh auth login' "$TOOL_REFERENCE_FILE"
    [ "$status" -eq 0 ]
}
