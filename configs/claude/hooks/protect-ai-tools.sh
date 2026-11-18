#!/usr/bin/env bash
# PreToolUse guard: refuse agent edits to the my-ai-tools managed layer.
#
# Protected: ~/.ai-tools/** (guidelines, memory stores), ~/.claude/settings.json
# and ~/.claude/hooks/** (the hook layer itself). Agents propose changes in the
# my-ai-tools repository and reinstall; hand-editing installed files silently
# drifts the fleet. This is the "agents loosened 7 of 58 CI checks" guard:
# the agent must not weaken its own rules.
#
# Override for a single shell command: prefix it with AI_TOOLS_EDIT_OK=1
# (the env var alone also allows file-tool edits, e.g. exported for a
# deliberate session).
#
# Reads one Claude Code hook-event JSON object on stdin; emits a deny
# decision on stdout. Fails open when jq is missing (the installer
# guarantees it).

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

if [ "${AI_TOOLS_EDIT_OK:-}" = "1" ]; then
	exit 0
fi

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

target=""
case "$tool_name" in
Write | Edit | MultiEdit | NotebookEdit)
	target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
	;;
Bash)
	target=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
	# An explicit opt-out inside the command itself is honoured.
	case "$target" in
	*AI_TOOLS_EDIT_OK=1*) exit 0 ;;
	esac
	;;
*)
	exit 0
	;;
esac

[ -n "$target" ] || exit 0

deny() {
	jq -n \
		--arg reason "$1" \
		'{
			hookSpecificOutput: {
				hookEventName: "PreToolUse",
				permissionDecision: "deny",
				permissionDecisionReason: $reason
			}
		}'
	exit 0
}

home="${HOME:-$(cd ~ && pwd)}"

# The hook sees commands before the shell expands them, so the managed paths
# must match in all three forms the agent can write them in. File-tool paths
# are whole values; a shell command may contain the path anywhere.
is_protected() {
	local p="$1"
	if [ "$tool_name" = "Bash" ]; then
		case "$target" in *"$p"*) return 0 ;; esac
	else
		case "$target" in "$p" | "$p"/*) return 0 ;; esac
	fi
	return 1
}

# shellcheck disable=SC2016  # '$HOME' is matched literally on purpose
for prefix in "$home" '~' '$HOME'; do
	for path in \
		"$prefix/.ai-tools" \
		"$prefix/.claude/settings.json" \
		"$prefix/.claude/settings.local.json" \
		"$prefix/.claude/hooks"; do
		if is_protected "$path"; then
			deny "$target is part of the my-ai-tools managed layer. Edit the my-ai-tools repository instead and reinstall (./cli.sh), or prefix a shell command with AI_TOOLS_EDIT_OK=1 for this one change."
		fi
	done
done

exit 0
