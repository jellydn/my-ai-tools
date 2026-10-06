#!/usr/bin/env bash

set -euo pipefail

readonly MARKER="<!-- visual-pr -->"

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <pr-number> <comment-file>" >&2
	exit 2
fi

readonly pr_number="$1"
readonly comment_file="$2"

if [ ! -f "$comment_file" ]; then
	echo "Comment file not found: $comment_file" >&2
	exit 2
fi

readonly repository="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
readonly viewer="$(gh api user --jq .login)"
readonly comment_id="$(
	gh api --paginate "repos/$repository/issues/$pr_number/comments" |
		jq -r --arg viewer "$viewer" --arg marker "$MARKER" \
			'.[] | select(.user.login == $viewer and (.body | startswith($marker))) | .id' |
		tail -n 1
)"

marked_comment="$(mktemp "${TMPDIR:-/tmp}/visual-pr-comment.XXXXXX")"
trap 'rm -f "$marked_comment"' EXIT
{
	printf '%s\n\n' "$MARKER"
	cat "$comment_file"
} >"$marked_comment"

if [ -n "$comment_id" ]; then
	jq -Rs '{body: .}' "$marked_comment" |
		gh api --method PATCH "repos/$repository/issues/comments/$comment_id" --input - --jq .html_url
else
	gh pr comment "$pr_number" --body-file "$marked_comment"
fi
