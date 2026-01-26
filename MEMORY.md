# MEMORY.md - AI Agent Knowledge Management

**Purpose**: Tell agents when and how to use qmd for persistent knowledge capture.

---

## When to Use qmd Knowledge

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

## How to Use qmd (via MCP Server)

When qmd MCP server is configured, you can autonomously:

### Search Knowledge

```
mcp__qmd__query - for best quality (hybrid search with reranking)
mcp__qmd__search - for fast keyword search
mcp__qmd__vsearch - for semantic similarity search
```

### Read Documents

```
mcp__qmd__get - get single document by path or docid
mcp__qmd__multi_get - get multiple by glob pattern
```

### Check Status

```
mcp__qmd__status - see collections and health
```

---

## What About Recording?

**DO NOT directly write to ~/.ai-knowledges/**

Instead, use the `qmd-knowledge` skill:

- Invoke via `/qmd-knowledge` slash command
- Agent will handle proper file creation and embedding updates

---

## Quick Reference

| Task             | Tool/Command           |
| ---------------- | ---------------------- |
| Search knowledge | `mcp__qmd__query`      |
| Get document     | `mcp__qmd__get`        |
| Record learning  | `/qmd-knowledge` skill |
| Check status     | `mcp__qmd__status`     |

---

## Project Detection

The `qmd-knowledge` skill auto-detects project from:

1. `QMD_PROJECT` env var (if set)
2. Git repository name
3. Current directory name

Knowledge is stored in `~/.ai-knowledges/{project-name}/`

---

## See Also

- [qmd GitHub](https://github.com/tobi/qmd) - qmd tool documentation
