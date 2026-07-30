## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Scope searches and file reads to the task. Limit command output with filters and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.
- Load supplemental guidance only when the task requires it. Start a fresh session when switching to unrelated work.
