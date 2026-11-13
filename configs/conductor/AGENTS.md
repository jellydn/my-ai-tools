# 🤖 Conductor Agent Guidelines

## Communication

Use ASD-STE100 Simplified Technical English. Read a relevant `CONTEXT.md` when it governs terms or behavior you change.

Conductor orchestrates parallel AI coding agents (Claude Code, Codex, Cursor, OpenCode) in isolated workspaces with automatic branch management, diff review, and merge workflows.

## Key Concepts

- **Workspaces** — Each task gets its own isolated workspace with a separate branch, working tree, and agent session
- **Harnesses** — Claude Code, Codex, Cursor, and OpenCode are supported agent runtimes
- **MCP** — Agent-specific MCP configs apply per harness (Claude Code uses `.mcp.json`, Codex uses `~/.codex/config.toml`, Cursor uses `.cursor/mcp.json`)

## Configuration

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Read only task-relevant files and instructions. Do not preload repository maps, architecture docs, memory, or skills.
- Scope searches and command output with paths, filters, and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.

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

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Load the shell integration in the shell that runs your commands: `eval "$(try init)"` for bash/zsh. Without it, `try` only prints shell commands. If the wrapper cannot run (for example, no `/dev/tty`), use the fallbacks below.
- Run `try . <name>` from the repository root for a worktree, or `try clone <url> [name]` for an external repository. Confirm that the new directory is a worktree or clone before editing; `try` can hide worktree creation failures. If creation fails, diagnose it and use the fallback with a new path.
- For a fresh experiment, run `try <name>` and press Ctrl-T in the interactive selector to create a directory; selecting an existing match does not create one. `try new <name>` is a search, not a creation subcommand. Without a terminal, create a new date-prefixed directory under `${TRY_PATH:-$HOME/src/tries}` with `mkdir` instead; choose an unused path.
- Worktrees and fresh experiments use date-prefixed names under `$TRY_PATH` (default: `~/src/tries`). A clone with a custom name uses that name without a date prefix; an unnamed clone uses `YYYY-MM-DD-<user>-<repo>`. Use the printed path in later commands; directory changes apply only to the invoking shell.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments under the tries directory instead of ad hoc `/tmp` folders. When `try` is unavailable or unsuitable, use `git worktree add -b <branch> <path>` for a repository with a commit, `git clone <url> <path>` for an external repository, or `mkdir` for a fresh experiment.
