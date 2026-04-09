# Tools Configuration

This section documents each AI tool's configuration in the repository.

## Overview

The repository manages configurations for 12+ AI coding tools. Each tool has its own directory under `configs/` with tool-specific files.

## Tool Directories

| Directory | AI Tool | Status |
|-----------|---------|--------|
| `configs/claude/` | Claude Code | Primary |
| `configs/opencode/` | OpenCode | Primary |
| `configs/amp/` | Amp | Primary |
| `configs/ccs/` | CCS | Primary |
| `configs/gemini/` | Gemini CLI | Primary |
| `configs/codex/` | Codex CLI | Primary |
| `configs/kilo/` | Kilo CLI | Primary |
| `configs/pi/` | Pi | Primary |
| `configs/copilot/` | GitHub Copilot CLI | Primary |
| `configs/cursor/` | Cursor Agent CLI | Primary |
| `configs/factory/` | Factory Droid | Primary |
| `configs/ai-launcher/` | AI Launcher | Primary |
| `configs/mempalace/` | MemPalace | Support |

## Common Patterns

Each tool configuration typically includes:

- **Settings** — Main configuration file (JSON, YAML, or TOML)
- **MCP Servers** — Any MCP server configurations
- **Agents** — Custom agent definitions (if supported)
- **Commands** — Custom slash commands (if supported)
- **Skills** — Tool-specific skills
- **Hooks** — Pre/Post tool hooks (if supported)

## Shared Components

| Component | Description |
|-----------|-------------|
| `configs/best-practices.md` | Software development guidelines |
| `configs/git-guidelines.md` | Git safety guidelines |
| `skills/` | Local skills for distribution |
| `lib/common.sh` | Shared shell utilities |

## Installation Priority

The `cli.sh` script installs tools in this order:

1. Prerequisites (jq, biome, formatters)
2. Claude Code (most comprehensive)
3. OpenCode
4. Amp
5. CCS
6. Gemini CLI
7. Codex CLI
8. Kilo CLI
9. Pi
10. GitHub Copilot CLI
11. Cursor Agent CLI
12. Factory Droid
13. AI Launcher
