#!/bin/bash
# MemPalace Auto-Save Hook for Claude Code
# Triggers every 15 messages to save structured memories
# Topics, decisions, quotes, code changes
# Also regenerates the critical facts layer

set -e

HOOK_NAME="mempal_save"
COUNTER_FILE="${TMPDIR:-/tmp}/.mempal_save_counter"
THRESHOLD=15

# Initialize counter if not exists
if [[ ! -f "$COUNTER_FILE" ]]; then
    echo "0" > "$COUNTER_FILE"
fi

# Read and increment counter
count=$(cat "$COUNTER_FILE")
count=$((count + 1))
echo "$count" > "$COUNTER_FILE"

# Only save every N messages
if [[ $count -lt $THRESHOLD ]]; then
    exit 0
fi

# Reset counter after threshold reached
echo "0" > "$COUNTER_FILE"

# Check if mempalace is available
if ! command -v python3 &>/dev/null; then
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    exit 0
fi

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$CLAUDE_SESSION_ID" | cut -c1-8)

# Build save payload using available context
# This captures the current session state for mempalace
cat <<EOF | python3 -m mempalace.tools.save_session - 2>/dev/null || true
{
    "timestamp": "$TIMESTAMP",
    "session_id": "$SESSION_ID",
    "hook": "$HOOK_NAME",
    "message_count": $THRESHOLD,
    "context": {
        "working_dir": "$PWD",
        "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
        "recent_files": $(git diff --name-only HEAD~3 2>/dev/null | head -5 | jq -R . | jq -s . 2>/dev/null || echo '[]')
    }
}
EOF

# Save structured memory types to mempalace
# Topics - what was discussed
python3 -c "
import mempalace
import sys

try:
    # Save session checkpoint
    mempalace.save_checkpoint(
        source='claude_code',
        hook='auto_save',
        trigger='message_threshold',
        context={'dir': '$PWD', 'branch': '$(git branch --show-current 2>/dev/null || echo "unknown")'}
    )

    # Regenerate critical facts layer
    mempalace.regenerate_facts_layer()

except Exception as e:
    # Silently fail - hooks shouldn't break the workflow
    pass
" 2>/dev/null || true

exit 0
