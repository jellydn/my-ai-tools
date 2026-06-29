#!/bin/bash
# Git Guard - Dangerous Git Command Detection for AI Tools
# Blocks destructive git commands from AI agents
#
# Receives JSON payload on stdin with tool call details.
# Returns exit code 0 (allow) or 1 (deny) with message on stdout.
#
# Usage:
#   cat payload.json | git-guard.sh

set -euo pipefail

# Read JSON payload from stdin
if [ -t 0 ]; then
	exit 0
fi

INPUT=$(cat 2>/dev/null || true)
if [ -z "$INPUT" ]; then
	exit 0
fi

# Extract the command from the JSON payload (works with claude/codex/opencode formats)
# Try common key names for the command being executed
COMMAND=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Try different payload shapes
    if isinstance(data, dict):
        # Claude format
        if 'tool_input' in data and isinstance(data['tool_input'], dict):
            cmd = data['tool_input'].get('command', '') or data['tool_input'].get('cmd', '')
        # Direct format
        elif 'command' in data:
            cmd = data['command']
        elif 'cmd' in data:
            cmd = data['cmd']
        # Cline SDK tool_call_before format
        elif 'toolCall' in data and isinstance(data['toolCall'], dict):
            inp = data['toolCall'].get('input', {})
            if isinstance(inp, dict):
                cmd = inp.get('command', '') or inp.get('cmd', '')
            else:
                cmd = str(inp) if inp else ''
        else:
            cmd = ''
    else:
        cmd = ''
    print(cmd[:500] if cmd else '')
except Exception:
    print('')
" 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
	exit 0
fi

# Normalize whitespace
COMMAND=$(echo "$COMMAND" | tr -s ' ')

# Check if it's a git command (case-insensitive)
if ! echo "$COMMAND" | grep -qi '\bgit\b'; then
	exit 0
fi

# Dangerous patterns to block
DANGEROUS_PATTERNS=(
	"git[[:space:]]*push[[:space:]]*.*--force[[:space:]]*$"
	"git[[:space:]]*push[[:space:]]*.*-f[[:space:]]*$"
	"git[[:space:]]*reset[[:space:]]*--hard"
	"git[[:space:]]*clean[[:space:]]*-[a-z]*f"
	"git[[:space:]]*clean[[:space:]]*-[a-z]*d"
	"git[[:space:]]*branch[[:space:]]*-D"
	"git[[:space:]]*filter-branch"
	"git[[:space:]]*reflog[[:space:]]*expire"
	"git[[:space:]]*gc[[:space:]]*.*--prune=now"
	"git[[:space:]]*stash[[:space:]]*drop"
	"git[[:space:]]*stash[[:space:]]*clear"
	"git[[:space:]]*update-ref[[:space:]]*-d"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
	if echo "$COMMAND" | grep -qiE "$pattern"; then
		echo "BLOCKED: Dangerous git command detected: $COMMAND"
		exit 1
	fi
done

# Also block rm -rf / and rm -rf ~
if echo "$COMMAND" | grep -qE "rm[[:space:]]*-rf[[:space:]]*/|rm[[:space:]]*-rf[[:space:]]*~"; then
	echo "BLOCKED: Dangerous rm command detected: $COMMAND"
	exit 1
fi

exit 0
