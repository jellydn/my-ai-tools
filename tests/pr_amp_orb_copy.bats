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

@test "copy_amp_configs does not write through a stage-path symlink" {
	# The staged copy must land in an exclusive mktemp file, never through a
	# leftover link at a fixed stage name: a link there must not redirect the
	# copy or end up installed in place of the dispatcher.
	local stage_link="$HOME/.config/amp/.orb-dispatch.sh.tmp"
	local canary="$BATS_TEST_TMPDIR/canary.sh"
	printf '#!/bin/sh\necho canary\n' > "$canary"
	chmod +x "$canary"
	ln -s "$canary" "$stage_link"

	run copy_amp_configs
	[ "$status" -eq 0 ]

	local dest="$HOME/.config/amp/orb-dispatch.sh"
	[ -f "$dest" ]
	[ ! -L "$dest" ]
	[ -x "$dest" ]
	# The link target must be untouched: the copy must not follow the stage link.
	printf '#!/bin/sh\necho canary\n' > "$BATS_TEST_TMPDIR/expected-canary"
	cmp -s "$canary" "$BATS_TEST_TMPDIR/expected-canary"
}

@test "copy_amp_configs does not install the dispatcher into a destination directory" {
	# A real directory at the destination path cannot be replaced by the
	# rename: mv would move the staged file into it and leave the path a
	# directory, which Amp cannot execute.
	local dest="$HOME/.config/amp/orb-dispatch.sh"
	mkdir -p "$dest"

	run copy_amp_configs
	[ "$status" -eq 0 ]

	[ -d "$dest" ]
	# The staged file must not be left inside the directory.
	[ -z "$(ls -A "$dest")" ]
}

@test "copy_amp_configs keeps the installed dispatcher when the copy fails" {
	local dest="$HOME/.config/amp/orb-dispatch.sh"
	printf 'previous dispatcher\n' > "$dest"
	chmod +x "$dest"

	# Fail the staged copy by injecting a cp that refuses the stage path.
	# The injection keeps the case independent of the user permissions, so
	# it also runs as root.
	local fake_bin="$BATS_TEST_TMPDIR/fake-bin"
	mkdir -p "$fake_bin"
	cat >"$fake_bin/cp" <<'SHIM'
#!/usr/bin/env bash
for arg in "$@"; do
	case "$arg" in
	*/.orb-dispatch.sh.??????) exit 1 ;;
	esac
done
exec "$REAL_CP" "$@"
SHIM
	chmod +x "$fake_bin/cp"

	# The staged copy keeps the installed dispatcher, so a failed install
	# cannot leave the provider without a script.
	REAL_CP="$(command -v cp)" PATH="$fake_bin:$PATH" run copy_amp_configs

	[ "$status" -eq 0 ]
	[ -f "$dest" ]
	[ ! -L "$dest" ]
	[ -x "$dest" ]
	[ "$(cat "$dest")" = "previous dispatcher" ]
	# The other copies still go through, so the shim delegated correctly
	# and the failure came from the staged copy alone.
	[ -f "$HOME/.config/amp/settings.json" ]
}

@test "copy_amp_configs installs an executable dispatcher under a restrictive umask" {
	# mktemp creates the stage file with mode 0600 and the copy keeps that
	# mode, so the owner execute bit has to be set explicitly.
	local dest="$HOME/.config/amp/orb-dispatch.sh"
	local previous_umask
	previous_umask="$(umask)"
	umask 0177
	run copy_amp_configs
	umask "$previous_umask"

	[ "$status" -eq 0 ]
	[ -f "$dest" ]
	[ -x "$dest" ]
}

@test "copy_amp_configs dry-run plan shows the dispatcher paths" {
	export DRY_RUN=true
	run copy_amp_configs
	[ "$status" -eq 0 ]

	# The plan must name the source and the destination, not empty paths.
	[[ "$output" == *"$FAKE_CHECKOUT/configs/amp/orb-dispatch.sh"* ]]
	[[ "$output" == *"$HOME/.config/amp/orb-dispatch.sh"* ]]

	# A dry run must not install anything.
	[ ! -e "$HOME/.config/amp/orb-dispatch.sh" ]
}
