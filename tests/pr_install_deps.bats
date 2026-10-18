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

@test "Bun and Rust installers do not require simulated binaries during dry-run" {
	run bash -c '
		export HOME="$(mktemp -d)" DRY_RUN=true BUN_INSTALL=""
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		resolve_installer_checksum() { printf "\n"; }
		execute_installer() { return 0; }
		PATH=/nonexistent
		install_bun_now
		install_rust_if_needed
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "Bun and Rust installers still require installed binaries in real mode" {
	run bash -c '
		export HOME="$(mktemp -d)" DRY_RUN=false BUN_INSTALL="" CARGO_HOME=""
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		resolve_installer_checksum() { printf "\n"; }
		execute_installer() { return 0; }
		PATH=/nonexistent
		(install_bun_now) || bun_failed=true
		install_rust_if_needed || rust_failed=true
		[ "$bun_failed" = true ] && [ "$rust_failed" = true ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "curl one-line installer completes a dry-run" {
	run bash -c '
		test_home=$(mktemp -d)
		git config --file "$test_home/.gitconfig" \
			url."file://$1".insteadOf https://github.com/jellydn/my-ai-tools.git
		HOME="$test_home" CI=true curl -fsSL "file://$1/install.sh" | \
			HOME="$test_home" CI=true bash -s -- --dry-run
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Installation complete!"* ]]
}

@test "local binary links create their directory, refresh symlinks, and preserve regular files" {
	run bash -c '
		export HOME="$(mktemp -d)" DRY_RUN=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		mkdir -p "$HOME/sources"
		touch "$HOME/sources/first" "$HOME/sources/second"

		_link_binary_on_local_bin "$HOME/sources/first" "tool"
		[ "$(readlink "$HOME/.local/bin/tool")" = "$HOME/sources/first" ] || exit 1
		_link_binary_on_local_bin "$HOME/sources/second" "tool"
		[ "$(readlink "$HOME/.local/bin/tool")" = "$HOME/sources/second" ] || exit 1

		rm "$HOME/.local/bin/tool"
		printf "keep" >"$HOME/.local/bin/tool"
		_link_binary_on_local_bin "$HOME/sources/first" "tool"
		[ "$(cat "$HOME/.local/bin/tool")" = "keep" ]
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
}

@test "check_gofmt installs Go via mise when gofmt is missing" {
	run bash -c '
		export DRY_RUN=false IS_WINDOWS=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		mise() { echo "MISE $*"; gofmt_ready=true; }
		command() {
			if [ "$1" = "-v" ] && [ "$2" = "gofmt" ]; then
				[ "$gofmt_ready" = true ]
				return
			fi
			builtin command "$@"
		}
		check_gofmt
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"MISE use -g go@latest"* ]]
	[[ "$output" == *"Go installed"* ]]
}

@test "check_gofmt falls back to manual guidance when mise fails" {
	run bash -c '
		export DRY_RUN=false IS_WINDOWS=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		mise() { return 1; }
		command() {
			if [ "$1" = "-v" ] && [[ "$2" = gofmt || "$2" = brew || "$2" = apt-get ]]; then
				return 1
			fi
			builtin command "$@"
		}
		check_gofmt
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"golang.org/dl"* ]]
}

@test "check_gofmt gives manual guidance when mise succeeds but gofmt stays unavailable" {
	run bash -c '
		export DRY_RUN=false IS_WINDOWS=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		mise() { return 0; }
		command() {
			if [ "$1" = "-v" ] && [[ "$2" = gofmt || "$2" = brew || "$2" = apt-get ]]; then
				return 1
			fi
			builtin command "$@"
		}
		check_gofmt
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"golang.org/dl"* ]]
	[[ "$output" != *"Go installed"* ]]
}

@test "check_gofmt dry-run does not install Go or claim success" {
	run bash -c '
		export DRY_RUN=true IS_WINDOWS=false
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		mise() { echo "UNEXPECTED INSTALL"; }
		command() {
			if [ "$1" = "-v" ] && [ "$2" = "gofmt" ]; then
				return 1
			fi
			builtin command "$@"
		}
		check_gofmt
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"[DRY RUN]"*"mise use -g go@latest"* ]]
	[[ "$output" != *"UNEXPECTED INSTALL"* ]]
	[[ "$output" != *"Go installed"* ]]
}

@test "qmd and OpenCode use npm on native Windows and keep Bun on Unix" {
	for platform in true false; do
		run env PATH="/usr/bin:/bin" bash -c '
			source "$1/lib/common.sh"
			source "$1/lib/install.sh"
			IS_WINDOWS="$2" DRY_RUN=true YES_TO_ALL=true
			bun() { return 0; }
			node() { return 0; }
			npm() { printf "/tmp/npm-prefix\n"; }
			npx() { return 0; }
			bunx() { return 0; }
			cygpath() { printf "%s\n" "$2"; }
			install_qmd_now
			install_opencode2
			printf "runner=%s\n" "$(_detect_script_runner)"
		' _ "$REPO_ROOT" "$platform"
		[ "$status" -eq 0 ]
		if [ "$platform" = true ]; then
			[[ "$output" == *"npm install -g @tobilu/qmd"* ]]
			[[ "$output" == *"npm install -g @opencode/cli"* ]]
			[[ "$output" == *"runner=npx"* ]]
			[[ "$output" != *"bun install"* ]]
		else
			[[ "$output" == *"bun install -g @tobilu/qmd"* ]]
			[[ "$output" == *"bun install -g --trust @opencode/cli"* ]]
			[[ "$output" == *"runner=bunx"* ]]
		fi
	done
}

@test "native Windows rejects Bun-only setup before installing packages" {
	run env PATH="/usr/bin:/bin" bash -c '
		source "$1/cli.sh"
		IS_WINDOWS=true DRY_RUN=false YES_TO_ALL=true
		bun() { return 0; }
		git() { return 0; }
		command() {
			if [ "$1" = -v ] && { [ "$2" = node ] || [ "$2" = npm ]; }; then return 1; fi
			builtin command "$@"
		}
		check_prerequisites
	' _ "$REPO_ROOT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"requires Node.js LTS with npm"* ]]
	[[ "$output" != *"Installing qmd"* ]]
}

@test "native Windows keeps relative npm shims in their global prefix" {
	run env PATH="/usr/bin:/bin" bash -c '
		export HOME="$(mktemp -d)" DRY_RUN=false YES_TO_ALL=true
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		IS_WINDOWS=true
		bun() { return 17; }
		cygpath() { printf "%s\n" "$2"; }
		mkdir -p "$HOME/.local/bin" "$HOME/Node Runtime" "$HOME/global"
		printf "%s\n" "#!/bin/sh" "exit 17" >"$HOME/.local/bin/qmd"
		printf "%s\n" "#!/bin/sh" "exit 18" >"$HOME/.local/bin/node"
		printf "%s\n" "#!/bin/sh" "exit 0" >"$HOME/Node Runtime/node.exe"
		printf "%s\n" "#!/bin/sh" "echo native-node" >"$HOME/Node Runtime/node"
		chmod +x "$HOME/.local/bin/"* "$HOME/Node Runtime/"*
		PATH="$HOME/.local/bin:$PATH:$HOME/global:$HOME/Node Runtime"
		npm() {
			if [ "$1" = prefix ]; then printf "%s\n" "$HOME/global"; return; fi
			mkdir -p "$HOME/global"
			printf "%s\n" "#!/bin/sh" "cat \"\$0.version\"" >"$HOME/global/qmd"
			printf "qmd-test-version\n" >"$HOME/global/qmd.version"
			chmod +x "$HOME/global/qmd"
		}
		install_qmd_now || exit 1
		qmd --version || exit 1
		[ "$(node --version)" = native-node ] || exit 1
		[ "${PATH%%:*}" = "$HOME/global" ] || exit 1
		[ -e "$HOME/.local/bin/qmd" ] || exit 1 # do not delete user files
		npm() { [ "$1" = prefix ] && printf "%s\n" "$HOME/global"; }
		install_qmd_now || exit 1 # no reinstall; npm install would fail
		qmd --version
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"qmd-test-version"* ]]
}
