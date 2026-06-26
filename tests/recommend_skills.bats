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

@test "recommend-skills.json has 17 entries in recommended_skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '.recommended_skills | length' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "17" ]
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
# grill-with-docs entry (renamed from grill-me)
# ---------------------------------------------------------------------------

@test "recommend-skills.json contains grill-with-docs skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.skill == "grill-with-docs")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "grill-with-docs entry has correct repo mattpocock/skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-with-docs")][0].repo' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "mattpocock/skills" ]
}

@test "grill-with-docs entry has non-empty description" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-with-docs")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "grill-with-docs description mentions docs-grounded or stress-test" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "grill-with-docs")][0].description' "$RECOMMEND_SKILLS_JSON"
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

@test "README.md install block contains grill-with-docs install command" {
    run grep -F 'npx skills add mattpocock/skills --skill grill-with-docs' "$README_FILE"
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
        # output must not contain a line ending exactly in 'grill-me' (not grill-with-docs)
        echo "$output" | grep -qP '\bgrill-me\b(?!-)' && return 1 || return 0
    fi
    return 0
}

@test "README.md Matt Pocock table row references grill-with-docs" {
    run grep -F 'grill-with-docs' "$README_FILE"
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

@test "README.md install block contains no-use-effect install command" {
    run grep -F 'npx skills add factory-ai/factory-plugins --skill no-use-effect' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md install block contains modern-web-guidance install command" {
    run grep -F 'npx skills add GoogleChrome/modern-web-guidance --skill modern-web-guidance' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md table row references GoogleChrome/modern-web-guidance" {
    run grep -F 'GoogleChrome/modern-web-guidance' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md install block contains mac-ocr install command" {
    run grep -F 'npx skills add privatenumber/mac-ocr --skill mac-ocr' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md table row references privatenumber/mac-ocr" {
    run grep -F 'privatenumber/mac-ocr' "$README_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mac-ocr"* ]]
}

@test "recommend-skills.json contains openclaw autoreview skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "openclaw/agent-skills" and .skill == "autoreview")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "README.md install block contains openclaw autoreview install command" {
    run grep -F 'npx skills add openclaw/agent-skills --skill autoreview' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md table row references openclaw autoreview SKILL.md URL" {
    run grep -F 'https://github.com/openclaw/agent-skills/blob/main/skills/autoreview/SKILL.md' "$README_FILE"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# openai/codex babysit-pr entry (newly added)
# ---------------------------------------------------------------------------

@test "recommend-skills.json contains openai/codex babysit-pr skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "openai/codex" and .skill == "babysit-pr")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "babysit-pr entry has non-empty description" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "babysit-pr")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "babysit-pr description mentions monitor or review comments" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.skill == "babysit-pr")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [[ "$output" == *"monitor"* ]] || [[ "$output" == *"review"* ]]
}

@test "README.md install block contains openai/codex babysit-pr install command" {
    run grep -F 'npx skills add openai/codex --skill babysit-pr' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md table row references openai/codex babysit-pr SKILL.md URL" {
    run grep -F 'https://github.com/openai/codex/blob/main/.codex/skills/babysit-pr/SKILL.md' "$README_FILE"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# shadcn/improve entry (newly added)
# ---------------------------------------------------------------------------

@test "recommend-skills.json contains shadcn/improve skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "shadcn/improve")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "shadcn/improve entry has non-empty description" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "shadcn/improve")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "shadcn/improve description mentions audit or plan" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "shadcn/improve")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [[ "$output" == *"audit"* ]] || [[ "$output" == *"plan"* ]]
}

@test "README.md install block contains shadcn/improve install command" {
    run grep -F 'npx skills add shadcn/improve' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "README.md table row references shadcn/improve GitHub URL" {
    run grep -F 'https://github.com/shadcn/improve' "$README_FILE"
    [ "$status" -eq 0 ]
}

@test "shadcn/improve is the first entry in recommended_skills" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '.recommended_skills[0].repo' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "shadcn/improve" ]
}

@test "shadcn/improve entry has no skill subfield" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    # shadcn/improve is a repo-level skill, not a sub-skill – skill key must be absent
    run jq -r '[.recommended_skills[] | select(.repo == "shadcn/improve")][0].skill' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "null" ]
}

@test "shadcn/improve description mentions model cost or execution strategy" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "shadcn/improve")][0].description' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [[ "$output" == *"model"* ]] || [[ "$output" == *"execution"* ]]
}

@test "recommend-skills.json contains shadcn/improve exactly once" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "shadcn/improve")] | length' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "recommend-skills.json still contains mvanhorn/last30days-skill after reorder" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "mvanhorn/last30days-skill")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "README.md Improve table row includes description about cheaper models" {
    run grep -F 'shadcn/improve' "$README_FILE"
    [ "$status" -eq 0 ]
    # The table row should contain context about planning/execution model split
    [[ "$output" == *"cheaper"* ]] || [[ "$output" == *"model"* ]] || [[ "$output" == *"plan"* ]]
}

@test "recommend-skills.json contains Gentleman-Programming/engram" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -r '[.recommended_skills[] | select(.repo == "Gentleman-Programming/engram")] | length' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "recommend-skills.json contains privatenumber/mac-ocr skill entry" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run jq -e '[.recommended_skills[] | select(.repo == "privatenumber/mac-ocr" and .skill == "mac-ocr")] | length > 0' "$RECOMMEND_SKILLS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}
