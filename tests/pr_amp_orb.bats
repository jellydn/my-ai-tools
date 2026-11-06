#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	SKILL="$REPO_ROOT/skills/amp-orb/SKILL.md"
	MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
}

@test "amp-orb records this Mac's smolvm provider" {
	run grep -F 'name: amp-orb' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'itman-vm' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F '~/src/tries' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F '/home/user/tries' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'amp-orb' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'smol-machines/tap/smolvm' "$SKILL"
	[ "$status" -eq 0 ]
	run grep -F 'Leave the token unprinted.' "$SKILL"
	[ "$status" -eq 0 ]

	run jq -e '[.plugins[] | select(.name == "amp-orb" and .source == "./skills/amp-orb")] | length == 1' \
		"$MARKETPLACE"
	[ "$status" -eq 0 ]
	[ "$output" = "true" ]
}
