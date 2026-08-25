#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	SKILL="$REPO_ROOT/skills/accountable-engineering/SKILL.md"
	MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
}

@test "accountable workflow has one completion gate per step" {
	run grep -Ec '^### [1-8]\. ' "$SKILL"
	[ "$status" -eq 0 ]
	[ "$output" -eq 8 ]
	run grep -c '^\*\*Complete when\*\*:' "$SKILL"
	[ "$status" -eq 0 ]
	[ "$output" -eq 8 ]
}

@test "accountable workflow requires material questions and checkable focused changes" {
	run grep -F 'Ask only when different interpretations would change' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'For each significant step, name' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'Account for every changed hunk as either required work or cleanup made necessary by that work.' "$SKILL"
	[ "$status" -eq 0 ]
}

@test "accountable engineering references installed paths" {
	run grep -F '@~/.agents/skills/accountable-engineering/SKILL.md' "$REPO_ROOT/configs/best-practices.md"
	[ "$status" -eq 0 ]
	run grep -F '@~/.agents/skills/accountable-engineering/SKILL.md' "$REPO_ROOT/configs/fable-guide.md"
	[ "$status" -eq 0 ]
	run grep -F '`~/.ai-tools/implementation-notes.md`' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -E '`(skills|configs)/' "$SKILL"
	[ "$status" -ne 0 ]
}

@test "accountable engineering is registered once in the Claude marketplace" {
	run jq -e '[.plugins[] | select(.name == "accountable-engineering")] | length == 1' "$MARKETPLACE"
	[ "$status" -eq 0 ]
	run jq -er '.plugins[] | select(.name == "accountable-engineering") | [.source, .category, .version] | @tsv' "$MARKETPLACE"
	[ "$status" -eq 0 ]
	[ "$output" = $'./skills/accountable-engineering\tproductivity\t1.0.0' ]
	[ -f "$REPO_ROOT/skills/accountable-engineering/SKILL.md" ]
}

@test "README documents accountable engineering installation and usage" {
	run grep -F 'Available skills: accountable-engineering,' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
	run grep -F -- '- `accountable-engineering` - Checkpoint-driven workflow' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
	run grep -F '`my-ai-tools-skills:accountable-engineering`' "$REPO_ROOT/README.md"
	[ "$status" -eq 0 ]
}
