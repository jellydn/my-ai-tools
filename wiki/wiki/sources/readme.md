---
title: "README.md — my-ai-tools Main Documentation"
source: "https://github.com/jellydn/my-ai-tools"
ingested: 2026-07-04
reingested: 2026-07-10
---

# README.md — my-ai-tools Main Documentation

The primary documentation source for the **my-ai-tools** monorepo. Describes the complete configuration management system for 20+ AI coding assistants.

## Summary

my-ai-tools is a monorepo that manages configuration files for 20+ AI coding tools (Claude Code, OpenCode, Amp, Pi, Codex, Cursor, Cline, Factory Droid, Grok, Kimi Code, MiMo-Code, herdr, Qoder CLI, Kiro CLI, Codiff, and more). It provides:

- **One-line installer** (`curl -fsSL https://ai-tools.itman.fyi/install.sh | bash`)
- **Bidirectional sync** — `cli.sh` installs configs, `generate.sh` exports local configs back to the repo
- **Central MCP registry** — shared MCP server configs across tools
- **Skill marketplace** — 27+ local skills + 17 community skill repos
- **Subagent infrastructure** — standardized agents (code-reviewer, test-generator, documentation-writer, ai-slop-remover, security-audit) across 12 tools
- **Pre-commit hooks** — trailing whitespace, YAML, oxfmt, end-of-file fixes

## Key Features

- 27+ **skills** for agentic coding (adr, codemap, prd, tdd, slop, docs-update, llm-wiki, etc.)
- **MCP Servers**: context7, sequential-thinking, qmd, fff, react-grab-mcp, logpilot, agentmemory, sem, ctx, codebase-memory-mcp
- **Agent Teams** — parallel multi-agent orchestration via feature-team-coordinator
- **Plugin systems** across multiple tools (Pi packages, Claude plugins, OpenCode plugins)
- **Backup & restore** — `cli.sh` creates timestamped backups, keeps last 5
- **Security** — pre-commit hooks prevent dangerous git operations

## Tools Covered (20+)

| Category       | Tools                                                                                   |
| -------------- | --------------------------------------------------------------------------------------- |
| Primary agents | Claude Code, OpenCode, Codex, Pi, Amp, Cursor, Cline                                    |
| Specialized    | Factory Droid, Grok, Kimi Code, Command Code, Kilo CLI                                  |
| Emerging       | Copilot CLI, Antigravity CLI, MiMo-Code, Qoder CLI, Kiro CLI, Codiff, ctx, herdr        |
| Review         | Open Code Review, CCS                                                                   |
| Deprecated     | Gemini CLI (Google One/unpaid tiers, June 18 2026 cutoff)                                |

## New Since Last Ingest (2026-07-10)

- **Subagent infrastructure** — 5 standardized agents across 12 tools (PR #293)
- **Codemap** — 7-document codebase analysis in `.planning/codebase/`
- **MiMo-Code**, **herdr**, **Qoder CLI**, **Kiro CLI**, **Codiff** — new tool sections
- **Agent Teams** — multi-agent coordination patterns
- **Community skills expanded** — 17 repos, 97+ skills from jezweb
- **15 projects built with AI** — real-world examples

## Related Pages

- [[my-ai-tools-repo]] — Monorepo structure and conventions
- [[ctx]] — Local agent-history search CLI
- [[mcp-registry]] — Central MCP server configuration
- [[pi-agent]] — AI coding agent for agentic workflows
- [[mimo-code]] — Xiaomi's persistent-memory coding agent
- [[herdr]] — Terminal-native agent multiplexer
- [[qoder-cli]] — Qoder CLI
- [[kiro-cli]] — Kiro CLI with ACP support
- [[codiff]] — Code diff analysis tool
- [[subagent-infrastructure]] — Standardized agents across 12 tools
- [[agent-teams]] — Multi-agent orchestration patterns
- [[community-skills-ecosystem]] — 17 community skill repos
