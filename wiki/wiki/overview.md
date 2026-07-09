---
title: "Overview"
type: overview
tags: [my-ai-tools]
updated: 2026-07-10
---

# Overview

This wiki tracks knowledge about **my-ai-tools** — a monorepo for managing configuration across 20+ AI coding assistants (Claude Code, OpenCode, Amp, Codex, Gemini, Pi, Cursor, Cline, Factory Droid, Grok, Kimi Code, MiMo-Code, herdr, Qoder CLI, Kiro CLI, Codiff, and others).

## Scope

The wiki is intended to compound understanding of:

- Tool-specific configs under `configs/<tool>/`
- Shared infrastructure: MCP registry, skills, hooks, install/export scripts
- Workflows: `cli.sh` install, `generate.sh` export, testing with bats and microsandbox
- Cross-tool patterns: agents, plugins, delegation, and safety hooks
- **New (2026-07-10)**: Subagent infrastructure, Agent Teams, community skills ecosystem

## Current State

Two sources ingested: the project README.md (initial + re-ingest 2026-07-10). The wiki now covers:

- **6 tool entities**: my-ai-tools-repo, ctx, pi-agent, mimo-code, herdr, subagent-infrastructure
- **3 concepts**: mcp-registry, agent-teams, community-skills-ecosystem
- **0 synthesis pages** (queries not yet filed)

### Wiki files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent instructions — how to work with this wiki |
| `CLAUDE.md` | Schema: wiki conventions and per-operation workflows |
| `wiki/index.md` | Catalog of all generated pages |
| `wiki/log.md` | Append-only operation log |
| `wiki/overview.md` | Big-picture synthesis |
| `wiki/sources/readme.md` | README.md source summary (re-ingested 2026-07-10) |
| `wiki/entities/my-ai-tools-repo.md` | Monorepo structure |
| `wiki/entities/ctx.md` | Agent-history search CLI |
| `wiki/entities/pi-agent.md` | Pi coding agent |
| `wiki/entities/mimo-code.md` | Xiaomi's persistent-memory coding agent |
| `wiki/entities/herdr.md` | Terminal-native agent multiplexer |
| `wiki/entities/subagent-infrastructure.md` | Standardized agents across 12 tools |
| `wiki/concepts/mcp-registry.md` | Central MCP server registry |
| `wiki/concepts/agent-teams.md` | Multi-agent orchestration patterns |
| `wiki/concepts/community-skills-ecosystem.md` | 17 community skill repos |

## Ingested Sources

- `README.md` (2026-07-04, re-ingested 2026-07-10) — Project overview, 20+ tools, subagent infrastructure, community skills

## How to Grow This Wiki

1. Drop immutable source files into `wiki/raw/`
2. Run `/llm-wiki ingest <file>` one source at a time
3. Use `/llm-wiki query <question>` once pages exist
4. Run `/llm-wiki lint` periodically to catch drift and gaps
