#!/usr/bin/env bats
# Test suite for configs/recommend-skills.json and related README.md content

REPO_ROOT="$BATS_TEST_DIRNAME/.."
RECOMMEND_SKILLS_JSON="$REPO_ROOT/configs/recommend-skills.json"
README_FILE="$REPO_ROOT/README.md"

# ---------------------------------------------------------------------------
# configs/recommend-skills.json – structural / schema tests
# ---------------------------------------------------------------------------

@test "recommend-skills.json is valid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq empty "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
}

@test "recommend-skills.json has top-level recommended_skills array" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '.recommended_skills | type == "array"' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "recommend-skills.json has 9 entries in recommended_skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '.recommended_skills | length' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "9" ]
}

@test "every entry in recommended-skills.json has a non-empty repo field" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == null or .repo == "")] | length == 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "every entry in recommended-skills.json has a non-empty description field" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.description == null or .description == "")] | length == 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# grill-me-with-docs entry (renamed from grill-me)
# ---------------------------------------------------------------------------

@test "recommend-skills.json contains grill-me-with-docs skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.skill == "grill-me-with-docs")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "grill-me-with-docs entry has correct repo mattpocock/skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-me-with-docs")][0].repo' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "mattpocock/skills" ]
}

@test "grill-me-with-docs entry has non-empty description" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-me-with-docs")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "grill-me-with-docs description mentions docs-grounded or stress-test" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-me-with-docs")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [[ "$output" == *"docs"* ]] || [[ "$output" == *"stress"* ]]
}

# ---------------------------------------------------------------------------
# improve-codebase-architecture entry (newly added)
# ---------------------------------------------------------------------------

@test "recommend-skills.json contains improve-codebase-architecture skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.skill == "improve-codebase-architecture")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "improve-codebase-architecture entry has correct repo mattpocock/skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "improve-codebase-architecture")][0].repo' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "mattpocock/skills" ]
}

@test "improve-codebase-architecture entry has non-empty description" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "improve-codebase-architecture")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "improve-codebase-architecture description mentions codebase or architecture" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "improve-codebase-architecture")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [[ "$output" == *"codebase"* ]] || [[ "$output" == *"architecture"* ]]
}

# ---------------------------------------------------------------------------
# Regression: old grill-me skill must no longer be present
# ---------------------------------------------------------------------------

@test "recommend-skills.json does not contain the old grill-me skill" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.skill == "grill-me")] | length == 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# Both mattpocock entries exist and share the same repo
# ---------------------------------------------------------------------------

@test "recommend-skills.json has exactly two mattpocock/skills entries" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "mattpocock/skills")] | length' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]
}

@test "all mattpocock/skills entries have a skill field specified" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "mattpocock/skills") | select(.skill == null or .skill == "")] | length == 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# README.md – install command content tests
# ---------------------------------------------------------------------------

@test "README.md install block contains grill-me-with-docs install command" {
    run grep -F 'npx skills add mattpocock/skills --skill grill-me-with-docs' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md install block contains improve-codebase-architecture install command" {
    run grep -F 'npx skills add mattpocock/skills --skill improve-codebase-architecture' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md does not have old bare grill-me install command" {
    # The old line was: npx skills add mattpocock/skills --skill grill-me
    # After the PR the skill was renamed, so the bare 'grill-me' argument must be absent
    run grep -F 'mattpocock/skills --skill grill-me' "$README_FILE"
    # grep should find the lines – verify they only reference the new skill names
    if [ "$status" -eq 0 ]; then
        # output must not contain a line ending exactly in 'grill-me' (not grill-me-with-docs)
        echo "$output" | grep -qP '\bgrill-me\b(?!-)' && return 1 || return 0
    fi
    return 0
}

@test "README.md Matt Pocock table row references grill-me-with-docs" {
    run grep -F 'grill-me-with-docs' "$README_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mattpocock"* ]]
}

@test "README.md Matt Pocock table row references improve-codebase-architecture" {
    run grep -F 'improve-codebase-architecture' "$README_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mattpocock"* ]]
}

@test "README.md install commands include both new mattpocock skills on separate lines" {
    run grep -c 'npx skills add mattpocock/skills --skill' "$README_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -ge 2 ]
}
