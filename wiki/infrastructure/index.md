# Infrastructure

Scripts, hooks, and system infrastructure.

## Shell Scripts

| Script | Purpose |
|--------|---------|
| `cli.sh` | Main installation script - copies configs from repo to home |
| `generate.sh` | Export script - copies configs from home back to repo |
| `install.sh` | Direct installer for curl-based installation |
| `install.ps1` | PowerShell installer for Windows |
| `lib/common.sh` | Shared utilities for all scripts |

## Script Features

### Common Library (`lib/common.sh`)

- Color output functions
- Cross-platform path handling
- OS detection (Windows vs Unix)
- Temp directory management
- Dry-run execution wrapper

### CLI Script (`cli.sh`)

- Prerequisite checking (git, bun/node, jq)
- Config backup (keeps last 5 backups)
- Tool-specific installation
- MCP server registration
- Hook setup

### Generate Script (`generate.sh`)

- Reverse sync from home directory
- Config validation
- Backup before export

## Hooks System

### PostToolUse Hooks

Auto-format code after edits:
- biome (TypeScript/JavaScript)
- gofmt (Go)
- prettier (Markdown)
- ruff (Python)
- rustfmt (Rust)
- shfmt (Shell)
- stylua (Lua)

### PreToolUse Hooks

1. **Git Guard** (`configs/claude/hooks/`)
   - Blocks dangerous git commands
   - Prevents force push, hard reset, etc.

2. **WebSearch Transformer**
   - Transforms search queries

### Auto-Save Hooks

- Saves session context to MemPalace memory
- Configured for multiple AI tools

## MCP Server Configuration

MCP servers are configured per tool:

| Server | Purpose |
|--------|---------|
| context7 | Documentation lookup |
| sequential-thinking | Multi-step reasoning |
| qmd | Knowledge management |
| fff | Fast file search |
| mempalace | AI memory system |
