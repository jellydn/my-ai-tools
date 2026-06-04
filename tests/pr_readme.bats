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

# Grok CLI README tests

@test "README.md references Grok in features table" {
    run grep -F "Grok" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md has Grok section heading" {
    run grep -E "##.*Grok.*CLI" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md mentions @xai-official/grok npm package" {
    run grep -F "@xai-official/grok" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Grok section references x.ai/cli homepage" {
    run grep -F "x.ai/cli" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Grok section references docs.x.ai for overview" {
    run grep -F "docs.x.ai/build/overview" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Resources section has x.ai/cli link" {
    run grep -F "x.ai/cli" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Resources section has docs.x.ai/build/overview link" {
    run grep -F "docs.x.ai/build/overview" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Grok section mentions AGENTS.md compatibility" {
    run grep -c "AGENTS.md" "$README_FILE"
    [ "$output" -gt 0 ]
}
