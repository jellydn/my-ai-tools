#!/bin/bash
# MemPalace Pre-Compact Hook for Claude Code
# Fires before context compression / emergency save
# Ensures critical memories are preserved before window shrinks
#
# Errors are logged to ~/.mempalace/logs/hooks.log for debugging
# while maintaining silent operation to not break workflow

set -e

HOOK_NAME="mempal_precompact"
LOG_DIR="$HOME/.mempalace/logs"
LOG_FILE="$LOG_DIR/hooks.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log function that writes to log file without affecting stdout/stderr
log_hook() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$HOOK_NAME] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Check if mempalace is available
if ! command -v python3 &>/dev/null; then
    log_hook "ERROR: python3 not found"
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    log_hook "ERROR: mempalace module not installed"
    exit 0
fi

# Generate timestamp and session info
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$CLAUDE_SESSION_ID" | cut -c1-8)
COMPACT_REASON="${COMPACT_REASON:-context_window}"

log_hook "INFO: Triggered (reason: $COMPACT_REASON)"

# Perform emergency save via mempalace
python3 << 'PYEOF' 2>> "$LOG_FILE" || log_hook "ERROR: Python execution failed"
import mempalace
import sys
import os

try:
    # Emergency checkpoint before context loss
    mempalace.emergency_save(
        source='claude_code',
        hook='pre_compact',
        reason='$COMPACT_REASON',
        context={'dir': os.getcwd(), 'session': os.environ.get('CLAUDE_SESSION_ID', 'unknown')[:8]}
    )

    # Mark critical memories for persistence
    mempalace.flag_critical_memories()

    # Quick facts layer update with recent only
    mempalace.quick_facts_update()

    # Log success
    with open(os.path.expanduser('~/.mempalace/logs/hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_precompact] INFO: Emergency save successful\n")

except Exception as e:
    # Log error but don't fail
    with open(os.path.expanduser('~/.mempalace/logs/hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_precompact] ERROR: {str(e)}\n")
PYEOF

exit 0
