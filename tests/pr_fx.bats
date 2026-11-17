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

@test "install_fx verifies a pinned archive and honors FX_INSTALL_DIR" {
	local archive_log="$BATS_TEST_TMPDIR/fx-archive-call"
	local path_log="$BATS_TEST_TMPDIR/fx-installer-path"
	local archive_root="$BATS_TEST_TMPDIR/fx-archive-root"
	local fake_archive="$BATS_TEST_TMPDIR/fx-test-archive.tar.gz"
	local arch checksum test_home install_dir
	mkdir -p "$archive_root"
	printf '#!/bin/sh\nprintf "fx test binary\\n"\n' >"$archive_root/fx"

	for arch in x86_64 aarch64; do
		test_home="$BATS_TEST_TMPDIR/fx-home-$arch"
		install_dir="$BATS_TEST_TMPDIR/fx-bin-$arch"
		mkdir -p "$test_home"
		tar -czf "$fake_archive" -C "$archive_root" fx
		case "$arch" in
		x86_64) checksum=be9428636afb1196cb662b48ed57bbed3b95e7c37f2bc7849e02c0960fae1f01 ;;
		aarch64) checksum=9905a51c213d1b7fe3b5079f00fd3e61f2dba5bde707397991e9535c4a700caf ;;
		esac

		run env HOME="$test_home" PATH="/usr/bin:/bin" FX_TEST_ARCH="$arch" FX_INSTALL_DIR="$install_dir" FAKE_ARCHIVE="$fake_archive" ARCHIVE_LOG="$archive_log" PATH_LOG="$path_log" REPO_ROOT="$REPO_ROOT" bash -c '
			uname() {
				case "$1" in
				-s) printf "Linux\n" ;;
				-m) printf "%s\n" "$FX_TEST_ARCH" ;;
				esac
			}
			export DRY_RUN=false YES_TO_ALL=true VERBOSE=false IS_WINDOWS=false
			source "$REPO_ROOT/cli.sh"
			download_and_verify_file() { printf "%s\n" "$@" >"$ARCHIVE_LOG"; printf "%s\n" "$FAKE_ARCHIVE"; }
			ensure_dir_on_path() { printf "%s\n" "$1" >"$PATH_LOG"; }
			install_fx
		'

		[ "$status" -eq 0 ]
		run cat "$archive_log"
		[ "$output" = "$(printf '%s\n' "https://releases.fx.sh/v0.0.4/fx-linux-$arch.tar.gz" "$checksum" "fx v0.0.4 (linux-$arch)")" ]
		run cat "$path_log"
		[ "$output" = "$install_dir" ]
		[ -x "$install_dir/fx" ]
		run "$install_dir/fx"
		[ "$output" = "fx test binary" ]
	done
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
