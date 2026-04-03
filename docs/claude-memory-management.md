# 🧠 Claude Code Memory Management

> Claude Code reads `CLAUDE.md` files from multiple locations and combines them into a persistent memory system. Understanding this hierarchy lets you give Claude the right context at the right scope.

## 📋 Overview

Claude Code loads memory from `CLAUDE.md` files found in:

1. **Global memory** — `~/.claude/CLAUDE.md` — loaded for every project
2. **Project memory** — `{project-root}/CLAUDE.md` — loaded when inside this project
3. **Local memory** — `{subdirectory}/CLAUDE.md` — loaded when working inside that subdirectory

All levels are merged together, with more specific (inner) files taking precedence when there is overlap.

---

## 🗂️ Memory Hierarchy

```
~/.claude/CLAUDE.md              ← Global: applies to all projects
{project-root}/CLAUDE.md         ← Project: applies to this project only
{project-root}/src/CLAUDE.md     ← Local: applies when working in src/
```

### Global memory (`~/.claude/CLAUDE.md`)

Use for personal preferences and cross-project conventions that should always be available:

- Preferred code style and formatting rules
- Favorite libraries or frameworks
- Personal workflow shortcuts
- Communication preferences (e.g. "keep answers concise")

### Project memory (`CLAUDE.md` in the repository root)

Commit this file to share context with your team:

- Architecture overview and key design decisions
- Conventions specific to this codebase
- Frequently referenced commands (`npm run dev`, `make test`, …)
- Known gotchas and quirks

### Local memory (`CLAUDE.md` in a subdirectory)

Add a `CLAUDE.md` to any subdirectory for tightly scoped context:

- Component or module-level guidelines
- Domain-specific terminology
- Patterns that only apply in that part of the codebase

---

## ✏️ Adding Memory

### Quick `/memory` command

The fastest way to add to your project's `CLAUDE.md` without leaving Claude Code:

```
/memory Add: always use pnpm instead of npm for this project
```

Claude writes the note into the appropriate `CLAUDE.md` file and confirms.

### Manually editing CLAUDE.md

Open any `CLAUDE.md` directly in your editor and add plain text, bullet points, or Markdown sections.

### Importing other files

Use the `@` import syntax inside `CLAUDE.md` to pull in additional files:

```md
@~/.ai-tools/best-practices.md
@~/.ai-tools/MEMORY.md
```

This keeps individual files focused while letting Claude see all relevant context.

---

## 🎯 Best Practices

### Keep memories focused and actionable

```md
# Good ✅
- Always run `bun run lint` before committing
- Use Zod for all runtime validation; never use `as` type casts

# Avoid ❌
- This project uses TypeScript and is a web application that does many things
```

### Separate concerns by level

| Concern                        | Where to put it          |
| ------------------------------ | ------------------------ |
| Personal preferences           | `~/.claude/CLAUDE.md`    |
| Project architecture/standards | `{root}/CLAUDE.md`       |
| Module-level patterns          | `{module}/CLAUDE.md`     |

### Review and prune regularly

Memory that is stale or wrong is worse than no memory. Periodically open `CLAUDE.md` and remove outdated entries.

### Commit project memory to git

```bash
# Track project-level CLAUDE.md with the rest of the code
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md with project conventions"
```

This ensures every team member (and every Claude Code session on any machine) loads the same project context.

### Keep global memory private

`~/.claude/CLAUDE.md` contains personal preferences. Do **not** copy it into the project root or commit it; it lives outside the repository.

---

## 🔗 Relationship with qmd Knowledge

`CLAUDE.md` provides **static, curated context** that is always in view. The [qmd knowledge system](qmd-knowledge-management.md) provides **searchable, growing knowledge** that Claude retrieves on demand.

Use them together:

| Tool        | Best for                                          |
| ----------- | ------------------------------------------------- |
| `CLAUDE.md` | Stable rules, conventions, and architecture notes |
| `qmd`       | Session learnings, issue notes, searchable history |

---

## 📖 Resources

- [Claude Code Memory documentation](https://docs.anthropic.com/en/docs/claude-code/memory)
- [qmd Knowledge Management](qmd-knowledge-management.md)
- [Best Practices](../configs/best-practices.md)
