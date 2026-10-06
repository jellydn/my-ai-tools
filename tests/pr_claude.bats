#!/usr/bin/env bats
# Tests for configs/claude/settings.json

load helpers

CLAUDE_SETTINGS="$REPO_ROOT/configs/claude/settings.json"
CLAUDE_GUIDELINES="$REPO_ROOT/configs/claude/CLAUDE.md"
CLI_SH="$REPO_ROOT/cli.sh"
INSTALL_SH="$REPO_ROOT/lib/install.sh"

@test "configs/claude/CLAUDE.md does not eagerly import supplemental guidance" {
    run grep -E '@[^[:space:]]+\.(md|mdx)([[:space:]]|$)' "$CLAUDE_GUIDELINES"
    [ "$status" -eq 1 ]
}

@test "configs/claude/CLAUDE.md documents token-efficient session habits" {
    run grep -F '## Token-Efficient Sessions' "$CLAUDE_GUIDELINES"
    [ "$status" -eq 0 ]

    run grep -F '/context' "$CLAUDE_GUIDELINES"
    [ "$status" -eq 0 ]

    run grep -F '/clear' "$CLAUDE_GUIDELINES"
    [ "$status" -eq 0 ]
}

@test "configs/claude/settings.json is valid JSON" {
    require_jq
    run jq empty "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/claude/settings.json uses token-efficient model routing" {
    require_jq
    run jq -e '.model == "sonnet" and .effortLevel == "medium" and .advisorModel == "opus" and .verbose == false' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/claude/settings.json enables Caveman" {
    require_jq
    run jq -e '.enabledPlugins["caveman@caveman"] == true and .extraKnownMarketplaces.caveman.source.repo == "JuliusBrussee/caveman"' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]

    run grep -F 'caveman|caveman@caveman|JuliusBrussee/caveman|claude' "$CLI_SH"
    [ "$status" -eq 0 ]
}

@test "Claude setup configures hook-only RTK integration" {
    run grep -F 'install_rtk' "$CLI_SH"
    [ "$status" -eq 0 ]

    run grep -F 'rtk-ai/rtk/refs/heads/master/install.sh' "$INSTALL_SH"
    [ "$status" -eq 0 ]

    require_jq
    run jq -e '[.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | contains("rtk hook claude"))] | length == 1' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "RTK installer handles native Windows without running the Unix installer" {
    run grep -F 'RTK automatic installation is unavailable on native Windows' "$INSTALL_SH"
    [ "$status" -eq 0 ]
}

@test "RTK installer dry-run succeeds with an empty user PATH" {
    run bash -c '
        source "$1/lib/common.sh"
        source "$1/lib/install.sh"
        export HOME
        HOME="$(mktemp -d)"
        trap '\''rm -rf "$HOME"'\'' EXIT
        export PATH="/usr/bin:/bin"
        export DRY_RUN=true YES_TO_ALL=true IS_WINDOWS=false
        install_rtk
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rtk-ai/rtk/refs/heads/master/install.sh"* ]]
}

@test "RTK installer skips safely on native Windows" {
    run bash -c '
        source "$1/lib/common.sh"
        source "$1/lib/install.sh"
        export DRY_RUN=false YES_TO_ALL=true IS_WINDOWS=true
        install_rtk
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"unavailable on native Windows"* ]]
}

@test "configs/claude/settings.json hooks has the current top-level event keys" {
    require_jq
    run jq -e '(.hooks | keys) == ["PostToolUse", "PreToolUse", "SessionStart"]' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json PostToolUse contains formatter hooks" {
    require_jq
    run jq -e '[.hooks.PostToolUse[].hooks[] | .command] | any(contains("biome check --write")) and any(contains("ruff format")) and any(contains("rustfmt"))' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json does not configure removed Stop hooks" {
    require_jq
    run jq -e '(.hooks | has("Stop") or has("StopFailure")) | not' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
