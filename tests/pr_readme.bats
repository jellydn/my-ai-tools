#!/usr/bin/env bats
# Tests for README.md documentation consistency

load helpers

README_FILE="$REPO_ROOT/README.md"

@test "README.md references commandcode as Pi default provider" {
    run grep -F "commandcode" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md mentions deepseek/deepseek-v4-pro as Pi default model" {
    run grep -F "deepseek/deepseek-v4-pro" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi section heading contains Antigravity Rotator" {
    run grep -F "Antigravity Rotator" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md contains npm install pi-antigravity-rotator command" {
    run grep -F "npm install -g pi-antigravity-rotator" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi provider table has commandcode row" {
    run grep -E "^\| commandcode" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi commandcode table row lists deepseek models" {
    run grep -E "commandcode.*deepseek/deepseek-v4-pro" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi commandcode table row lists mimo-v2.5-pro" {
    run grep -E "commandcode.*mimo-v2.5-pro" "$README_FILE"
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
