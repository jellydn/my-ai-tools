#!/usr/bin/env bats
# Tests for configs/claude/hooks/protect-ai-tools.sh: the guard must deny
# agent writes to the my-ai-tools managed layer, keep read-only inspection
# working, understand NotebookEdit's notebook_path, handle Windows-native
# path forms, and honour the AI_TOOLS_EDIT_OK=1 opt-out.

setup() {
	HOOK="$BATS_TEST_DIRNAME/../configs/claude/hooks/protect-ai-tools.sh"
	FAKE_HOME="$(mktemp -d)"
	export HOME="$FAKE_HOME"
	# The documented operator opt-out must not leak into the tests.
	unset AI_TOOLS_EDIT_OK || true
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
	[ "$status" -eq 0 ]
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies NotebookEdit via notebook_path under ~/.ai-tools" {
	run run_hook '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"'"$FAKE_HOME"'/.ai-tools/learnings.ipynb"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "allows NotebookEdit outside the managed layer" {
	run run_hook '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"'"$FAKE_HOME"'/project/analysis.ipynb"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "denies a Bash redirect into ~/.claude/hooks" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"echo hacked > ~/.claude/hooks/git-guard.ts"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a Bash edit of ~/.ai-tools via \$HOME" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ $HOME/.ai-tools/best-practices.md"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies Bash writers that modify, remove or copy onto managed paths" {
	while IFS= read -r cmd; do
		run run_hook '{"tool_name":"Bash","tool_input":{"command":"'"$cmd"' '"$FAKE_HOME"'/.ai-tools/MEMORY.md"}}'
		echo "$output" | grep -q '"permissionDecision": "deny"'
	done < <(printf '%s\n' 'rm' 'mv other.md' 'cp other.md' 'tee' 'touch' 'truncate -s0' 'chmod +x' 'dd of=')
}

@test "allows read-only inspection of managed files without the override" {
	while IFS= read -r cmd; do
		run run_hook '{"tool_name":"Bash","tool_input":{"command":"'"$cmd"' '"$FAKE_HOME"'/.ai-tools/MEMORY.md"}}'
		[ "$status" -eq 0 ]
		[ -z "$output" ]
	done < <(printf '%s\n' 'cat' 'less' 'head -50' 'jq .title' 'grep -c lesson' 'wc -l')
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"ls -la ~/.claude/hooks/"}}'
	[ -z "$output" ]
}

@test "allows piping a managed file to a write elsewhere" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat ~/.ai-tools/MEMORY.md > /tmp/copy.md"}}'
	[ -z "$output" ]
}

@test "denies a native Windows backslash Write path" {
	HOME="C:/Users/reviewer" run run_hook '{"tool_name":"Write","tool_input":{"file_path":"C:\\\\Users\\\\reviewer\\\\.ai-tools\\\\MEMORY.md","content":"x"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies an MSYS home path against a drive-letter HOME" {
	HOME="C:/Users/reviewer" run run_hook '{"tool_name":"Write","tool_input":{"file_path":"/c/Users/reviewer/.claude/settings.json"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a native Windows write path against an MSYS HOME" {
	HOME="/c/Users/reviewer" run run_hook '{"tool_name":"Write","tool_input":{"file_path":"C:\\\\Users\\\\reviewer\\\\.ai-tools\\\\MEMORY.md","content":"x"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a Windows backslash Bash redirect into managed hooks" {
	HOME="C:/Users/reviewer" run run_hook '{"tool_name":"Bash","tool_input":{"command":"echo x > C:\\\\Users\\\\reviewer\\\\.claude\\\\hooks\\\\guard.ts"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "allows the AI_TOOLS_EDIT_OK=1 opt-out in the command" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"AI_TOOLS_EDIT_OK=1 sed -i s/a/b/ $HOME/.ai-tools/best-practices.md"}}'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "denies when the opt-out token appears later in the command" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ ~/.ai-tools/best-practices.md # then set AI_TOOLS_EDIT_OK=1"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies an unclassified command that mentions a managed path" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import sys; print(sys.argv)\" ~/.ai-tools/MEMORY.md"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a redirect with no whitespace before the operator" {
	run run_hook '{"tool_name":"Bash","tool_input":{"command":"echo x> ~/.claude/hooks/guard.sh"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies write-capable arguments to allowlisted-looking commands" {
	while IFS= read -r cmd; do
		run run_hook '{"tool_name":"Bash","tool_input":{"command":"'"$cmd"'"}}'
		echo "$output" | grep -q '"permissionDecision": "deny"'
	done < <(printf '%s\n' \
		'sort -o ~/.ai-tools/MEMORY.md /tmp/notes' \
		'sed w ~/.claude/hooks/guard.sh /tmp/notes' \
		'env python3 -c pass ~/.ai-tools/MEMORY.md')
}

@test "denies a writer on a later line of a multi-line command" {
	payload=$(jq -n --arg c "cat ~/.ai-tools/MEMORY.md
python3 -c pass ~/.ai-tools/MEMORY.md" '{tool_name:"Bash",tool_input:{command:$c}}')
	run run_hook "$payload"
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a file-tool write to a managed settings snapshot" {
	run run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$FAKE_HOME"'/.claude/settings.backup.json"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
}

@test "denies a PowerShell-style env path into managed settings" {
	HOME="C:/Users/reviewer" run run_hook '{"tool_name":"Bash","tool_input":{"command":"echo x > $env:USERPROFILE\\.claude\\settings.json"}}'
	echo "$output" | grep -q '"permissionDecision": "deny"'
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
