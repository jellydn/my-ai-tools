---
title: "my-ai-tools Repo"
type: entity
tags: [project, monorepo]
updated: 2026-07-04
---

# my-ai-tools Repo

A monorepo for comprehensive configuration management across 20+ AI coding assistants. Maintained by [jellydn](https://github.com/jellydn).

## Overview

The repo provides bidirectional config sync — `cli.sh` installs managed configs to user home directories, `generate.sh` exports live local configs back into the repo. All configs are versioned, validated, and reviewed.

## Key Characteristics

- **Language**: Bash scripts + JSON/TOML configs
- **CI**: GitHub Actions — runs BATS tests, config validation, pre-commit hooks
- **Formatting**: biome (tabs, 120 line width, double quotes)
- **Testing**: bats-core functional tests in `tests/`
- **Sandboxing**: microsandbox (Ubuntu microVMs) for testing

## Structure

- `cli.sh` — main install entry point
- `generate.sh` — export entry point
- `lib/` — shared bash libraries (common.sh, install.sh, require_bash.sh)
- `configs/<tool>/` — per-tool configuration files
- `configs/mcp-registry.json` — central MCP server definitions
- `tests/` — BATS functional tests
- `skills/` — local marketplace plugins

## Related

- [[mcp-registry]] — Central MCP server registry
- [[ctx]] — Agent-history search
- [[pi-agent]] — Pi coding agent
