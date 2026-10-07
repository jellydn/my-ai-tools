#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	PLUGIN_ROOT="$REPO_ROOT/configs/amp/plugins/my-ai-tools-skills"
}

setup_visual_pr_fixture() {
	VISUAL_PR_BIN_DIR="$BATS_TEST_TMPDIR/bin"
	VISUAL_PR_COMMENT_FILE="$BATS_TEST_TMPDIR/comment.md"
	mkdir -p "$VISUAL_PR_BIN_DIR"
	printf '%s\n' 'visual outline' >"$VISUAL_PR_COMMENT_FILE"
	cat >"$VISUAL_PR_BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_CALLS"
case "$*" in
	"repo view --json nameWithOwner --jq .nameWithOwner") echo "jellydn/my-ai-tools" ;;
	"api user --jq .login") echo "jellydn" ;;
	"api --paginate repos/jellydn/my-ai-tools/issues/42/comments")
		[ "${GH_LOOKUP_FAIL:-}" != "1" ] || exit 1
		echo "$GH_COMMENTS"
		;;
	"api --method PATCH repos/jellydn/my-ai-tools/issues/comments/9 --input - --jq .html_url")
		cat >"$GH_PAYLOAD"
		echo "https://github.com/jellydn/my-ai-tools/pull/42#issuecomment-9"
		;;
	"pr comment 42 --body-file "*)
		cp "${*: -1}" "$GH_PAYLOAD"
		echo "https://github.com/jellydn/my-ai-tools/pull/42#issuecomment-10"
		;;
	*) exit 1 ;;
esac
EOF
	chmod +x "$VISUAL_PR_BIN_DIR/gh"
}

run_visual_pr_publish() {
	local comments="$1"
	local lookup_fail="${2:-}"
	run env PATH="$VISUAL_PR_BIN_DIR:$PATH" GH_CALLS="$BATS_TEST_TMPDIR/calls" \
		GH_PAYLOAD="$BATS_TEST_TMPDIR/payload" GH_COMMENTS="$comments" GH_LOOKUP_FAIL="$lookup_fail" \
		"$REPO_ROOT/skills/visual-pr/scripts/publish-comment.sh" 42 "$VISUAL_PR_COMMENT_FILE"
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
		if [[ "$description" == \"*\" ]] || [[ "$description" == \'*\' ]]; then
			description="${description:1:${#description}-2}"
		fi
		[ "${#description}" -le 160 ]
	done
}

@test "visual-pr publishes a comment without replacing the PR description" {
	local skill_file="$REPO_ROOT/skills/visual-pr/SKILL.md"
	local publish_script="$REPO_ROOT/skills/visual-pr/scripts/publish-comment.sh"

	run grep -F 'scripts/publish-comment.sh' "$skill_file"
	[ "$status" -eq 0 ]

	run grep -F 'gh pr comment "$pr_number" --body-file "$marked_comment"' "$publish_script"
	[ "$status" -eq 0 ]

	run grep -E 'gh pr edit .*--body-file' "$skill_file" "$publish_script"
	[ "$status" -ne 0 ]
}

@test "visual-pr updates the current user's existing marked comment" {
	setup_visual_pr_fixture
	run_visual_pr_publish \
		'[{"id":7,"body":"<!-- visual-pr --> old","user":{"login":"other"}},{"id":9,"body":"<!-- visual-pr --> old","user":{"login":"jellydn"}}]'

	[ "$status" -eq 0 ]
	[ "$output" = "https://github.com/jellydn/my-ai-tools/pull/42#issuecomment-9" ]
	run grep -F 'api --method PATCH repos/jellydn/my-ai-tools/issues/comments/9' "$BATS_TEST_TMPDIR/calls"
	[ "$status" -eq 0 ]
	run jq -e '.body | startswith("<!-- visual-pr -->\n\nvisual outline")' "$BATS_TEST_TMPDIR/payload"
	[ "$status" -eq 0 ]
}

@test "visual-pr posts a new marked comment when none exists" {
	setup_visual_pr_fixture
	run_visual_pr_publish '[]'

	[ "$status" -eq 0 ]
	[ "$output" = "https://github.com/jellydn/my-ai-tools/pull/42#issuecomment-10" ]
	run grep -F 'pr comment 42 --body-file' "$BATS_TEST_TMPDIR/calls"
	[ "$status" -eq 0 ]
	run grep -F '<!-- visual-pr -->' "$BATS_TEST_TMPDIR/payload"
	[ "$status" -eq 0 ]
}

@test "visual-pr stops without publishing when comment lookup fails" {
	setup_visual_pr_fixture
	run_visual_pr_publish '[]' 1

	[ "$status" -ne 0 ]
	run grep -E 'pr comment|api --method PATCH' "$BATS_TEST_TMPDIR/calls"
	[ "$status" -ne 0 ]
}

@test "Claude marketplace exposes the first-party visual-pr skill" {
	local marketplace="$REPO_ROOT/.claude-plugin/marketplace.json"
	local recommendations="$REPO_ROOT/configs/recommend-skills.json"

	run jq -e '[.plugins[] | select(.name == "visual-pr" and .source == "./skills/visual-pr")] | length == 1' "$marketplace"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]

	run jq -e '[.recommended_skills[] | select(.repo == "humanlayer/skills" and .skill == "visual-pr")] | length == 0' \
		"$recommendations"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "Claude marketplace exposes the first-party babysit-pr skill" {
	local marketplace="$REPO_ROOT/.claude-plugin/marketplace.json"

	run jq -e '[.plugins[] | select(.name == "babysit-pr" and .source == "./skills/babysit-pr")] | length == 1' \
		"$marketplace"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}

@test "Plannotator bundles parseable interview and fact-review examples" {
	run python3 - "$REPO_ROOT/skills/plannotator-setup-goal/SKILL.md" <<'PY'
import json
import pathlib
import re
import sys

skill = pathlib.Path(sys.argv[1]).read_text()
examples = [json.loads(block) for block in re.findall(r"```json\n(.*?)\n```", skill, re.S)]
assert len(examples) == 2
interview, facts = examples
assert interview["stage"] == "interview"
question = interview["questions"][0]
assert question["answerMode"] == "multi-custom"
assert set(question["recommendedOptionIds"]) <= {option["id"] for option in question["options"]}
assert facts["stage"] == "facts"
fact = facts["facts"][0]
assert fact["accepted"] is False and fact["removed"] is False
assert fact["recommendedAutomatedVerification"] is True and fact["automatedVerification"] is True
assert "interview-result.json" in skill and "facts-result.json" in skill and "facts.meta.json" in skill
assert "plannotator annotate goals/<slug>/facts.md --gate" not in skill
PY
	[ "$status" -eq 0 ]
}

@test "Portless guidance gates system changes and retains current runtime defaults" {
	local skill_file="$REPO_ROOT/skills/portless-local/SKILL.md"
	run grep -F 'Ask for explicit approval before' "$skill_file"
	[ "$status" -eq 0 ]
	[[ "$output" == *"CA trust-store"* && "$output" == *"LAN exposure"* && "$output" == *"public Funnel/ngrok"* ]]
	run grep -F 'PORTLESS_SYNC_HOSTS=0' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F 'Requires Node.js 24+' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F 'invoking user' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F '/tmp/portless' "$skill_file"
	[ "$status" -ne 0 ]
}

@test "Codemap rejects scope expansion and scans filenames without exposing secrets" {
	local skill_file="$REPO_ROOT/skills/codemap/SKILL.md"
	run grep -F 'do not silently expand to the whole repository' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F 'perform the four focus passes sequentially' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F 'rg -l ' "$skill_file"
	[ "$status" -eq 0 ]
	run grep -F 'more than 20 lines' "$skill_file"
	[ "$status" -eq 0 ]
}
