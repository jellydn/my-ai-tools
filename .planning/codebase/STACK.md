# Technology Stack

**Analysis Date:** 2026-04-22

## Languages

**Primary:**

- **Bash** - All automation scripts (`cli.sh`, `generate.sh`, `lib/common.sh`)
- **JSON** - Configuration files for all AI tools
- **Markdown** - Documentation, agents, commands, and skills

**Secondary:**

- **TypeScript** - Claude hooks (`configs/claude/hooks/`)
- **PowerShell** - Windows installer (`install.ps1`)
- **JavaScript** - Helper scripts (`lib/*.js`)

## Runtime

**Environment:**

- Bash 4.0+ (POSIX-compliant scripts with `#!/bin/bash`)
- Cross-platform: macOS, Linux, Windows (Git Bash, MSYS2, WSL)

**Package Manager:**

- Bun (preferred) or Node.js LTS (fallback)
- npx for MCP server installations

## Frameworks

**Core:**

- **Claude Code** - Primary AI IDE with custom settings, MCP servers, hooks
- **OpenCode** - AI assistant with custom agents
- **Amp** - AI coding tool with MCP integration
- **CCS (Claude Code Switch)** - Claude Code proxy for affordable providers
- **Codex** - OpenAI Codex CLI integration
- **Gemini CLI** - Google Gemini CLI configuration
- **Pi** - Alternative AI coding tool
- **Cursor** - AI-powered editor with custom commands
- **GitHub Copilot CLI** - Copilot CLI configuration
- **Kilo** - Lightweight AI coding tool
- **Factory Droid** - Factory CLI configuration

**Testing:**

- **Bats** (Bash Automated Testing System) - Shell script testing framework
- Test files: `tests/*.bats`

**Build/Dev:**

- Git + GitHub for version control
- Changesets for versioning (`.changeset/`)
- Pre-commit hooks for shellcheck validation

## Key Dependencies

**Critical:**

- `jq` - JSON processor (required for JSON manipulation)
- `git` - Version control (required)
- `curl` - HTTP client for installer downloads

**Infrastructure:**

- `biome` - Formatting for TypeScript/JavaScript files
- `prettier` - Markdown formatting
- `shfmt` - Shell script formatting
- `shellcheck` - Shell script linting
- `bun`/`node` - Runtime for hooks and scripts

**MCP Servers:**

- `@upstash/context7-mcp` - Context7 documentation search
- `@modelcontextprotocol/server-sequential-thinking` - Sequential reasoning
- `qmd` - Knowledge management MCP
- `fff-mcp` - Fast file search MCP
- `@react-grab/mcp` - React component extraction
- `mcp-remote` (Notion) - Notion integration

## Configuration

**Environment:**

- Environment variables for AI tool paths: `~/.claude/`, `~/.config/opencode/`, etc.
- `TMPDIR` handling for cross-device link compatibility
- `HOME` resolution for portable paths

**Build:**

- `package.json` - Hooks dependencies in `configs/claude/hooks/`
- `tsconfig.json` - TypeScript compilation config
- `.pre-commit-config.yaml` - Pre-commit hooks (shellcheck)

## Platform Requirements

**Development:**

- Unix-like shell (bash/zsh/fish)
- Git 2.0+
- jq 1.6+
- Bun or Node.js LTS

**Production (Installation Target):**

- User home directory write access
- AI tools installed (Claude Code, OpenCode, etc.)
- Cross-platform: macOS, Linux, Windows with Git Bash

---

_Stack analysis: 2026-04-22_
