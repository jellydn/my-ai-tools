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
      "command": "npx",
      "args": ["-y", "qmd"]
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
claude mcp info context7
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
[**Plannotator**](https://github.com/anthropics/plannotator) - Annotate coding plans with context about files, dependencies, tests.

```bash
npx plannotator@latest
```

### Claude-Mem
[**Claude-Mem**](https://github.com/kirankunigiri/claude-mem) - Memory management for Claude conversations.

```bash
npx @kirankunigiri/claude-mem
```

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

- 🌐 Website: [productsway.com](https://productsway.com)
- 📺 YouTube: [IT Man Channel](https://bit.ly/m/itman)
- 💻 GitHub: [@jellydn](https://github.com/jellydn)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## ⭐ Show your support

Give a ⭐️ if this project helped you!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dunghd)

## 📝 License

Copyright © 2025 [Dung Huynh](https://github.com/jellydn)

---

Made with ❤️ by [Dung Huynh](https://productsway.com)
