# 🤖 Conductor Agent Guidelines

Conductor orchestrates parallel AI coding agents (Claude Code, Codex, Cursor, OpenCode) in isolated workspaces with automatic branch management, diff review, and merge workflows.

## Key Concepts

- **Workspaces** — Each task gets its own isolated workspace with a separate branch, working tree, and agent session
- **Harnesses** — Claude Code, Codex, Cursor, and OpenCode are supported agent runtimes
- **MCP** — Agent-specific MCP configs apply per harness (Claude Code uses `.mcp.json`, Codex uses `~/.codex/config.toml`, Cursor uses `.cursor/mcp.json`)

## Configuration

- Project settings: `.conductor/settings.toml` in repo root
- User settings: `~/.conductor/settings.toml`
- Local overrides: `.conductor/settings.local.toml`

See the full [Conductor docs](https://www.conductor.build/docs) for details.
