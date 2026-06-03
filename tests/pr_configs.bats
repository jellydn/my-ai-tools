#!/usr/bin/env bats
# Tests for config files changed in PR:
#   .pre-commit-config.yaml
#   configs/ai-launcher/config.json
#   configs/antigravity-cli/settings.json
#   configs/claude/settings.json
#   configs/copilot/mcp-config.json
#   configs/pi/models.json
#   configs/pi/settings.json
#   README.md (documentation consistency)

REPO_ROOT="$BATS_TEST_DIRNAME/.."
PRE_COMMIT_CONFIG="$REPO_ROOT/.pre-commit-config.yaml"
AI_LAUNCHER_CONFIG="$REPO_ROOT/configs/ai-launcher/config.json"
ANTIGRAVITY_SETTINGS="$REPO_ROOT/configs/antigravity-cli/settings.json"
CLAUDE_SETTINGS="$REPO_ROOT/configs/claude/settings.json"
COPILOT_MCP="$REPO_ROOT/configs/copilot/mcp-config.json"
PI_MODELS="$REPO_ROOT/configs/pi/models.json"
PI_SETTINGS="$REPO_ROOT/configs/pi/settings.json"
README_FILE="$REPO_ROOT/README.md"

# ---------------------------------------------------------------------------
# Helper: skip if jq is unavailable
# ---------------------------------------------------------------------------
require_jq() {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
}

# ===========================================================================
# .pre-commit-config.yaml
# ===========================================================================

@test ".pre-commit-config.yaml exists" {
    [ -f "$PRE_COMMIT_CONFIG" ]
}

@test ".pre-commit-config.yaml is valid YAML (bash syntax check via grep structure)" {
    run grep -c "^repos:" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test ".pre-commit-config.yaml references mirrors-oxfmt repo" {
    run grep -F "oxc-project/mirrors-oxfmt" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml uses oxfmt rev v0.51.0" {
    run grep -F "v0.51.0" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml has oxfmt hook id" {
    run grep -F "id: oxfmt" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml does not reference mirrors-prettier" {
    run grep -F "mirrors-prettier" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}

@test ".pre-commit-config.yaml does not have prettier hook id" {
    run grep -E "^\s+- id: prettier$" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}

@test ".pre-commit-config.yaml still contains pre-commit-hooks repo" {
    run grep -F "pre-commit/pre-commit-hooks" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml still contains check-yaml hook" {
    run grep -F "id: check-yaml" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml does not define types_or for oxfmt" {
    run grep -F "types_or" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}

# ===========================================================================
# configs/ai-launcher/config.json
# ===========================================================================

@test "configs/ai-launcher/config.json is valid JSON" {
    require_jq
    run jq empty "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand uses opencode/big-pickle" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json opencode tool promptCommand does not reference deepseek-v4-flash-free" {
    require_jq
    run jq -r '[.tools[] | select(.name == "opencode")][0].promptCommand' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != *"deepseek-v4-flash-free"* ]]
}

@test "configs/ai-launcher/config.json review template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "review")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-zen template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-zen")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-staged template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-staged")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json commit-atomic template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "commit-atomic")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json architecture-explanation template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "architecture-explanation")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json draft-pull-request template command uses opencode/big-pickle" {
    require_jq
    run jq -r '[.templates[] | select(.name == "draft-pull-request")][0].command' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"opencode/big-pickle"* ]]
}

@test "configs/ai-launcher/config.json has no remaining deepseek-v4-flash-free references" {
    run grep -F "deepseek-v4-flash-free" "$AI_LAUNCHER_CONFIG"
    [ "$status" -ne 0 ]
}

@test "configs/ai-launcher/config.json has a tools array" {
    require_jq
    run jq -e '.tools | type == "array"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/ai-launcher/config.json has a templates array" {
    require_jq
    run jq -e '.templates | type == "array"' "$AI_LAUNCHER_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ===========================================================================
# configs/antigravity-cli/settings.json
# ===========================================================================

@test "configs/antigravity-cli/settings.json is valid JSON" {
    require_jq
    run jq empty "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/antigravity-cli/settings.json model is Gemini 3.5 Flash (High)" {
    require_jq
    run jq -r '.model' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "Gemini 3.5 Flash (High)" ]
}

@test "configs/antigravity-cli/settings.json model is not Claude Opus 4.6 (Thinking)" {
    require_jq
    run jq -r '.model' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" != "Claude Opus 4.6 (Thinking)" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains autoreview script" {
    require_jq
    run jq -e '[.permissions.allow[] | select(contains("autoreview"))] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains unsandboxed(tail)" {
    require_jq
    run jq -e '[.permissions.allow[] | select(. == "unsandboxed(tail)")] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow contains unsandboxed(bun add)" {
    require_jq
    run jq -e '[.permissions.allow[] | select(. == "unsandboxed(bun add)")] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.allow is an array" {
    require_jq
    run jq -e '.permissions.allow | type == "array"' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/antigravity-cli/settings.json permissions.deny still contains git reset --hard" {
    require_jq
    run jq -e '[.permissions.deny[] | select(contains("git reset --hard"))] | length > 0' "$ANTIGRAVITY_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ===========================================================================
# configs/claude/settings.json
# ===========================================================================

@test "configs/claude/settings.json is valid JSON" {
    require_jq
    run jq empty "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/claude/settings.json hooks object contains StopFailure key" {
    require_jq
    run jq -e '.hooks | has("StopFailure")' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure is a non-empty array" {
    require_jq
    run jq -e '.hooks.StopFailure | type == "array" and length > 0' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure first entry has hooks array" {
    require_jq
    run jq -e '.hooks.StopFailure[0].hooks | type == "array" and length > 0' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json StopFailure hook type is command" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].type' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "command" ]
}

@test "configs/claude/settings.json StopFailure hook command references orca agent-hooks" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [[ "$output" == *".orca/agent-hooks"* ]]
}

@test "configs/claude/settings.json StopFailure hook command references claude-hook.sh" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude-hook.sh"* ]]
}

@test "configs/claude/settings.json still has Stop hook" {
    require_jq
    run jq -e '.hooks | has("Stop")' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/claude/settings.json hooks has all expected top-level event keys" {
    require_jq
    run jq -e '(.hooks | keys) | (contains(["StopFailure"]) and contains(["Stop"]) and contains(["PostToolUse"]))' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# Boundary: StopFailure hook must not be accidentally empty string
@test "configs/claude/settings.json StopFailure hook command is non-empty" {
    require_jq
    run jq -r '.hooks.StopFailure[0].hooks[0].command' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# ===========================================================================
# configs/copilot/mcp-config.json
# ===========================================================================

@test "configs/copilot/mcp-config.json is valid JSON" {
    require_jq
    run jq empty "$COPILOT_MCP"
    [ "$status" -eq 0 ]
}

@test "configs/copilot/mcp-config.json agentmemory server exists" {
    require_jq
    run jq -e '.mcpServers | has("agentmemory")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_URL" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_URL")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_SECRET" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_SECRET")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory env has AGENTMEMORY_TOOLS" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | has("AGENTMEMORY_TOOLS")' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json agentmemory AGENTMEMORY_TOOLS default contains all" {
    require_jq
    run jq -r '.mcpServers.agentmemory.env.AGENTMEMORY_TOOLS' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"all"* ]]
}

@test "configs/copilot/mcp-config.json agentmemory AGENTMEMORY_URL default contains localhost:3111" {
    require_jq
    run jq -r '.mcpServers.agentmemory.env.AGENTMEMORY_URL' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"localhost:3111"* ]]
}

@test "configs/copilot/mcp-config.json all pre-existing servers still present" {
    require_jq
    run jq -e '
        (.mcpServers | keys) |
        contains(["context7", "sequential-thinking", "fff", "qmd", "react-grab-mcp", "logpilot", "agentmemory"])
    ' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json every server has a type field" {
    require_jq
    run jq -e '[.mcpServers[] | select(.type == null or .type == "")] | length == 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/copilot/mcp-config.json every server has a tools field" {
    require_jq
    run jq -e '[.mcpServers[] | select(.tools == null)] | length == 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# Regression: agentmemory env must not be an empty object (was {} before PR)
@test "configs/copilot/mcp-config.json agentmemory env is not empty" {
    require_jq
    run jq -e '.mcpServers.agentmemory.env | length > 0' "$COPILOT_MCP"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ===========================================================================
# configs/pi/models.json
# ===========================================================================

@test "configs/pi/models.json is valid JSON" {
    require_jq
    run jq empty "$PI_MODELS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/models.json has vibeproxy provider" {
    require_jq
    run jq -e '.providers | has("vibeproxy")' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy api is openai-completions" {
    require_jq
    run jq -r '.providers.vibeproxy.api' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "openai-completions" ]
}

@test "configs/pi/models.json vibeproxy apiKey is vibeproxy" {
    require_jq
    run jq -r '.providers.vibeproxy.apiKey' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "vibeproxy" ]
}

@test "configs/pi/models.json vibeproxy baseUrl is http://127.0.0.1:51200/v1" {
    require_jq
    run jq -r '.providers.vibeproxy.baseUrl' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "http://127.0.0.1:51200/v1" ]
}

@test "configs/pi/models.json vibeproxy has 7 models" {
    require_jq
    run jq -r '.providers.vibeproxy.models | length' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "7" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-3-flash-agent model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent contextWindow is 1048576" {
    require_jq
    run jq -r '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].contextWindow' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "1048576" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent has toolCalling true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].toolCalling == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy gemini-3-flash-agent has reasoning true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-flash-agent")][0].reasoning == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains claude-opus-4-6-thinking model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy claude-opus-4-6-thinking has reasoning true" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")][0].reasoning == true' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy claude-opus-4-6-thinking contextWindow is 250000" {
    require_jq
    run jq -r '[.providers.vibeproxy.models[] | select(.id == "claude-opus-4-6-thinking")][0].contextWindow' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "250000" ]
}

@test "configs/pi/models.json vibeproxy contains claude-sonnet-4-6 model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "claude-sonnet-4-6")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-3-pro-high model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-3-pro-high")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy contains gemini-pro-agent model" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == "gemini-pro-agent")] | length > 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model has non-empty id" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.id == null or .id == "")] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model has positive contextWindow" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.contextWindow <= 0)] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json vibeproxy every model supports text input" {
    require_jq
    run jq -e '[.providers.vibeproxy.models[] | select(.input | contains(["text"]) | not)] | length == 0' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/models.json still contains google-antigravity provider" {
    require_jq
    run jq -e '.providers | has("google-antigravity")' "$PI_MODELS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ===========================================================================
# configs/pi/settings.json
# ===========================================================================

@test "configs/pi/settings.json is valid JSON" {
    require_jq
    run jq empty "$PI_SETTINGS"
    [ "$status" -eq 0 ]
}

@test "configs/pi/settings.json defaultModel is gemini-3-flash-agent" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "gemini-3-flash-agent" ]
}

@test "configs/pi/settings.json defaultModel is not gemini-3.5-flash" {
    require_jq
    run jq -r '.defaultModel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" != "gemini-3.5-flash" ]
}

@test "configs/pi/settings.json defaultProvider is vibeproxy" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "vibeproxy" ]
}

@test "configs/pi/settings.json defaultProvider is not google-antigravity" {
    require_jq
    run jq -r '.defaultProvider' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" != "google-antigravity" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/gemini-3-flash-agent" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/gemini-3-flash-agent")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/claude-opus-4-6-thinking" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/claude-opus-4-6-thinking")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/claude-sonnet-4-6" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/claude-sonnet-4-6")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/gemini-3-pro-high" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/gemini-3-pro-high")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains vibeproxy/gemini-pro-agent" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "vibeproxy/gemini-pro-agent")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels contains commandcode models" {
    require_jq
    run jq -e '[.enabledModels[] | select(startswith("commandcode/"))] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/glm-5.1" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/glm-5.1")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/kimi-k2.6" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/kimi-k2.6")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/deepseek-v4-flash" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/deepseek-v4-flash")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels does not contain opencode-go/deepseek-v4-pro" {
    require_jq
    run jq -e '[.enabledModels[] | select(. == "opencode-go/deepseek-v4-pro")] | length == 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-dynamic-workflows" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-dynamic-workflows")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json packages contains pi-commandcode-provider" {
    require_jq
    run jq -e '[.packages[] | select(type == "string" and . == "npm:pi-commandcode-provider")] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json enabledModels is a non-empty array" {
    require_jq
    run jq -e '.enabledModels | type == "array" and length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "configs/pi/settings.json defaultThinkingLevel is high" {
    require_jq
    run jq -r '.defaultThinkingLevel' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "high" ]
}

# Boundary: defaultModel must match a model that vibeproxy exposes
@test "configs/pi/settings.json defaultModel is listed in enabledModels as vibeproxy entry" {
    require_jq
    local default_model
    default_model=$(jq -r '.defaultModel' "$PI_SETTINGS")
    local default_provider
    default_provider=$(jq -r '.defaultProvider' "$PI_SETTINGS")
    run jq -e --arg model "${default_provider}/${default_model}" \
        '[.enabledModels[] | select(. == $model)] | length > 0' "$PI_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ===========================================================================
# README.md – documentation consistency with changed configs
# ===========================================================================

@test "README.md references vibeproxy as Pi default provider" {
    run grep -F "vibeproxy" "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md mentions gemini-3-flash-agent as Pi default model" {
    run grep -F "gemini-3-flash-agent" "$README_FILE"
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
