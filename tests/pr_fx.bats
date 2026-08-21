#!/usr/bin/env bats
# Tests for configs/fx/ and fx CLI integration

load helpers

FX_CONFIG_DIR="$REPO_ROOT/configs/fx"

@test "configs/fx/AGENTS.md exists" {
	[ -f "$FX_CONFIG_DIR/AGENTS.md" ]
}

@test "configs/fx/AGENTS.md references tmux" {
	run grep -F "tmux" "$FX_CONFIG_DIR/AGENTS.md"
	[ "$status" -eq 0 ]
}

@test "install_fx verifies a pinned release and honors FX_INSTALL_DIR" {
	local test_home="$BATS_TEST_TMPDIR/fx-install-home"
	local install_dir="$BATS_TEST_TMPDIR/fx-custom-bin"
	local call_log="$BATS_TEST_TMPDIR/fx-installer-call"
	local path_log="$BATS_TEST_TMPDIR/fx-installer-path"
	mkdir -p "$test_home"

	run env HOME="$test_home" PATH="/usr/bin:/bin" FX_INSTALL_DIR="$install_dir" CALL_LOG="$call_log" PATH_LOG="$path_log" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=true VERBOSE=false IS_WINDOWS=false
		source "$REPO_ROOT/cli.sh"
		execute_installer() { printf "%s\n" "$@" >"$CALL_LOG"; }
		ensure_dir_on_path() { printf "%s\n" "$1" >"$PATH_LOG"; }
		install_fx
	'

	[ "$status" -eq 0 ]
	run cat "$call_log"
	[ "$output" = $'https://fx.sh/setup.sh\n254c2d4410678aa28acb17941f5447b34b312f829893d4261bb4d713508f924f\nfx v0.0.4\nv0.0.4' ]
	run cat "$path_log"
	[ "$output" = "$install_dir" ]
}

@test "copy_fx_configs installs guidance without changing private MCP state" {
	local test_home="$BATS_TEST_TMPDIR/fx-copy-home"
	mkdir -p "$test_home/.fx"
	printf '{"private":true}\n' >"$test_home/.fx/mcp.json"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_fx_configs
	'

	[ "$status" -eq 0 ]
	cmp "$FX_CONFIG_DIR/AGENTS.md" "$test_home/.fx/AGENTS.md"
	run cat "$test_home/.fx/mcp.json"
	[ "$output" = '{"private":true}' ]
}

@test "copy_fx_configs fails instead of reporting success when guidance is missing" {
	local test_home="$BATS_TEST_TMPDIR/fx-copy-failure-home"
	local empty_repo="$BATS_TEST_TMPDIR/fx-empty-repo"
	mkdir -p "$test_home/.fx" "$empty_repo/configs/fx"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" EMPTY_REPO="$empty_repo" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		SCRIPT_DIR="$EMPTY_REPO"
		copy_fx_configs
	'

	[ "$status" -ne 0 ]
	[[ "$output" != *"fx configs copied"* ]]
}

@test "generate_fx_configs exports only guidance" {
	local test_home="$BATS_TEST_TMPDIR/fx-generate-home"
	local output_repo="$BATS_TEST_TMPDIR/fx-output-repo"
	mkdir -p "$test_home/.fx" "$output_repo"
	printf '# fx test guidance\n' >"$test_home/.fx/AGENTS.md"
	printf '{"private":true}\n' >"$test_home/.fx/mcp.json"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" OUTPUT_REPO="$output_repo" bash -c '
		export DRY_RUN=false VERBOSE=false
		source "$REPO_ROOT/generate.sh"
		SCRIPT_DIR="$OUTPUT_REPO"
		generate_fx_configs
	'

	[ "$status" -eq 0 ]
	[ -f "$output_repo/configs/fx/AGENTS.md" ]
	[ ! -e "$output_repo/configs/fx/mcp.json" ]
	run cat "$output_repo/configs/fx/AGENTS.md"
	[ "$output" = "# fx test guidance" ]
}

@test "generate_fx_configs does not report success when guidance is missing" {
	local test_home="$BATS_TEST_TMPDIR/fx-generate-missing-home"
	local output_repo="$BATS_TEST_TMPDIR/fx-missing-output-repo"
	mkdir -p "$test_home/.fx" "$output_repo"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" OUTPUT_REPO="$output_repo" bash -c '
		export DRY_RUN=false VERBOSE=false
		source "$REPO_ROOT/generate.sh"
		SCRIPT_DIR="$OUTPUT_REPO"
		generate_fx_configs
	'

	[ "$status" -eq 0 ]
	[[ "$output" == *"fx config not found"* ]]
	[[ "$output" != *"fx configs generated"* ]]
}
