#!/usr/bin/env bats
# prompt_yn must consume the whole line so "y" + Enter does not skip the next prompt.

REPO_ROOT="$BATS_TEST_DIRNAME/.."
COMMON_SH="$REPO_ROOT/lib/common.sh"

@test "prompt_yn reads a full line instead of one byte" {
	if grep -F 'dd bs=1 count=1' "$COMMON_SH"; then
		echo "FAIL: prompt_yn still uses one-byte dd; leftover Enter skips the next prompt" >&2
		return 1
	fi
	if ! grep -qE 'IFS= read -r response' "$COMMON_SH"; then
		echo "FAIL: prompt_yn is missing a full-line read" >&2
		return 1
	fi
}

@test "prompt_yn y+enter does not skip the next prompt" {
	if ! command -v python3 &>/dev/null; then
		skip "python3 required for pty"
	fi

	run python3 - "$COMMON_SH" <<'PY'
import os
import pty
import select
import sys
import time

common_sh = sys.argv[1]
script = r"""
source "$1"
out=""
if prompt_yn first; then out="${out}1y"; else out="${out}1n"; fi
if prompt_yn second; then out="${out} 2y"; else out="${out} 2n"; fi
printf 'RESULTS:%s\n' "$out"
"""

pid, fd = pty.fork()
if pid == 0:
    os.execvp("bash", ["bash", "-c", script, "bash", common_sh])

os.write(fd, b"y\ny\n")
deadline = time.time() + 5
chunks = []
while time.time() < deadline:
    ready, _, _ = select.select([fd], [], [], 0.2)
    if not ready:
        try:
            waited = os.waitpid(pid, os.WNOHANG)
        except ChildProcessError:
            break
        if waited[0] == pid:
            break
        continue
    try:
        data = os.read(fd, 1024)
    except OSError:
        break
    if not data:
        break
    chunks.append(data)

try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
os.close(fd)

output = b"".join(chunks).decode("utf-8", "replace")
print(output)
if "RESULTS:1y 2y" not in output:
    sys.exit(1)
PY

	echo "$output"
	[ "$status" -eq 0 ]
	[[ "$output" == *"RESULTS:1y 2y"* ]]
}
