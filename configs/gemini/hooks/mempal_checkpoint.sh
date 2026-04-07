#!/bin/bash
# MemPalace Checkpoint Hook for Gemini CLI
# Quick save triggered by BeforeTool/AfterTool hooks

set -e

# Check if mempalace is available
if ! command -v python3 &>/dev/null; then
    exit 0
fi

if ! python3 -c "import mempalace" 2>/dev/null; then
    exit 0
fi

# Get current context
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CURRENT_DIR="$PWD"
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GEMINI_TOOL="${GEMINI_CURRENT_TOOL:-unknown}"
GEMINI_AGENT="${GEMINI_CURRENT_AGENT:-default}"

# Quick checkpoint via mempalace
python3 -c "
import mempalace
import sys

try:
    mempalace.quick_checkpoint(
        source='gemini',
        hook='checkpoint',
        context={
            'dir': '$CURRENT_DIR',
            'branch': '$GIT_BRANCH',
            'tool': '$GEMINI_TOOL',
            'agent': '$GEMINI_AGENT',
            'timestamp': '$TIMESTAMP'
        }
    )
except Exception as e:
    # Silently fail - hooks shouldn't break workflow
    pass
" 2>/dev/null || true

exit 0
