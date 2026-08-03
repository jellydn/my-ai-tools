# 🤖 Reasonix Agent Guidelines

Reasonix is a DeepSeek-native terminal coding agent with an append-only loop
aligned to DeepSeek's prefix cache. Long sessions keep 90%+ cache hit and
input-token cost collapses to ~1/5. https://reasonix.io

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

## Reasonix-specific practices

- Keep the session running — context is append-only, so every new turn starts
  from a cache hit instead of a cold start. Avoid `/clear` mid-task.
- Run `/init` once per project to seed project memory (`REASONIX.md` /
  `AGENTS.md`); subsequent turns reuse the warm prefix.
- Use `/plan` (or `Shift+Tab` → Plan) for long-horizon work; permissions and
  the workspace sandbox still govern every tool call.
- Prefer `reasonix run -y "<task>"` for headless unattended writes; plain
  `reasonix run` fails closed when a writer needs approval.
- MCP tools surface as `mcp__<server>__<tool>`. MCP prompts become
  `/mcp__server__prompt` slash commands; resources are `@server:uri`.
- Project-level `.mcp.json` (Claude Code `mcpServers` schema) is read as-is
  from the repo root; `reasonix.toml` wins on name collisions.

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Scope searches and file reads to the task. Limit command output with filters and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.
- Load supplemental guidance only when the task requires it. Start a fresh session when switching to unrelated work.
