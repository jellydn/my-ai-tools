# 🤖 Conductor Agent Guidelines

Conductor orchestrates parallel AI coding agents (Claude Code, Codex, Cursor, OpenCode) in isolated workspaces with automatic branch management, diff review, and merge workflows.

## Key Concepts

- **Workspaces** — Each task gets its own isolated workspace with a separate branch, working tree, and agent session
- **Harnesses** — Claude Code, Codex, Cursor, and OpenCode are supported agent runtimes
- **MCP** — Agent-specific MCP configs apply per harness (Claude Code uses `.mcp.json`, Codex uses `~/.codex/config.toml`, Cursor uses `.cursor/mcp.json`)

## Configuration

## Learning Recording

Read @~/.ai-tools/MEMORY.md and @~/.ai-tools/agent-memory.md for the full decision rule.

After fixing a bug (confirmed by human), introducing a new tech choice, or encountering something important, ask the user:

> "Would you like me to record this as a learning?"

If yes:
- **qmd** (durable) — project-specific gotchas, architecture decisions, conventions
- **agentmemory** (session) — transient context only the current session needs

- Project settings: `.conductor/settings.toml` in repo root
- User settings: `~/.conductor/settings.toml`
- Local overrides: `.conductor/settings.local.toml`

See the full [Conductor docs](https://www.conductor.build/docs) for details.
