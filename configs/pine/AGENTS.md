# All PINE agents

Use ASD-STE100 Simplified Technical English. Be practical, concise, and verify important results.

## Shared repository practices

- Read `~/.ai-tools/best-practices.md` when a task needs the detailed workflow.
- Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing Git operations.
- Read `~/.ai-tools/agent-memory.md` before deciding whether to persist a learning.
- Ask before destructive operations; do not guess safety.
- Keep changes focused and test them before reporting completion.

## Tool defaults

Use PINE's built-in web and browser MCP servers for web research. Use the configured MCP servers for file search, code intelligence, memory, and semantic Git operations when available. Prefer `fff`, `codebase-memory-mcp`, and `sem` over ad-hoc shell work for those tasks.

The shared skills installed by my-ai-tools are available through `~/.agents/skills`. Read a skill's `SKILL.md` when its task matches the work.
