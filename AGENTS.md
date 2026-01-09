# Agents Guide

## Project
my-ai-tools: Configuration management repository for AI coding tools (Claude Code, OpenCode, Amp, CCS) and their integration with MCP servers and plugins.

## Build/Run Commands
- `./cli.sh` - Install and configure AI tools to home directory
- `./cli.sh --dry-run` - Preview changes without applying them
- `./cli.sh --backup` - Backup existing configs before installation
- `./generate.sh` - Export current home configs back to repository

## Architecture
- **Shell Scripts**: Setup orchestration (`cli.sh`, `generate.sh`)
- **configs/**: Tool-specific configurations
  - `claude/` - Claude Code settings, MCP servers, commands
  - `opencode/` - OpenCode agents, commands, skills
  - `amp/` - Amp settings and MCP servers
  - `ccs/` - Claude Code Switch (multi-profile) setup
- **Configs Types**: JSON (settings), YAML (config), Markdown (docs, instructions)

## Style Guide
- Bash scripts: POSIX-compliant, colorized output (RED/GREEN/YELLOW/BLUE), error handling with `set -e`
- JSON: Standard formatting (settings.json, mcp-servers.json)
- Documentation: Markdown with emoji headers (🚀, 📋, 🎨) for visual hierarchy
- No absolute paths (use `$HOME` and relative paths for portability)
- Copy-paste ready code blocks in documentation

## Key Patterns
- Dry-run support for all destructive operations
- Backup functionality for existing configs
- Prerequisite checking (git, bun/node)
- MCP server integration via npx on-demand (context7, sequential-thinking)
- Plugin enablement via claude CLI
