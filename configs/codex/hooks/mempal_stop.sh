#!/bin/bash
# MemPalace Stop Hook for Codex
# Triggered when a Codex session ends
# Performs final checkpoint and cleanup

set -e

HOOK_NAME="mempal_stop"
LOG_DIR="$HOME/.mempalace/logs"
LOG_FILE="$LOG_DIR/codex-hooks.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log function
log_hook() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$HOOK_NAME] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Check prerequisites
if ! command -v python3 &>/dev/null; then
    log_hook "ERROR: python3 not found"
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    log_hook "ERROR: mempalace module not installed"
    exit 0
fi

# Get session context
CURRENT_DIR="$PWD"
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

log_hook "INFO: Session stopping (dir: $CURRENT_DIR, branch: $GIT_BRANCH)"

# Final checkpoint before session ends
python3 << 'PYEOF' 2>> "$LOG_FILE" || log_hook "ERROR: Python execution failed"
import mempalace
import sys
import os

try:
    # Final checkpoint
    mempalace.session_end(
        source='codex',
        hook='stop',
        context={
            'dir': os.getcwd(),
            'branch': os.popen('git branch --show-current 2>/dev/null').read().strip() or 'unknown'
        }
    )

    # Save any pending memories
    mempalace.flush_pending()

    # Log success
    with open(os.path.expanduser('~/.mempalace/logs/codex-hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_stop] [INFO] Session end checkpoint saved\n")

except Exception as e:
    # Log error but don't fail
    with open(os.path.expanduser('~/.mempalace/logs/codex-hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_stop] [ERROR] {str(e)}\n")
PYEOF

exit 0
