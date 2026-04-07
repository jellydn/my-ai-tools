# Lore

Timeline and history of the my-ai-tools codebase.

## Overview

my-ai-tools began as a personal configuration repository and evolved into a comprehensive setup guide for multiple AI coding tools. The repository has grown from supporting a single tool (Claude Code) to managing configurations for 12+ AI assistants.

## Major Eras

### Era 1: Initial Setup

The repository started as a configuration backup for Claude Code with:
- Basic settings.json
- MCP server configurations
- Custom commands and agents

### Era 2: Multi-Tool Expansion

Added support for multiple AI tools:
- **OpenCode** — OpenAI-powered assistant
- **Amp** — Modular's AI coding assistant
- **CCS** — Claude Code Switch for provider switching
- **Gemini CLI** — Google's AI agent
- **Codex CLI** — OpenAI's command-line tool

### Era 3: Skill Ecosystem

Developed a comprehensive skill system:
- Local marketplace skills (adr, codemap, handoffs, pickup, pr-review, prd, qmd-knowledge, ralph, slop, tdd)
- Integration with community skill repositories

### Era 4: AI Memory Integration

Integrated MemPalace AI memory system:
- Memory auto-save hooks for all tools
- Specialist agents pattern documentation
- MCP server integration across all tools

## Deprecated Features

### Claude-Mem

Originally used for knowledge management. Replaced by qmd-based knowledge system.

### Inline MCP Registration

Early MCP servers were registered directly in settings. Now uses dedicated mcp-servers.json for better organization.

## Longest-Standing Features

These features have survived multiple refactors:

1. **cli.sh** — Core installation script, continuously improved
2. **Claude Code configuration** — Most comprehensive setup
3. **PostToolUse hooks** — Auto-formatting system
4. **Git Guard** — Prevents destructive git commands

## Major Refactors

### Shell Script Quality

Refactored cli.sh and generate.sh:
- Added comprehensive error handling
- Improved cross-platform support
- Quality score improvements (98/100)

### Configuration Structure

Standardized configuration structure across tools:
- Consistent file naming
- Shared best practices
- Unified MCP server approach

## Growth Trajectory

The repository has grown from a single Claude config to a comprehensive multi-tool system:

- 1 tool → 12+ tools
- Basic settings → Full configurations with agents, commands, skills, hooks
- Manual setup → One-line installer
- Single platform → Cross-platform (macOS, Linux, Windows)

## Key Contributors

- **Dung Huynh Duc** (@jellydn) — Primary maintainer
- Community contributors via GitHub PRs
