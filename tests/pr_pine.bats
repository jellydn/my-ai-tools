#!/usr/bin/env bats
# Tests for PINE coding-agent documentation

load helpers

README="$REPO_ROOT/TOOL_REFERENCE.md"

@test "tool reference mentions PINE in the supported-tools list" {
    run grep -F "PINE" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference links the official PINE repository" {
    run grep -F "https://github.com/pmndre/pine" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference documents the official PINE npm package" {
    run grep -F "npm install -g @pmndre/pine" "$README"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference documents PINE initialization and project usage" {
    run grep -F "pine init" "$README"
    [ "$status" -eq 0 ]
    run grep -F "pine ." "$README"
    [ "$status" -eq 0 ]
}

@test "PINE documentation states that my-ai-tools does not manage its configuration" {
    run grep -F "does not manage a PINE configuration" "$README"
    [ "$status" -eq 0 ]
}

@test "PINE has one tool-reference section before ctx" {
    [ "$(grep -c '^## .*PINE (Optional)$' "$README")" -eq 1 ]
    local pine_line ctx_line
    pine_line=$(grep -n '^## .*PINE (Optional)$' "$README" | cut -d: -f1)
    ctx_line=$(grep -n '^## .*ctx (Optional)$' "$README" | cut -d: -f1)
    [ "$pine_line" -lt "$ctx_line" ]
}
