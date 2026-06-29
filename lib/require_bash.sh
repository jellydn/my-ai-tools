#!/bin/bash
# Shared re-exec guard for bash-only entry-point scripts.
#
# lib/common.sh uses bash-only syntax (process substitution, arrays,
# ${var//pat/repl}) that sh/dash cannot parse. This file is intentionally
# POSIX-compatible so sh can source it and trigger the re-exec BEFORE
# lib/common.sh is ever reached.
#
# Source this file FIRST, before any other lib/ sources, from any
# entry-point script that ultimately needs bash features:
#
#     #!/bin/bash
#     . "$(dirname "${BASH_SOURCE:-$0}")/lib/require_bash.sh"
#     source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Detection logic:
#   - [ -z "${BASH_VERSION:-}" ]  → true for non-bash shells (dash, ksh, etc.)
#   - shopt -oq posix             → true when bash is invoked as sh
#                                  (POSIX mode is auto-enabled in that case)
#
# The `2>/dev/null` on shopt suppresses "command not found" if sourced
# from a truly non-bash shell; in that case BASH_VERSION is empty, so
# the first clause already short-circuits the OR and the guard fires.

if [ -z "${BASH_VERSION:-}" ] || shopt -oq posix 2>/dev/null; then
	if command -v bash >/dev/null 2>&1; then
		exec bash "$0" "$@"
	else
		echo "Error: $0 requires bash, but bash was not found in PATH" >&2
		exit 1
	fi
fi
