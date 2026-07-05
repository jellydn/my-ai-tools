---
title: "Overview"
type: overview
tags: [my-ai-tools]
updated: 2026-07-04
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

One source ingested: the project README.md. The wiki now covers the repository structure, MCP registry, ctx CLI, and Pi agent configuration.

### Wiki files

| File                                | Purpose                                              |
| ----------------------------------- | ---------------------------------------------------- |
| `AGENTS.md`                         | Agent instructions — how to work with this wiki      |
| `CLAUDE.md`                         | Schema: wiki conventions and per-operation workflows |
| `wiki/index.md`                     | Catalog of all generated pages                       |
| `wiki/log.md`                       | Append-only operation log                            |
| `wiki/overview.md`                  | Big-picture synthesis                                |
| `wiki/sources/readme.md`            | README.md source summary                             |
| `wiki/entities/my-ai-tools-repo.md` | Monorepo structure                                   |
| `wiki/entities/ctx.md`              | Agent-history search CLI                             |
| `wiki/entities/pi-agent.md`         | Pi coding agent                                      |
| `wiki/concepts/mcp-registry.md`     | Central MCP server registry                          |

## Ingested Sources

- `README.md` (2026-07-04) — Project overview, feature matrix, tool configs, docs, tests

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
