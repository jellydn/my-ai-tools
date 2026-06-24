#!/bin/bash
# MemPalace Auto-Save Hook for Claude Code
# Triggers every 15 messages to save structured memories
# Topics, decisions, quotes, code changes
# Also regenerates the critical facts layer
#
# Errors are logged to ~/.mempalace/logs/hooks.log for debugging
# while maintaining silent operation to not break workflow

set -e

HOOK_NAME="mempal_save"
COUNTER_FILE="${TMPDIR:-/tmp}/.mempal_save_counter"
THRESHOLD=15
LOG_DIR="$HOME/.mempalace/logs"
LOG_FILE="$LOG_DIR/hooks.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log function that writes to log file without affecting stdout/stderr
log_hook() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$HOOK_NAME] $1" >> "$LOG_FILE" 2>/dev/null || true
}

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
    log_hook "ERROR: python3 not found"
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    log_hook "ERROR: mempalace module not installed"
    exit 0
fi

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$CLAUDE_SESSION_ID" | cut -c1-8)

log_hook "INFO: Triggered (count: $THRESHOLD)"

# Save structured memory types to mempalace
python3 << 'PYEOF' 2>> "$LOG_FILE" || log_hook "ERROR: Python execution failed"
import mempalace
import sys
import os

try:
    # Save session checkpoint
    mempalace.save_checkpoint(
        source='claude_code',
        hook='auto_save',
        trigger='message_threshold',
        context={'dir': os.getcwd(), 'branch': os.popen('git branch --show-current 2>/dev/null').read().strip() or 'unknown'}
    )

    # Regenerate critical facts layer
    mempalace.regenerate_facts_layer()

    # Log success
    with open(os.path.expanduser('~/.mempalace/logs/hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_save] INFO: Save successful\n")

except Exception as e:
    # Log error but don't fail
    with open(os.path.expanduser('~/.mempalace/logs/hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_save] ERROR: {str(e)}\n")
PYEOF

exit 0
