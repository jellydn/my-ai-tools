#!/bin/bash
# MemPalace Auto-Compact Hook for tools without native PreCompact support
# This is a generic checkpoint that can be triggered by various mechanisms:
# - Periodic polling (cron, background job)
# - Command wrappers (before/after AI tool commands)
# - Signal handlers (SIGUSR1 for manual trigger)
#
# Usage:
#   mempauto_compact.sh [trigger_reason]
#
# Environment:
#   MEMPALACE_DIR - Override default ~/.mempalace location
#   MEMPALACE_LOG_LEVEL - Set to "debug" for verbose output

set -e

HOOK_NAME="mempauto_compact"
TRIGGER_REASON="${1:-periodic}"
LOG_DIR="${MEMPALACE_DIR:-$HOME/.mempalace}/logs"
LOG_FILE="$LOG_DIR/auto-compact.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log function
log_compact() {
    local level="${2:-INFO}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$HOOK_NAME] [$level] $1" >> "$LOG_FILE" 2>/dev/null || true

    if [[ "${MEMPALACE_LOG_LEVEL}" == "debug" ]]; then
        echo "[$timestamp] [$HOOK_NAME] [$level] $1" >&2
    fi
}

# Check prerequisites
if ! command -v python3 &>/dev/null; then
    log_compact "python3 not found" "ERROR"
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    log_compact "mempalace module not installed" "ERROR"
    exit 0
fi

# Get current context
CURRENT_DIR="$PWD"
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
SESSION_ID="${AI_SESSION_ID:-$(date +%s)}"

log_compact "Triggered (reason: $TRIGGER_REASON, dir: $CURRENT_DIR)" "INFO"

# Perform auto-compact via mempalace
python3 << 'PYEOF' 2>> "$LOG_FILE" || log_compact "Python execution failed" "ERROR"
import mempalace
import sys
import os

try:
    # Auto-compact: emergency save + quick facts update
    mempalace.emergency_save(
        source='auto_compact',
        hook='periodic_checkpoint',
        reason=os.environ.get('MEMPALACE_TRIGGER', 'periodic'),
        context={
            'dir': os.getcwd(),
            'branch': os.popen('git branch --show-current 2>/dev/null').read().strip() or 'unknown',
            'session': os.environ.get('AI_SESSION_ID', 'unknown')[:8]
        }
    )

    # Flag any critical memories for persistence
    mempalace.flag_critical_memories()

    # Quick facts layer update
    mempalace.quick_facts_update()

    # Log success (silently)
    with open(os.path.expanduser('~/.mempalace/logs/auto-compact.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempauto_compact] [INFO] Auto-compact successful\n")

except Exception as e:
    # Log error but don't fail the workflow
    with open(os.path.expanduser('~/.mempalace/logs/auto-compact.log'), 'a') as f:
        f.write(f"[{os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()}] [mempauto_compact] [ERROR] {str(e)}\n")
PYEOF

exit 0
