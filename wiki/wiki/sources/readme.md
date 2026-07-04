---
title: "README.md — my-ai-tools Main Documentation"
source: "https://github.com/jellydn/my-ai-tools"
ingested: 2026-07-04
---

# README.md — my-ai-tools Main Documentation

The primary documentation source for the **my-ai-tools** monorepo. Describes the complete configuration management system for AI coding assistants.

## Summary

my-ai-tools is a monorepo that manages configuration files for 20+ AI coding tools (Claude Code, OpenCode, Amp, Pi, Codex, Cursor, Cline, Factory Droid, Grok, Kimi Code, and more). It provides:

- **One-line installer** (`curl -fsSL https://ai-tools.itman.fyi/install.sh | bash`)
- **Bidirectional sync** — `cli.sh` installs configs, `generate.sh` exports local configs back to the repo
- **Central MCP registry** — shared MCP server configs across tools
- **Skill marketplace** — 30+ community skills for agentic workflows
- **Pre-commit hooks** — trailing whitespace, YAML, oxfmt, end-of-file fixes

## Key Features

- 30+ **skills** for agentic coding (adr, codemap, prd, tdd, slop, docs-update, llm-wiki, etc.)
- **MCP Servers**: context7, sequential-thinking, qmd, fff, react-grab-mcp, logpilot, agentmemory, sem, ctx
- **Agent Teams** — parallel multi-agent orchestration (Conductor, Orca)
- **Plugin systems** across multiple tools (Pi packages, Claude plugins, OpenCode plugins)
- **Backup & restore** — `cli.sh` creates timestamped backups, keeps last 5
- **Security** — pre-commit hooks prevent dangerous git operations

## Tools Covered

| Category | Tools |
|----------|-------|
| Primary agents | Claude Code, OpenCode, Codex, Pi, Amp, Cursor, Cline |
| Specialized | Factory Droid, Grok, Kimi Code, Command Code, Kilo CLI |
| Emerging | Copilot CLI, Gemini CLI (deprecated), Antigravity CLI, Qoder CLI, Kiro CLI, Codiff, ctx |
| Review | Open Code Review, CCS |

## Directory Structure

```
cli.sh, generate.sh         # Entry points
lib/                        # Shared utilities (common.sh, install.sh)
configs/<tool>/             # Per-tool config directories
configs/mcp-registry.json   # Central MCP server registry
skills/                     # Local marketplace plugins
tests/                      # BATS functional tests
```

## Commands

- `./cli.sh --dry-run` — preview install
- `./cli.sh` — install configs to home directory
- `./generate.sh --dry-run` — preview export
- `./generate.sh` — export local configs to repo
- `biome check .` — code formatting (tabs, 120 line width, double quotes)
- `bats tests/` — run functional tests

## Related Pages

- [[my-ai-tools-repo]] — Monorepo structure and conventions
- [[ctx]] — Local agent-history search CLI
- [[mcp-registry]] — Central MCP server configuration
- [[pi-agent]] — AI coding agent for agentic workflows
