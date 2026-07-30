# 🤖 Antigravity CLI Agent Guidelines

## AI Tool Guidelines

- Use the fff MCP tools for all file search operations instead of default tools.
- Use the sem MCP tools for semantic version control and git operations.

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
- Never run destructive commands.
- Use our conventions for file names, tests, and commands.
- Keep your code clean and organized. Do not over-engineer solutions or overcomplicate things unnecessarily.
- Write clear and concise code. Avoid unnecessary complexity and redundancy.
- Use meaningful variable and function names.
- Prefer self-documenting code. Write comments and documentation where necessary.
- Keep your code modular and reusable. Avoid tight coupling and excessive dependencies.
