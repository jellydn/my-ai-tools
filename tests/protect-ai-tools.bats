#!/usr/bin/env bats
# Tests for configs/claude/hooks/protect-ai-tools.sh: the guard must deny
# agent edits to the my-ai-tools managed layer, pass everything else through,
# and honour the AI_TOOLS_EDIT_OK=1 opt-out.

setup() {
	HOOK="$BATS_TEST_DIRNAME/../configs/claude/hooks/protect-ai-tools.sh"
	FAKE_HOME="$(mktemp -d)"
	export HOME="$FAKE_HOME"
}

teardown() {
	rm -rf "$FAKE_HOME"
}

run_hook() {
	printf '%s' "$1" | bash "$HOOK"
}

@test "denies Write to a file under ~/.ai-tools" {
	run run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$FAKE_HOME"'/.ai-tools/MEMORY.md","content":"x"}}'
	[ "$status" -eq 0 ]
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies Edit to ~/.claude/settings.json" {
	run run_hook '{"tool_name":"Edit","tool_input":{"file_path":"'"$FAKE_HOME"'/.claude/settings.json"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies NotebookEdit under ~/.claude/hooks" {
	run run_hook '{"tool_name":"NotebookEdit","tool_input":{"file_path":"'"$FAKE_HOME"'/.claude/hooks/protect-ai-tools.sh"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a Bash redirect into ~/.claude/hooks" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"echo hacked > ~/.claude/hooks/git-guard.ts"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a Bash edit of ~/.ai-tools via \$HOME" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ $HOME/.ai-tools/best-practices.md"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "allows the AI_TOOLS_EDIT_OK=1 opt-out in the command" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"AI_TOOLS_EDIT_OK=1 sed -i s/a/b/ $HOME/.ai-tools/best-practices.md"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "allows writes outside the managed layer" {
	run run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$FAKE_HOME"'/project/src/index.ts","content":"x"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "allows unrelated Bash commands" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"ls -la src/"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "ignores unknown tools" {
	run run_hook '{"tool_name":"Grep","tool_input":{"pattern":"ai-tools"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
