# PINE tooling

PINE is configured with the same shared MCP set as the other coding agents:

- `web`, `browser`, and `computer` (PINE built-ins)
- `context7`, `sequential-thinking`, `qmd`, `codebase-memory-mcp`, `fff`
- `react-grab-mcp`, `logpilot`, `agentmemory`, `sem`, and `ctx`

The installer maps the universal skill directory `~/.agents/skills` into PINE through `pine.json`. MCP commands that are not installed are kept configured but will be unavailable until their dependency is installed.
