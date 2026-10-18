#!/usr/bin/env bats

load helpers

setup() {
    export HOME="$BATS_TEST_TMPDIR/home with spaces"
    mkdir -p "$HOME/.local/share/pi-durable" "$HOME/work/pi-durable"
    cat > "$HOME/.local/share/pi-durable/node" <<'NODE'
#!/bin/sh
printf 'cwd=%s\nagent=%s\nmask=%s\n' "$PWD" "$PI_CODING_AGENT_DIR" "$(umask)"
printf 'arg=%s\n' "$@"
exit 23
NODE
    chmod +x "$HOME/.local/share/pi-durable/node"
}

@test "Durable continues by default from its private stable paths and propagates failure" {
    run sh "$REPO_ROOT/configs/pi/durable/pi-durable"
    [ "$status" -eq 23 ]
    [[ "$output" == *"cwd=$HOME/work/pi-durable"* ]]
    [[ "$output" == *"agent=$HOME/.local/state/pi-durable/agent"* ]]
    [[ "$output" == *"mask=0077"* ]]
    [[ "$output" == *"arg=$HOME/.local/share/pi-durable/source/packages/coding-agent/src/experimental/source-resolver.ts"* ]]
    [[ "$output" == *"arg=$HOME/.local/share/pi-durable/source/packages/coding-agent/src/experimental/durable/main.ts"* ]]
    [[ "$output" == *"arg=--continue" ]]
}

@test "Durable creates a session only on an explicit new request" {
    run sh "$REPO_ROOT/configs/pi/durable/pi-durable" --new
    [ "$status" -eq 23 ]
    [[ "$output" != *"arg=--continue"* ]]
    [[ "$output" != *"arg=--new"* ]]

    run sh "$REPO_ROOT/configs/pi/durable/pi-durable" --continue
    [ "$status" -eq 23 ]
    [[ "$output" == *"arg=--continue" ]]
}

@test "Durable rejects unsupported arguments and missing work directories" {
    run sh "$REPO_ROOT/configs/pi/durable/pi-durable" --serve
    [ "$status" -eq 2 ]
    run sh "$REPO_ROOT/configs/pi/durable/pi-durable" --new extra
    [ "$status" -eq 2 ]
    rmdir "$HOME/work/pi-durable"
    run sh "$REPO_ROOT/configs/pi/durable/pi-durable"
    [ "$status" -ne 0 ]
    [[ "$output" != *"arg="* ]]
}
