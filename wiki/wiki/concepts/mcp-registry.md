---
title: "MCP Registry"
type: concept
tags: [mcp, integration]
updated: 2026-07-04
---

# MCP Registry

The central MCP (Model Context Protocol) server registry at `configs/mcp-registry.json` drives MCP server installation across all supported AI tools.

## Registered Servers

| Server                | Purpose                                | How to Run                                                |
| --------------------- | -------------------------------------- | --------------------------------------------------------- |
| `context7`            | Documentation lookup for any library   | `npx -y @upstash/context7-mcp`                            |
| `sequential-thinking` | Multi-step reasoning                   | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| `qmd`                 | Knowledge management with AI search    | `qmd mcp`                                                 |
| `fff`                 | Fast file search with frecency ranking | `fff-mcp`                                                 |
| `react-grab-mcp`      | React component capture and inspection | `npx -y @react-grab/mcp --stdio`                          |
| `logpilot`            | AI-powered log analysis                | `logpilot mcp-server`                                     |
| `agentmemory`         | Persistent memory for agents           | `npx -y @agentmemory/mcp`                                 |
| `sem`                 | Semantic version control               | `sem-mcp`                                                 |
| `ctx`                 | Local agent-history search             | `ctx mcp serve`                                           |

## Propagation

The `install_mcp_servers_from_registry()` function reads from this registry to configure MCP for Claude Code, OpenCode, Codex, Amp, Gemini, Antigravity, CommandCode, Copilot, Cursor, Factory, Cline, Grok, MiMo-Code, Qoder CLI, and Kiro.

Individual tool MCP config files also receive direct entries for offline/copy-based setup.

## Related

- [[ctx]] — Agent-history search MCP server
- [[my-ai-tools-repo]] — Monorepo structure
