#!/usr/bin/env bats

REPO_ROOT="$BATS_TEST_DIRNAME/.."
CLI_FILE="$REPO_ROOT/cli.sh"
GENERATE_FILE="$REPO_ROOT/generate.sh"
README_FILE="$REPO_ROOT/README.md"
CURSOR_AGENT_FILE="$REPO_ROOT/configs/cursor/agents/code-quality-review.md"
THERMO_SKILL_FILE="$REPO_ROOT/skills/code-quality-review/SKILL.md"

@test "Cursor thermo-nuclear review agent file exists" {
    [ -f "$CURSOR_AGENT_FILE" ]
}

@test "thermo-nuclear code quality skill file exists" {
    [ -f "$THERMO_SKILL_FILE" ]
}

@test "cli.sh installs Cursor custom agents" {
    run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/cursor/agents" "$HOME/.cursor/agents"' "$CLI_FILE"
    [ "$status" -eq 0 ]
}

@test "generate.sh exports Cursor custom agents" {
    run grep -F 'copy_claude_subdirectory "$HOME/.cursor/agents" "$SCRIPT_DIR/configs/cursor/agents" "Cursor agents"' "$GENERATE_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md documents Cursor thermo-nuclear review agent" {
    run grep -F 'code-quality-review' "$README_FILE"
    [ "$status" -eq 0 ]
}
