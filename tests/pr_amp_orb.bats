#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export HOME="$BATS_TEST_TMPDIR/home"
	export AMP_ORB_WORKDIR="$HOME/missing-workspace"
	export XDG_STATE_HOME="$HOME/state"
	export ORB_ID=test-orb ORB_TOKEN=test-token
	export SMOLVM="$BATS_TEST_TMPDIR/smolvm"
	export MOCK_STATE=running MOCK_STATE_FILE="$BATS_TEST_TMPDIR/state"
	cat > "$SMOLVM" <<'MOCK'
#!/usr/bin/env bash
state=${MOCK_STATE}
[[ ! -f "$MOCK_STATE_FILE" ]] || state=$(cat "$MOCK_STATE_FILE")
case "$2" in
status)
	[[ "$MOCK_STATUS_FAIL" != 1 ]] || exit 1
	[[ "$state" != missing ]] || { printf "machine '%s' not found\n" "${3:-}" >&2; exit 1; }
	printf '{"state":"%s"}\n' "$state"
	;;
list)
	if [[ -n "$MOCK_REGISTERED" ]]; then
		printf '[{"name":"%s","state":"%s"}]\n' "$MOCK_REGISTERED" "$state"
	else
		printf '[]\n'
	fi
	;;
create)
	if [[ -f "$MOCK_STATE_FILE" && "$(cat "$MOCK_STATE_FILE")" != missing ]]; then
		printf "create machine: machine '%s' already exists or is being created\n" "${3:-}" >&2
		exit 1
	fi
	printf 'created\n' > "$MOCK_STATE_FILE"
	;;
start) printf 'running\n' > "$MOCK_STATE_FILE" ;;
resume)
	if [[ "$MOCK_FAIL_RESUME" == 1 ]]; then
		# The machine stays registered (as paused) even though resuming
		# fails, like a paused machine whose checkpoint file is missing.
		printf 'paused\n' > "$MOCK_STATE_FILE"
		printf 'read checkpoint footer: I/O error: No such file or directory\n' >&2
		exit 1
	fi
	printf 'running\n' > "$MOCK_STATE_FILE"
	;;
pause) printf 'paused\n' > "$MOCK_STATE_FILE" ;;
delete) printf 'missing\n' > "$MOCK_STATE_FILE" ;;
exec) [[ "$state" == running ]] && printf 'bootstrap started\n' ;;
*) exit 1 ;;
esac
MOCK
	chmod +x "$SMOLVM"
}

@test "orb cleanup works repeatedly without the host workspace" {
	export ORB_OPERATION=pause
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = paused ]
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = paused ]

	export ORB_OPERATION=delete
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = missing ]
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
}

@test "orb spawn resumes an existing machine without the host workspace" {
	export ORB_OPERATION=spawn MOCK_STATE=paused
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = running ]
	[ "$output" = "bootstrap started" ]
}

@test "fresh orb spawn requires the host workspace" {
	export ORB_OPERATION=spawn MOCK_STATE=missing
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -ne 0 ]
	[[ "$output" == *"working directory $AMP_ORB_WORKDIR does not exist"* ]]
	[ ! -e "$MOCK_STATE_FILE" ]
}

@test "orb spawn falls back to the image when the project snapshot is missing" {
	export ORB_OPERATION=spawn MOCK_STATE=missing ORB_SNAPSHOT_ID=missing-snapshot
	mkdir -p "$AMP_ORB_WORKDIR"
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = running ]
	[ "$output" = "bootstrap started" ]
}

@test "orb spawn finds a registered machine when status fails" {
	export ORB_OPERATION=spawn MOCK_STATE=paused MOCK_STATUS_FAIL=1 MOCK_REGISTERED=orb-test-orb
	mkdir -p "$AMP_ORB_WORKDIR"
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = running ]
	[ "$output" = "bootstrap started" ]
}

@test "orb spawn rebuilds a wedged machine" {
	export ORB_OPERATION=spawn MOCK_STATE=paused MOCK_FAIL_RESUME=1
	mkdir -p "$AMP_ORB_WORKDIR"
	run "$REPO_ROOT/configs/amp/orb-dispatch.sh"
	[ "$status" -eq 0 ]
	[ "$(cat "$MOCK_STATE_FILE")" = running ]
	[[ "$output" == *"wedged"* ]]
	[[ "$output" == *"bootstrap started"* ]]
}
