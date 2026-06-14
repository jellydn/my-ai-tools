#!/usr/bin/env bats
# Test suite for generate.sh – specifically the copy_single function refactor
# (execute → execute_quoted) introduced in this PR.

REPO_ROOT="$BATS_TEST_DIRNAME/.."

setup() {
    # Set up a controlled HOME so generate.sh's main() no-ops on missing dirs
    export ORIG_HOME="$HOME"
    export HOME
    HOME="$(mktemp -d)"
    export SCRIPT_DIR
    SCRIPT_DIR="$(mktemp -d)"
    export DRY_RUN=false

    # Source common.sh for execute_quoted / log_* helpers
    source "$REPO_ROOT/lib/common.sh"
    # Source generate.sh; main() runs but all generate_* functions return early
    # because the expected config directories do not exist under the temp HOME.
    source "$REPO_ROOT/generate.sh"
}

teardown() {
    # Restore HOME and clean up temp directories
    rm -rf "$HOME"
    rm -rf "$SCRIPT_DIR"
    export HOME="$ORIG_HOME"
}

# ---------------------------------------------------------------------------
# copy_single – basic copy (the function now uses execute_quoted internally)
# ---------------------------------------------------------------------------

@test "copy_single copies an existing file to the destination" {
    local src dest
    src="$(mktemp)"
    echo "test content" > "$src"
    dest="$SCRIPT_DIR/copy_single_output_$$.txt"

    run copy_single "$src" "$dest"

    [ "$status" -eq 0 ]
    [ -f "$dest" ]
    grep -q "test content" "$dest"

    rm -f "$src" "$dest"
}

@test "copy_single creates destination parent directory if it does not exist" {
    local src dest_dir dest
    src="$(mktemp)"
    echo "hello" > "$src"
    dest_dir="$SCRIPT_DIR/nested/dir/$$"
    dest="$dest_dir/output.txt"

    run copy_single "$src" "$dest"

    [ "$status" -eq 0 ]
    [ -f "$dest" ]

    rm -f "$src"
    rm -rf "$SCRIPT_DIR/nested"
}

@test "copy_single handles source path containing spaces" {
    local src_dir src dest
    src_dir="$(mktemp -d)"
    # Create a source file whose directory path contains spaces
    local spaced_dir="$src_dir/path with spaces"
    mkdir -p "$spaced_dir"
    src="$spaced_dir/data.txt"
    echo "space test" > "$src"
    dest="$SCRIPT_DIR/space_copy_$$.txt"

    run copy_single "$src" "$dest"

    [ "$status" -eq 0 ]
    [ -f "$dest" ]
    grep -q "space test" "$dest"

    rm -rf "$src_dir"
    rm -f "$dest"
}

@test "copy_single handles destination path containing spaces" {
    local src dest_dir dest
    src="$(mktemp)"
    echo "dest space test" > "$src"
    dest_dir="$SCRIPT_DIR/dest with spaces $$"
    dest="$dest_dir/output.txt"

    run copy_single "$src" "$dest"

    [ "$status" -eq 0 ]
    [ -f "$dest" ]
    grep -q "dest space test" "$dest"

    rm -f "$src"
    rm -rf "$dest_dir"
}

@test "copy_single logs a warning and succeeds when source file does not exist" {
    local dest="$SCRIPT_DIR/should_not_exist_$$.txt"

    run copy_single "/nonexistent/path/file-$$-missing.txt" "$dest"

    # Function should exit 0 (just warns, doesn't fail)
    [ "$status" -eq 0 ]
    # Destination must NOT be created
    [ ! -f "$dest" ]
}

# ---------------------------------------------------------------------------
# copy_single – DRY_RUN mode
# ---------------------------------------------------------------------------

@test "copy_single in DRY_RUN mode does not write any file" {
    export DRY_RUN=true

    local src dest
    src="$(mktemp)"
    echo "dry run test" > "$src"
    dest="$SCRIPT_DIR/dry_run_output_$$.txt"

    run copy_single "$src" "$dest"

    [ "$status" -eq 0 ]
    # File must NOT exist because DRY_RUN suppresses execution
    [ ! -f "$dest" ]

    rm -f "$src"
    export DRY_RUN=false
}

@test "copy_single in DRY_RUN mode emits [DRY RUN] marker in output" {
    export DRY_RUN=true

    local src dest
    src="$(mktemp)"
    echo "dry run content" > "$src"
    dest="$SCRIPT_DIR/dry_run_check_$$.txt"

    run copy_single "$src" "$dest"

    local clean_output
    clean_output="$(printf '%s' "$output" | sed -E 's/\x1B\[[0-9;]*m//g')"
    [[ "$clean_output" == *"[DRY RUN]"* ]]

    rm -f "$src"
    export DRY_RUN=false
}

# ---------------------------------------------------------------------------
# execute_quoted – unit tests for the helper itself
# ---------------------------------------------------------------------------

@test "execute_quoted runs command with arguments containing spaces" {
    local target_dir="$SCRIPT_DIR/eq test dir $$"
    # execute_quoted must handle the space in the path without failing
    run execute_quoted mkdir -p "$target_dir"
    [ "$status" -eq 0 ]
    [ -d "$target_dir" ]
    rm -rf "$target_dir"
}

@test "execute_quoted in DRY_RUN mode does not execute the command" {
    export DRY_RUN=true
    local target_dir="$SCRIPT_DIR/eq_dry_dir_$$"

    run execute_quoted mkdir -p "$target_dir"

    [ "$status" -eq 0 ]
    [ ! -d "$target_dir" ]

    export DRY_RUN=false
}

@test "execute_quoted in DRY_RUN mode shows [DRY RUN] in output" {
    export DRY_RUN=true

    run execute_quoted echo "hello world"

    local clean_output
    clean_output="$(printf '%s' "$output" | sed -E 's/\x1B\[[0-9;]*m//g')"
    [[ "$clean_output" == *"[DRY RUN]"* ]]

    export DRY_RUN=false
}
