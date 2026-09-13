#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	PLUGIN_ROOT="$REPO_ROOT/configs/amp/plugins/my-ai-tools-skills"
}

@test "Amp skills plugin bundles every canonical skill without drift" {
	run diff -qr -x README-DISCOVERY.md "$REPO_ROOT/skills" "$PLUGIN_ROOT/skills"
	[ "$status" -eq 0 ]
}

@test "Amp skills plugin registers every bundled skill" {
	local skill_dir
	local skill_name
	local skill_count=0

	for skill_dir in "$PLUGIN_ROOT"/skills/*; do
		[ -d "$skill_dir" ] || continue
		skill_name="$(basename "$skill_dir")"
		[ -f "$skill_dir/SKILL.md" ]
		run grep -F $'\t"'"$skill_name"'",' "$PLUGIN_ROOT/index.ts"
		[ "$status" -eq 0 ]
		skill_count=$((skill_count + 1))
	done

	run grep -c $'^\t"[a-z0-9-]*",$' "$PLUGIN_ROOT/index.ts"
	[ "$status" -eq 0 ]
	[ "$output" -eq "$skill_count" ]
}

@test "bundled skill names match their directories" {
	local skill_dir
	local skill_name

	for skill_dir in "$PLUGIN_ROOT"/skills/*; do
		[ -d "$skill_dir" ] || continue
		skill_name="$(basename "$skill_dir")"
		run grep -Eq "^name: [\"']?$skill_name[\"']?$" "$skill_dir/SKILL.md"
		[ "$status" -eq 0 ]
	done
}

@test "canonical skill descriptions stay concise" {
	local description
	local skill_file

	for skill_file in "$REPO_ROOT"/skills/*/SKILL.md; do
		description="$(sed -n 's/^description:[[:space:]]*//p' "$skill_file" | head -n 1)"
		[ -n "$description" ]
		[[ "$description" != "|"* ]]
		[[ "$description" != ">"* ]]
		[ "${#description}" -le 160 ]
	done
}
