#!/usr/bin/env bats
# Test suite for the sh/dash re-exec guard.
#
# lib/common.sh uses bash-only syntax (process substitution, arrays,
# ${var//pat/repl}) that sh/dash cannot parse. The entry-point scripts
# (generate.sh, cli.sh) source lib/require_bash.sh, which detects sh/dash
# invocation and re-execs under bash before lib/common.sh is ever reached.
#
# lib/require_bash.sh is intentionally POSIX-compatible so sh can source it
# in the first place. These tests lock in that property.

REPO_ROOT="$BATS_TEST_DIRNAME/.."
GUARD_FILE="$REPO_ROOT/lib/require_bash.sh"

# Helper: assert the guard line appears before the source line in a script.
# Uses cat + string-prefix length comparison to avoid fragile grep pipeline escaping.
# Args: $1 = script path, $2 = guard pattern, $3 = source pattern
assert_guard_before_source() {
    local script="$1" guard_pattern="$2" source_pattern="$3"
    local content
    content=$(cat "$script")
    local guard_prefix="${content%%$guard_pattern*}"
    local source_prefix="${content%%$source_pattern*}"
    [ "${#guard_prefix}" -lt "${#source_prefix}" ]
}

# ---------------------------------------------------------------------------
# Static checks: the canonical guard in lib/require_bash.sh
# ---------------------------------------------------------------------------

@test "lib/require_bash.sh contains the exec bash re-exec and macOS shopt posix check" {
    # Check each assertion independently so the failure message names the missing piece.
    if ! grep -qF 'exec bash "$0" "$@"' "$GUARD_FILE"; then
        echo "FAIL: lib/require_bash.sh missing the exec bash re-exec line" >&2
        return 1
    fi
    if ! grep -qF 'shopt -oq posix' "$GUARD_FILE"; then
        echo "FAIL: lib/require_bash.sh missing the macOS shopt posix check" >&2
        return 1
    fi
}

@test "lib/require_bash.sh falls back to a clear error if bash is missing" {
    grep -qF 'requires bash' "$GUARD_FILE"
}

@test "lib/require_bash.sh is POSIX-compatible (passes sh -n syntax check)" {
    skip_if_no_sh
    # sh must be able to parse this file before it can re-exec under bash.
    sh -n "$GUARD_FILE"
}

# ---------------------------------------------------------------------------
# Static checks: each entry-point script sources the guard before lib/common.sh
# ---------------------------------------------------------------------------

@test "generate.sh and cli.sh both source lib/require_bash.sh before lib/common.sh" {
    # Run each script check independently so the failure message names the offending script.
    if ! assert_guard_before_source "$REPO_ROOT/generate.sh" 'lib/require_bash.sh' 'lib/common.sh'; then
        echo "FAIL: generate.sh does not source lib/require_bash.sh before lib/common.sh" >&2
        return 1
    fi
    if ! assert_guard_before_source "$REPO_ROOT/cli.sh" 'lib/require_bash.sh' 'lib/common.sh'; then
        echo "FAIL: cli.sh does not source lib/require_bash.sh before lib/common.sh" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Behavioural checks: invoke via sh, assert transparent re-exec
# ---------------------------------------------------------------------------

skip_if_no_sh() {
    if ! command -v sh >/dev/null 2>&1; then
        skip "sh not available"
    fi
}

skip_if_no_bash() {
    if ! command -v bash >>/dev/null 2>&1; then
        skip "bash not available (re-exec guard requires bash on PATH)"
    fi
}

@test "sh generate.sh --dry-run exits 0 (re-exec guard works)" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
}

@test "sh generate.sh --dry-run output contains the Config Generator header" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Config Generator"* ]]
}

@test "sh generate.sh --dry-run output contains the DRY RUN MODE banner" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN MODE"* ]]
}

@test "sh generate.sh --dry-run output contains the completion message" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Config generation complete"* ]]
}

@test "sh generate.sh --dry-run output mentions Claude Code generation" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Claude Code"* ]]
}

@test "sh generate.sh --dry-run output does not contain a bash syntax error" {
    skip_if_no_sh
    skip_if_no_bash

    run sh "$REPO_ROOT/generate.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"syntax error"* ]]
    [[ "$output" != *"unexpected token"* ]]
}
