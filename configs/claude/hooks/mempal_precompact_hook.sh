#!/bin/bash
# MemPalace Pre-Compact Hook for Claude Code
# Fires before context compression / emergency save
# Ensures critical memories are preserved before window shrinks

set -e

HOOK_NAME="mempal_precompact"

# Check if mempalace is available
if ! command -v python3 &>/dev/null; then
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    exit 0
fi

# Generate timestamp and session info
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$CLAUDE_SESSION_ID" | cut -c1-8)
COMPACT_REASON="${COMPACT_REASON:-context_window}"

# Emergency save - capture critical state before compression
cat <<EOF | python3 -m mempalace.tools.emergency_save - 2>/dev/null || true
{
    "timestamp": "$TIMESTAMP",
    "session_id": "$SESSION_ID",
    "hook": "$HOOK_NAME",
    "reason": "$COMPACT_REASON",
    "priority": "high",
    "working_dir": "$PWD"
}
EOF

# Perform emergency save via mempalace
python3 -c "
import mempalace
import sys

try:
    # Emergency checkpoint before context loss
    mempalace.emergency_save(
        source='claude_code',
        hook='pre_compact',
        reason='$COMPACT_REASON',
        context={'dir': '$PWD', 'session': '$SESSION_ID'}
    )

    # Mark critical memories for persistence
    mempalace.flag_critical_memories()

    # Quick facts layer update with recent only
    mempalace.quick_facts_update()

except Exception as e:
    # Silently fail - hooks shouldn't break the workflow
    pass
" 2>/dev/null || true

exit 0
