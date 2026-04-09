#!/bin/bash
# MemPalace Session Start Hook for Codex
# Triggered when a new Codex session starts
# Performs initial checkpoint and setup

set -e

HOOK_NAME="mempal_session_start"
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

log_hook "INFO: Session started (dir: $CURRENT_DIR, branch: $GIT_BRANCH)"

# Initialize session checkpoint
python3 << 'PYEOF' 2>> "$LOG_FILE" || log_hook "ERROR: Python execution failed"
import mempalace
import sys
import os

try:
    # Initialize session checkpoint
    mempalace.session_init(
        source='codex',
        hook='session_start',
        context={
            'dir': os.getcwd(),
            'branch': os.popen('git branch --show-current 2>/dev/null').read().strip() or 'unknown'
        }
    )

    # Log success
    with open(os.path.expanduser('~/.mempalace/logs/codex-hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_session_start] [INFO] Session init successful\n")

except Exception as e:
    # Log error but don't fail
    with open(os.path.expanduser('~/.mempalace/logs/codex-hooks.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempal_session_start] [ERROR] {str(e)}\n")
PYEOF

exit 0
