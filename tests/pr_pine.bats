#!/usr/bin/env bats
# Tests for PINE coding-agent support

load helpers

REFERENCE="$REPO_ROOT/TOOL_REFERENCE.md"
CLI="$REPO_ROOT/cli.sh"
PINE_CONFIG="$REPO_ROOT/configs/pine/pine.json"
PINE_AGENT="$REPO_ROOT/configs/pine/agents/main/agent.json"

@test "tool reference mentions PINE in the supported-tools list" {
    run grep -F "PINE" "$REFERENCE"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference links the official PINE repository" {
    run grep -F "https://github.com/pmndre/pine" "$REFERENCE"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "tool reference documents the official PINE npm package" {
    run grep -F "npm install -g @pmndre/pine" "$REFERENCE"
    [ "$status" -eq 0 ]
}

@test "PINE documentation covers shared skills, MCP, and backup behavior" {
    run grep -F '`~/.agents/skills` directory' "$REFERENCE"
    [ "$status" -eq 0 ]
    run grep -F 'backs up `~/.pine`' "$REFERENCE"
    [ "$status" -eq 0 ]
    run grep -F 'same MCP server set' "$REFERENCE"
    [ "$status" -eq 0 ]
}

@test "PINE config exposes the universal skills path and shared MCP servers" {
    run python3 - "$PINE_CONFIG" <<'PY'
import json
import sys

config = json.load(open(sys.argv[1], encoding="utf-8"))
assert "~/.agents/skills" in config["skills"]
for server in (
    "web", "browser", "context7", "sequential-thinking", "qmd",
    "codebase-memory-mcp", "fff", "react-grab-mcp", "logpilot",
    "agentmemory", "sem", "ctx",
):
    assert server in config["mcp"], server
PY
    [ "$status" -eq 0 ]
}

@test "PINE installer and backup hooks are present" {
    run grep -F '"pine:install_pine"' "$CLI"
    [ "$status" -eq 0 ]
    run grep -F 'copy_config_dir "$HOME/.pine" "$BACKUP_DIR" "pine"' "$CLI"
    [ "$status" -eq 0 ]
    run grep -F 'copy_pine_configs' "$CLI"
    [ "$status" -eq 0 ]
}

@test "PINE remains optional in yes mode and installs when explicitly selected" {
    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        run_install_sequence
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" != *ATTEMPT:pine* ]]

    run bash -c '
        source "$1/cli.sh"
        YES_TO_ALL=true
        TOOL_ALLOWLIST_YES+=(pine)
        for entry in "${INSTALL_SEQUENCE[@]}"; do
            eval "${entry#*:}() { echo ATTEMPT:${entry%%:*}; }"
        done
        run_install_sequence
    ' _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ "$(grep -c "^ATTEMPT:pine$" <<<"$output")" -eq 1 ]
}

@test "PINE config files are valid JSON" {
    run python3 - "$PINE_CONFIG" "$PINE_AGENT" <<'PY'
import json
import sys

for filename in sys.argv[1:]:
    with open(filename, encoding="utf-8") as handle:
        json.load(handle)
PY
    [ "$status" -eq 0 ]
}

@test "PINE has one tool-reference section before ctx" {
    [ "$(grep -c '^## .*PINE (Optional)$' "$REFERENCE")" -eq 1 ]
    local pine_line ctx_line
    pine_line=$(grep -n '^## .*PINE (Optional)$' "$REFERENCE" | cut -d: -f1)
    ctx_line=$(grep -n '^## .*ctx (Optional)$' "$REFERENCE" | cut -d: -f1)
    [ "$pine_line" -lt "$ctx_line" ]
}
