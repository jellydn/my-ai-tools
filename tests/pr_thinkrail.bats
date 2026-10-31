#!/usr/bin/env bats

load helpers

setup() {
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
}

@test "ThinkRail is opt-in and runs only when selected" {
	run bash "$REPO_ROOT/cli.sh" --yes --without-integrations --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"Skipping thinkrail installer (not in -y allowlist)"* ]]
	[[ "$output" != *"https://raw.githubusercontent.com/JetBrains/thinkrail/main/install.sh"* ]]

	run bash "$REPO_ROOT/cli.sh" --yes --without-integrations --with-tools=thinkrail --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"[DRY RUN] Would execute installer from: https://raw.githubusercontent.com/JetBrains/thinkrail/main/install.sh"* ]]
	[ ! -e "$HOME/.local/bin/thinkrail" ]
}

@test "ThinkRail dry run does not download or write configuration" {
	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		YES_TO_ALL=true DRY_RUN=true
		curl() { echo UNEXPECTED:network; return 99; }
		install_thinkrail
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"[DRY RUN] Would execute installer"* ]]
	[[ "$output" != *UNEXPECTED:* ]]
	[ ! -e "$HOME/.claude" ]
	[ ! -e "$HOME/.thinkrail" ]
	[ ! -e "$HOME/.bashrc" ]
}

@test "ThinkRail installs a runnable CLI without changing shell startup files" {
	cat > "$BATS_TEST_TMPDIR/installer" <<'SH'
#!/usr/bin/env bash
[ "$1" = --no-modify-path ] || exit 2
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\necho "ThinkRail fixture 0.2.0"\n' > "$HOME/.local/bin/thinkrail"
chmod +x "$HOME/.local/bin/thinkrail"
SH
	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		YES_TO_ALL=true DRY_RUN=false
		# Return a local installer fixture instead of downloading upstream code.
		download_and_verify_file() { echo "$fixture"; }
		fixture="$2"
		install_thinkrail && thinkrail --version
	' _ "$REPO_ROOT" "$BATS_TEST_TMPDIR/installer"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ThinkRail fixture 0.2.0"* ]]
	[ -x "$HOME/.local/bin/thinkrail" ]
	[ ! -e "$HOME/.bashrc" ]
	[ ! -e "$HOME/.thinkrail" ]
}

@test "ThinkRail installer errors are not reported as success" {
	run bash -c '
		source "$1/lib/common.sh"
		source "$1/lib/install.sh"
		YES_TO_ALL=true DRY_RUN=false
		download_and_verify_file() { return 1; }
		install_thinkrail
	' _ "$REPO_ROOT"
	[ "$status" -ne 0 ]
	[[ "$output" == *"ThinkRail installation failed"* ]]
	[[ "$output" != *"ThinkRail installed"* ]]
}
