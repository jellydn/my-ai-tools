#!/usr/bin/env bash
# Keep the "## Token Efficiency" section identical across every managed global
# instruction profile (configs/**/AGENTS.md, configs/**/GEMINI.md).
#
# These profiles are deliberately standalone — eager `@file.md` imports cost
# tokens in every session — so the section is duplicated on purpose and
# generated from configs/token-efficiency.md instead of hand-edited.
#
# Usage:
#   scripts/sync-token-efficiency.sh           # rewrite profiles in place
#   scripts/sync-token-efficiency.sh --check   # exit 1 if any profile is stale

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$REPO_ROOT/configs/token-efficiency.md"
HEADING="## Token Efficiency"

CHECK_ONLY=false
[ "${1:-}" = "--check" ] && CHECK_ONLY=true

if [ ! -f "$CANONICAL" ]; then
	echo "missing canonical section: $CANONICAL" >&2
	exit 1
fi

# Emit the profile with its Token Efficiency section replaced by the canonical
# one, appending the section when the profile does not have it yet.
render_profile() {
	awk -v canonical="$CANONICAL" -v heading="$HEADING" '
		BEGIN {
			while ((getline line < canonical) > 0) section = section line "\n"
			sub(/\n+$/, "\n", section)
		}
		!in_section && $0 == heading { printf "%s", section; in_section = 1; found = 1; next }
		in_section {
			if (/^## /) { in_section = 0; print ""; print; }
			next
		}
		{ print }
		END { if (!found) { print ""; printf "%s", section } }
	' "$1"
}

managed_profiles() {
	find "$REPO_ROOT/configs" -type f \( -name AGENTS.md -o -name GEMINI.md \) | sort
}

stale=()
while IFS= read -r profile; do
	if ! render_profile "$profile" | diff -q - "$profile" >/dev/null 2>&1; then
		stale+=("${profile#"$REPO_ROOT"/}")
		[ "$CHECK_ONLY" = true ] && continue
		render_profile "$profile" >"$profile.tmp" && mv "$profile.tmp" "$profile"
	fi
done < <(managed_profiles)

if [ ${#stale[@]} -eq 0 ]; then
	echo "Token Efficiency section is in sync across managed profiles"
	exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
	printf 'out of sync with configs/token-efficiency.md:\n' >&2
	printf '  %s\n' "${stale[@]}" >&2
	printf 'run scripts/sync-token-efficiency.sh to fix\n' >&2
	exit 1
fi

printf 'synced:\n'
printf '  %s\n' "${stale[@]}"
