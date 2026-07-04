---
title: "ctx — Agent-History Search"
type: entity
tags: [tool, cli, search]
updated: 2026-07-04
---

# ctx

Open-source CLI tool ([ctx.rs](https://ctx.rs)) that indexes past coding-agent sessions into local SQLite, enabling search, inspection, and citation of prior work.

## Integration in my-ai-tools

ctx was added as a first-class tool in PR #282:

- **Installer**: `install_ctx()` in `lib/install.sh` — Unix via `curl | sh`, Windows PowerShell fallback
- **Config sync**: `copy_ctx_configs()` in `cli.sh`, `generate_ctx_configs()` in `generate.sh`
- **Backup**: `~/.ctx/` included in `backup_configs()`
- **MCP**: Read-only MCP server (`ctx mcp serve`) configured for all 15+ tools via central registry

## MCP Tools

| Tool | Description |
|------|-------------|
| `status` | Index status |
| `sources` | List discovered history sources |
| `search` | Search by query or file path |
| `sql` | Run read-only SQL against index |
| `show_session` | Get session transcript |
| `show_event` | Get event with surrounding context |

## Related

- [[mcp-registry]] — Central MCP server registry
- [[my-ai-tools-repo]] — Monorepo structure
