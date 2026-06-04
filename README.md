# Welcome to my-ai-tools 👋

[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/jellydn/my-ai-tools/pulls)

> **Comprehensive configuration management for AI coding tools** - Replicate my complete setup for Claude Code, OpenCode, Amp, Kilo CLI, Codex, Gemini CLI, Antigravity CLI, Pi, GitHub Copilot CLI, Cursor Agent CLI, Factory Droid, Cline, Grok CLI and CCS with custom configurations, MCP servers, skills, plugins, and commands.

📖 **[View Documentation Website](https://ai-tools.itman.fyi)** - Interactive landing page with full documentation and search.

## ✨ Features

- 🚀 **One-line installer** - Get started in seconds
- 🔄 **Bidirectional sync** - Install configs or export your current setup
- 🤖 **Multiple AI tools** - Claude Code, OpenCode, Amp, CCS, Gemini, Antigravity, Grok, and more
- 🔌 **MCP Server integration** - Context7, Sequential-thinking, qmd, agentmemory
- 🎯 **Custom agents & skills** - Pre-configured for maximum productivity
- 🤝 **Agent Teams** - Coordinate specialized agents for complex workflows (code review, testing, docs)
- 📦 **Plugin support** - Official and community plugins
- 🛡️ **Git Guard Hook** - Prevents dangerous git commands (force push, hard reset, etc.)

## 🔌 MCP Servers & Plugins Overview

| Tool            | MCP Servers                                                                                 | Plugins/Extensions                                                                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Claude Code** | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | Official + Community (plannotator, claude-hud, worktrunk, codex)                                                                                                    |
| **OpenCode**    | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | @plannotator/opencode, opencode-chrome-annotation                                                                                                                   |
| **Codex**       | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot, node_repl   | -                                                                                                                                                                   |
| **Pi**          | context7, sequential-thinking, qmd, fff, react-grab-mcp, notion, agentmemory                | Packages (pi-extension, autoresearch, hooks, fff, mcp-adapter, simplify, todo, btw, code-previews, codex-goal, dynamic-workflows, commandcode-provider, web-access) |
| **Amp**         | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | -                                                                                                                                                                   |
| **Gemini**      | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | Deprecated for Google One/unpaid tiers; migrate to Antigravity                                                                                                      |
| **Antigravity** | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot (via plugin) | my-ai-tools-gemini-migration                                                                                                                                        |
| **Kilo**        | (uses OpenCode config)                                                                      | (uses OpenCode plugins)                                                                                                                                             |
| **CommandCode** | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | -                                                                                                                                                                   |
| **Copilot**     | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | -                                                                                                                                                                   |
| **Cursor**      | context7 (via bunx), sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot   | -                                                                                                                                                                   |
| **Factory**     | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | core, security-engineer, droid-evolved, autoresearch                                                                                                                |
| **Orca**        | -                                                                                           | Agent hooks (claude, gemini, codex, cursor, droid)                                                                                                                  |
| **Cline**       | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | -                                                                                                                                                                   |
| **Grok**        | context7, sequential-thinking, qmd, agentmemory, fff, react-grab-mcp, logpilot              | -                                                                                                                                                                   |

### 📋 MCP Server Details

| Server                | Purpose                                                                                   | Package                                            |
| --------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `context7`            | Documentation lookup for any library                                                      | `@upstash/context7-mcp`                            |
| `sequential-thinking` | Multi-step reasoning for complex analysis                                                 | `@modelcontextprotocol/server-sequential-thinking` |
| `qmd`                 | Knowledge management with AI-powered search                                               | `qmd`                                              |
| `agentmemory`         | "Persistent memory" per the tool; we use it session-only (qmd = durable; see `MEMORY.md`) | `@agentmemory/mcp`                                 |
| `fff`                 | Fast file search with frecency ranking                                                    | `fff-mcp`                                          |
| `react-grab-mcp`      | React component capture and inspection                                                    | `@react-grab/mcp`                                  |
| `logpilot`            | AI-powered log analysis and tmux monitoring                                               | `logpilot`                                         |

## 🎬 Demo

[![IT Man Channel](https://img.shields.io/badge/YouTube-IT%20Man%20Channel-red?logo=youtube)](https://github.com/jellydn/itman-channel)

[![IT Man - My AI Setup in 2026](https://i.ytimg.com/vi/ESudSFAyuuw/mqdefault.jpg)](https://www.youtube.com/watch?v=ESudSFAyuuw)

## 📋 Prerequisites

### All Platforms

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **Claude Code subscription** or use [CCS](#-ccs---claude-code-switch-optional) with affordable providers (GLM, MiniMax)

### Windows-Specific

- **Git for Windows** - Required for Git Bash support
  - Download: https://git-scm.com/download/win
  - Make sure to select "Git from the command line and also from 3rd-party software" during installation
- **PowerShell 5.1+** - For the PowerShell installer
- **jq** - Will be auto-installed via winget if available, or download from [GitHub releases](https://github.com/jqlang/jq/releases)

## 🚀 Quick Start

### One-Line Installer (Recommended)

Install directly without cloning the repository:

```bash
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash
```

> **Security Note:** Review the script before running:
>
> ```bash
> curl -fsSL https://ai-tools.itman.fyi/install.sh -o install.sh
> cat install.sh  # Review the script
> bash install.sh
> ```

**Options:**

```bash
# Preview changes without making them
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --dry-run

# Backup existing configs before installing
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --backup

# Skip backup prompt
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --no-backup
```

### Manual Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
./cli.sh
```

**Options:**

- `--dry-run` - Preview changes without making them
- `--backup` - Backup existing configs before installing
- `--no-backup` - Skip backup prompt

## 🔄 Bidirectional Config Sync

### Forward: Install to Home (`cli.sh`)

Copy configurations from this repository to your home directory (`~/.claude/`, `~/.config/opencode/`, etc.):

```bash
./cli.sh [--dry-run] [--backup] [--no-backup]
```

### Reverse: Generate from Home (`generate.sh`)

Export your current configurations back to this repository for version control:

```bash
./generate.sh [--dry-run]
```

> **Tip:** Use `generate.sh` after customizing your local setup to save changes back to this repo.

## 🪟 Windows Installation

The installer supports Windows via PowerShell or Git Bash.

### Prerequisites for Windows

1. **Git for Windows** - Includes Git Bash (required for running shell scripts)
   - Download from: https://git-scm.com/download/win
   - During installation, choose "Use Git and optional Unix tools from the Command Prompt" to add Git Bash to PATH

2. **jq** (JSON processor) - Auto-installed via winget if available
   - Manual install: `winget install -e --id jqlang.jq`

### Option 1: PowerShell (Recommended for Windows)

```powershell
# Run directly from the published URL
irm https://ai-tools.itman.fyi/install.ps1 | iex

# To pass options, download first, then run the local file:
irm https://ai-tools.itman.fyi/install.ps1 -OutFile install.ps1
.\install.ps1 -DryRun
```

**Local execution:**

```powershell
# Clone and run locally
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
.\install.ps1
```

### Option 2: Git Bash

```bash
# Open Git Bash (from right-click menu or Start menu)
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
bash ./cli.sh
```

> **Note:** If `bash` is not recognized in PowerShell, add Git to your PATH:
>
> ```powershell
> [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Git\bin", "User")
> ```

---

Primary AI coding assistant with extensive customization.

### Installation

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### MCP Servers Setup

#### Automatic Setup (Recommended)

Run the setup script to configure MCP servers:

```bash
./cli.sh
```

The script will prompt you to install each MCP server:

- [`context7`](https://github.com/upstash/context7) - Documentation lookup for any library
- [`sequential-thinking`](https://mcp.so/server/sequentialthinking) - Multi-step reasoning for complex analysis
- [`qmd`](https://github.com/tobi/qmd) - Quick Markdown Search with AI-powered knowledge management
- [`agentmemory`](https://github.com/rohitg00/agentmemory) - "Persistent memory" per the tool's branding; we use it session-only (qmd is the durable KB; see `~/.ai-tools/MEMORY.md`)
- [`fff`](https://github.com/dmtrKovalenko/fff.nvim) - Fast file search with built-in memory for AI agents
- [`react-grab-mcp`](https://github.com/nyan-left/react-grab-mcp) - React component extraction and analysis
- [`logpilot`](https://github.com/jellydn/logpilot) - AI-powered log analysis and tmux session monitoring

#### Manual Setup

##### For Claude Code

Configuration in [`~/.claude/mcp-servers.json`](configs/claude/mcp-servers.json):

```json
{
	"mcpServers": {
		"context7": {
			"command": "npx",
			"args": ["-y", "@upstash/context7-mcp@latest"]
		},
		"sequential-thinking": {
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"command": "qmd",
			"args": ["mcp"]
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		},
		"fff": {
			"type": "stdio",
			"command": "fff-mcp",
			"args": []
		},
		"react-grab-mcp": {
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"command": "logpilot",
			"args": ["mcp-server"]
		}
	}
}
```

Or use the CLI (installed globally for all projects):

```bash
claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add --scope user --transport stdio qmd -- qmd mcp
claude mcp add --scope user --transport stdio agentmemory -- npx -y @agentmemory/mcp
claude mcp add --scope user --transport stdio fff -- fff-mcp  # Requires: curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash
claude mcp add --scope user --transport stdio logpilot -- logpilot mcp-server  # Requires: cargo install logpilot
```

> **MCP Scopes:**
>
> - `--scope user` (global): Available across all projects
> - `--scope local` (default): Only in current project directory
> - `--scope project`: Stored in `.mcp.json` for team sharing

#### Managing MCP Servers

```bash
# List all configured servers
claude mcp list

# Remove an MCP server
claude mcp remove context7

# Get details for a specific server
claude mcp get qmd
```

#### Knowledge Management

Replace deprecated `claude-mem` with **qmd-based knowledge system**:

- Project-specific knowledge bases in `~/.ai-knowledges/`
- AI-powered search via qmd MCP server
- No repository pollution
- See [qmd Knowledge Management Guide](docs/qmd-knowledge-management.md)

### Plugins

#### Prerequisites

Before installing plugins, ensure:

1. **Claude Code subscription** - Active subscription with plugin support
2. **Plugin marketplace access** - Verify marketplace is enabled for your repository
3. **Network connectivity** - Required for downloading marketplace plugins

To check marketplace availability:

```bash
# Verify Claude CLI supports plugins
claude plugin list

# If the above fails, check your Claude Code installation and subscription
```

#### Installation

The setup script (`./cli.sh`) automatically checks marketplace availability before installing plugins. If marketplace is unavailable, it will offer to install local plugins only.

**Automated installation (recommended):**

```bash
./cli.sh  # Includes marketplace check and fallback to local plugins
```

**Manual installation** (requires marketplace access):

```bash
# First, add the official marketplace
claude plugin marketplace add anthropics/claude-plugins-official

# Official plugins
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install learning-output-style@claude-plugins-official
claude plugin install swift-lsp@claude-plugins-official
claude plugin install lua-lsp@claude-plugins-official
claude plugin install code-simplifier@claude-plugins-official
claude plugin install rust-analyzer-lsp@claude-plugins-official
claude plugin install claude-md-management@claude-plugins-official

# Community plugins (add marketplace first)
# Plugin installation format: plugin-name@marketplace-name
# Example: The repository 'backnotprop/plannotator' registers as marketplace 'plannotator',
#          then you install plugin 'plannotator' from that marketplace
claude plugin marketplace add backnotprop/plannotator
claude plugin install plannotator@plannotator

claude plugin marketplace add jarrodwatts/claude-hud
claude plugin install claude-hud@claude-hud

claude plugin marketplace add max-sixty/worktrunk
claude plugin install worktrunk@worktrunk

claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex

# Install skills from this repository (jellydn/my-ai-tools)
# Recommended: Install all skills at once using npx skills add
npx skills add jellydn/my-ai-tools --yes --global --agent claude-code

# Or install interactively (select which skills to install)
npx skills add jellydn/my-ai-tools --global --agent claude-code

# Available skills: prd, ralph, qmd-knowledge, codemap, adr, handoffs, pickup, pr-review, slop, tdd, thermo-nuclear-code-quality-review, commit-atomic, draft-pull-request
# Skills are installed to ~/.agents/skills/ with symlinks in ~/.claude/skills/
```

#### Troubleshooting

**Skills installation issues?**

If you encounter issues:

1. **Check npx availability**: Ensure Node.js and npx are installed (`npx --version`)
2. **Use local skills**: The setup script automatically falls back to local skills from `skills/` folder
3. **Manual installation**: Copy skill folders directly to `~/.claude/skills/`
4. **Interactive mode**: Run without `--yes` flag to select specific skills

**Common issues:**

- "npx not found" → Install Node.js to use remote skill installation, or use local skills via `./cli.sh`
- "Permission denied" → Try running without sudo, or use `--global` flag
- "Skills already installed" → Remove existing skills first with `npx skills remove --global`

#### Plugin List

| Plugin                               | Description                             | Source            |
| ------------------------------------ | --------------------------------------- | ----------------- |
| `typescript-lsp`                     | TypeScript language server              | Official          |
| `pyright-lsp`                        | Python language server                  | Official          |
| `context7`                           | Documentation lookup                    | Official          |
| `frontend-design`                    | UI/UX design assistance                 | Official          |
| `learning-output-style`              | Interactive learning mode               | Official          |
| `swift-lsp`                          | Swift language support                  | Official          |
| `lua-lsp`                            | Lua language support                    | Official          |
| `code-simplifier`                    | Code simplification                     | Official          |
| `rust-analyzer-lsp`                  | Rust language support                   | Official          |
| `claude-md-management`               | Markdown management                     | Official          |
| `plannotator`                        | Plan annotation tool                    | Community         |
| `plannotator-setup-goal`             | Turn ideas into goal packages           | Local Marketplace |
| `prd`                                | Product Requirements Documents          | Local Marketplace |
| `ralph`                              | PRD to JSON converter                   | Local Marketplace |
| `qmd-knowledge`                      | Project knowledge management            | Local Marketplace |
| `codemap`                            | Parallel codebase analysis              | Local Marketplace |
| `thermo-nuclear-code-quality-review` | Extremely strict maintainability review | Local Marketplace |
| `claude-hud`                         | Status line with usage monitoring       | Community         |
| `worktrunk`                          | Work management                         | Community         |
| `codex`                              | Codex code review & task delegation     | Community         |

#### Key Marketplace Plugins

**`codemap`** - Orchestrates parallel codebase analysis producing 7 structured documents in `.planning/codebase/`:

- `STACK.md` - Technologies, dependencies, configuration
- `INTEGRATIONS.md` - 3rd party APIs, databases, auth
- `ARCHITECTURE.md` - System patterns, layers, data flow
- `STRUCTURE.md` - Directory layout, key locations
- `CONVENTIONS.md` - Code style, patterns, error handling
- `TESTING.md` - Framework, structure, mocking, coverage
- `CONCERNS.md` - Tech debt, bugs, security issues

**`prd`** - Generate Product Requirements Documents

**`ralph`** - Convert PRDs to JSON for autonomous agent execution

**`qmd-knowledge`** - Project-specific knowledge management ([guide](docs/qmd-knowledge-management.md))

### Hooks & Status Line

Configure in [`~/.claude/settings.json`](configs/claude/settings.json):

#### PostToolUse Hooks

Auto-format after file edits:

```json
{
	"hooks": {
		"PostToolUse": [
			{
				"matcher": "Write|Edit|MultiEdit",
				"hooks": [
					{
						"type": "command",
						"command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.(ts|tsx|js|jsx)$'; then biome check --write \"$file_path\"; fi; }"
					},
					{
						"type": "command",
						"command": "if [[ \"$( jq -r .tool_input.file_path )\" =~ \\.go$ ]]; then gofmt -w \"$( jq -r .tool_input.file_path )\"; fi"
					},
					{
						"type": "command",
						"command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.(md|mdx)$'; then npx prettier --write \"$file_path\"; fi; }"
					},
					{
						"type": "command",
						"command": "if [[ \"$( jq -r .tool_input.file_path )\" =~ \\.py$ ]]; then ruff format \"$( jq -r .tool_input.file_path )\"; fi"
					},
					{
						"type": "command",
						"command": "if [[ \"$( jq -r .tool_input.file_path )\" =~ \\.rs$ ]]; then rustfmt \"$( jq -r .tool_input.file_path )\"; fi"
					},
					{
						"type": "command",
						"command": "if [[ \"$( jq -r .tool_input.file_path )\" =~ \\.sh$ ]]; then shfmt -w \"$( jq -r .tool_input.file_path )\"; fi"
					},
					{
						"type": "command",
						"command": "if [[ \"$( jq -r .tool_input.file_path )\" =~ \\.lua$ ]]; then stylua \"$( jq -r .tool_input.file_path )\"; fi"
					}
				]
			}
		]
	}
}
```

**Supported Formatters:**

- **biome** - TypeScript/JavaScript files (`.ts`, `.tsx`, `.js`, `.jsx`) - includes linting
- **gofmt** - Go files (`.go`)
- **prettier** - Markdown files (`.md`, `.mdx`)
- **ruff** - Python files (`.py`) - modern, fast formatter
- **rustfmt** - Rust files (`.rs`)
- **shfmt** - Shell scripts (`.sh`)
- **stylua** - Lua files (`.lua`)

**Installation:** The setup script (`./cli.sh`) automatically checks and installs these tools with mise priority:

- `jq` - JSON parsing (required)
- `biome` - JavaScript/TypeScript formatting
- `gofmt` - Go formatting (requires Go installation)
- `prettier` - Markdown formatting (used via `npx`)
- `ruff` - Python formatting (installed via mise, pipx, or pip)
- `rustfmt` - Rust formatting (installed via mise or rustup)
- `shfmt` - Shell script formatting (installed via mise, brew, or go install)
- `stylua` - Lua formatting (installed via mise, brew, or cargo)

#### PreToolUse Hooks

##### Git Guard Hook

Prevents dangerous git commands from being executed:

```json
{
	"hooks": {
		"PreToolUse": [
			{
				"matcher": "Bash",
				"hooks": [
					{
						"type": "command",
						"command": "bun ~/.claude/hooks/index.ts PreToolUse"
					}
				]
			}
		]
	}
}
```

**Blocked commands:**

- `git push --force` / `-f` (without lease protection)
- `git reset --hard` (destroys uncommitted changes)
- `git clean -fd` (removes untracked files)
- `git branch -D` (force delete branch)
- `git rebase -i` (interactive rebase)
- `git checkout --force` / `-f` (force checkout)
- `git stash drop/clear` (removes stashes)
- And more...

The implementation can be found in `configs/claude/hooks/index.ts` and `configs/claude/hooks/git-guard.ts`.

##### WebSearch Transformer

Transform WebSearch queries:

```json
{
	"hooks": {
		"PreToolUse": [
			{
				"matcher": "WebSearch",
				"hooks": [
					{
						"type": "command",
						"command": "node \"~/.ccs/hooks/websearch-transformer.cjs\"",
						"timeout": 120
					}
				]
			}
		]
	}
}
```

#### Status Line

Using claude-hud plugin:

```json
{
	"statusLine": {
		"type": "command",
		"command": "bash -c 'node \"$(ls -td ~/.claude/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null | head -1)dist/index.js\"'"
	}
}
```

<img width="1058" height="138" alt="Claude HUD Status Line" src="https://github.com/user-attachments/assets/afab87bb-d78f-4cc8-9e1b-f3948a7e6fe6" />

> **Tip:** Auto-compact is disabled. Use `claude-hud` to monitor context usage.

### Custom Commands, Agents & Skills

#### Custom Commands

Located in [`configs/claude/commands/`](configs/claude/commands/):

- `/ccs` - CCS delegation and profile management
- `/ultrathink` - Deep thinking mode

#### Custom Agents

Located in [`configs/claude/agents/`](configs/claude/agents/):

- `ai-slop-remover` - Remove AI-generated boilerplate and improve code quality
- `code-reviewer` - Comprehensive code quality and security review
- `test-generator` - Generate meaningful tests with edge case coverage
- `documentation-writer` - Create clear, helpful documentation
- `feature-team-coordinator` - Coordinate specialized agents for complex workflows

📖 **[Agent Teams Guide](docs/claude-code-teams.md)** - Learn how to use Agent Teams to coordinate multiple specialized agents for complex tasks like feature development, code review, and documentation.

#### Skills

**Local Marketplace Plugins** - Installed by `cli.sh` from [`skills/`](skills/):

- `adr` - Architecture Decision Records
- `codemap` - Parallel codebase analysis producing structured documentation
- `commit-atomic` - Atomic commits by logically grouping changes with commitizen convention (no `git add -A`)
- `draft-pull-request` - Create draft pull requests using gh CLI with what/why/how template
- `handoffs` - Create handoff plans for continuing work (provides `/handoffs` command)
- `pickup` - Resume work from previous handoff sessions (provides `/pickup` command)
- `plannotator-setup-goal` - Turn an idea into a structured goal package via Plannotator-gated discovery, fact sheet, and plan
- `portless-local` - Named .localhost URLs for local development - replaces port numbers with stable URLs
- `pr-review` - Pull request review workflows
- `prd` - Generate Product Requirements Documents
- `qmd-knowledge` - Project knowledge management
- `ralph` - Convert PRDs to JSON for autonomous agent execution
- `slop` - AI slop detection and removal
- `tdd` - Test-Driven Development workflows
- `thermo-nuclear-code-quality-review` - Extremely strict maintainability and structural code quality reviews

#### Projects Built with AI

Real-world projects built using these AI tools:

| Project                                                             | Description                                                                     | Tools Used                                  |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------- |
| - [Oak](https://github.com/jellydn/oak)                             | Lightweight macOS focus companion for deep work with notch-first UI             | Ralph + OpenCode + Codex GPT 5.2            |
| - [Prosody](https://github.com/jellydn/prosody)                     | Mobile app for English speaking rhythm coaching with AI feedback                | Ralph + OpenCode + GLM + Amp/Codex (review) |
| - [Keybinder](https://github.com/jellydn/keybinder)                 | macOS app for managing skhd keyboard shortcuts                                  | Claude + spec-kit                           |
| - [SealCode](https://github.com/jellydn/vscode-seal-code)           | VS Code extension for AI-powered code review                                    | Amp + Ralph                                 |
| - [Ralph](https://github.com/jellydn/ralph)                         | Autonomous AI agent loop for PRD-driven development                             | TypeScript                                  |
| - [AI Launcher](https://github.com/jellydn/ai-launcher)             | Fast launcher for switching between AI coding assistants                        | TypeScript                                  |
| - [Tiny Coding Agent](https://github.com/jellydn/tiny-coding-agent) | Minimal coding agent focused on simplicity                                      | TypeScript                                  |
| - [dotenv-tui](https://github.com/jellydn/dotenv-tui)               | Terminal UI for managing `.env` files across projects                           | Go + Bubble Tea                             |
| - [tiny-cloak.nvim](https://github.com/jellydn/tiny-cloak.nvim)     | Neovim plugin that masks sensitive data in `.env` files                         | Lua + Neovim                                |
| - [tiny-term.nvim](https://github.com/jellydn/tiny-term.nvim)       | Minimal terminal plugin for Neovim 0.11+                                        | Lua + Neovim                                |
| - [Sky Alert](https://github.com/jellydn/sky-alert)                 | Real-time flight monitoring Telegram bot                                        | OpenCode + GLM 4.7 + Amp + Codex CLI        |
| - [Docklight](https://github.com/jellydn/docklight)                 | Minimal, self-hosted web UI for managing a single-node Dokku server             | Ralph + OpenCode                            |
| - [Little Writing](https://github.com/jellydn/little-writing)       | A handwriting tracing app for kids built with React, react-konva, and Capacitor | Claude + spec-kit + GLM 5                   |
| - [Zed Codemux](https://github.com/jellydn/zed-codemux)             | Open Zed terminals inside tmux or zellij — port of vscode-mux to the Zed editor | Ralph                                       |

📖 **[Learning Stories](docs/learning-stories.md)** - Detailed notes on development approaches, key takeaways, and tools I've tried.

#### Recommended Community Skills

Official and community-maintained skill collections for specific frameworks:

| Framework                  | Skills Repository                                                                                             | Description                                                                                                                                                                                                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **UI/UX Design**           | [Interface Design](https://interface-design.dev/)                                                             | Comprehensive guide to interface design patterns and best practices for anyone working with UI/UX development.                                                                                                                                                                      |
| **Expo**                   | [expo/skills](https://github.com/expo/skills)                                                                 | Official Expo skills for React Native development. Includes app creation, building, debugging, EAS updates, and config management workflows.                                                                                                                                        |
| **Next.js**                | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)                                       | Vercel's agent skills for Next.js and React development. Includes project creation, component generation, and deployment workflows.                                                                                                                                                 |
| **React Patterns**         | [factory-ai/factory-plugins](https://skills.sh/factory-ai/factory-plugins/no-use-effect)                      | No-use-effect skill: 5 patterns to replace useEffect with better alternatives - derived state, data-fetching libraries, event handlers, useMountEffect, and key prop resets.                                                                                                        |
| **Andrej Karpathy**        | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)                 | Community skills inspired by Andrej Karpathy's coding principles and practices for AI-focused development workflows.                                                                                                                                                                |
| **Humanizer**              | [blader/humanizer](https://github.com/blader/humanizer)                                                       | Removes signs of AI-generated writing from text. Based on Wikipedia's AI writing detection guide, it detects 24 patterns to make text sound more natural and human.                                                                                                                 |
| **Claude Skills**          | [jezweb/claude-skills](https://github.com/jezweb/claude-skills)                                               | 97 production-ready skills for Claude Code CLI including Cloudflare, React, AI integrations, and more. Includes context-mate for project analysis and workflow management.                                                                                                          |
| **OZ Skills**              | [warpdotdev/oz-skills](https://github.com/warpdotdev/oz-skills)                                               | 14 production-ready skills by Warp. Includes `docs-update` for automated documentation synchronization with code changes across all major platforms (Mintlify, Docusaurus, GitBook, Fumadocs). Other skills cover CI fix, PR creation, web testing, accessibility audits, and more. |
| **Auto-Review**            | [openclaw/agent-skills](https://github.com/openclaw/agent-skills/blob/main/skills/autoreview/SKILL.md)        | Auto-review skill for structured and actionable pull request feedback workflows.                                                                                                                                                                                                    |
| **Skills Discovery**       | [vercel-labs/skills/find-skills](https://github.com/vercel-labs/skills/blob/main/skills/find-skills/SKILL.md) | Skill discovery helper. Search and install skills from skills.sh when users ask about capabilities. Uses `npx skills find [query]`.                                                                                                                                                 |
| **Matt Pocock**            | [mattpocock/skills](https://github.com/mattpocock/skills)                                                     | Community skills by Matt Pocock. Includes `grill-with-docs` for docs-grounded plan stress-testing, `improve-codebase-architecture` for finding deepening opportunities, and more.                                                                                                   |
| **Mitsuhiko**              | [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff)                                             | Skills and extensions by Armin Ronacher. Includes tmux session control, GitHub CLI, web browser automation, Sentry integration, mermaid diagrams, and more.                                                                                                                         |
| **Git Stacked PRs**        | [github/gh-stack](https://github.com/github/gh-stack)                                                         | GitHub CLI extension for managing stacked branches and pull requests. Create, push, rebase, sync, and navigate stacks of dependent PRs for incremental code review workflows.                                                                                                       |
| **Facts**                  | [av/facts](https://github.com/av/facts)                                                                       | Track project specs and facts in a `.facts` file. Lifecycle stages (`@draft` → `@spec` → `@implemented`) with shell-command verification. Ships four skills: `facts`, `facts-discover`, `facts-refine`, and `facts-implement`.                                                      |
| **Modern Web Guidance**    | [GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance)                       | Search tool for modern web development best practices (HTML, CSS, accessibility, and client-side JS APIs).                                                                                                                                                                          |
| **Plannotator Setup Goal** | [backnotprop/plannotator](https://github.com/backnotprop/plannotator)                                         | Turn ideas into structured goal packages with fact sheets and execution plans, gated by Plannotator annotation                                                                                                                                                                      |

**Installation:**

```bash
# Install skills using npx skills add
npx skills add expo/skills --global --agent claude-code
npx skills add vercel-labs/agent-skills --global --agent claude-code
npx skills add factory-ai/factory-plugins --skill no-use-effect --global --agent claude-code
npx skills add blader/humanizer --global --agent claude-code
npx skills add jezweb/claude-skills --global --agent claude-code
npx skills add mattpocock/skills --skill grill-with-docs --global --agent claude-code
npx skills add mattpocock/skills --skill improve-codebase-architecture --global --agent claude-code
npx skills add mitsuhiko/agent-stuff --global --agent claude-code
npx skills add github/gh-stack --global --agent claude-code
npx skills add warpdotdev/oz-skills --skill docs-update --global --agent claude-code
npx skills add openclaw/agent-skills --skill autoreview --global --agent claude-code
npx skills add av/facts --global --agent claude-code
npx skills add GoogleChrome/modern-web-guidance --skill modern-web-guidance --global --agent claude-code
```

### Configuration Files

All configuration files are located in the [`configs/claude/`](configs/claude/) directory:

- [`settings.json`](configs/claude/settings.json) - Main Claude Code settings
- [`mcp-servers.json`](configs/claude/mcp-servers.json) - MCP server configurations
- [`commands/`](configs/claude/commands/) - Custom slash commands
- [`agents/`](configs/claude/agents/) - Custom agent definitions

Local marketplace plugins are in [`skills/`](skills/).

#### Tips & Tricks

- **OpusPlan Mode**: Use opusplan mode to plan with Opus and implement with Sonnet, then use Plannotator to review plans
- **Session Management**: Disable auto-compact in settings. Monitor context usage with `claude-hud`. Press `Ctrl+C` to quit or `/clear` to reset between coding sessions. Create a plan with `/handoffs` and resume with `/pickup` when approaching 90% context limit on big tasks.
- **Git Worktree**: Use git worktree with `try` CLI. For tmux users, use `claude-squash` to manage sessions efficiently. Use [superset.sh](https://superset.sh/) to run multiple AI agents in parallel across worktrees
- **Neovim Integration**: Check out [tiny-nvim](https://github.com/jellydn/tiny-nvim) for a complete setup with [sidekick.nvim](https://github.com/folke/sidekick.nvim) or [claudecode.nvim](https://github.com/coder/claudecode.nvim)
- **Cost Optimization**: Use [CCS](https://ccs.kaitran.ca/) to switch between affordable providers.

---

## 🎨 OpenCode (Optional)

OpenAI-powered AI coding assistant. [Homepage](https://opencode.ai)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://opencode.ai/install | bash
```

### Configuration

Copy [`configs/opencode/opencode.json`](configs/opencode/opencode.json) to `~/.config/opencode/`:

```json
{
	"$schema": "https://opencode.ai/config.json",
	"instructions": ["~/.ai-tools/best-practices.md", "~/.ai-tools/MEMORY.md"],
	"theme": "kanagawa",
	"default_agent": "plan",
	"mcp": {
		"context7": {
			"type": "remote",
			"url": "https://mcp.context7.com/mcp",
			"enabled": true
		},
		"qmd": {
			"type": "local",
			"command": ["qmd", "mcp"],
			"enabled": true
		},
		"fff": {
			"type": "local",
			"command": ["fff-mcp"],
			"enabled": true
		},
		"sequential-thinking": {
			"type": "local",
			"command": [
				"npx",
				"-y",
				"@modelcontextprotocol/server-sequential-thinking"
			],
			"enabled": true
		},
		"react-grab-mcp": {
			"type": "local",
			"command": ["npx", "-y", "@react-grab/mcp", "--stdio"],
			"enabled": true
		},
		"logpilot": {
			"type": "local",
			"command": ["logpilot", "mcp-server"],
			"enabled": true
		},
		"agentmemory": {
			"type": "local",
			"command": ["npx", "-y", "@agentmemory/mcp"],
			"enabled": true
		}
	},
	"agent": {
		"build": {
			"permission": {
				"bash": {
					"git push": "ask",
					"qmd": "allow",
					"qmd query": "allow",
					"qmd get": "allow",
					"qmd search": "allow",
					"$HOME/.config/opencode/skill/qmd-knowledge/scripts/record.sh": "allow",
					"$HOME/.claude/skills/qmd-knowledge/scripts/record.sh": "allow"
				}
			}
		}
	},
	"plugin": [
		"@plannotator/opencode@latest",
		"opencode-chrome-annotation@latest"
	],
	"formatter": {
		"biome": {
			"command": ["biome", "check", "--write", "$FILE"],
			"extensions": [".ts", ".tsx", ".js", ".jsx"]
		},
		"gofmt": {
			"command": ["gofmt", "-w", "$FILE"],
			"extensions": [".go"]
		},
		"prettier": {
			"command": ["npx", "prettier", "--write", "$FILE"],
			"extensions": [".md", ".mdx"]
		},
		"ruff": {
			"command": ["ruff", "format", "$FILE"],
			"extensions": [".py"]
		},
		"rustfmt": {
			"command": ["rustfmt", "$FILE"],
			"extensions": [".rs"]
		},
		"shfmt": {
			"command": ["shfmt", "-w", "$FILE"],
			"extensions": [".sh"]
		},
		"stylua": {
			"command": ["stylua", "$FILE"],
			"extensions": [".lua"]
		}
	}
}
```

**Formatters**: OpenCode automatically formats code after edits using:

- **biome** for TypeScript/JavaScript files (`.ts`, `.tsx`, `.js`, `.jsx`)
- **gofmt** for Go files (`.go`)
- **prettier** for Markdown files (`.md`, `.mdx`)
- **ruff** for Python files (`.py`)
- **rustfmt** for Rust files (`.rs`)
- **shfmt** for shell scripts (`.sh`)
- **stylua** for Lua files (`.lua`)

Similar to Claude Code's PostToolUse hooks, formatters run automatically after write/edit operations.

### Plugins

OpenCode supports community plugins that enhance functionality:

- **[@plannotator/opencode](https://github.com/backnotprop/plannotator)** - Interactive code planning and annotation

- **[opencode-chrome-annotation](https://www.npmjs.com/package/opencode-chrome-annotation)** - Chrome-based annotation for plan reviews

Plugins are automatically installed on next OpenCode launch.

### Custom Agents

Located in [`configs/opencode/agent/`](configs/opencode/agent/):

- `ai-slop-remover` - Remove AI-generated boilerplate
- `docs-writer` - Generate documentation
- `review` - Code review
- `security-audit` - Security auditing

### Custom Providers

OpenCode supports custom model providers via OpenAI-compatible endpoints:

| Provider  | Models                          | Endpoint                      |
| --------- | ------------------------------- | ----------------------------- |
| llama.cpp | GLM-4.7-Flash (local inference) | `http://192.168.1.11:8000/v1` |
| ollama    | minimax-m2.5:cloud              | `http://127.0.0.1:11434/v1`   |

These are configured in `opencode.json` under the `provider` key with custom model limits.

### Custom Commands

Located in [`configs/opencode/command/`](configs/opencode/command/):

- `simplify` - Simplify over-engineered code for clarity and maintainability
- `batch` - Run multiple tasks in parallel as worker tasks

</details>

---

## 🚀 Command Code (Optional)

AI coding assistant that continuously learns your taste of writing code. [Homepage](https://commandcode.ai)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### 📋 Installation

```bash
npm install -g command-code
```

### 🔧 Configuration

Run the setup script to install configurations to `~/.commandcode/`:

```bash
./cli.sh
```

The setup script automatically configures MCP servers and copies agent guidelines.

### ✨ Key Features

- **Taste Learning** - Learn your code style preferences from repositories
- **MCP Servers** - Extend functionality with Model Context Protocol servers
- **Skills** - Manage agent skills from GitHub repositories
- **Slash Commands** - Built-in commands like `/resume`, `/taste`, `/review`, `/mcp`, etc.

### 🔌 MCP Servers

Configuration in @configs/commandcode/mcp.json:

````json
{
	"mcpServers": {
		"context7": {
			"command": "npx",
			"args": ["-y", "@upstash/context7-mcp@latest"]
		},
		"sequential-thinking": {
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"command": "qmd",
			"args": ["mcp"]
		},
		"fff": {
			"command": "fff-mcp",
			"args": []
		},
		"react-grab-mcp": {
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	}
}

Located in @configs/commandcode/agents/:

- `ai-slop-remover` - Remove AI-generated boilerplate
- `review` - Code review

### ⌨️ Custom Commands

Located in @configs/commandcode/commands/:

- `simplify` - Simplify over-engineered code
- `pr-review` - Pull request review workflows

### 📖 Agent Guidelines

Installed to `~/.commandcode/AGENTS.md` with instructions for:

- Session management with tmux
- Using fff MCP for file search
- Following best practices from `~/.ai-tools/best-practices.md`
- qmd knowledge management integration
- Git safety guidelines

</details>

---

## 🎯 Amp (Optional)

AI coding assistant by Modular. [Homepage](https://ampcode.com)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://ampcode.com/install.sh | bash
````

### Configuration

Copy [`configs/amp/settings.json`](configs/amp/settings.json) to `~/.config/amp/`:

```json
{
	"amp.dangerouslyAllowAll": true,
	"amp.experimental.autoHandoff": { "context": 90 },
	"amp.mcpServers": {
		"context7": {
			"url": "https://mcp.context7.com/mcp"
		},
		"sequential-thinking": {
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"command": "qmd",
			"args": ["mcp"]
		},
		"fff": {
			"command": "fff-mcp",
			"args": []
		},
		"react-grab-mcp": {
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	},
	"amp.terminal.theme": "kanagawa"
}
```

See [`configs/amp/AGENTS.md`](configs/amp/AGENTS.md) for agent guidelines.

</details>

---

## 🔄 CCS - Claude Code Switch (Optional)

Universal AI profile manager for Claude Code. [Homepage](https://ccs.kaitran.ca) | [Documentation](https://docs.ccs.kaitran.ca)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @kaitranntt/ccs
```

### What It Does

CCS lets you run Claude, Gemini, GLM, and any Anthropic-compatible API - concurrently, without conflicts.

**Three Main Capabilities:**

1. **Multiple Claude Accounts** - Run work + personal Claude subscriptions simultaneously
2. **OAuth Providers** - Gemini, Codex, Antigravity, Qwen, iFLY, Kiro, GitHub Copilot (zero API keys needed)
3. **API Profiles** - GLM, Ollama, or any Anthropic-compatible API

### Quick Start

1. **Open Dashboard**:

   ```bash
   ccs config
   # Opens http://localhost:3000
   ```

2. **Configure Your Accounts** via the visual dashboard:
   - Claude Accounts (work, personal, client)
   - OAuth Providers (one-click auth)
   - API Profiles (configure with your keys)
   - Health Monitor (real-time status)

3. **Start Using**:
   ```bash
   ccs           # Default Claude session
   ccs gemini    # Gemini (OAuth)
   ccs codex     # OpenAI Codex (OAuth)
   ccs agy       # Antigravity (OAuth)
   ccs qwen      # Qwen (OAuth)
   ccs iflow     # iFLY (OAuth)
   ccs kiro      # Kiro (OAuth)
   ccs ghcp      # GitHub Copilot (OAuth)
   ccs glm       # GLM (API key)
   ccs ollama    # Local Ollama
   ```

### Configuration

CCS auto-creates config on install (currently version 8). Dashboard is the recommended way to manage settings.

**Config location**: [`~/.ccs/config.yaml`](configs/ccs/config.yaml)

Key features from the current config:

- **CLIProxy OAuth providers**: gemini, codex, agy, qwen, iflow, kiro, ghcp
- **API Profiles**: glm, ollama-cloud (cloud-hosted), ollama (local)
- **WebSearch fallback chain**: Gemini → OpenCode → Grok (automatic fallback for third-party providers)
- **Copilot API proxy**: Optional GitHub Copilot integration via `npx copilot-api auth` (disabled by default)
- **Thinking modes**: auto, off, manual with tier defaults (opus=high, sonnet=medium, haiku=low)

See [`configs/ccs/config.yaml`](configs/ccs/config.yaml) for the full configuration.

**Advanced**: The `websearch` section enables CLI-based web search for third-party profiles that don't have Anthropic's WebSearch tool. Fallback chain tries providers in order until one succeeds.

</details>

---

## 🤖 OpenAI Codex CLI (Optional)

OpenAI's command-line coding assistant. [Homepage](https://developers.openai.com/codex/cli)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @openai/codex
```

### Configuration

Located in [`configs/codex/`](configs/codex/):

- [`config.toml`](configs/codex/config.toml) - Main TOML configuration with MCP servers
- [`AGENTS.md`](configs/codex/AGENTS.md) - Agent guidelines

### MCP Servers

```toml
[mcp_servers.context7]
command = "npx"
args = [ "-y", "@upstash/context7-mcp" ]

[mcp_servers.sequential-thinking]
command = "npx"
args = [ "-y", "@modelcontextprotocol/server-sequential-thinking" ]

[mcp_servers.qmd]
command = "qmd"
args = [ "mcp" ]

[mcp_servers.fff]
command = "fff-mcp"
args = []

[mcp_servers.react-grab-mcp]
command = "npx"
args = [ "-y", "@react-grab/mcp", "--stdio" ]

[mcp_servers.logpilot]
command = "logpilot"
args = ["mcp-server"]

[mcp_servers.node_repl]
args = []
command = "/Applications/Codex.app/Contents/Resources/node_repl"
startup_timeout_sec = 120

[mcp_servers.node_repl.env]
CODEX_HOME = "$HOME/.codex"
NODE_REPL_NODE_PATH = "/Applications/Codex.app/Contents/Resources/node"
```

### Usage

```bash
# Start Codex CLI
codex

# Use with Ollama (local models)
codex --oss

# Use with a specific task
codex "Explain this code"
```

</details>

---

## 🔷 Google Gemini CLI (Deprecated for Google One / unpaid tiers)

Google's AI agent that brings the power of Gemini directly into your terminal. [Homepage](https://github.com/google-gemini/gemini-cli)

> **Migration notice:** Google is transitioning Google One and unpaid-tier Gemini CLI users to Antigravity CLI. Gemini CLI will stop serving those tiers starting June 18, so use the Antigravity CLI setup below for those accounts. This repository still keeps Gemini CLI configs for existing installations, API-key workflows, and migration/export compatibility.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @google/gemini-cli
```

Or using Homebrew (macOS/Linux):

```bash
brew install gemini-cli
```

### Authentication

Gemini CLI supports multiple authentication methods:

**Option 1: Login with Google (OAuth)**

```bash
gemini
# Follow the browser authentication flow
```

**Option 2: Gemini API Key**

```bash
export GEMINI_API_KEY="YOUR_API_KEY"
gemini
```

Get your API key from [Google AI Studio](https://aistudio.google.com/apikey).

### Configuration

Located in [`configs/gemini/`](configs/gemini/):

- [`settings.json`](configs/gemini/settings.json) - Main configuration with MCP servers and experimental features
- [`GEMINI.md`](configs/gemini/GEMINI.md) - Agent guidelines
- [`AGENTS.md`](configs/gemini/AGENTS.md) - Additional agent guidelines
- [`agents/`](configs/gemini/agents/) - Custom agent definitions (`.md` format with YAML frontmatter)
  - `ai-slop-remover.md` - Clean up AI-generated code patterns
  - `docs-writer.md` - Generate comprehensive documentation
  - `review.md` - Code review with best practices
  - `security-audit.md` - Security vulnerability assessment
- [`commands/`](configs/gemini/commands/) - Custom slash commands (`.toml` format)
  - `ultrathink.toml` - Deep thinking mode

### Key Features

- 🆓 **Free tier**: 60 requests/min and 1,000 requests/day with personal Google account
- 🧠 **Powerful models**: Access to Gemini 2.5 Flash and Pro with 1M token context window
- 🔧 **Built-in tools**: Google Search grounding, file operations, shell commands
- 🔌 **MCP support**: Extensible via Model Context Protocol
- 💻 **Terminal-first**: Designed for command-line developers

### Usage

```bash
# Start Gemini CLI
gemini

# Include multiple directories
gemini --include-directories ../lib,../docs

# Use specific model
gemini -m gemini-2.5-flash

# Non-interactive mode for scripts
gemini -p "Explain the architecture of this codebase"
```

### Custom Commands

Custom commands are stored in `~/.gemini/commands/` as TOML files. Example:

```bash
# Run the ultrathink command
/ultrathink What is the best approach to optimize this database query?
```

### MCP Servers

Configure MCP servers in `~/.gemini/settings.json` to extend functionality:

```json
{
	"mcpServers": {
		"context7": {
			"url": "https://mcp.context7.com/mcp"
		},
		"sequential-thinking": {
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"command": "qmd",
			"args": ["mcp"]
		},
		"fff": {
			"command": "fff-mcp",
			"args": []
		},
		"react-grab-mcp": {
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	},
	"experimental": {
		"enableAgents": true
	}
}
```

> **Note:** Custom agents in `~/.gemini/agents/` are automatically discovered when `experimental.enableAgents` is set to `true`.

</details>

---

## 🛸 Antigravity CLI (Optional)

Google's Antigravity CLI for terminal-first agent workflows. This repository installs Antigravity as a first-class tool and stages migrated Gemini CLI configuration under `~/.gemini/antigravity-cli/`. Antigravity is the migration target for Google One and unpaid-tier Gemini CLI users.

<details>
<summary><strong>Installation, Migration & Configuration</strong></summary>

### Installation

```bash
# Mac/Linux
curl -fsSL https://antigravity.google/cli/install.sh | bash

# Windows PowerShell
irm https://antigravity.google/cli/install.ps1 | iex
```

Or run this repo's installer:

```bash
./cli.sh
```

### Gemini CLI / gcli Migration

Antigravity CLI stores its config in `~/.gemini/antigravity-cli/` and can import existing Gemini CLI extensions as Antigravity plugins:

```bash
agy plugin import gemini
```

This repository also ships a source-controlled migrated plugin at `configs/antigravity-cli/plugins/my-ai-tools-gemini-migration/` with:

- Gemini MCP servers converted to Antigravity `mcp_config.json`
- Gemini agents staged as Antigravity plugin agents
- Gemini `AGENTS.md` and `GEMINI.md` staged as plugin rules

Global Gemini skills in `~/.gemini/skills/` are shared with Antigravity CLI, so no separate skill copy is required.

### Usage

- [https://antigravity.google/docs/cli-using](https://antigravity.google/docs/cli-using)
- [https://antigravity.google/docs/cli-features](https://antigravity.google/docs/cli-features)
- [https://antigravity.google/docs/gcli-migration](https://antigravity.google/docs/gcli-migration)

```bash
# Start Antigravity CLI
agy

# Manage plugins, MCP, skills, and settings from inside the TUI
/mcp
/skills
/config
```

### Configuration Files

- `~/.gemini/antigravity-cli/settings.json` - CLI settings, sandbox, permissions
- `~/.gemini/antigravity-cli/keybindings.json` - optional keybindings
- `~/.gemini/antigravity-cli/plugins/<plugin_name>/` - plugins with `plugin.json`, `mcp_config.json`, agents, skills, hooks, and rules

If you already use CCS in this repository, you can launch the Antigravity profile directly:

```bash
ccs agy
```

</details>

---

## 🎯 Kilo CLI (Optional)

AI coding assistant built on top of OpenCode with powerful productivity features. [Homepage](https://kilo.ai)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @kilocode/cli
```

Kilo provides both `kilo` and `kilocode` commands.

### Configuration

Kilo CLI uses its own configuration directory at `~/.config/kilo/`:

- [`config.json`](configs/kilo/config.json) - Main configuration with permissions and settings

Configuration is managed through:

1. `/connect` command for provider setup (interactive)
2. Config files directly at `~/.config/kilo/config.json`
3. `kilo auth` for credential management

### MCP Servers

Kilo delegates to OpenCode's MCP configuration. See [OpenCode MCP Servers](#mcp-servers-1) for the full list (context7, sequential-thinking, qmd, fff, react-grab-mcp, logpilot, agentmemory).

### Key Features

- 🚀 **Built on OpenCode**: Full compatibility with OpenCode configuration and plugins
- 🤖 **300+ AI Models**: Access to Claude, GPT, Gemini, DeepSeek, Llama, and more
- 🥔 **Giga Potato Model**: Free stealth model optimized for agentic programming with vision support
- 🔌 **Plugin ecosystem**: Compatible with OpenCode plugins
- 📝 **Custom agents**: Same agent system as OpenCode
- 🎨 **Terminal UI**: Enhanced terminal interface for productivity

### Usage

```bash
# Start Kilo CLI
kilo

# Or use the kilocode alias
kilocode

# Use with specific model
kilo --model kilo/giga-potato

# Non-interactive mode
kilo run "Refactor this component to use hooks"
```

</details>

---

## 🥧 Pi (Optional)

AI coding agent built for agentic coding workflows. [Homepage](https://pi.dev)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://pi.dev/install.sh | sh
```

### Configuration

Pi uses `~/.pi/agent/settings.json` for global user settings and `.pi/settings.json` in project roots for project-level configuration.

Located in [`configs/pi/`](configs/pi/):

- [`settings.json`](configs/pi/settings.json) - Global settings with package registrations
- [`models.json`](configs/pi/models.json) - Provider and model definitions (vibeproxy, antigravity proxy, ollama)

Installer copies the repo-managed files `configs/pi/settings.json` and `configs/pi/models.json` to `~/.pi/agent/settings.json` and `~/.pi/agent/models.json` respectively. The default settings configure `vibeproxy` as the default provider with `claude-opus-4-6-thinking` default model. You can inspect or edit them at `~/.pi/agent/settings.json` after installation.

**Key Settings:**

- **Default Model**: `claude-opus-4-6-thinking` (via vibeproxy)
- **Default Provider**: `vibeproxy`
- **Default Thinking Level**: `high`
- **Theme**: `kanagawa`
- **Permission Level**: `high`
- **Quiet Startup**: Enabled (skips changelog on launch)
- **Hide Thinking Block**: Disabled (shows thinking process)

### Pi Packages

Pi uses a package-based extension system (not MCP). Install packages with:

```bash
pi install pi-flow-enforcer
pi install pi-agent-pack
```

Then register them in `~/.pi/agent/settings.json`:

```json
{
	"packages": [
		{
			"source": "npm:@plannotator/pi-extension",
			"skills": []
		},
		"https://github.com/davebcn87/pi-autoresearch",
		"npm:pi-hooks",
		"npm:@ff-labs/pi-fff",
		"npm:pi-mcp-adapter",
		"npm:pi-simplify",
		"npm:pi-manage-todo-list",
		"npm:pi-btw",
		"npm:pi-code-previews",
		"npm:pi-codex-goal",
		"npm:pi-dynamic-workflows",
		"npm:pi-commandcode-provider",
		"npm:pi-web-access"
	]
}
```

**Package Overview:**

| Package                     | Description                                                                |
| --------------------------- | -------------------------------------------------------------------------- |
| `@plannotator/pi-extension` | Interactive plan review with visual annotation                             |
| `pi-autoresearch`           | Autonomous experiment loop for optimization targets                        |
| `pi-hooks`                  | Collection of extensions (checkpoint, lsp, permission, ralph-loop, repeat) |
| `@ff-labs/pi-fff`           | FFF-powered fuzzy file and content search                                  |
| `pi-mcp-adapter`            | MCP (Model Context Protocol) adapter for Pi                                |
| `pi-simplify`               | Reviews changed code for clarity, consistency, and maintainability         |
| `pi-manage-todo-list`       | GitHub Copilot-style todo list management tool                             |
| `pi-btw`                    | Parallel side conversations with `/btw` command                            |
| `pi-code-previews`          | Live previews of code changes during editing                               |
| `pi-codex-goal`             | Codex-style goal management integration                                    |
| `pi-dynamic-workflows`      | Dynamic workflow automation for Pi                                         |
| `pi-commandcode-provider`   | CommandCode model provider integration for Pi                              |
| `pi-web-access`             | Web search and content fetching for AI models                              |

### Enabled Models

Pi is configured with multi-provider model access:

| Provider           | Models                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| github-copilot     | `gpt-5-mini`, `gpt-4.1`, `gpt-5.4`                                                              |
| vibeproxy          | `claude-opus-4-6-thinking`, `claude-sonnet-4-6`, `gemini-3-flash-agent`, `gemini-3-pro-high`    |
|                    | `gemini-pro-agent`                                                                              |
| google-antigravity | `claude`, `gemini-3.5-flash`, `gemini-3.1-pro`, `claude-sonnet-4-6`, `claude-opus-4-6-thinking` |
|                    | `gemini-3.5-flash-low`, `gemini-3.5-flash-high`, `gemini-3.1-pro-low`, `gemini-3.1-pro-high`    |
|                    | `gemini-pro-agent`, `gemini-2.5-pro`, `gemini-2.5-flash`, `gpt-oss-120b` (via rotator)          |
| commandcode        | `moonshotai/Kimi-K2.6`, `MiniMaxAI/MiniMax-M2.7`, `xiaomi/mimo-v2.5-pro`                        |
|                    | `deepseek/deepseek-v4-pro`, `deepseek/deepseek-v4-flash`                                        |
| openrouter         | `moonshotai/kimi-k2.6:free`                                                                     |
| ollama             | `minimax-m2.5:cloud`                                                                            |

### Pi Vibeproxy & Antigravity Rotator

For multi-account rotation, local model routing, and quota management across Google Antigravity and Anthropic accounts, use [vibeproxy](https://github.com/automazeio/vibeproxy) or [pi-antigravity-rotator](https://github.com/tuxevil/pi-antigravity-rotator).

Both run as a local proxy on port `51200` and support per-model routing, real-time quota tracking, and automatic token management.

```bash
# Install Vibeproxy (macOS Menu Bar App)
brew install --cask vibeproxy

# Or install Antigravity Rotator
npm install -g pi-antigravity-rotator
pi-antigravity-rotator login
pi-antigravity-rotator start
```

Once running, Pi connects automatically via the configured provider (`vibeproxy` or `google-antigravity` respectively) in [`configs/pi/models.json`](configs/pi/models.json).

### Usage

```bash
# Start Pi
pi

# Run a task non-interactively
pi "Refactor this function to be more readable"
```

</details>

---

## 🐙 GitHub Copilot CLI (Optional)

GitHub Copilot in the terminal — agentic coding assistant that brings AI capabilities directly to your command line. [Best Practices](https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-best-practices) | [Docs](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Prerequisites

Requires an active GitHub Copilot subscription and Node.js/npm.

### Installation

```bash
npm install -g @github/copilot
```

### Configuration

Copilot CLI configs are stored in [`configs/copilot/`](configs/copilot/) and installed to the official global paths under `~/.copilot/`.

- [`AGENTS.md`](configs/copilot/AGENTS.md) - Agent guidelines and best practices, installed to `~/.copilot/copilot-instructions.md`
- [`mcp-config.json`](configs/copilot/mcp-config.json) - MCP server configuration, installed to `~/.copilot/mcp-config.json`

### MCP Servers

```json
{
	"mcpServers": {
		"context7": {
			"type": "local",
			"command": "npx",
			"args": ["-y", "@upstash/context7-mcp@latest"]
		},
		"sequential-thinking": {
			"type": "local",
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"fff": {
			"type": "local",
			"command": "fff-mcp",
			"args": []
		},
		"qmd": {
			"type": "local",
			"command": "qmd",
			"args": ["mcp"]
		},
		"react-grab-mcp": {
			"type": "local",
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"],
			"env": {},
			"tools": ["*"]
		},
		"logpilot": {
			"type": "local",
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"type": "local",
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	}
}
```

### Usage

```bash
# Start a Copilot CLI session
copilot

# Use plan mode for complex tasks (or press Shift+Tab to toggle)
/plan Add OAuth2 authentication with Google and GitHub providers

# Delegate tangential tasks to the cloud agent
/delegate Update documentation for the new API endpoints

# Select model based on task complexity
/model

# Work across multiple repositories
/add-dir /path/to/other-repo
```

</details>

---

## 🖱️ Cursor Agent CLI (Optional)

Cursor's background agent CLI — run AI-powered coding tasks directly from your terminal. [Docs](https://cursor.com/docs/cli/using)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Prerequisites

Requires the [Cursor](https://cursor.com) desktop application to be installed.

### Installation

The `cursor` CLI is bundled with the Cursor desktop app. After installing Cursor, add it to your PATH via the Command Palette:

```
Shell Command: Install 'cursor' command in PATH
```

### Configuration

Cursor Agent CLI configs are stored in [`configs/cursor/`](configs/cursor/) and installed to the official paths under `~/.cursor/`.

- [`AGENTS.md`](configs/cursor/AGENTS.md) - Agent guidelines and best practices, installed to `~/.cursor/rules/general.mdc`
- [`agents/`](configs/cursor/agents/) - Custom agents, installed to `~/.cursor/agents/`

### 📋 MCP Servers

Cursor supports MCP servers via `@~/.cursor/mcp.json`:

```json
{
	"mcpServers": {
		"context7": {
			"command": "bunx",
			"args": ["-y", "@upstash/context7-mcp@latest"]
		},
		"fff": {
			"command": "fff-mcp",
			"args": []
		},
		"sequential-thinking": {
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"command": "qmd",
			"args": ["mcp"]
		},
		"react-grab-mcp": {
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	}
}
```

### Custom Commands

Located in [`configs/cursor/commands/`](configs/cursor/commands/):

- `deslop` - Remove AI-generated boilerplate and improve code quality

### Custom Agents

Located in [`configs/cursor/agents/`](configs/cursor/agents/):

- `thermo-nuclear-code-quality-review` - Run a strict maintainability and structural quality audit

### Usage

```bash
# Open a project in Cursor
cursor .

# Open a specific file
cursor /path/to/file

# Check the CLI version
cursor --version
```

</details>

---

## 🏭 Factory Droid (Optional)

Factory's AI coding agent — end-to-end feature development from your terminal. [Homepage](https://factory.ai) | [Docs](https://docs.factory.ai/cli/getting-started/quickstart)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @factory/cli
```

After installation, navigate to your project and start the droid CLI:

```bash
cd /path/to/your/project
droid
```

### BYOK Setup (Bring Your Own Key)

Factory Droid supports using your own AI provider API keys. See the [BYOK documentation](https://docs.factory.ai/cli/byok/overview) for supported providers and configuration.

Set your API key via environment variable:

```bash
export FACTORY_API_KEY=your_api_key_here
```

Or use the interactive login:

```bash
droid /login
```

### Configuration

Factory Droid configs are stored in `configs/factory/` and installed to `~/.factory/`:

- [`AGENTS.md`](configs/factory/AGENTS.md) - Global agent guidelines
- [`mcp.json`](configs/factory/mcp.json) - MCP server configurations
- [`settings.json`](configs/factory/settings.json) - Factory Droid settings
- [`config.json`](configs/factory/config.json) - Custom model definitions
- `droids/` - Optional user-created directory for custom droid definitions

### Plugins

Factory Droid includes plugins that enhance functionality:

| Plugin                              | Description                                        |
| ----------------------------------- | -------------------------------------------------- |
| `core@factory-plugins`              | Core Factory functionality                         |
| `security-engineer@factory-plugins` | Security-focused code review engine                |
| `droid-evolved@factory-plugins`     | Advanced droid capabilities with improved autonomy |
| `autoresearch@factory-plugins`      | Autonomous research and experiment loop            |

### Custom Models

Factory Droid supports custom models via any OpenAI-compatible endpoint:

```json
{
	"customModels": [
		{
			"model": "minimax-m2.5:cloud",
			"id": "custom:minimax-m2.5:cloud-0",
			"baseUrl": "http://127.0.0.1:11434/v1",
			"apiKey": "ollama",
			"displayName": "minimax-m2.5:cloud",
			"maxOutputTokens": 128000,
			"provider": "generic-chat-completion-api"
		},
		{
			"model": "glm-4.7",
			"id": "custom:GLM-4.7-[Z.AI-Coding-Plan]-0",
			"baseUrl": "https://api.z.ai/api/coding/paas/v4",
			"displayName": "GLM-4.7 [Z.AI Coding Plan]",
			"maxOutputTokens": 131072,
			"provider": "generic-chat-completion-api"
		}
	]
}
```

### MCP Servers

```json
{
	"mcpServers": {
		"context7": {
			"type": "stdio",
			"command": "npx",
			"args": ["-y", "@upstash/context7-mcp@latest"]
		},
		"sequential-thinking": {
			"type": "stdio",
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"fff": {
			"type": "stdio",
			"command": "fff-mcp",
			"args": []
		},
		"qmd": {
			"type": "stdio",
			"command": "qmd",
			"args": ["mcp"]
		},
		"react-grab-mcp": {
			"type": "stdio",
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"type": "stdio",
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"type": "stdio",
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	}
}
```

### Usage

```bash
# Start interactive mode
droid

# Start with an initial prompt
droid "review app.tsx"

# Run non-interactively
droid exec "analyze this file"

# Resume last session
droid --resume

# Check for updates
droid update
```

</details>

---

## 💻 Cline (Optional)

AI coding assistant that runs in your terminal — built for high-performance agentic coding with support for multiple providers. [Homepage](https://cline.bot) | [Docs](https://docs.cline.bot)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g cline
```

### Authentication

Cline supports multiple authentication methods:

**Option 1: OAuth (Cline Account)**

```bash
cline
# Follow the browser authentication flow
```

**Option 2: API Keys**

Configure API keys via the Cline dashboard or set environment variables:

```bash
export FIREWORKS_API_KEY="your_key_here"
export OPENAI_API_KEY="your_key_here"
```

### Configuration

Cline configs are stored in `configs/cline/` and installed to `~/.cline/`:

- [`mcp-settings.json`](configs/cline/mcp-settings.json) - MCP server configurations, installed to `~/.cline/data/settings/cline_mcp_settings.json`
- [`models.json`](configs/cline/models.json) - Model configurations
- [`providers.json`](configs/cline/providers.json.example) - Provider credentials (copy from example and fill in your keys)
- [`kanban-config.json`](configs/cline/kanban-config.json) - Kanban board settings

### MCP Servers

```json
{
	"mcpServers": {
		"context7": {
			"alwaysAllow": [],
			"url": "https://mcp.context7.com/mcp"
		},
		"sequential-thinking": {
			"alwaysAllow": [],
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
		},
		"qmd": {
			"alwaysAllow": [],
			"command": "qmd",
			"args": ["mcp"]
		},
		"fff": {
			"alwaysAllow": [],
			"command": "fff-mcp",
			"args": []
		},
		"react-grab-mcp": {
			"alwaysAllow": [],
			"command": "npx",
			"args": ["-y", "@react-grab/mcp", "--stdio"]
		},
		"logpilot": {
			"alwaysAllow": [],
			"command": "logpilot",
			"args": ["mcp-server"]
		},
		"agentmemory": {
			"alwaysAllow": [],
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		}
	}
}
```

### Usage

```bash
# Start Cline interactive mode
cline

# Run a specific task
cline "Refactor this component to use TypeScript"

# Use with specific model
cline --model accounts/fireworks/routers/kimi-k2p5-turbo

# List available commands
cline --help
```

### Skills

Cline uses the universal skills directory at `~/.agents/skills/`. The installer automatically manages skills from the [`skills/`](skills/) folder.

</details>

---

## 🤖 Grok CLI (Optional)

xAI's AI coding assistant for the terminal. [Homepage](https://x.ai/cli) | [Docs](https://docs.x.ai/build/overview)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### 📋 Installation

```bash
npm install -g @xai-official/grok
```

Alternatively, use the curl installer:

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
```

### 🔧 Configuration

Run the setup script to install configurations to `~/.grok/`:

```bash
./cli.sh
```

The setup script automatically deploys MCP servers and agent guidelines.

### ✨ Key Features

- **Claude Code / AGENTS.md compatible** — Grok respects the same `AGENTS.md` format used by Claude Code
- **Universal skills** — Compatible with Claude Code AGENTS.md skills and `~/.agents/` conventions
- **MCP Servers** — Extend functionality via Model Context Protocol using config.toml
- **Headless scripting** — Run Grok non-interactively for CI/CD and automation pipelines
- **Modes** — Multiple interaction modes via modes and commands system

### 🔌 MCP Servers

Configuration in `configs/grok/config.toml`:

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[mcp_servers.sequential-thinking]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sequential-thinking"]

[mcp_servers.qmd]
command = "qmd"
args = ["mcp"]

[mcp_servers.fff]
command = "fff-mcp"
args = []

[mcp_servers.react-grab-mcp]
command = "npx"
args = ["-y", "@react-grab/mcp", "--stdio"]

[mcp_servers.logpilot]
command = "logpilot"
args = ["mcp-server"]

[mcp_servers.agentmemory]
command = "npx"
args = ["-y", "@agentmemory/mcp"]
```

### 📖 Agent Guidelines

Installed to `~/.grok/AGENTS.md` with instructions for:

- Session management with tmux
- Using fff MCP for file search
- Following best practices from `~/.ai-tools/best-practices.md`
- qmd knowledge management integration
- Git safety guidelines

### Usage

```bash
# Start Grok CLI
grok

# Run non-interactively (headless mode)
grok -p "Analyze the test coverage for this project"

# Use with a specific task
grok "Explain the architecture of this codebase"
```

</details>

---

## 🔄 AI Launcher (Optional)

Fast launcher for switching between AI coding assistants. [Homepage](https://github.com/jellydn/ai-launcher)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh | sh
```

### Configuration

Copy [`configs/ai-launcher/config.json`](configs/ai-launcher/config.json) to `~/.config/ai-launcher/`:

**Tools:**

| Tool       | Aliases   | Description           |
| ---------- | --------- | --------------------- |
| `claude`   | `c`       | Anthropic Claude CLI  |
| `codex`    | `co`      | OpenAI Codex CLI      |
| `opencode` | `o`, `oc` | OpenCode AI assistant |
| `amp`      | `a`       | Amp by Modular        |
| `pi`       | `p`       | Pi coding agent       |

**Templates:**

| Template                        | Aliases                    | Description                            |
| ------------------------------- | -------------------------- | -------------------------------------- |
| `review`                        | `rev`, `code-review`       | Code review with OpenCode              |
| `commit-zen`                    | `zen`, `logical-commit`    | Generate commitizen commit messages    |
| `commit-atomic`                 | `ac`, `auto-commit`        | Atomic commit messages                 |
| `architecture-explanation`      | `arch`, `arch-explanation` | Explain codebase architecture          |
| `draft-pull-request`            | `pr`, `draft-pr`           | Create draft PR via gh CLI             |
| `types`                         | `typescript`               | Enhance TypeScript types               |
| `test`                          | `spec`, `tests`            | Generate tests (Arrange-Act-Assert)    |
| `docs`                          | `document`                 | Add JSDoc documentation                |
| `explain`                       | `wtf`, `explain-code`      | Explain code in detail                 |
| `review-security`               | `sec`, `security`          | Security-focused review                |
| `review-refactor`               | `refactor`                 | Refactoring recommendations            |
| `review-performance`            | `perf`, `optimize`         | Performance analysis                   |
| `remove-verbal`                 | `verbal`, `comments`       | Clean verbal comments                  |
| `remove-ai-slop`                | `slop`, `clean-ai`         | Remove AI-generated code patterns      |
| `tidy-first`                    | `tidy`                     | Apply Tidy First principles            |
| `simplify`                      | `simple`                   | Simplify over-engineered code          |
| `simplifier`                    | `simplify-code`            | Code simplification plugin             |
| `logical-grouping-pull-request` | `split-pr`                 | Create PR with logical commit grouping |

</details>

---

## 🛠️ Companion Tools

<details>
<summary><strong>Additional Tools & Integrations</strong></summary>

### Plannotator

[**Plannotator**](https://plannotator.ai/) - Annotate plans outside the terminal for better collaboration. ([GitHub](https://github.com/backnotprop/plannotator))

### Claude-Mem

⚠️ **DEPRECATED** - Use [qmd Knowledge Management](docs/qmd-knowledge-management.md) instead.

### qmd Knowledge Skill

**qmd Knowledge Skill** is an experimental memory/context management system:

- No repository pollution (external storage)
- AI-powered semantic search
- Multi-project support
- Simple & reliable

See [GitHub Issue #11](https://github.com/jellydn/my-ai-tools/issues/11) for details.

### Claude HUD

[**Claude HUD**](https://github.com/jarrodwatts/claude-hud) - Status line monitoring for context usage, tools, agents, and todos.

```bash
# Inside Claude Code
/claude-hud:setup
```

### Try

[**Try**](https://github.com/tobi/try) - Fresh directories for every vibe. ([Interactive Demo](https://asciinema.org/a/ve8AXBaPhkKz40YbqPTlVjqgs))

### Claude Squad

[**Claude Squad**](https://github.com/smtg-ai/claude-squad) - Manage multiple AI agents in separate workspaces with isolated git worktrees.

### cmux

[**cmux**](https://github.com/manaflow-ai/cmux) - Ghostty-based macOS terminal with vertical tabs and notifications for AI coding agents.

### Conductor

[**Conductor**](https://www.conductor.build/) - Orchestrate parallel AI coding agents to work on multiple tasks simultaneously.

### Helmor

[**Helmor**](https://helmor.ai/) - Powerful workspace manager for AI coding agents with worktree isolation and automated setup.

### Spec Kit

[**Spec Kit**](https://github.com/github/spec-kit) - Toolkit for Spec-Driven Development. ([GitHub](https://github.com/github/spec-kit))

### Backlog.md

[**Backlog.md**](https://github.com/MrLesk/Backlog.md) - Markdown-native task manager and Kanban visualizer. ([npm](https://www.npmjs.com/package/backlog.md))

### Agent Browser

[**agent-browser**](https://github.com/vercel-labs/agent-browser) - Headless browser automation CLI for AI agents.

```bash
npx skills add vercel-labs/agent-browser
```

### Dev Browser

[**Dev Browser**](https://github.com/SawyerHood/dev-browser) - Browser automation plugin with persistent page state for Claude Code.

```bash
/plugin marketplace add sawyerhood/dev-browser
/plugin install dev-browser@sawyerhood/dev-browser
```

### React Tools

For React developers:

- [**React Grab**](https://www.react-grab.com/) - MCP server for extracting and analyzing React components (`@react-grab/mcp`)
- [**React Scan**](https://react-scan.com/) - Detect performance issues in your React app automatically

### Orca

[**Orca**](https://onOrca.dev) - Next-gen desktop IDE for orchestrating AI coding agents with worktree isolation, multi-agent terminals, and built-in source control. ([GitHub](https://github.com/stablyai/orca))

```bash
brew install --cask stablyai/orca/orca
```

This repository backs up Orca agent hook scripts under `configs/orca/agent-hooks/` and restores them to `~/Library/Application Support/orca/agent-hooks/` during `./cli.sh`. Hook scripts are available for Claude Code, Gemini CLI, Codex CLI, Cursor, and Factory Droid — each sends lifecycle events to Orca's hook endpoint for session tracking.

### herdr

[**herdr**](https://herdr.dev/) - Terminal-native workspace manager and multiplexer for supervising multiple AI coding agents (Claude Code, Codex, pi, and more) side by side. Run, monitor, and orchestrate agents in parallel with real terminal panes, status tracking, and a local socket API. ([GitHub](https://github.com/ogulcancelik/herdr))

</details>

---

## 📚 Best Practices

Setup includes [`configs/best-practices.md`](configs/best-practices.md) with comprehensive software development guidelines:

- Kent Beck's "Tidy First?" principles
- Kent C. Dodds' programming wisdom
- Testing Trophy approach
- Performance optimization patterns

Copy the file to your preferred location and reference it in your AI tools.

---

## 📖 Resources

- [Claude Code Documentation](https://claude.com/claude-code) - Official docs
- [OpenCode Documentation](https://opencode.ai/docs) - Guide with agents and skills
- [Antigravity CLI Getting Started](https://antigravity.google/docs/cli-getting-started) - Official guide
- [Antigravity CLI Using Guide](https://antigravity.google/docs/cli-using) - Commands and usage
- [Antigravity CLI Features](https://antigravity.google/docs/cli-features) - Feature overview
- [Antigravity gcli Migration](https://antigravity.google/docs/gcli-migration) - Migration guide
- [MCP Servers Directory](https://mcp.so) - Model Context Protocol servers
- [Context7 Documentation](https://context7.com/docs) - Library documentation lookup
- [CCS Documentation](https://github.com/kaitranntt/ccs) - Claude Code Switch
- [Claude Code Showcase](https://github.com/ChrisWiles/claude-code-showcase) - Community examples
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - Production configs
- [Claude Code Best Practice](https://github.com/shanraisshan/claude-code-best-practice) - Best practices and tips for Claude Code
- [Why I switched to Claude Code 2.0](https://blog.silennai.com/claude-code)
- [Llama.cpp Setup with Claude/Codex CLI](https://tammam.io/blog/llama-cpp-setup-with-claude-codex-cli/) - Local model setup guide
- [Modern Web Guidance](https://developer.chrome.com/docs/modern-web-guidance) - Chrome's best practices for modern web development
- [xAI CLI](https://x.ai/cli) - Grok CLI official page
- [Grok Build Docs](https://docs.x.ai/build/overview) - Getting started and configuration

---

## 👤 Author

**Dung Huynh**

- Website: [productsway.com](https://productsway.com)
- YouTube: [IT Man Channel](https://www.youtube.com/@it-man)
- GitHub: [@jellydn](https://github.com/jellydn)

---

## ⭐ Show your support

Give a ⭐️ if this project helped you!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dunghd)

---

## 📝 Contributing

Contributions, issues and feature requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

Made with ❤️ by [Dung Huynh](https://productsway.com)
