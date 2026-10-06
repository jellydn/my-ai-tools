#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	SCRIPT="$REPO_ROOT/skills/pr-review/scripts/extract-pr-comments.js"
	WORK="$BATS_TEST_TMPDIR/extract"
	mkdir -p "$WORK"
}

write_fixtures() {
	cat >"$WORK/review.json" <<'EOF'
[
  {
    "id": 10,
    "body": "Keep this unresolved thread",
    "path": "skills/example/SKILL.md",
    "user": { "login": "reviewer", "type": "User" },
    "html_url": "https://example.test/10"
  },
  {
    "id": 11,
    "in_reply_to_id": 10,
    "body": "A reply does not resolve the thread",
    "path": "skills/example/SKILL.md",
    "user": { "login": "author", "type": "User" }
  },
  {
    "id": 20,
    "body": "This thread is resolved",
    "path": "skills/example/SKILL.md",
    "user": { "login": "reviewer", "type": "User" }
  }
]
EOF
	printf '%s\n' '[]' >"$WORK/issues.json"
}

@test "extract-pr-comments keeps an unresolved thread that has a reply" {
	write_fixtures
	cat >"$WORK/threads.json" <<'EOF'
{
  "data": {
    "repository": {
      "pullRequest": {
        "reviewThreads": {
          "nodes": [
            {
              "isResolved": false,
              "comments": { "nodes": [{ "databaseId": 10 }, { "databaseId": "11" }] }
            },
            {
              "isResolved": true,
              "comments": { "nodes": [{ "databaseId": 20 }] }
            }
          ]
        }
      }
    }
  }
}
EOF

	run node "$SCRIPT" "$WORK/review.json" "$WORK/issues.json" "$WORK/threads.json" "$WORK/out.ndjson"

	[ "$status" -eq 0 ]
	[[ "$output" != *"likely resolved"* ]]
	[[ "$output" == *"Skipped 1 comments on resolved review threads"* ]]
	[[ "$output" == *"replies are not treated as resolution"* ]]
	run jq -sc '[.[].github_id] | sort' "$WORK/out.ndjson"
	[ "$status" -eq 0 ]
	[ "$output" = "[10]" ]
}

@test "extract-pr-comments refuses to infer resolution without thread state" {
	write_fixtures
	run node "$SCRIPT" "$WORK/review.json" "$WORK/issues.json" "$WORK/missing-threads.json" "$WORK/out.ndjson"

	[ "$status" -ne 0 ]
	[[ "$output" == *"Thread-resolution file not found"* ]]
	[ ! -f "$WORK/out.ndjson" ]
}
