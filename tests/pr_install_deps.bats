#!/usr/bin/env bats
# Structural guards for the shell libraries: syntax, module size, PATH handling.

load helpers

@test "all shell entry points and libraries pass bash -n" {
	run bash -c '
		cd "$1" || exit 1
		bash -n cli.sh generate.sh install.sh lib/*.sh scripts/*.sh
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "lib modules stay under 1000 lines" {
	# cli.sh and generate.sh are pre-existing oversized entry points; the rule is
	# enforced for lib/ so new installer work decomposes instead of piling up.
	run bash -c '
		oversized=0
		for file in "$1"/lib/*.sh; do
			lines=$(wc -l <"$file")
			if [ "$lines" -ge 1000 ]; then
				echo "$file: $lines lines"
				oversized=1
			fi
		done
		exit "$oversized"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "lib/install.sh sources the prerequisite module" {
	run grep -F 'source "$(dirname "${BASH_SOURCE[0]}")/install-deps.sh"' "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
}

@test "prerequisite installers are available after sourcing lib/install.sh" {
	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		for fn in install_rust_if_needed install_global_tools install_jq_if_needed \
			install_qmd_now install_fff_mcp_now install_logpilot_now install_sem_now \
			handle_bun_installation cargo_bin_dir; do
			declare -F "$fn" >/dev/null || {
				echo "missing: $fn"
				exit 1
			}
		done
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "PATH mutations go through ensure_dir_on_path" {
	# The helper itself is the only place allowed to touch PATH directly.
	run bash -c 'cat "$1"/lib/*.sh | grep -cF "export PATH="' _ "$REPO_ROOT"
	[ "$output" -eq 1 ]

	run bash -c 'cat "$1"/lib/*.sh | grep -cF "case \":\$PATH:\""' _ "$REPO_ROOT"
	[ "$output" -eq 1 ]

	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		declare -f ensure_dir_on_path
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"export PATH="* ]]
}

@test "ensure_dir_on_path is idempotent and ignores empty input" {
	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		PATH="/usr/bin:/bin"
		ensure_dir_on_path "/opt/demo/bin"
		ensure_dir_on_path "/opt/demo/bin"
		ensure_dir_on_path ""
		echo "$PATH"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = "/opt/demo/bin:/usr/bin:/bin" ]
}
