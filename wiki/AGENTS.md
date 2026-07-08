# LLM Wiki — Agent Instructions

## What This Is

This wiki is a persistent, compounding knowledge base for **my-ai-tools** — a monorepo for managing configuration across 14+ AI coding assistants (Claude Code, OpenCode, Amp, Codex, Gemini CLI, Pi, Cursor, etc.).

## How to Work With This Wiki

The wiki is a set of markdown files maintained by the LLM. Follow these rules:

### Operations

- **`/llm-wiki init`** — Initialize the wiki structure
- **`/llm-wiki ingest <source>`** — Integrate a new source file
- **`/llm-wiki query <question>`** — Answer using wiki knowledge
- **`/llm-wiki lint`** — Health-check for contradictions, orphans, gaps
- **`/llm-wiki status`** — Show wiki summary

### Conventions

- **Immutable sources**: Never modify files in `raw/`. Sources are append-only.
- **One ingest at a time**: Read, summarize, ask for emphasis, then create/update 5–15 pages.
- **Cross-references**: Use `[[Page Name]]` wiki links. Link on first mention per page.
- **Contradictions**: Add `> [!NOTE] Contradiction` blocks when new sources conflict with existing content.
- **Log every operation**: Append to `wiki/log.md` after every ingest, query (if filed), or lint.
- **Keep index current**: Every new or changed page must appear in `wiki/index.md`.
- **File good answers**: Valuable query results should become wiki pages.

### Project Context

This wiki is part of the **my-ai-tools** repo. See the root [`AGENTS.md`](../AGENTS.md) for project-wide conventions (bash scripting, git safety, testing with bats).
