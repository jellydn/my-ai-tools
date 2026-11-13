# OpenCode Global Guidelines

## Communication

Use ASD-STE100 Simplified Technical English. Read a relevant `CONTEXT.md` when it governs terms or behavior you change.

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Read only task-relevant files and instructions. Do not preload repository maps, architecture docs, memory, or skills.
- Scope searches and command output with paths, filters, and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.

## General Practices

- Read `~/.ai-tools/best-practices.md` only when the repository lacks equivalent guidance or the task needs its detailed workflow.
- Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.
- Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing git operations.
- Ask before destructive operations. Prefer clear, simple, self-documenting code.
- Run the repository's focused tests, typecheck, and lint checks after changes.

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Prefer `try . <name>` for a worktree from the current repository, `try clone <url> [name]` for an external repository, and `try new <name>` for a fresh experiment.
- `try` creates `$TRY_PATH/YYYY-MM-DD-<name>` (default `TRY_PATH`: `~/src/tries`) and changes directory only in the invoking shell. Use the printed path in later commands.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments in `try`-managed directories instead of ad hoc `/tmp` folders. Fall back to `git worktree add -b <branch> <path>` only when `try` is unavailable or unsuitable.
