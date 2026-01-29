# 🚀 MEMORY.md - AI Agent Knowledge Management

**Purpose**: Tell agents when and how to use qmd for persistent knowledge capture.

---

## 📋 Pre-flight Check: Is Knowledge Base Ready?

Before using qmd knowledge features, check if the project's knowledge base is set up:

```bash
# Check if qmd is installed
command -v qmd || echo "qmd not found - install with: bun install -g https://github.com/tobi/qmd"

# Check if MCP server is configured (should return qmd server info)
mcp__qmd__status

# Check if project collection exists
qmd collection list
```

**If NOT set up for this project, automatically set it up:**

```bash
# Auto-detect project name: try git remote, fallback to repo folder name, then current folder
PROJECT_NAME=$(
  { git remote get-url origin 2>/dev/null | xargs basename -s .git 2>/dev/null; } ||
  { git rev-parse --show-toplevel 2>/dev/null | xargs basename; } ||
  basename "$PWD"
)

# Filter out empty or invalid values (like "origin")
if [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = "origin" ]; then
  PROJECT_NAME=$(basename "$PWD")
fi

# 1. Create project directory structure
mkdir -p ~/.ai-knowledges/$PROJECT_NAME/learnings
mkdir -p ~/.ai-knowledges/$PROJECT_NAME/issues

# 2. Add to qmd (skip if already exists - suppress errors)
qmd collection add ~/.ai-knowledges/$PROJECT_NAME --name $PROJECT_NAME 2>/dev/null || {
  # Verify collection exists
  if qmd collection list 2>/dev/null | grep -q "$PROJECT_NAME"; then
    echo "✓ Collection '$PROJECT_NAME' already exists"
  fi
}

# 3. Add context (skip if already exists)
qmd context add qmd://$PROJECT_NAME "Knowledge base for $PROJECT_NAME project" 2>/dev/null || true

# 4. Generate embeddings for search
qmd embed

# Inform user
echo "✓ Knowledge base initialized for: $PROJECT_NAME"
echo "  Storage: ~/.ai-knowledges/$PROJECT_NAME"
```

---

## 📚 When to Use qmd Knowledge

**DO use qmd for:**

- Project-specific learnings (architecture decisions, gotchas, patterns)
- Issue resolution notes (how you fixed something)
- Project conventions and standards
- Context that should persist across sessions

**DON'T use for:**

- Temporary debugging context (use `/handoffs` and `/pickup` instead)
- General programming knowledge (already in your training)
- Obvious implementations
- Boilerplate code

---

## 🛠️ How to Use qmd (via MCP Server)

When qmd MCP server is configured, you can autonomously:

### Search Knowledge

```text
mcp__qmd__query - for best quality (hybrid search with reranking)
mcp__qmd__search - for fast keyword search
mcp__qmd__vsearch - for semantic similarity search
```

### Read Documents

```text
mcp__qmd__get - get single document by path or docid
mcp__qmd__multi_get - get multiple by glob pattern
```

### Check Status

```text
mcp__qmd__status - see collections and health
```

---

## 📝 What About Recording?

### 🚫 Do not directly write to ~/.ai-knowledges/

Instead, use the `qmd-knowledge` skill:

- Invoke via `/qmd-knowledge` slash command
- Agent will handle proper file creation and embedding updates

---

## 📋 Best Practices

### 🎨 Session Wrap-up

At the end of a work session, consider prompting the user about key learnings:

> "What were the main discoveries or decisions from this session? Would you like me to record any learnings?"

### 🎨 Pattern Detection

Be attentive to phrases that indicate valuable knowledge capture opportunities:

- "I discovered that..."
- "I learned that..."
- "The solution was..."
- "The key insight is..."
- "Don't forget to..."
- "Make sure to..."

When you detect these patterns, suggest recording:
> "That sounds like a useful learning. Would you like me to record it?"

### 🎨 Auto-Index Updates

The record script automatically runs `qmd embed` after each write, ensuring the knowledge base is searchable immediately. No manual re-indexing required.

---

## 📖 Quick Reference

| Task             | Tool/Command           |
| ---------------- | ---------------------- |
| Search knowledge | `mcp__qmd__query`      |
| Get document     | `mcp__qmd__get`        |
| Record learning  | `/qmd-knowledge` skill |
| Check status     | `mcp__qmd__status`     |

---

## 🔍 Project Detection

The `qmd-knowledge` skill auto-detects project from:

1. `QMD_PROJECT` env var (if set)
2. Git repository name
3. Current directory name

Knowledge is stored in `~/.ai-knowledges/{project-name}/`

---

## 🔗 See Also

- [qmd GitHub](https://github.com/tobi/qmd) - qmd tool documentation
