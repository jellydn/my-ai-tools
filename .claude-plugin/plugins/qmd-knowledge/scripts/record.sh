#!/bin/bash

# qmd-knowledge record script
# Records learnings, issues, and notes to the project knowledge base

set -e

TYPE="$1"
shift

# Detect project name from current directory or use default
PROJECT_NAME="${QMD_PROJECT:-my-ai-tools}"
KNOWLEDGE_BASE="$HOME/.ai-knowledges/$PROJECT_NAME"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure knowledge base exists
if [ ! -d "$KNOWLEDGE_BASE" ]; then
    echo -e "${RED}Error: Knowledge base not found at $KNOWLEDGE_BASE${NC}"
    echo ""
    echo "To set up the knowledge base, run:"
    echo "  mkdir -p $KNOWLEDGE_BASE/{references/learnings,references/issues}"
    echo ""
    echo "Then initialize qmd collection:"
    echo "  qmd collection add $KNOWLEDGE_BASE --name $PROJECT_NAME"
    echo "  qmd embed"
    echo ""
    echo "See docs/qmd-knowledge-management.md for detailed setup instructions."
    exit 1
fi

# Function to slugify text
slugify() {
    local slug
    slug=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')
    # Fallback to timestamp if slug is empty
    if [ -z "$slug" ]; then
        slug="note-$(date +%H%M%S)"
    fi
    echo "$slug"
}

# Validate path stays within knowledge base (prevent path traversal)
validate_safe_path() {
    local dest_dir="$1"
    local filename="$2"

    # Get absolute paths for comparison
    local abs_knowledge_base
    local abs_dest_path
    abs_knowledge_base=$(cd "$KNOWLEDGE_BASE" 2>/dev/null && pwd)
    abs_dest_path=$(cd "$KNOWLEDGE_BASE/$dest_dir" 2>/dev/null && pwd)/"$filename"

    if [ -z "$abs_knowledge_base" ]; then
        echo -e "${RED}Error: Knowledge base directory does not exist${NC}" >&2
        return 1
    fi

    # Check if destination path starts with knowledge base path
    if [[ "$abs_dest_path" != "$abs_knowledge_base"* ]]; then
        echo -e "${RED}Error: Path traversal attempt detected: $filename${NC}" >&2
        return 1
    fi

    # Ensure no parent directory references
    if [[ "$filename" == *".."* ]]; then
        echo -e "${RED}Error: Invalid filename with parent directory reference: $filename${NC}" >&2
        return 1
    fi

    return 0
}

# Debounced index update - only runs if enough time has passed
EMBED_COOLDOWN=30
EMBED_MARKER="$KNOWLEDGE_BASE/.embed_pending"

update_index() {
    if ! command -v qmd &> /dev/null; then
        echo -e "${YELLOW}Warning: qmd not found. Install with: bun install -g https://github.com/tobi/qmd${NC}"
        return
    fi

    local now
    local last_embed
    now=$(date +%s)

    # Check for pending embedding marker
    if [ -f "$EMBED_MARKER" ]; then
        last_embed=$(cat "$EMBED_MARKER" 2>/dev/null || echo 0)
        local elapsed=$((now - last_embed))

        if [ $elapsed -lt $EMBED_COOLDOWN ]; then
            echo -e "${YELLOW}Debouncing qmd embed (last run ${elapsed}s ago, cooldown: ${EMBED_COOLDOWN}s)${NC}"
            return
        fi
    fi

    echo -e "${GREEN}Updating qmd embeddings...${NC}"
    if qmd embed 2>/dev/null; then
        echo "$now" > "$EMBED_MARKER"
    else
        echo -e "${YELLOW}Note: qmd embed failed. Ensure collection is added: qmd collection add $KNOWLEDGE_BASE --name $PROJECT_NAME${NC}"
    fi
}

# Helper: Create a knowledge file with validation and directory setup
# Usage: create_knowledge_file "subdir" "filename" "content"
# Returns: 0 on success, 1 on validation failure
create_knowledge_file() {
    local subdir="$1"
    local filename="$2"
    local content="$3"

    # Validate path stays within knowledge base
    if ! validate_safe_path "$subdir" "$filename"; then
        return 1
    fi

    # Create directory if needed
    mkdir -p "$KNOWLEDGE_BASE/$subdir"

    # Write file
    echo "$content" > "$KNOWLEDGE_BASE/$subdir/$filename"
    echo -e "${GREEN}✓ Created: $KNOWLEDGE_BASE/$subdir/$filename${NC}"
    update_index
}

case "$TYPE" in
    learning)
        TOPIC="$1"
        if [ -z "$TOPIC" ]; then
            echo -e "${RED}Error: Learning topic required${NC}"
            echo "Usage: $0 learning \"topic description\""
            exit 1
        fi

        SLUG=$(slugify "$TOPIC")
        FILENAME="$(date +%Y-%m-%d)-${SLUG}.md"

        CONTENT="# Learning: $TOPIC

**Date:** $(date +"%Y-%m-%d %H:%M:%S")

## Context

<!-- Add context about when/how this learning was discovered -->

## Learning

<!-- Describe what was learned -->

## Application

<!-- How can this learning be applied in the future? -->

---

*Recorded by qmd-knowledge skill*"

        create_knowledge_file "references/learnings" "$FILENAME" "$CONTENT"
        echo "Edit this file to add details."
        ;;

    issue)
        ID="$1"
        NOTE="$2"
        if [ -z "$ID" ]; then
            echo -e "${RED}Error: Issue ID required${NC}"
            echo "Usage: $0 issue <id> \"note text\""
            exit 1
        fi

        SAFE_ID=$(slugify "$ID")
        if [ -z "$SAFE_ID" ]; then
            echo -e "${RED}Error: Invalid issue ID '${ID}'${NC}"
            exit 1
        fi

        FILENAME="${SAFE_ID}.md"
        FILEPATH="$KNOWLEDGE_BASE/references/issues/$FILENAME"

        # Validate and create directory
        if ! validate_safe_path "references/issues" "$FILENAME"; then
            exit 1
        fi
        mkdir -p "$KNOWLEDGE_BASE/references/issues"

        # Create or append to issue file
        if [ ! -f "$FILEPATH" ]; then
            echo "# Issue #$SAFE_ID

## Notes

" > "$FILEPATH"
        fi

        # Append the note
        echo "

### $(date +"%Y-%m-%d %H:%M:%S")

${NOTE:-<!-- Add note here -->}

" >> "$FILEPATH"

        echo -e "${GREEN}✓ Added note to issue #$SAFE_ID: $FILEPATH${NC}"
        update_index
        ;;

    note)
        TEXT="$1"
        if [ -z "$TEXT" ]; then
            echo -e "${RED}Error: Note text required${NC}"
            echo "Usage: $0 note \"note text\""
            exit 1
        fi

        SLUG=$(slugify "$TEXT" | cut -c1-50)
        FILENAME="$(date +%Y-%m-%d)-${SLUG}.md"

        CONTENT="# Note

**Date:** $(date +"%Y-%m-%d %H:%M:%S")

$TEXT

---

*Recorded by qmd-knowledge skill*"

        create_knowledge_file "references/learnings" "$FILENAME" "$CONTENT"
        ;;

    *)
        echo -e "${RED}Error: Unknown type '$TYPE'${NC}"
        echo ""
        echo "Usage:"
        echo "  $0 learning \"topic description\""
        echo "  $0 issue <id> \"note text\""
        echo "  $0 note \"general note text\""
        exit 1
        ;;
esac
