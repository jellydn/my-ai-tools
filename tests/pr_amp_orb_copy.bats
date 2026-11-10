#!/usr/bin/env bats
# copy_amp_configs must install a real executable orb-dispatch.sh.
# install.sh deletes its temporary checkout after install, so a symlink to
# the repo file would leave a dangling dispatcher.

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export HOME="$BATS_TEST_TMPDIR/home"
	export DRY_RUN=false
	source "$REPO_ROOT/lib/common.sh"
	source "$REPO_ROOT/lib/install.sh"
	source "$REPO_ROOT/cli.sh"
	# A throwaway checkout so the test can delete the source without
	# touching the real repository.
	FAKE_CHECKOUT="$BATS_TEST_TMPDIR/checkout"
	mkdir -p "$FAKE_CHECKOUT/configs"
	cp -R "$REPO_ROOT/configs/amp" "$FAKE_CHECKOUT/configs/amp"
	# detect_tool reports "directory" once ~/.config/amp exists, so no
	# amp binary is needed to reach copy_amp_configs.
	mkdir -p "$HOME/.config/amp"
	export SCRIPT_DIR="$FAKE_CHECKOUT"
}

@test "copy_amp_configs installs a real dispatcher file that survives checkout removal" {
	run copy_amp_configs
	[ "$status" -eq 0 ]

	local dest="$HOME/.config/amp/orb-dispatch.sh"
	[ -f "$dest" ]
	[ ! -L "$dest" ]
	[ -x "$dest" ]
	cmp -s "$dest" "$FAKE_CHECKOUT/configs/amp/orb-dispatch.sh"

	# The dispatcher must keep working after the source checkout is gone,
	# as install.sh does when it removes its temporary clone.
	rm -rf "$FAKE_CHECKOUT"
	[ -f "$dest" ]
	[ -x "$dest" ]
}

@test "copy_amp_configs replaces a dangling symlink with a real file" {
	ln -s "$BATS_TEST_TMPDIR/gone/orb-dispatch.sh" "$HOME/.config/amp/orb-dispatch.sh"
	run copy_amp_configs
	[ "$status" -eq 0 ]

	local dest="$HOME/.config/amp/orb-dispatch.sh"
	[ -f "$dest" ]
	[ ! -L "$dest" ]
	[ -x "$dest" ]
}

@test "copy_amp_configs does not write through a destination symlink" {
	local canary="$FAKE_CHECKOUT/canary.sh"
	printf '#!/bin/sh\necho canary\n' > "$canary"
	chmod +x "$canary"
	ln -s "$canary" "$HOME/.config/amp/orb-dispatch.sh"

	run copy_amp_configs
	[ "$status" -eq 0 ]

	local dest="$HOME/.config/amp/orb-dispatch.sh"
	[ -f "$dest" ]
	[ ! -L "$dest" ]
	[ -x "$dest" ]
	# The canary must be untouched: the copy must not follow the link.
	printf '#!/bin/sh\necho canary\n' > "$BATS_TEST_TMPDIR/expected-canary"
	cmp -s "$canary" "$BATS_TEST_TMPDIR/expected-canary"
}
