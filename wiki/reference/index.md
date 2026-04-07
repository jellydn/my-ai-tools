# Reference

Technical reference for configuration and dependencies.

## Prerequisites

### Required

| Tool | Purpose | Installation |
|------|---------|--------------|
| Git | Version control | Platform package manager |
| Bun or Node.js | Runtime for scripts | bun.sh or nodejs.org |
| jq | JSON parsing | Platform package manager |
| Python 3.9+ | MemPalace requirement | python.org |

### Optional

| Tool | Purpose | File Types |
|------|---------|------------|
| biome | JavaScript/TypeScript formatting | .ts, .tsx, .js, .jsx |
| gofmt | Go formatting | .go |
| prettier | Markdown formatting | .md, .mdx |
| ruff | Python formatting | .py |
| rustfmt | Rust formatting | .rs |
| shfmt | Shell script formatting | .sh |
| stylua | Lua formatting | .lua |

## MCP Servers

### Official MCP Servers

| Server | Package | Purpose |
|--------|---------|---------|
| context7 | @upstash/context7-mcp | Documentation lookup |
| sequential-thinking | @modelcontextprotocol/server-sequential-thinking | Multi-step reasoning |
| qmd | qmd | Knowledge management |
| fff | fff-mcp | Fast file search |
| mempalace | mempalace | AI memory system |

### Installation Commands

```bash
# context7
npx -y @upstash/context7-mcp@latest

# sequential-thinking
npx -y @modelcontextprotocol/server-sequential-thinking

# qmd
qmd mcp

# fff
curl -fsSL https://dmtrKovalenko.dev/install-fff-mcp.sh | bash

# mempalace
pip3 install mempalace
```

## AI Tools Versions

| Tool | Minimum Version | Notes |
|------|-----------------|-------|
| Claude Code | Latest | Subscription required |
| OpenCode | Latest | API key required |
| Amp | Latest | API key required |
| CCS | Latest | Uses subscription or API |
| Gemini CLI | Latest | Free tier available |
| Codex CLI | Latest | Free tier available |
| Factory Droid | Latest | BYOK supported |

## Directory Conventions

| Location | Description |
|----------|-------------|
| `~/.claude/` | Claude Code config |
| `~/.config/opencode/` | OpenCode config |
| `~/.config/amp/` | Amp config |
| `~/.ccs/` | CCS config |
| `~/.gemini/` | Gemini CLI config |
| `~/.codex/` | Codex CLI config |
| `~/.config/kilo/` | Kilo CLI config |
| `~/.pi/` | Pi config |
| `~/.copilot/` | Copilot CLI config |
| `~/.cursor/rules/` | Cursor Agent config |
| `~/.factory/` | Factory Droid config |
