# Welcome to my-ai-tools 👋

Comprehensive guide to replicate my AI coding tools setup with custom configurations, MCP servers, plugins, and commands.

## 📋 Prerequisites

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **Claude Code subscription** - For full Claude Code features (required)

## 🚀 Quick Start

```bash
sh cli.sh
```

**Options:**

- `--dry-run` - Preview changes without making them
- `--backup` - Backup existing configs before installing
- `--no-backup` - Skip backup prompt

## 🤖 Claude Code (Required)

Primary AI coding assistant with extensive customization.

### Installation

```bash
npm install -g @anthropic-ai/claude-code
```

### MCP Servers

Add to `~/.claude/mcp-servers.json`:

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
    }
  }
}
```

**Available MCP Servers:**

- [`context7`](https://github.com/upstash/context7) - Documentation lookup for any library
- [`sequential-thinking`](https://mcp.so/server/sequentialthinking) - Multi-step reasoning for complex analysis

### Plugins

Enable in Claude Code settings:

| Plugin                  | Description                         | Link                                                 |
| ----------------------- | ----------------------------------- | ---------------------------------------------------- |
| `claude-mem`            | Context memory across sessions      | [GitHub](https://github.com/thedotmack/claude-mem)   |
| `typescript-lsp`        | TypeScript language server          | Official                                             |
| `pyright-lsp`           | Python language server              | Official                                             |
| `context7`              | Documentation lookup                | [GitHub](https://github.com/upstash/context7)        |
| `frontend-design`       | UI/UX design assistance             | Official                                             |
| `learning-output-style` | Interactive learning mode           | Official                                             |
| `swift-lsp`             | Swift language support              | Official                                             |
| `lua-lsp`               | Lua language support                | Official                                             |
| `beads`                 | Issue tracking & project management | [GitHub](https://github.com/steveyegge/beads)        |
| `plannotator`           | Plan annotation tool                | [GitHub](https://github.com/backnotprop/plannotator) |
| `claude-hud`            | Status line with usage monitoring   | [GitHub](https://github.com/jarrodwatts/claude-hud)  |

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
            "command": "node \"/Users/YOUR_USERNAME/.ccs/hooks/websearch-transformer.cjs\"",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### Custom Commands

- `/handoffs` - Create handoff plans for continuing work in new sessions
- `/pickup` - Resume work from previous handoff sessions

Plus all commands from installed plugins.

### Configuration Files

Copy from `configs/claude/` directory:

- `settings.json` - Main settings with hooks and permissions
- `mcp-servers.json` - MCP server definitions
- `CLAUDE.md` - Global instructions
- `commands/` - Custom command definitions

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

This is useful for:
- Saving your current configuration to version control
- Backing up working configs
- Sharing your setup with others

**Note:** Sensitive files (like `*.settings.json` containing API keys) are automatically excluded from CCS config sync.

## 🎨 OpenCode (Optional)

Alternative AI coding assistant with custom agents and skills.

### Installation

```bash
# Terminal (recommended)
curl -fsSL https://opencode.ai/install | bash

# Or via npm
npm install -g opencode-ai

# Or via bun
bun add -g opencode-ai

# Or via Homebrew
brew install opencode
```

### Configuration

Copy `configs/opencode/opencode.json` to `~/.config/opencode/`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["./configs/best-practices.md"],
  "theme": "kanagawa",
  "default_agent": "plan",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    }
  },
  "agent": {
    "build": {
      "permission": {
        "bash": {
          "git push": "ask"
        }
      }
    }
  },
  "plugin": ["@plannotator/opencode@latest"]
}
```

### Custom Agents

| Agent             | Description                              | Mode     |
| ----------------- | ---------------------------------------- | -------- |
| `ai-slop-remover` | Cleans AI-generated code patterns        | subagent |
| `docs-writer`     | Technical documentation writer           | subagent |
| `review`          | Code review for quality & best practices | subagent |
| `security-audit`  | Security vulnerability identification    | subagent |

### Custom Commands

- `/slop [branch]` - Remove AI code patterns from a branch

### Skills

- `git-release` - Create consistent releases and changelogs

## 🎯 Amp (Optional)

Lightweight AI assistant with browser and backlog integration.

### Installation

```bash
# Recommended: via install script (supports auto-updating)
curl -fsSL https://ampcode.com/install.sh | bash

# Or via npm (if necessary)
npm install -g @sourcegraph/amp@latest
```

### Configuration

Copy `configs/amp/settings.json` to `~/.config/amp/`:

```json
{
  "amp.dangerouslyAllowAll": true,
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
    }
  }
}
```

### MCP Servers

- [`context7`](https://github.com/upstash/context7) - Documentation lookup for any library
- [`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp) - Control and inspect live Chrome browser instances. Debug, analyze network requests, take screenshots, profile performance, and automate browser testing. ([npm](https://npmjs.org/package/chrome-devtools-mcp))
- [`backlog`](https://github.com/MrLesk/Backlog.md) - Task management and backlog tracking

## 🔄 CCS - Claude Code Switch (Optional)

[**CCS (Claude Code Switch)**](https://github.com/kaitranntt/ccs) - Seamlessly switch between multiple Claude accounts and API providers.

### Installation

```bash
npm install -g @kaitranntt/ccs
```

### Features

- **Multiple Accounts**: Switch between different Claude subscriptions instantly
- **API Profiles**: Support for GLM, Kimi, OpenRouter, and custom endpoints
- **CLIProxy**: OAuth-based providers (Gemini, Codex, Agy, Qwen, iFlow, Kiro, GitHub Copilot)
- **WebSearch Fallback**: Automatic web search for third-party providers
- **Zero Downtime**: Switch accounts without losing context

### Configuration

Copy all files from `configs/ccs/` to `~/.ccs/`:

- `config.yaml` - Main configuration
- `config.json` - Claude Code integration
- `*.settings.json` - API provider settings (glm, kimi, mm, etc.)
- `cliproxy/` - OAuth provider configurations
- `hooks/` - Web search hooks

```yaml
version: 7

profiles:
  glm:
    type: api
    settings: ~/.ccs/glm.settings.json
  kimi:
    type: api
    settings: ~/.ccs/kimi.settings.json
  mm:
    type: api
    settings: ~/.ccs/mm.settings.json

cliproxy:
  providers:
    - gemini
    - codex
    - agy
    - qwen
    - iflow

websearch:
  enabled: true
  providers:
    gemini:
      enabled: true
      model: gemini-2.5-flash
```

### Usage

```bash
# Switch to a profile
ccs kimi

# Create new account profile
ccs auth create work

# List available profiles
ccs auth list
```

## 🛠️ Companion Tools

### Plannotator

[**Plannotator**](https://plannotator.ai/) - Annotate plans outside the terminal for better collaboration. ([GitHub](https://github.com/backnotprop/plannotator))

### Claude-Mem

[**Claude-Mem**](https://claude-mem.ai/) - Stop explaining context repeatedly. Build faster with persistent memory. ([GitHub](https://github.com/thedotmack/claude-mem))

**Note:** Auto-compact is disabled in this setup to preserve full session history.

### Claude HUD

[**Claude HUD**](https://github.com/jarrodwatts/claude-hud) - Status line monitoring plugin for tracking context usage, active tools, running agents, and todo progress.

```bash
# Inside Claude Code, run:
/claude-hud:setup
```

The HUD appears immediately — no restart needed.

### Try

[**Try**](https://github.com/tobi/try) - Fresh directories for every vibe. Instantly navigate through experiment directories with fuzzy search, smart sorting, and auto-dating. ([Interactive Demo](https://asciinema.org/a/ve8AXBaPhkKz40YbqPTlVjqgs))

### Claude Squad

[**Claude Squad**](https://github.com/smtg-ai/claude-squad) - Terminal app to manage multiple AI agents (Claude Code, Aider, Codex, Gemini, etc.) in separate workspaces. Work on multiple tasks simultaneously with isolated git worktrees.

### Spec Kit

[**Spec Kit**](https://github.com/github/spec-kit) - Toolkit for Spec-Driven Development. Create specifications, implementation plans, and task lists for new features and greenfield projects with AI-native workflow. ([GitHub](https://github.com/github/spec-kit))

### Backlog.md

[**Backlog.md**](https://github.com/MrLesk/Backlog.md) - Markdown-native task manager and Kanban visualizer. Manage project backlogs entirely in Git with CLI, web interface, and AI integration. ([npm](https://www.npmjs.com/package/backlog.md))

## 📚 Best Practices

Setup includes `best-practices.md` with comprehensive software development guidelines based on:

- Kent Beck's "Tidy First?" principles
- Kent C. Dodds' programming wisdom
- Testing Trophy approach
- Performance optimization patterns

Copy [`configs/best-practices.md`](configs/best-practices.md) to your preferred location and reference it in your AI tools.

## 📖 Resources

- [Claude Code Documentation](https://claude.com/claude-code)
- [OpenCode Documentation](https://opencode.ai/docs)
- [MCP Servers Directory](https://mcp.so)
- [Context7 Documentation](https://context7.com/docs)
- [CCS Documentation](https://github.com/kaitranntt/ccs)
- [Claude Code Showcase](https://github.com/ChrisWiles/claude-code-showcase)

## 👤 Author

**Dung Huynh**

- Website: [productsway.com](https://productsway.com)
- YouTube: [IT Man Channel](https://bit.ly/m/itman)
- GitHub: [@jellydn](https://github.com/jellydn)

## ⭐ Show your support

Give a ⭐️ if this project helped you!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dunghd)

## 📝 Contributing

Contributions, issues and feature requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

Made with ❤️ by [Dung Huynh](https://productsway.com)
