#!/usr/bin/env bats
# Tests for README.md documentation consistency

load helpers

README_FILE="$REPO_ROOT/README.md"

@test "README.md references vibeproxy as Pi default provider" {
    run grep -F "vibeproxy" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md mentions claude-opus-4-6-thinking as Pi default model" {
    run grep -F "claude-opus-4-6-thinking" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi section heading contains Vibeproxy" {
    run grep -iF "vibeproxy" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md contains brew install cask vibeproxy command" {
    run grep -F "brew install --cask vibeproxy" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi provider table has vibeproxy row" {
    run grep -E "^\| vibeproxy" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi vibeproxy table row lists gemini-3-flash-agent" {
    run grep -E "vibeproxy.*gemini-3-flash-agent" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi vibeproxy table row lists claude-opus-4-6-thinking" {
    run grep -E "vibeproxy.*claude-opus-4-6-thinking" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md no longer states google-antigravity as Pi default provider" {
    # The line that used to say "Default Provider: google-antigravity" must be gone
    run grep -F "**Default Provider**: \`google-antigravity\`" "$README_FILE"
    [ "$status" -ne 0 ]
}

@test "README.md no longer states gemini-3.5-flash as Pi default model" {
    run grep -F "**Default Model**: \`gemini-3.5-flash\`" "$README_FILE"
    [ "$status" -ne 0 ]
}
