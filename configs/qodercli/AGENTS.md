# 🤖 Qoder CLI Agent Guidelines

## Communication

Use ASD-STE100 Simplified Technical English. Read a relevant `CONTEXT.md` when it governs terms or behavior you change.

## Session Management with tmux

Run dev servers, tests, and interactive CLIs inside tmux with the **current directory name as the session name** for easy debugging:

```bash
SESSION=$(basename "$PWD")
tmux new -d -s "$SESSION" 2>/dev/null || true

# Run dev server with portless if available, otherwise fallback to npm
if command -v portless &>/dev/null; then
    tmux send-keys -t "$SESSION" 'portless run npm run dev' Enter
else
    tmux send-keys -t "$SESSION" 'npm run dev' Enter
fi

tmux capture-pane -p -t "$SESSION" -S -20  # check output
```

## 🔧 AI Tool Guidelines

- Use the fff MCP tools for all file search operations instead of default tools.
- Use the sem MCP tools for semantic version control and git operations.
- When using bash commands for file/content search, prefer `fd` (fdfind) and `rg` (ripgrep) over standard `find` and `grep` for better performance and git-awareness.

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Read only task-relevant files and instructions. Do not preload repository maps, architecture docs, memory, or skills.
- Scope searches and command output with paths, filters, and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.

## 📋 General Practices

- Read `~/.ai-tools/best-practices.md` only when the repository lacks equivalent guidance or the task needs its detailed workflow.
- Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.
- Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing git operations.
- Ask before destructive operations — don't guess safety
- Code is communication — prefer clarity and simplicity
- Self-documenting code through meaningful names and structure
- Modular design that can evolve
- Comments explain why, not what
- Run typecheck, lint and biome on js/ts file changes after finish.
- Prefer to use Bun to run scripts if possible, otherwise use tsx to run ts files.

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Prefer `try . <name>` for a worktree from the current repository, `try clone <url> [name]` for an external repository, and `try new <name>` for a fresh experiment.
- `try` creates `$TRY_PATH/YYYY-MM-DD-<name>` (default `TRY_PATH`: `~/src/tries`) and changes directory only in the invoking shell. Use the printed path in later commands.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments in `try`-managed directories instead of ad hoc `/tmp` folders. Fall back to `git worktree add -b <branch> <path>` only when `try` is unavailable or unsuitable.
