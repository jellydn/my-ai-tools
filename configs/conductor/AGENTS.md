# 🤖 Conductor Agent Guidelines

## Communication

Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md files if present, and use their ubiquitous language.

Conductor orchestrates parallel AI coding agents (Claude Code, Codex, Cursor, OpenCode) in isolated workspaces with automatic branch management, diff review, and merge workflows.

## Key Concepts

- **Workspaces** — Each task gets its own isolated workspace with a separate branch, working tree, and agent session
- **Harnesses** — Claude Code, Codex, Cursor, and OpenCode are supported agent runtimes
- **MCP** — Agent-specific MCP configs apply per harness (Claude Code uses `.mcp.json`, Codex uses `~/.codex/config.toml`, Cursor uses `.cursor/mcp.json`)

## Configuration

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Scope searches and file reads to the task. Limit command output with filters and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.
- Load supplemental guidance only when the task requires it. Start a fresh session when switching to unrelated work.

## Learning Recording

Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.

After fixing a bug (confirmed by human), introducing a new tech choice, or encountering something important, ask the user:

> "Would you like me to record this as a learning?"

If yes:
- **qmd** (durable) — project-specific gotchas, architecture decisions, conventions
- **agentmemory** (session) — transient context only the current session needs

- Project settings: `.conductor/settings.toml` in repo root
- User settings: `~/.conductor/settings.toml`
- Local overrides: `.conductor/settings.local.toml`

See the full [Conductor docs](https://www.conductor.build/docs) for details.
