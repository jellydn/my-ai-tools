#!/bin/bash
# MemPalace Save Hook for Factory Droid
# Inherits from Claude Code hooks with Factory-specific paths

set -e

# Factory Droid reuses Claude hooks but with adjusted paths
# This script is a thin wrapper that sources the Claude hook if available

CLAUDE_HOOK="$HOME/.claude/hooks/mempal_save_hook.sh"
FACTORY_DIR="$HOME/.factory"

# Check if mempalace is available
if ! command -v python3 &>/dev/null; then
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    exit 0
fi

# Use Claude hook if available, otherwise do minimal save
if [[ -f "$CLAUDE_HOOK" ]]; then
    # Source Claude's hook (it handles counter logic)
    export MEMPALACE_MODE="factory"
    bash "$CLAUDE_HOOK" 2>/dev/null || true
else
    # Minimal fallback save
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    python3 -c "
import mempalace
import sys
try:
    mempalace.quick_checkpoint(
        source='factory',
        hook='stop',
        context={'dir': '$PWD', 'timestamp': '$TIMESTAMP'}
    )
except Exception as e:
    pass
" 2>/dev/null || true
fi

exit 0
