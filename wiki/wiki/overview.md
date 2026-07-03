---
title: "Overview"
type: overview
tags: [my-ai-tools]
updated: 2026-07-03
---

# Overview

This wiki tracks knowledge about **my-ai-tools** — a monorepo for managing configuration across 14+ AI coding assistants (Claude Code, OpenCode, Amp, Codex, Gemini, Pi, Cursor, and others).

## Scope

The wiki is intended to compound understanding of:

- Tool-specific configs under `configs/<tool>/`
- Shared infrastructure: MCP registry, skills, hooks, install/export scripts
- Workflows: `cli.sh` install, `generate.sh` export, testing with bats and microsandbox
- Cross-tool patterns: agents, plugins, delegation, and safety hooks

## Current State

No sources have been ingested yet. The wiki shell is initialized and ready for raw documents.

### Wiki files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent instructions — how to work with this wiki |
| `CLAUDE.md` | Schema: wiki conventions and per-operation workflows |
| `wiki/index.md` | Catalog of all generated pages |
| `wiki/log.md` | Append-only operation log |
| `wiki/overview.md` | Big-picture synthesis |

## Good First Sources

Candidates to add to `wiki/raw/` and ingest:

- `README.md` — project overview and feature matrix
- `AGENTS.md` — agent workflow and conventions
- `configs/mcp-registry.json` — central MCP server definitions
- `configs/best-practices.md` and `configs/git-guidelines.md`
- PR-specific notes or design docs for active work (e.g. PR #279)

## How to Grow This Wiki

1. Drop immutable source files into `wiki/raw/`
2. Run `/llm-wiki ingest <file>` one source at a time
3. Use `/llm-wiki query <question>` once pages exist
4. Run `/llm-wiki lint` periodically to catch drift and gaps
