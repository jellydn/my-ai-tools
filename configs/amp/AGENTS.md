# 📋 Amp Agent Guidelines

## Communication

Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md files if present, and use their ubiquitous language.

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

## AI Tool Guidelines

- Use the fff MCP tools for all file search operations instead of default tools.
- Use the sem MCP tools for semantic version control and git operations.
- When using bash commands for file/content search, prefer `fd` (fdfind) and `rg` (ripgrep) over standard `find` and `grep` for better performance and git-awareness.

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Scope searches and file reads to the task. Limit command output with filters and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.
- Load supplemental guidance only when the task requires it. Start a fresh session when switching to unrelated work.

## General Practices

- Read `~/.ai-tools/best-practices.md` only when the repository lacks equivalent guidance or the task needs its detailed workflow.
- Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.
- Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing git operations.
- Always propose a plan before edits. Use phases to break down tasks into manageable steps.
- Run typecheck, lint and biome on js/ts file changes after finish
- Prefer to use Bun to run scripts if possible, otherwise use tsx to run ts files.
- Ask before destructive operations — don't guess safety
- Code is communication — prefer clarity and simplicity
- Self-documenting code through meaningful names and structure
- Modular design that can evolve
- Comments explain why, not what
