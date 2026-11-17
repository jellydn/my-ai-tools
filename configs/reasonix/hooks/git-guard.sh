#!/bin/bash
# Reasonix Git Guard Hook
# Blocks dangerous git commands from AI agents

set -euo pipefail

if [ -t 0 ]; then
	exit 0
fi

INPUT=$(cat 2>/dev/null || true)
if [ -z "$INPUT" ]; then
	exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    cmd = ''
    if isinstance(data, dict):
        if 'command' in data:
            cmd = data['command']
        elif 'cmd' in data:
            cmd = data['cmd']
        elif 'tool_input' in data and isinstance(data['tool_input'], dict):
            cmd = data['tool_input'].get('command', '') or data['tool_input'].get('cmd', '')
    print(cmd[:500] if cmd else '')
except Exception:
    print('')
" 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
	exit 0
fi

COMMAND=$(echo "$COMMAND" | tr -s ' ')

if ! echo "$COMMAND" | grep -qi '\bgit\b'; then
	exit 0
fi

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
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
	if echo "$COMMAND" | grep -qiE "$pattern"; then
		echo "BLOCKED: Dangerous git command detected: $COMMAND"
		exit 1
	fi
done

exit 0
