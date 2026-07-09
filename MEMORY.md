# 🚀 MEMORY.md - AI Agent Knowledge Management

**Purpose**: Tell agents when to use **qmd** (durable project KB), when to use **agentmemory** (session-only learnings), and when to skip recording entirely. Cross-session task continuity goes through `/handoffs` + `/pickup`, not these stores.

---

## 📋 Pre-flight Check: Is Knowledge Base Ready?

Before using qmd knowledge features, check if the project's knowledge base is set up:

```bash
# Check if qmd is installed
command -v qmd || echo "qmd not found - install with: bun install -g @tobilu/qmd"

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

# Filter out empty or invalid values (like "origin" or URL-like strings)
if [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = "origin" ] || [[ "$PROJECT_NAME" =~ ^[./:] ]]; then
  PROJECT_NAME=$(
    { git rev-parse --show-toplevel 2>/dev/null | xargs basename; } ||
    basename "$PWD"
  )
fi

# 1. Create project directory structure
mkdir -p ~/.ai-knowledges/$PROJECT_NAME/learnings
mkdir -p ~/.ai-knowledges/$PROJECT_NAME/issues

# 2. Add to qmd (check for existing collection more robustly)
ERR_FILE="/tmp/qmd-collection-add-$$.err"
if qmd collection add ~/.ai-knowledges/$PROJECT_NAME --name $PROJECT_NAME 2>"$ERR_FILE"; then
  echo "✓ Collection '$PROJECT_NAME' added"
  rm -f "$ERR_FILE"
elif grep -qi "already exists" "$ERR_FILE" 2>/dev/null; then
  echo "✓ Collection '$PROJECT_NAME' already exists"
  rm -f "$ERR_FILE"
elif qmd collection list 2>/dev/null | grep -q "^$PROJECT_NAME$"; then
  echo "✓ Collection '$PROJECT_NAME' already exists"
  rm -f "$ERR_FILE"
else
  echo "⚠ Warning: Could not verify collection setup"
  rm -f "$ERR_FILE"
fi

# 3. Add context (skip if already exists)
qmd context add qmd://$PROJECT_NAME "Knowledge base for $PROJECT_NAME project" 2>/dev/null || true

# 4. Generate embeddings for search
qmd embed 2>/dev/null || true

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

## 🧠 Agentmemory (session memory MCP)

`agentmemory` is a per-session, per-project memory MCP for **short-lived learnings that the agent itself discovered during the current run**. It is _not_ durable storage and _not_ a substitute for qmd.

### Use `agentmemory` for (session-only, not durable)

- Discoveries made in _this_ run: "the build is blocked on env var `X`", "branch Y has a WIP constraint", "the failing test depends on fixture Z"
- Pre-commit / post-commit style findings the _current_ agent wants to surface to itself on the next pass
- Hints the next session today will need, but no one will need in a month

### Do NOT use `agentmemory` for

- Anything that survives a session boundary with value — that is qmd
- Recurring gotchas, project-local facts, architecture smells, code review notes — these are durable and belong in qmd
- Long-form docs, ADRs, runbooks — write to disk and let qmd index them
- Cross-project or cross-machine knowledge — qmd collections are the canonical layer
- Cross-session task continuity — use `/handoffs` (write) and `/pickup` (resume), not agentmemory
- Secrets, tokens, or anything user-private (memory is per-project, not encrypted)

### Decision rule (apply before every record)

> "Will the next agent working on this project benefit from this in 3 months?"
>
> - **Yes** → `mcp__qmd__*` (`/qmd-knowledge` skill)
> - **No, but the next session today might** → `mcp__agentmemory__memory_save`
> - **No at all** → don't record
> - **"I need to keep working on this tomorrow"** → write a `/handoffs` plan, not a memory note

### Three memory lanes

| Lane          | Horizon             | Tool                                              |
| ------------- | ------------------- | ------------------------------------------------- |
| `qmd`         | Months              | `mcp__qmd__save` via `/qmd-knowledge` skill       |
| `agentmemory` | Today, same project | `mcp__agentmemory__memory_save`                   |
| `/handoffs`   | Cross-session task  | `/handoffs` slash command → resume with `/pickup` |

If you find yourself wanting both "remember this for me next time" and "let me continue this tomorrow" — that is two separate stores; pick the lane that matches the actual horizon.

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

### 🧭 Implementation notes workflow

Use @./`agent-memory.md` as the working rule for implementation notes:

- Capture what was learned
- Capture blockers and issues
- Capture weird behavior or gotchas
- Keep it concise and factual
- Route durable project knowledge to qmd when it should survive beyond the session

---

## 📋 Best Practices

### 🎨 Session Wrap-up

At the end of a work session, consider prompting the user about key learnings:

> "What were the main discoveries or decisions from this session? Would you like me to record any learnings — and if so, into qmd (durable) or agentmemory (session)?"

### 🎨 Pattern Detection → Decision Rule

When you spot a knowledge-capture trigger, **apply the 3-month rule first**, then choose a lane.

| Phrase                                       | Lane                                    |
| -------------------------------------------- | --------------------------------------- |
| "I learned that…" / "The fix was…" (general) | Usually qmd — unless it is session-only |
| "Blocked on X until env var Y"               | `agentmemory` (session)                 |
| "Branch W has a WIP constraint"              | `agentmemory` (session)                 |
| "Don't forget to…" / recurring gotcha        | qmd (durable)                           |
| "This project uses pattern P"                | qmd (durable, project-local)            |
| "Continue debugging tomorrow" / "resume X"   | `/handoffs` + `/pickup` (not memory)    |

If unsure, ask the user which lane — never record into both.

### 🎨 Auto-Index Updates

The record script automatically runs `qmd embed` after each write, ensuring the knowledge base is searchable immediately. No manual re-indexing required.

---

## 📖 Quick Reference

All tools are MCP-style names so agents can call them by an exact string.

### qmd (durable)

| Task             | Tool/Command           |
| ---------------- | ---------------------- |
| Search knowledge | `mcp__qmd__query`      |
| Get document     | `mcp__qmd__get`        |
| Record learning  | `/qmd-knowledge` skill |
| Check status     | `mcp__qmd__status`     |

### agentmemory (session)

| Task                     | Tool                                         |
| ------------------------ | -------------------------------------------- |
| Save a finding           | `mcp__agentmemory__memory_save`              |
| Recall past findings     | `mcp__agentmemory__memory_recall`            |
| Hybrid recall + rerank   | `mcp__agentmemory__memory_smart_search`      |
| List recent sessions     | `mcp__agentmemory__memory_sessions`          |
| Export memory            | `mcp__agentmemory__memory_export`            |
| Audit memory             | `mcp__agentmemory__memory_audit`             |
| Delete a specific memory | `mcp__agentmemory__memory_governance_delete` |

---

## 🔍 Project Detection

The `qmd-knowledge` skill auto-detects the project from:

1. `QMD_PROJECT` env var (if set)
2. Git repository name
3. Current directory name

Knowledge is stored in `~/.ai-knowledges/{project-name}/`

---

## 🔗 See Also

- [qmd GitHub](https://github.com/tobi/qmd) - qmd tool documentation
