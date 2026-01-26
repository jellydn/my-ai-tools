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
    echo "Create it by running:"
    echo "  mkdir -p $KNOWLEDGE_BASE"
    echo "  # Copy skill files from your my-ai-tools config location"
    exit 1
fi

# Function to slugify text
slugify() {
    local slug=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')
    # Fallback to timestamp if slug is empty
    if [ -z "$slug" ]; then
        slug="note-$(date +%H%M%S)"
    fi
    echo "$slug"
}

# Function to update qmd index
update_index() {
    if command -v qmd &> /dev/null; then
        echo -e "${GREEN}Updating qmd embeddings...${NC}"
        qmd embed 2>/dev/null || echo -e "${YELLOW}Note: qmd embed failed. Ensure collection is added: qmd collection add $KNOWLEDGE_BASE --name $PROJECT_NAME${NC}"
    else
        echo -e "${YELLOW}Warning: qmd not found. Install with: bun install -g https://github.com/tobi/qmd${NC}"
    fi
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
        FILENAME="references/learnings/$(date +%Y-%m-%d)-${SLUG}.md"
        FILEPATH="$KNOWLEDGE_BASE/$FILENAME"
        
        # Create learnings directory if it doesn't exist
        mkdir -p "$KNOWLEDGE_BASE/references/learnings"
        
        # Create the learning file
        cat > "$FILEPATH" <<EOF
# Learning: $TOPIC

**Date:** $(date +"%Y-%m-%d %H:%M:%S")

## Context

<!-- Add context about when/how this learning was discovered -->

## Learning

<!-- Describe what was learned -->

## Application

<!-- How can this learning be applied in the future? -->

---

*Recorded by qmd-knowledge skill*
EOF
        
        echo -e "${GREEN}✓ Created learning: $FILEPATH${NC}"
        echo "Edit this file to add details."
        update_index
        ;;
        
    issue)
        ID="$1"
        NOTE="$2"
        if [ -z "$ID" ]; then
            echo -e "${RED}Error: Issue ID required${NC}"
            echo "Usage: $0 issue <id> \"note text\""
            exit 1
        fi
        
        FILENAME="references/issues/$ID.md"
        FILEPATH="$KNOWLEDGE_BASE/$FILENAME"
        
        # Create issues directory if it doesn't exist
        mkdir -p "$KNOWLEDGE_BASE/references/issues"
        
        # Create or append to issue file
        if [ ! -f "$FILEPATH" ]; then
            cat > "$FILEPATH" <<EOF
# Issue #$ID

## Notes

EOF
        fi
        
        # Append the note
        cat >> "$FILEPATH" <<EOF

### $(date +"%Y-%m-%d %H:%M:%S")

${NOTE:-<!-- Add note here -->}

EOF
        
        echo -e "${GREEN}✓ Added note to issue #$ID: $FILEPATH${NC}"
        update_index
        ;;
        
    note)
        TEXT="$1"
        if [ -z "$TEXT" ]; then
            echo -e "${RED}Error: Note text required${NC}"
            echo "Usage: $0 note \"note text\""
            exit 1
        fi
        
        # Create a general note with timestamp and topic slug
        TOPIC="note"
        SLUG=$(slugify "$TEXT")
        # Limit slug length to avoid overly long filenames
        SLUG=$(echo "$SLUG" | cut -c1-50)
        FILENAME="references/learnings/$(date +%Y-%m-%d)-${SLUG}.md"
        FILEPATH="$KNOWLEDGE_BASE/$FILENAME"
        
        # Create learnings directory if it doesn't exist
        mkdir -p "$KNOWLEDGE_BASE/references/learnings"
        
        cat > "$FILEPATH" <<EOF
# Note

**Date:** $(date +"%Y-%m-%d %H:%M:%S")

$TEXT

---

*Recorded by qmd-knowledge skill*
EOF
        
        echo -e "${GREEN}✓ Created note: $FILEPATH${NC}"
        update_index
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
