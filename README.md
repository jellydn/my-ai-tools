# Welcome to my-ai-tools 👋

[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/jellydn/my-ai-tools/pulls)

> **Comprehensive configuration management for AI coding tools** - Replicate my complete setup for Claude Code, OpenCode, Amp, and CCS with custom configurations, MCP servers, plugins, and commands.

## ✨ Features

- 🚀 **One-line installer** - Get started in seconds
- 🔄 **Bidirectional sync** - Install configs or export your current setup
- 🤖 **Multiple AI tools** - Claude Code, OpenCode, Amp, CCS, and more
- 🔌 **MCP Server integration** - Context7, Sequential-thinking, qmd
- 🎯 **Custom agents & skills** - Pre-configured for maximum productivity
- 📦 **Plugin support** - Official and community plugins

## 🎬 Demo

[![IT Man Channel](https://img.shields.io/badge/YouTube-IT%20Man%20Channel-red?logo=youtube)](https://bit.ly/m/itman)

> Watch the [complete setup guide on YouTube](https://bit.ly/m/itman) or check out the [Claude HUD demo](https://github.com/jarrodwatts/claude-hud) to see the tools in action.

## 🚀 Quick Start

### Prerequisites

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **Claude Code subscription** - For full features (required)

### Installation

Install everything with a single command:

```bash
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash
```

**Options:**
```bash
# Preview changes first
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --dry-run

# With automatic backup
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --backup
```

<details>
<summary><strong>📦 Manual Installation</strong></summary>

Clone and run the installer:

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
./cli.sh
```

**Available options:**
- `--dry-run` - Preview changes without applying
- `--backup` - Backup existing configs
- `--no-backup` - Skip backup prompt

</details>

## 🤖 Supported Tools

<details>
<summary><strong>Claude Code</strong> (Required - Primary tool)</summary>

### Installation
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### MCP Servers
The installer automatically sets up:
- [`context7`](https://github.com/upstash/context7) - Documentation lookup for any library
- [`sequential-thinking`](https://mcp.so/server/sequentialthinking) - Multi-step reasoning
- [`qmd`](https://github.com/tobi/qmd) - AI-powered knowledge management

### Features
- Custom commands for common workflows
- Pre-configured agents for specialized tasks
- Community and official plugins
- Hooks for automated actions
- Skills for extended capabilities

**Manual configuration:** Add to `~/.claude/mcp-servers.json`:
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

**Useful commands:**
```bash
# List all configured servers
claude mcp list

# Remove a server
claude mcp remove context7

# Get server details
claude mcp get context7
# Get details for a specific server
claude mcp get qmd
```

**💡 Knowledge Management:**

Replace deprecated `claude-mem` with the **qmd-based knowledge system**:

- Project-specific knowledge bases in `~/.ai-knowledges/`
- AI-powered search via qmd MCP server
- No repository pollution
- See [qmd Knowledge Management Guide](docs/qmd-knowledge-management.md) for setup and usage

### Plugins

Install via setup script (`./cli.sh`) or manually:

```bash
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

# Community plugins
claude plugin install plannotator@backnotprop
claude plugin install claude-hud@claude-hud
claude plugin install worktrunk@worktrunk
```

| Plugin                  | Description                                                                                   | Source                                             |
| ----------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `typescript-lsp`        | TypeScript language server                                                                    | Official                                           |
| `pyright-lsp`           | Python language server                                                                        | Official                                           |
| `context7`              | Documentation lookup                                                                          | Official                                           |
| `frontend-design`       | UI/UX design assistance                                                                       | Official                                           |
| `learning-output-style` | Interactive learning mode                                                                     | Official                                           |
| `swift-lsp`             | Swift language support                                                                        | Official                                           |
| `lua-lsp`               | Lua language support                                                                          | Official                                           |
| `code-simplifier`       | Code simplification                                                                           | Official                                           |
| `rust-analyzer-lsp`     | Rust language support                                                                         | Official                                           |
| `claude-md-management`  | Markdown management                                                                           | Official                                           |
| `plannotator`           | Plan annotation tool                                                                          | Community                                          |
| `prd`                   | Product Requirements Document generation                                                      | Local Marketplace                                  |
| `ralph`                 | PRD to JSON converter for autonomous agent system                                             | Local Marketplace                                  |
| `qmd-knowledge`         | Project knowledge management via qmd                                                          | Local Marketplace                                  |
| `map-codebase`          | Parallel codebase analysis producing 7 structured documents                                   | Local Marketplace                                  |
| `claude-hud`            | Status line with usage monitoring                                                             | Community                                          |
| `worktrunk`             | Work management                                                                               | Community                                          |
| ~~`claude-mem`~~        | ⚠️ **DEPRECATED** - Use qmd instead or using [my fork](https://github.com/jellydn/claude-mem) | [GitHub](https://github.com/thedotmack/claude-mem) |
| ~~`beads`~~             | ⚠️ **DEPRECATED** - Native tasks                                                              | [GitHub](https://github.com/steveyegge/beads)      |

**Key Marketplace Plugins:**

- **`codemap`** - Orchestrates parallel codebase analysis to produce 7 structured documents in `.planning/codebase/`:
  - `STACK.md` - Technologies, dependencies, configuration
  - `INTEGRATIONS.md` - 3rd party providers, APIs, databases, auth
  - `ARCHITECTURE.md` - System patterns, layers, data flow
  - `STRUCTURE.md` - Directory layout, key locations, naming conventions
  - `CONVENTIONS.md` - Code style, patterns, error handling
  - `TESTING.md` - Framework, structure, mocking, coverage
  - `CONCERNS.md` - Tech debt, bugs, security, performance issues

  Use for onboarding, planning features, understanding patterns, and identifying technical debt. Inspired by [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done).

- **`prd`** - Generate Product Requirements Documents for new features

- **`ralph`** - Convert PRDs to JSON format for autonomous agent execution

- **`qmd-knowledge`** - Project-specific knowledge management using qmd MCP server (see [guide](docs/qmd-knowledge-management.md))

### Hooks

Configure in `~/.claude/settings.json`:

**PostToolUse Hooks** - Auto-format after file edits:

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
          }
        ]
      }
    ]
  }
}
```

**PreToolUse Hooks** - Transform WebSearch queries:

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

**Status Line** - Using claude-hud plugin (auto-compact disabled):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c 'node \"$(ls -td ~/.claude/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null | head -1)dist/index.js\"'"
  }
}
```

> **Tip:** Auto-compact is disabled. Use `claude-hud` to monitor context usage instead of the deprecated context-threshold hook.

### Custom Commands

- `/handoffs` - Create handoff plans for continuing work in new sessions
- `/pickup` - Resume work from previous handoff sessions
- `/plannotator-review` - Open interactive code review for current changes

Plus all commands from installed plugins.

### Custom Agents

| Agent             | Description                       | Mode     |
| ----------------- | --------------------------------- | -------- |
| `ai-slop-remover` | Cleans AI-generated code patterns | subagent |

### Skills

**Note:** `prd`, `ralph`, `qmd-knowledge`, and `codemap` are installed by `cli.sh` (marketplace by default, or local `.claude-plugin/` when selected).

- `ccs-delegation` - Auto-profile selection for CCS with context enhancement
- `context-check` - Strategic context usage guidance

### 🎓 Projects Built with AI

Real-world projects built using these AI tools:

| Project                                                           | Description                                              | Tools Used        |
| ----------------------------------------------------------------- | -------------------------------------------------------- | ----------------- |
| [Keybinder](https://github.com/jellydn/keybinder)                 | macOS app for managing skhd keyboard shortcuts           | Claude + spec-kit |
| [SealCode](https://github.com/jellydn/vscode-seal-code)           | VS Code extension for AI-powered code review             | Amp + Ralph       |
| [Ralph](https://github.com/jellydn/ralph)                         | Autonomous AI agent loop for PRD-driven development      | TypeScript        |
| [AI CLI Switcher](https://github.com/jellydn/ai-cli-switcher)     | Fast launcher for switching between AI coding assistants | TypeScript        |
| [Tiny Coding Agent](https://github.com/jellydn/tiny-coding-agent) | Minimal coding agent focused on simplicity               | TypeScript        |

📖 **[Learning Stories](docs/learning-stories.md)** - Detailed notes on development approaches, key takeaways, and tools I've tried.

### 🌟 Recommended Community Skills

Official and community-maintained skill collections for specific frameworks:

| Framework            | Skills Repository                                                                                             | Description                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Expo**             | [expo/skills](https://github.com/expo/skills)                                                                 | Official Expo skills for React Native development. Includes app creation, building, debugging, EAS updates, and config management workflows. |
| **Next.js**          | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)                                       | Vercel's agent skills for Next.js and React development. Includes project creation, component generation, and deployment workflows.          |
| **Skills Discovery** | [vercel-labs/skills/find-skills](https://github.com/vercel-labs/skills/blob/main/skills/find-skills/SKILL.md) | Skill discovery helper. Search and install skills from skills.sh when users ask about capabilities. Uses `npx skills find [query]`.          |

**Installation:**

```bash
# Clone skills to your local config directory
git clone https://github.com/expo/skills.git ~/.claude/skills/expo
git clone https://github.com/vercel-labs/agent-skills.git ~/.claude/skills/nextjs
```

### 💡 Tips & Tricks

- **OpusPlan Mode**: Use opusplan mode to plan with Opus and implement with Sonnet, then use Plannotator to review plans
- **Session Management**: Disable auto-compact in settings. Monitor context usage with `claude-hud`. Press `Ctrl+C` to quit or `/clear` to reset between coding sessions. Create a plan with `/handoffs` and resume with `/pickup` when approaching 90% context limit on big tasks.
- **Git Worktree**: Use git worktree with `try` CLI. For tmux users, use `claude-squash` to manage sessions efficiently
- **Neovim Integration**: Check out [tiny-nvim](https://github.com/jellydn/tiny-nvim) for a complete setup with [sidekick.nvim](https://github.com/folke/sidekick.nvim) or [claudecode.nvim](https://github.com/coder/claudecode.nvim)
- **Cost Optimization**: Use [CCS](https://ccs.kaitran.ca/) to switch between affordable providers:
  - [GLM Coding Plan](https://z.ai/subscribe?ic=56OG3XE37T) - $3/month for Claude Code, Cline, and 10+ coding tools
  - [MiniMax Coding Plan](https://platform.minimax.io/subscribe/coding-plan?code=CVeaL1h9wo&source=link) - $2/month with limited time.

### Configuration Files

All Claude Code configs are stored in `~/.claude/` (canonical location):

| File/Directory     | Description                                    |
| ------------------ | ---------------------------------------------- |
| `settings.json`    | Main settings with hooks, permissions, plugins |
| `mcp-servers.json` | MCP server definitions                         |
| `CLAUDE.md`        | Global instructions                            |
| `commands/`        | Custom command definitions                     |
| `agents/`          | Custom agent definitions                       |
| `skills/`          | Custom skill definitions                       |

**Latest `settings.json` configuration:**

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1"
  },
  "permissions": {
    "allow": [
      "mcp__sequential-thinking__sequentialthinking",
      "mcp__qmd__query",
      "mcp__qmd__get",
      "mcp__qmd__search",
      "mcp__qmd__vsearch",
      "mcp__qmd__multi_get",
      "mcp__qmd__status",
      "mcp__playwright__*",
      "WebSearch",
      "WebFetch(domain:github.com)",
      "Bash(curl:*)",
      "Bash(python3:*)",
      "Bash(git log:*)",
      "Bash(git pull:*)",
      "Bash(git rebase:*)",
      "Bash(gh pr:*)",
      "Bash(gh api:*)",
      "Bash(claude:*)",
      "Bash(ccs:*)",
      "Bash(kubectl get:*)",
      "Bash(docker-compose up:*)",
      "Bash(npm update:*)",
      "Bash(npm install:*)",
      "Bash(npx biome:*)",
      "Bash(jq:*)",
      "Bash(shellcheck:*)",
      "Bash(qmd:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(tree:*)"
    ],
    "defaultMode": "plan"
  },
  "model": "opusplan",
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
          }
        ]
      }
    ],
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
  },
  "statusLine": {
    "type": "command",
    "command": "bash -c 'node \"$(ls -td ~/.claude/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null | head -1)dist/index.js\"'"
  },
  "enabledPlugins": {
    "claude-mem@thedotmack": false,
    "typescript-lsp@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "learning-output-style@claude-plugins-official": true,
    "swift-lsp@claude-plugins-official": true,
    "lua-lsp@claude-plugins-official": true,
    "plannotator@plannotator": true,
    "claude-hud@claude-hud": true,
    "code-simplifier@claude-plugins-official": true,
    "worktrunk@worktrunk": true,
    "rust-analyzer-lsp@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true
  }
}
```

## 🔄 Bidirectional Config Sync

This repository supports two-way synchronization:

### Forward: Install to Home (`cli.sh`)

Copy configs from this repository to your home directory:

```bash
./cli.sh [--dry-run] [--backup] [--no-backup]
```

Options:

- `--dry-run` - Preview changes without applying
- `--backup` - Create backup before overwriting
- `--no-backup` - Skip backup prompt

### Reverse: Generate from Home (`generate.sh`)

Copy your current configs FROM home TO this repository:

```bash
./generate.sh [--dry-run]
```

**Configuration location:** `~/.claude/`
- `settings.json` - Editor settings
- `mcp-servers.json` - MCP server definitions
- `commands/` - Custom commands
- `agents/` - Custom agents
- `skills/` - Skills directory

</details>

<details>
<summary><strong>OpenCode</strong> (Optional)</summary>

### Installation
```bash
# Terminal (recommended)
curl -fsSL https://api.opencode.sh/api/v2/get-started | bash

# Or via npm
npm install -g opencode

# Or via bun
bun add -g opencode
```

### Features
- Custom agents and commands
- Skills for extended functionality
- VS Code-like interface

**Configuration location:** `~/.config/opencode/`

</details>

<details>
<summary><strong>Amp</strong> (Optional)</summary>

### Installation
```bash
# Via install script (recommended, supports auto-updates)
curl -fsSL https://amp.sh | bash

# Or via npm
npm install -g @amp-labs/amp
```

### Features
- Custom skills integration
- MCP server support
- Lightweight and fast

**Configuration location:** `~/.config/amp/`

</details>

<details>
<summary><strong>CCS - Claude Code Switch</strong> (Optional)</summary>

### Installation
```bash
npm install -g ccs
```

### Features
- Switch between multiple Claude Code accounts
- Profile management
- Hooks system for automation
- Delegate sessions for team collaboration

**Configuration location:** `~/.ccs/`

</details>

<details>
<summary><strong>OpenAI Codex CLI</strong> (Optional)</summary>

### Installation

The setup script will prompt to install Codex CLI:

```bash
./cli.sh
```

Or install manually:

```bash
npm install -g @openai/codex
```

### Configuration

Copy all files from `configs/codex/` to `~/.codex/`:

- `AGENTS.md` - Agent guidelines and best practices (replaces deprecated `instructions.md`)
- `config.json` - Model configuration and settings
- `config.toml` - Advanced configuration including MCP servers
- `prompts/` - Custom slash commands (e.g., `/handoffs`, `/tdd`, `/pr-review`)
- `skills/` - Custom skills directory for extended capabilities

### MCP Servers

Codex CLI supports MCP servers via `config.toml`:

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
```

| Server                | Purpose                                   |
| --------------------- | ----------------------------------------- |
| `context7`            | Documentation lookup for any library      |
| `sequential-thinking` | Multi-step reasoning for complex analysis |
| `qmd`                 | Knowledge management via qmd MCP          |

### Slash Commands

Codex CLI supports custom slash commands via `~/.codex/prompts/` directory. Commands are defined as Markdown files where the filename becomes the command name.

**Location:** `~/.codex/prompts/` (copied from `configs/codex/prompts/`)

**Available Commands:**

| Command      | Description                   | Usage                             |
| ------------ | ----------------------------- | --------------------------------- |
| `/handoffs`  | Create session handoff plans  | `/handoffs purpose-of-work`       |
| `/pickup`    | Resume from handoff           | `/pickup 2024-01-29-feature-x.md` |
| `/tdd`       | Test-Driven Development       | `/tdd start feature-name`         |
| `/pr-review` | Fix PR review comments        | `/pr-review 123`                  |
| `/adr`       | Architecture Decision Records | `/adr new "Decision title"`       |
| `/slop`      | Remove AI code slop           | `/slop main`                      |

**Argument Variables:**

- `$1`, `$2`, ... `$9` - Individual positional arguments
- `$ARGUMENTS` - Entire argument string
- `$$` - Literal dollar sign

**Example:**

```markdown
# Create handoff plan

<purpose>$ARGUMENTS</purpose>

Create a detailed handoff plan for...
```

**Usage:**

```
/handoffs implement-auth-feature
```

### Agent Guidelines (AGENTS.md)

Codex CLI follows the `AGENTS.md` convention, similar to `CLAUDE.md` for Claude Code and `~/.config/AGENTS.md` for Amp. The `AGENTS.md` file in `~/.codex/` provides persistent, global guidelines for Codex's behavior.

### Skills

Codex CLI supports [agent skills](https://developers.openai.com/codex/skills) in `~/.codex/skills/` directory. Skills are modular packages that extend Codex's capabilities with specialized knowledge, workflows, and tools - similar to Claude Code skills.

```markdown
# 🤖 Codex CLI Agent Guidelines

- Follow my software development practice @~/.ai-tools/best-practices.md
- Read @~/.ai-tools/MEMORY.md first
- Keep responses concise and actionable
- Always propose a plan before edits
```

**Using with Ollama (Local Models):**

To use Codex with local Ollama models, use the `--oss` flag:

```bash
npm install -g codex-cli
```

### Features
- MCP server integration
- Slash commands
- Agent guidelines support
- Skills system

**Configuration location:** `~/.config/codex-cli/`

</details>

<details>
<summary><strong>AI CLI Switcher</strong> (Optional)</summary>

Switch between different AI coding assistants seamlessly.

### Installation & Configuration
Automatically configured by `./cli.sh` at `~/.config/ai-switcher/`

</details>

## 🔄 Bidirectional Config Sync

### Install to Home (`./cli.sh`)
Deploys configurations from this repository to your home directory:
- `configs/claude/` → `~/.claude/`
- `configs/opencode/` → `~/.config/opencode/`
- `configs/amp/` → `~/.config/amp/`
- `configs/ccs/` → `~/.ccs/`

### Export from Home (`./generate.sh`)
Captures your current configurations back to the repository:
```bash
./generate.sh              # Export configs
./generate.sh --dry-run    # Preview without changes
```

This allows you to:
- Back up your working configurations
- Share your setup with others
- Keep your repository in sync with local changes

## 🛠️ Companion Tools

<details>
<summary><strong>View recommended tools</strong></summary>

### Plannotator
[**Plannotator**](https://plannotator.ai/) - Annotate plans outside the terminal for better collaboration. ([GitHub](https://github.com/backnotprop/plannotator))

```bash
npx plannotator@latest
```

### Claude-Mem

⚠️ **DEPRECATED** - The original claude-mem is currently broken and not recommended. See [issue #609](https://github.com/thedotmack/claude-mem/issues/609).

**Alternative:** Use the [qmd Knowledge Management System](docs/qmd-knowledge-management.md) for project-specific knowledge capture.

### qmd Knowledge Skill
[**qmd**](https://github.com/tobi/qmd) - Quick Markdown Search with AI-powered knowledge management.

**Status:** 🧪 Experimental

See [qmd Knowledge Management Guide](docs/qmd-knowledge-management.md) and [GitHub Issue #11](https://github.com/jellydn/my-ai-tools/issues/11).

### Claude HUD
[**Claude HUD**](https://github.com/jarrodwatts/claude-hud) - Status line monitoring for Claude Code.

```bash
# Inside Claude Code, run:
/claude-hud:setup
```

<img width="1058" height="138" alt="Claude HUD Screenshot" src="https://github.com/user-attachments/assets/afab87bb-d78f-4cc8-9e1b-f3948a7e6fe6" />

### Try
[**Try**](https://github.com/tobi/try) - Fresh directories for experiments with fuzzy search and smart sorting. ([Demo](https://asciinema.org/a/ve8AXBaPhkKz40YbqPTlVjqgs))

### Claude Squad
[**Claude Squad**](https://github.com/smtg-ai/claude-squad) - Manage multiple AI agents in separate workspaces with isolated git worktrees.

### Spec Kit
[**Spec Kit**](https://github.com/github/spec-kit) - Spec-Driven Development toolkit for AI-native workflows.

### Backlog.md
[**Backlog.md**](https://github.com/MrLesk/Backlog.md) - Markdown-native task manager and Kanban visualizer.

### Agent Browser
[**agent-browser**](https://github.com/vercel-labs/agent-browser) - Headless browser automation CLI for AI agents.

```bash
npx skills add vercel-labs/agent-browser
```

</details>

## 📚 Best Practices

Setup includes [`best-practices.md`](configs/best-practices.md) with comprehensive guidelines:
- Kent Beck's "Tidy First?" principles
- Kent C. Dodds' programming wisdom
- Testing Trophy approach
- Performance optimization patterns

## 📖 Resources

<details>
<summary><strong>Documentation & Learning</strong></summary>

### Official Documentation
- [Claude Code Documentation](https://claude.com/claude-code)
- [OpenCode Documentation](https://opencode.ai/docs)
- [MCP Servers Directory](https://mcp.so)
- [Context7 Documentation](https://context7.com/docs)

### Community Resources
- [Claude Code Showcase](https://github.com/ChrisWiles/claude-code-showcase) - Community examples
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - Production configs
- [Why I switched to Claude Code 2.0](https://blog.silennai.com/claude-code)

### Additional Guides
- [Skill Standard Documentation](docs/SKILL_STANDARD.md)
- [Learning Stories](docs/learning-stories.md)
- [qmd Knowledge Management](docs/qmd-knowledge-management.md)

</details>

## 👤 Author

**Dung Huynh**

- Website: [productsway.com](https://productsway.com)
- YouTube: [IT Man Channel](https://www.youtube.com/@it-man)
- GitHub: [@jellydn](https://github.com/jellydn)

## ⭐ Show your support

Give a ⭐️ if this project helped you!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dunghd)

## 📝 License

Copyright © 2025 [Dung Huynh](https://github.com/jellydn)

---

Made with ❤️ by [Dung Huynh](https://productsway.com)
