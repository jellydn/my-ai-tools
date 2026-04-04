# Technology Stack

## Languages & Runtimes

| Language | Version | Purpose |
|----------|---------|---------|
| **Shell (Bash)** | POSIX-compliant | Main installer scripts (`cli.sh`, `generate.sh`) |
| **TypeScript** | ESNext | Claude hooks (`configs/claude/hooks/`) |
| **JavaScript** | ES2022+ | Plugin configurations, MCP server configs |

## Core Technologies

### Runtime Environments
- **Bun** (preferred) - JavaScript runtime for running hooks and scripts
- **Node.js** (fallback) - Alternative runtime
- **Python3** - YAML validation, general scripting support
- **Go** - gofmt formatter for Go files

### Package Managers
- **npm** - Package installation for AI tools and formatters
- **bun** - Fast JavaScript runtime and package manager
- **cargo** - Rust formatter (stylua) installation
- **mise** - Tool version management

## AI Coding Tools

| Tool | Config Location | Description |
|------|-----------------|-------------|
| **Claude Code** | `configs/claude/` | Primary AI coding assistant |
| **OpenCode** | `configs/opencode/` | OpenAI-powered assistant |
| **Amp** | `configs/amp/` | Modular AI coding tool |
| **CCS** | `configs/ccs/` | Claude Code Switch - multi-provider |
| **Gemini CLI** | `configs/gemini/` | Google Gemini CLI |
| **Codex CLI** | `configs/codex/` | OpenAI Codex CLI |
| **Pi** | `configs/pi/` | Agentic coding tool |
| **Copilot CLI** | `configs/copilot/` | GitHub Copilot CLI |
| **Cursor Agent** | `configs/cursor/` | Cursor Agent CLI |
| **Kilo CLI** | `configs/kilo/` | OpenCode-based CLI |
| **Factory Droid** | `configs/factory/` | Factory AI agent |
| **AI Launcher** | `configs/ai-launcher/` | Tool switcher |

## MCP Servers (Model Context Protocol)

| Server | Package | Purpose |
|--------|---------|---------|
| **context7** | `@upstash/context7-mcp` | Documentation lookup |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | Multi-step reasoning |
| **qmd** | `qmd` | Knowledge management |
| **chrome-devtools** | `chrome-devtools-mcp` | Browser automation |

## Formatters & Linters

| Tool | Files | Language |
|------|-------|----------|
| **biome** | `.ts`, `.tsx`, `.js`, `.jsx` | TypeScript/JavaScript |
| **gofmt** | `.go` | Go |
| **prettier** | `.md`, `.mdx` | Markdown |
| **ruff** | `.py` | Python |
| **rustfmt** | `.rs` | Rust |
| **shfmt** | `.sh` | Shell scripts |
| **stylua** | `.lua` | Lua |

## Configuration Formats

| Format | Usage |
|--------|-------|
| **JSON** | Claude settings, MCP servers, general configs |
| **YAML** | CCS configuration (`config.yaml`) |
| **TOML** | Gemini commands, Codex config |
| **Markdown** | Documentation, agents, skills |

## Key Dependencies

### Package.json Dependencies
- `.opencode/package.json`: `@opencode-ai/plugin` (v1.3.7)
- `configs/claude/hooks/package.json`: `bun-types`, `@types/node`

### Shell Script Dependencies
- **jq** - JSON parsing (required)
- **git** - Version control (required)
- **curl** - Network requests
- **ripgrep** - Text search

## Project Structure

```
my-ai-tools/                  # Root configuration repository
├── cli.sh                    # Installation script
├── generate.sh               # Export script
├── install.sh                # Remote installer
├── configs/                  # Source configurations
│   ├── claude/              # Claude Code config
│   ├── opencode/            # OpenCode config
│   ├── amp/                 # Amp config
│   ├── ccs/                 # CCS config
│   ├── gemini/              # Gemini CLI config
│   ├── codex/               # Codex CLI config
│   ├── factory/             # Factory Droid config
│   └── ...
├── skills/                   # Claude skills for distribution
│   ├── codemap/
│   ├── qmd-knowledge/
│   ├── prd/
│   └── ...
├── lib/
│   └── common.sh            # Shared shell functions
└── tests/                    # Test files
```

## Prerequisites

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **jq** - JSON parsing
- **Claude Code subscription** - Or use CCS with affordable providers
