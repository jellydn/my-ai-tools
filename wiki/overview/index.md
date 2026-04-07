# my-ai-tools Overview

my-ai-tools is a comprehensive configuration management repository for AI coding tools. It enables users to replicate a complete setup for Claude Code, OpenCode, Amp, CCS, Gemini CLI, and many other AI assistants with custom configurations, MCP servers, skills, plugins, and commands.

## What This Repository Provides

- **One-line installer** — Get started in seconds with curl-based installation
- **Bidirectional sync** — Install configs to your home directory or export your current setup back to the repo
- **Multiple AI tool support** — Configure and manage 18+ AI coding assistants
- **MCP Server integration** — Context7, Sequential-thinking, qmd, fff, MemPalace
- **Custom agents and skills** — Pre-configured for maximum productivity
- **Auto-format hooks** — Format code automatically after edits (biome, gofmt, prettier, ruff, rustfmt, shfmt, stylua)
- **Git Guard hooks** — Prevent dangerous git commands

## Supported AI Tools

| Tool | Config Path | Description |
|------|-------------|-------------|
| Claude Code | `configs/claude/` | Anthropic's AI coding assistant |
| OpenCode | `configs/opencode/` | OpenAI-powered coding assistant |
| Amp | `configs/amp/` | Modular's AI coding assistant |
| CCS | `configs/ccs/` | Claude Code Switch - profile manager |
| Gemini CLI | `configs/gemini/` | Google's AI agent |
| Codex CLI | `configs/codex/` | OpenAI's command-line coding assistant |
| Kilo CLI | `configs/kilo/` | OpenCode-based CLI with 300+ models |
| Pi | `configs/pi/` | Agentic coding workflows |
| GitHub Copilot CLI | `configs/copilot/` | Copilot in the terminal |
| Cursor Agent CLI | `configs/cursor/` | Cursor's background agent |
| Factory Droid | `configs/factory/` | Factory's AI coding agent |
| AI Launcher | `configs/ai-launcher/` | Fast launcher for switching tools |

## Quick Links

- [Getting Started](./getting-started.md) — Installation and setup
- [Architecture](./architecture.md) — System design and data flows
- [Tools Configuration](../tools/index.md) — Individual AI tool configs
- [Skills Reference](../skills/index.md) — Available local skills
- [Infrastructure](../infrastructure/index.md) — CLI scripts and hooks
