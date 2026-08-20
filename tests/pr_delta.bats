#!/usr/bin/env bats
# Tests for Delta getting-started documentation

load helpers

REPO_ROOT="$BATS_TEST_DIRNAME/.."
README="$REPO_ROOT/README.md"
DOC="$REPO_ROOT/docs/delta-getting-started.md"
CHANGESET="$REPO_ROOT/.changeset/add-delta-getting-started.md"

@test "Delta getting-started doc exists" {
	[ -f "$DOC" ]
	run grep -F 'delta.dev/docs/getting-started' "$DOC"
	[ "$status" -eq 0 ]
	run grep -F 'zed.dev/blog/introducing-delta' "$DOC"
	[ "$status" -eq 0 ]
}

@test "Delta getting-started covers install, sign-in, and first thread" {
	run grep -F '## Install' "$DOC"
	[ "$status" -eq 0 ]
	run grep -F '## Sign in and connect a model' "$DOC"
	[ "$status" -eq 0 ]
	run grep -F '## Start your first thread' "$DOC"
	[ "$status" -eq 0 ]
	run grep -F 'xattr -dr com.apple.quarantine' "$DOC"
	[ "$status" -eq 0 ]
	run grep -F 'ANTHROPIC_API_KEY' "$DOC"
	[ "$status" -eq 0 ]
}

@test "README documents Delta in supported-tools list" {
	run grep -F 'Delta' "$README"
	[ "$status" -eq 0 ]
	run grep -F '## 🧵 Delta (Optional)' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'docs/delta-getting-started.md' "$README"
	[ "$status" -eq 0 ]
}

@test "README Resources links to Delta docs" {
	run grep -F 'https://delta.dev/docs/getting-started' "$README"
	[ "$status" -eq 0 ]
	run grep -F 'https://zed.dev/blog/introducing-delta' "$README"
	[ "$status" -eq 0 ]
}

@test "Delta getting-started has a changeset" {
	[ -f "$CHANGESET" ]
	run grep -F 'Delta' "$CHANGESET"
	[ "$status" -eq 0 ]
}
