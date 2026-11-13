#!/usr/bin/env bash
# Keep the shared sections identical across every managed instruction profile:
#   - "## Token Efficiency" from configs/token-efficiency.md in
#     configs/**/AGENTS.md and configs/**/GEMINI.md
#   - "## Experiment Workspaces" from configs/experiment-workspaces.md in those
#     profiles, configs/claude/CLAUDE.md, and the repository AGENTS.md/GEMINI.md
#
# These profiles are deliberately standalone — eager `@file.md` imports cost
# tokens in every session — so the sections are duplicated on purpose and
# generated from their canonical files instead of hand-edited.
#
# Usage:
#   scripts/sync-token-efficiency.sh           # rewrite profiles in place
#   scripts/sync-token-efficiency.sh --check   # exit 1 if any profile is stale

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CHECK_ONLY=false
[ "${1:-}" = "--check" ] && CHECK_ONLY=true

# Emit the profile ($3) with the heading ($2) replaced by the canonical file
# ($1), appending the section when the profile does not have it yet.
render_profile() {
	awk -v canonical="$1" -v heading="$2" '
		BEGIN {
			while ((getline line < canonical) > 0) {
				section = section line "\n"
			}
			sub(/\n+$/, "\n", section)
		}
		!in_section && $0 == heading { printf "%s", section; in_section = 1; found = 1; next }
		in_section {
			if (/^## /) { in_section = 0; print ""; print; }
			next
		}
		{ print }
		END { if (!found) { print ""; printf "%s", section } }
	' "$3"
}

managed_profiles() {
	find "$REPO_ROOT/configs" -type f \( -name AGENTS.md -o -name GEMINI.md \) | sort
}

stale=()

# sync_section <canonical> <heading> <profile>...
sync_section() {
	local canonical="$REPO_ROOT/$1" heading="$2" profile first_line
	shift 2
	if [ ! -f "$canonical" ]; then
		echo "missing canonical section: $canonical" >&2
		exit 1
	fi
	IFS= read -r first_line <"$canonical"
	if [ "$first_line" != "$heading" ]; then
		echo "canonical section must start with $heading: $canonical" >&2
		exit 1
	fi
	for profile in "$@"; do
		if ! render_profile "$canonical" "$heading" "$profile" | diff -q - "$profile" >/dev/null 2>&1; then
			stale+=("${profile#"$REPO_ROOT"/} (${canonical#"$REPO_ROOT"/})")
			[ "$CHECK_ONLY" = true ] && continue
			render_profile "$canonical" "$heading" "$profile" >"$profile.tmp" && mv "$profile.tmp" "$profile"
		fi
	done
}

profiles=()
while IFS= read -r profile; do profiles+=("$profile"); done < <(managed_profiles)
sync_section configs/token-efficiency.md "## Token Efficiency" "${profiles[@]}"
sync_section configs/experiment-workspaces.md "## Experiment Workspaces" "${profiles[@]}" \
	"$REPO_ROOT/configs/claude/CLAUDE.md" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/GEMINI.md"

if [ ${#stale[@]} -eq 0 ]; then
	echo "Shared sections are in sync across managed profiles"
	exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
	printf 'out of sync with their canonical sections:\n' >&2
	printf '  %s\n' "${stale[@]}" >&2
	printf 'run scripts/sync-token-efficiency.sh to fix\n' >&2
	exit 1
fi

printf 'synced:\n'
printf '  %s\n' "${stale[@]}"
