#!/usr/bin/env bats
# Tests for README.md documentation consistency

load helpers

README_FILE="$REPO_ROOT/README.md"
PI_SETTINGS="$REPO_ROOT/configs/pi/settings.json"

@test "README.md Pi defaults match configs/pi/settings.json" {
    require_jq
    local provider model
    provider=$(jq -r '.defaultProvider' "$PI_SETTINGS")
    model=$(jq -r '.defaultModel' "$PI_SETTINGS")

    run grep -F "**Default Provider**: \`$provider\`" "$README_FILE"
    [ "$status" -eq 0 ]

    run grep -F "**Default Model**: \`$model\`" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md still references commandcode provider for Pi" {
    run grep -F "commandcode" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md still mentions deepseek/deepseek-v4-pro among Pi models" {
    run grep -F "deepseek/deepseek-v4-pro" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi overview lists current packages" {
    run grep -F "pi-qwencloud-provider" "$README_FILE"
    [ "$status" -eq 0 ]
    run grep -F "pi-cursor-sdk" "$README_FILE"
    [ "$status" -eq 0 ]
    run grep -F "dynamic-workflows" "$README_FILE"
    [ "$status" -eq 1 ]
    run grep -F "pi-xai-oauth" "$README_FILE"
    [ "$status" -eq 1 ]
}

@test "README.md Auto-Install note is outside the bash fence" {
    run bash -c '
        awk "
            /^```bash$/ { in_bash=1; next }
            /^```$/ { in_bash=0; next }
            in_bash && /Auto-Install/ { found=1 }
            END { exit found ? 0 : 1 }
        " "$1"
    ' _ "$README_FILE"
    [ "$status" -eq 1 ]
}

@test "README.md Pi section heading contains Antigravity Rotator" {
    run grep -F "Antigravity Rotator" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md contains npm install pi-antigravity-rotator command" {
    run grep -F "npm install -g pi-antigravity-rotator" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi enabled models table has openai-codex row" {
    run grep -E "^\| openai-codex" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi openai-codex table row lists gpt models" {
    run grep -E "openai-codex.*gpt-5.4" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md Pi openai-codex table row lists gpt-5.4-mini" {
    run grep -E "openai-codex.*gpt-5.4-mini" "$README_FILE"
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
