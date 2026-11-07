#!/usr/bin/env bash
# Amp self-hosted orb provider for this Mac. One smolvm machine per orb.
# ~/src/tries is mounted at /home/user/tries.
# Start with: amp orb provider "$HOME/.config/amp/orb-dispatch.sh"
# smolvm's own example is examples/amp-orbs/dispatch-smolvm.sh.
set -euo pipefail

SMOLVM="${SMOLVM:-smolvm}"
TRIES="${AMP_ORB_WORKDIR:-$HOME/src/tries}"
GUEST_WORKDIR=/home/user/tries
SNAP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/amp-orbs/snapshots"
CPUS="${ORB_CPUS:-4}"
MEMORY_MIB="${ORB_MEMORY_MIB:-8192}"
STORAGE_GIB="${ORB_STORAGE_GIB:-40}"

X64_IMAGE=us-central1-docker.pkg.dev/amp-prod-0/amp-orb/amp-orb:latest
ARM64_IMAGE=us-central1-docker.pkg.dev/amp-prod-0/amp-orb/amp-orb-arm64:latest

# Amp's default ORB_IMAGE is the x64 orb. This Mac needs the arm64 image.
case "$(uname -m)" in
arm64 | aarch64)
	case "${ORB_IMAGE:-}" in
	"" | "$X64_IMAGE") IMAGE=$ARM64_IMAGE ;;
	*) IMAGE=$ORB_IMAGE ;;
	esac
	;;
*)
	IMAGE="${ORB_IMAGE:-$X64_IMAGE}"
	;;
esac

# smolvm names: letters, digits, "-" and "_". No doubled or trailing hyphen.
sanitize() {
	local raw=$1
	raw=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9_-' '-')
	raw=$(printf '%s' "$raw" | sed -e 's/-\{2,\}/-/g' -e 's/^-//' -e 's/-$//')
	printf '%s' "$raw"
}

state_of() {
	local out
	if out=$("$SMOLVM" machine status --name "$1" --json 2>/dev/null); then
		printf '%s' "$out" | python3 -c '
import json, sys
raw = sys.stdin.read().strip()
if not raw:
    raise SystemExit
data = json.loads(raw)
if isinstance(data, list):
    data = data[0] if data else {}
print((data.get("state") or "").lower())
'
		return 0
	fi
	# `machine status` failed: the machine is absent, or smolvm is wedged
	# (e.g. another controller's operation is in flight). Confirm against
	# the machine index so a machine that exists is not re-created. When
	# even the index is unreachable, assume absence; creating a machine
	# that actually exists fails loudly and is recovered by the caller.
	if out=$("$SMOLVM" machine list --json 2>/dev/null); then
		printf '%s' "$out" | python3 -c '
import json, sys
try:
    machines = json.load(sys.stdin)
except Exception:
    raise SystemExit
for machine in machines:
    if machine.get("name") == sys.argv[1]:
        print((machine.get("state") or "").lower())
        raise SystemExit
' "$1"
	fi
	return 0
}

bring_up() {
	local name=$1
	case "$(state_of "$name")" in
	running) ;;
	paused) "$SMOLVM" machine resume --name "$name" ;;
	stopped | created) "$SMOLVM" machine start --name "$name" ;;
	*) return 1 ;;
	esac
}

snap_path() {
	printf '%s/%s.checkpoint' "$SNAP_ROOT" "$(sanitize "$1")"
}

create_machine() {
	local name=$1
	local snap=${2:-}
	if [[ -n "$snap" && -f "$snap" ]]; then
		if ! "$SMOLVM" machine create --name "$name" --from "$snap"; then
			return 1
		fi
	elif [[ ! -d "$TRIES" ]]; then
		printf 'amp orb: working directory %s does not exist\n' "$TRIES" >&2
		return 1
	else
		# A second controller for the same token may have created the
		# machine between our check and this create. Guarded so the
		# "already exists" conflict returns to the caller for recovery
		# instead of aborting the dispatch under `set -e`.
		if ! "$SMOLVM" machine create \
			--name "$name" \
			--image "$IMAGE" \
			--net \
			--cpus "$CPUS" \
			--mem "$MEMORY_MIB" \
			--storage "$STORAGE_GIB" \
			--workdir "$GUEST_WORKDIR" \
			--user user \
			--volume "$TRIES:$GUEST_WORKDIR"; then
			return 1
		fi
	fi
	case "$(state_of "$name")" in
	running) ;;
	paused) "$SMOLVM" machine resume --name "$name" ;;
	*) "$SMOLVM" machine start --name "$name" ;;
	esac
}

# Discard a machine that is registered but cannot run, then recreate it.
# Applies when resume/start hit a missing checkpoint after an interrupted
# pause or a concurrent delete overlapped. The orb is disposable: its disk
# rebuilds from the image (or snapshot) and the host mount survives.
recover_machine() {
	local name=$1
	local snap=${2:-}
	local st
	st=$(state_of "$name")
	case "$st" in
	running) return 0 ;;
	"")
		printf 'amp orb: cannot create machine %s\n' "$name" >&2
		return 1
		;;
	paused | stopped | created)
		# The machine may be healthy — the earlier probes only failed
		# transiently. Retry resume/start before discarding it.
		if bring_up "$name"; then
			return 0
		fi
		;;
	esac
	# Recreating needs a usable snapshot or the host working directory.
	# Refuse to delete the existing disk when neither holds, so the
	# operator can fix the prerequisite without losing saved state.
	if [[ -z "$snap" || ! -f "$snap" ]] && [[ ! -d "$TRIES" ]]; then
		printf 'amp orb: working directory %s does not exist\n' "$TRIES" >&2
		return 1
	fi
	printf 'amp orb: machine %s is wedged (state %s); discarding and recreating\n' "$name" "$st" >&2
	"$SMOLVM" machine delete --name "$name" -f || return 1
	create_machine "$name" "$snap"
}

# --secret-env reads ORB_TOKEN in this process. The value stays off the command line.
bootstrap() {
	local name=$1
	local -a env_args=(--secret-env "ORB_TOKEN=ORB_TOKEN")
	if [[ -n "${AMP_URL:-}" ]]; then
		env_args+=(-e "AMP_URL=${AMP_URL}")
	fi
	"$SMOLVM" machine exec \
		--name "$name" \
		-u user \
		-w "$GUEST_WORKDIR" \
		-d \
		"${env_args[@]}" \
		-- amp orb bootstrap
}

name="orb-$(sanitize "${ORB_ID:-}")"
if [[ "$name" == "orb-" || ${#name} -gt 128 ]]; then
	printf 'amp orb: ORB_ID %q is not a smolvm machine name\n' "${ORB_ID:-}" >&2
	exit 1
fi

case "${ORB_OPERATION:?ORB_OPERATION is required}" in
spawn)
	: "${ORB_TOKEN:?ORB_TOKEN is required}"
	if ! bring_up "$name"; then
		snap=
		if [[ -n "${ORB_SNAPSHOT_ID:-}" ]]; then
			snap=$(snap_path "$ORB_SNAPSHOT_ID")
		fi
		if ! create_machine "$name" "$snap"; then
			recover_machine "$name" "$snap" || exit 1
		fi
	fi
	bootstrap "$name"
	;;
pause)
	st=$(state_of "$name")
	if [[ -z "$st" ]]; then
		exit 0
	fi
	if [[ "$st" == paused && -n "${ORB_SNAPSHOT_ID:-}" ]]; then
		"$SMOLVM" machine resume --name "$name"
		st=running
	fi
	if [[ "$st" != running ]]; then
		exit 0
	fi
	# A host mount is refused unless the checkpoint keeps it.
	if [[ -n "${ORB_SNAPSHOT_ID:-}" ]]; then
		mkdir -p "$SNAP_ROOT"
		"$SMOLVM" machine checkpoint \
			--name "$name" \
			--host-mounts \
			-o "$(snap_path "$ORB_SNAPSHOT_ID")"
	fi
	"$SMOLVM" machine pause --name "$name"
	;;
delete)
	if [[ -n "$(state_of "$name")" ]]; then
		"$SMOLVM" machine delete --name "$name" -f
	fi
	;;
*)
	printf 'amp orb: unknown ORB_OPERATION %q\n' "${ORB_OPERATION:-}" >&2
	exit 1
	;;
esac
