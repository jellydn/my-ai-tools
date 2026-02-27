# Welcome to my-ai-tools 👋

[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/jellydn/my-ai-tools/pulls)

> **Comprehensive configuration management for AI coding tools** - Replicate my complete setup for Claude Code, OpenCode, Amp, Kilo CLI, Codex, Gemini CLI and CCS with custom configurations, MCP servers, skills, plugins, and commands.

📖 **[View Documentation Website](https://ai-tools.itman.fyi)** - Interactive landing page with full documentation and search.

## ✨ Features

- 🚀 **One-line installer** - Get started in seconds
- 🔄 **Bidirectional sync** - Install configs or export your current setup
- 🤖 **Multiple AI tools** - Claude Code, OpenCode, Amp, CCS, and more
- 🔌 **MCP Server integration** - Context7, Sequential-thinking, qmd
- 🎯 **Custom agents & skills** - Pre-configured for maximum productivity
- 📦 **Plugin support** - Official and community plugins
- 🛡️ **Git Guard Hook** - Prevents dangerous git commands (force push, hard reset, etc.)

## 🎬 Demo

[![IT Man Channel](https://img.shields.io/badge/YouTube-IT%20Man%20Channel-red?logo=youtube)](https://github.com/jellydn/itman-channel)

[![IT Man - My AI Setup in 2026](https://i.ytimg.com/vi/ESudSFAyuuw/mqdefault.jpg)](https://www.youtube.com/watch?v=ESudSFAyuuw)

## 📋 Prerequisites

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **Claude Code subscription** or use [CCS](#-ccs---claude-code-switch-optional) with affordable providers (GLM, MiniMax)

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

---

## 🤖 Claude Code

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

#### Manual Setup

##### For Claude Desktop

Add to [`~/.claude/mcp-servers.json`](configs/claude/mcp-servers.json):

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
    }
  }
}
```

##### For Claude Code

Use the CLI (installed globally for all projects):

```bash
claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add --scope user --transport stdio qmd -- qmd mcp
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

# Install skills from this repository (jellydn/my-ai-tools)
# Recommended: Install all skills at once using npx skills add
npx skills add jellydn/my-ai-tools --yes --global --agent claude-code

# Or install interactively (select which skills to install)
npx skills add jellydn/my-ai-tools --global --agent claude-code

# Available skills: prd, ralph, qmd-knowledge, codemap, adr, handoffs, pickup, plannotator-review, pr-review, slop, tdd
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

| Plugin                  | Description                       | Source            |
| ----------------------- | --------------------------------- | ----------------- |
| `typescript-lsp`        | TypeScript language server        | Official          |
| `pyright-lsp`           | Python language server            | Official          |
| `context7`              | Documentation lookup              | Official          |
| `frontend-design`       | UI/UX design assistance           | Official          |
| `learning-output-style` | Interactive learning mode         | Official          |
| `swift-lsp`             | Swift language support            | Official          |
| `lua-lsp`               | Lua language support              | Official          |
| `code-simplifier`       | Code simplification               | Official          |
| `rust-analyzer-lsp`     | Rust language support             | Official          |
| `claude-md-management`  | Markdown management               | Official          |
| `plannotator`           | Plan annotation tool              | Community         |
| `prd`                   | Product Requirements Documents    | Local Marketplace |
| `ralph`                 | PRD to JSON converter             | Local Marketplace |
| `qmd-knowledge`         | Project knowledge management      | Local Marketplace |
| `codemap`               | Parallel codebase analysis        | Local Marketplace |
| `claude-hud`            | Status line with usage monitoring | Community         |
| `worktrunk`             | Work management                   | Community         |

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
- `/plannotator-review` - Interactive code review
- `/ultrathink` - Deep thinking mode

#### Custom Agents

Located in [`configs/claude/agents/`](configs/claude/agents/):

- `ai-slop-remover` - Remove AI-generated boilerplate and improve code quality

#### Skills

**Local Marketplace Plugins** - Installed by `cli.sh` from [`skills/`](skills/):

- `adr` - Architecture Decision Records
- `codemap` - Parallel codebase analysis producing structured documentation
- `handoffs` - Create handoff plans for continuing work (provides `/handoffs` command)
- `pickup` - Resume work from previous handoff sessions (provides `/pickup` command)
- `pr-review` - Pull request review workflows
- `prd` - Generate Product Requirements Documents
- `qmd-knowledge` - Project knowledge management
- `ralph` - Convert PRDs to JSON for autonomous agent execution
- `plannotator-review` - Interactive code review via Plannotator UI
- `slop` - AI slop detection and removal
- `tdd` - Test-Driven Development workflows

#### Projects Built with AI

Real-world projects built using these AI tools:

| Project                                                           | Description                                              | Tools Used                  |
| ----------------------------------------------------------------- | -------------------------------------------------------- | --------------------------- |
| [Oak](https://github.com/jellydn/oak)                             | Lightweight macOS focus companion for deep work with notch-first UI | Ralph + OpenCode + Codex GPT 5.2 |
| [Prosody](https://github.com/jellydn/prosody)                     | Mobile app for English speaking rhythm coaching with AI feedback    | Ralph + OpenCode + GLM + Amp/Codex (review) |
| [Keybinder](https://github.com/jellydn/keybinder)                 | macOS app for managing skhd keyboard shortcuts           | Claude + spec-kit           |
| [SealCode](https://github.com/jellydn/vscode-seal-code)           | VS Code extension for AI-powered code review             | Amp + Ralph                 |
| [Ralph](https://github.com/jellydn/ralph)                         | Autonomous AI agent loop for PRD-driven development      | TypeScript                  |
| [AI Launcher](https://github.com/jellydn/ai-launcher)             | Fast launcher for switching between AI coding assistants | TypeScript                  |
| [Tiny Coding Agent](https://github.com/jellydn/tiny-coding-agent) | Minimal coding agent focused on simplicity               | TypeScript                  |
| [dotenv-tui](https://github.com/jellydn/dotenv-tui)               | Terminal UI for managing `.env` files across projects    | Go + Bubble Tea             |
| [tiny-cloak.nvim](https://github.com/jellydn/tiny-cloak.nvim)     | Neovim plugin that masks sensitive data in `.env` files  | Lua + Neovim                |
| [tiny-term.nvim](https://github.com/jellydn/tiny-term.nvim)       | Minimal terminal plugin for Neovim 0.11+                 | Lua + Neovim                |
| [Sky Alert](https://github.com/jellydn/sky-alert)                 | Real-time flight monitoring Telegram bot                 | OpenCode + GLM 4.7 + Amp + Codex CLI |

📖 **[Learning Stories](docs/learning-stories.md)** - Detailed notes on development approaches, key takeaways, and tools I've tried.

#### Recommended Community Skills

Official and community-maintained skill collections for specific frameworks:

| Framework            | Skills Repository                                                                                             | Description                                                                                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **UI/UX Design**     | [Interface Design](https://interface-design.dev/)                                                             | Comprehensive guide to interface design patterns and best practices for anyone working with UI/UX development.                                                             |
| **Expo**             | [expo/skills](https://github.com/expo/skills)                                                                 | Official Expo skills for React Native development. Includes app creation, building, debugging, EAS updates, and config management workflows.                               |
| **Next.js**          | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)                                       | Vercel's agent skills for Next.js and React development. Includes project creation, component generation, and deployment workflows.                                        |
| **Andrej Karpathy**  | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)                 | Community skills inspired by Andrej Karpathy's coding principles and practices for AI-focused development workflows.                                                       |
| **Humanizer**        | [blader/humanizer](https://github.com/blader/humanizer)                                                       | Removes signs of AI-generated writing from text. Based on Wikipedia's AI writing detection guide, it detects 24 patterns to make text sound more natural and human.        |
| **Claude Skills**    | [jezweb/claude-skills](https://github.com/jezweb/claude-skills)                                               | 97 production-ready skills for Claude Code CLI including Cloudflare, React, AI integrations, and more. Includes context-mate for project analysis and workflow management. |
| **Skills Discovery** | [vercel-labs/skills/find-skills](https://github.com/vercel-labs/skills/blob/main/skills/find-skills/SKILL.md) | Skill discovery helper. Search and install skills from skills.sh when users ask about capabilities. Uses `npx skills find [query]`.                                        |

**Installation:**

```bash
# Install skills using npx skills add
npx skills add expo/skills --global --agent claude-code
npx skills add vercel-labs/agent-skills --global --agent claude-code
npx skills add blader/humanizer --global --agent claude-code
npx skills add jezweb/claude-skills --global --agent claude-code
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
- **Git Worktree**: Use git worktree with `try` CLI. For tmux users, use `claude-squash` to manage sessions efficiently
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
    "@mohak34/opencode-notifier@latest"
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
- **[@mohak34/opencode-notifier](https://github.com/mohak34/opencode-notifier)** - Sound and system notifications for events (permission requests, completion, errors, questions)

Plugins are automatically installed on next OpenCode launch. Configure notification behavior via `~/.config/opencode/opencode-notifier.json` if desired.

### Custom Agents

Located in [`configs/opencode/agent/`](configs/opencode/agent/):

- `ai-slop-remover` - Remove AI-generated boilerplate
- `docs-writer` - Generate documentation
- `review` - Code review
- `security-audit` - Security auditing

### Custom Commands

Located in [`configs/opencode/command/`](configs/opencode/command/):

- `plannotator-review` - Interactive code review

</details>

---

## 🎯 Amp (Optional)

AI coding assistant by Modular. [Homepage](https://ampcode.com)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://ampcode.com/install.sh | bash
```

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
    "chrome-devtools": {
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest"]
    },
    "backlog": {
      "command": "backlog",
      "args": ["mcp", "start"]
    },
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

See [`configs/amp/AGENTS.md`](configs/amp/AGENTS.md) for agent guidelines.

### Skills

| Skill | Description |
|-------|-------------|
| `plannotator-review` | Interactive code review via Plannotator UI |

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
2. **OAuth Providers** - Gemini, Codex, Antigravity, GitHub Copilot (zero API keys needed)
3. **API Profiles** - GLM, Kimi, OpenRouter, or any Anthropic-compatible API

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
   ccs glm       # GLM (API key)
   ccs ollama    # Local Ollama
   ```

### Configuration

CCS auto-creates config on install. Dashboard is the recommended way to manage settings.

**Config location**: [`~/.ccs/config.yaml`](configs/ccs/config.yaml)

See [`configs/ccs/config.yaml`](configs/ccs/config.yaml) for example configuration.

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

- [`config.json`](configs/codex/config.json) - Main configuration
- [`config.toml`](configs/codex/config.toml) - Alternative TOML format
- [`AGENTS.md`](configs/codex/AGENTS.md) - Agent guidelines

### Usage

```bash
# Start Codex CLI
codex

# Use with Ollama (local models)
codex --oss

# Use with a specific task
codex "Explain this code"
```

### Skills

| Skill | Description |
|-------|-------------|
| `plannotator-review` | Interactive code review via Plannotator UI |

</details>

---

## 🔷 Google Gemini CLI (Optional)

Google's AI agent that brings the power of Gemini directly into your terminal. [Homepage](https://github.com/google-gemini/gemini-cli)

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

- `claude` / `c` - Claude CLI
- `opencode` / `o`, `oc` - OpenCode
- `amp` / `a` - Amp

**Templates:**

- `review` - Code review
- `commit` / `commit-zen` - Commit messages
- `ac` / `commit-atomic` - Atomic commits
- `pr` / `draft-pr` - Pull requests
- `types` - Type safety
- `test` - Tests
- `docs` - Documentation
- `simplify` - Code simplification

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
- [MCP Servers Directory](https://mcp.so) - Model Context Protocol servers
- [Context7 Documentation](https://context7.com/docs) - Library documentation lookup
- [CCS Documentation](https://github.com/kaitranntt/ccs) - Claude Code Switch
- [Claude Code Showcase](https://github.com/ChrisWiles/claude-code-showcase) - Community examples
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - Production configs
- [Why I switched to Claude Code 2.0](https://blog.silennai.com/claude-code)

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
