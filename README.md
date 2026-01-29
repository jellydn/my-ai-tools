# Welcome to my-ai-tools 👋

[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/jellydn/my-ai-tools/pulls)

> **Comprehensive configuration management for AI coding tools** - Replicate my complete setup for Claude Code, OpenCode, Amp, Codex and CCS with custom configurations, MCP servers, plugins, and commands.

## ✨ Features

- 🚀 **One-line installer** - Get started in seconds
- 🔄 **Bidirectional sync** - Install configs or export your current setup
- 🤖 **Multiple AI tools** - Claude Code, OpenCode, Amp, CCS, and more
- 🔌 **MCP Server integration** - Context7, Sequential-thinking, qmd
- 🎯 **Custom agents & skills** - Pre-configured for maximum productivity
- 📦 **Plugin support** - Official and community plugins

## 🎬 Demo

[![IT Man Channel](https://img.shields.io/badge/YouTube-IT%20Man%20Channel-red?logo=youtube)](https://github.com/jellydn/itman-channel)

[![IT Man - My AI Setup in 2026](https://i.ytimg.com/vi/ESudSFAyuuw/mqdefault.jpg)](https://www.youtube.com/watch?v=ESudSFAyuuw)

## 📋 Prerequisites

- **Bun or Node.js LTS** - Runtime for tools and scripts
- **Git** - Version control
- **Claude Code subscription** - For full Claude Code features (required)

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

## 🤖 Claude Code (Required)

Primary AI coding assistant with extensive customization.

### Installation

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

<details>
<summary><strong>📦 MCP Servers Setup</strong></summary>

### Automatic Setup (Recommended)

Run the setup script to configure MCP servers:

```bash
./cli.sh
```

The script will prompt you to install each MCP server:

- [`context7`](https://github.com/upstash/context7) - Documentation lookup for any library
- [`sequential-thinking`](https://mcp.so/server/sequentialthinking) - Multi-step reasoning for complex analysis
- [`qmd`](https://github.com/tobi/qmd) - Quick Markdown Search with AI-powered knowledge management

### Manual Setup

#### For Claude Desktop

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

#### For Claude Code

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

### Managing MCP Servers

```bash
# List all configured servers
claude mcp list

# Remove an MCP server
claude mcp remove context7

# Get details for a specific server
claude mcp get qmd
```

### Knowledge Management

Replace deprecated `claude-mem` with **qmd-based knowledge system**:

- Project-specific knowledge bases in `~/.ai-knowledges/`
- AI-powered search via qmd MCP server
- No repository pollution
- See [qmd Knowledge Management Guide](docs/qmd-knowledge-management.md)

</details>

<details>
<summary><strong>🔌 Plugins</strong></summary>

### Installation

Install via setup script or manually:

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

### Plugin List

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
| `map-codebase`          | Parallel codebase analysis        | Local Marketplace |
| `claude-hud`            | Status line with usage monitoring | Community         |
| `worktrunk`             | Work management                   | Community         |

### Key Marketplace Plugins

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

</details>

<details>
<summary><strong>⚙️ Hooks & Status Line</strong></summary>

Configure in [`~/.claude/settings.json`](configs/claude/settings.json):

### PostToolUse Hooks

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
          }
        ]
      }
    ]
  }
}
```

### PreToolUse Hooks

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

### Status Line

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

</details>

<details>
<summary><strong>🎯 Custom Commands, Agents & Skills</strong></summary>

### Custom Commands

Located in [`configs/claude/commands/`](configs/claude/commands/):

- `/ccs` - CCS delegation and profile management
- `/plannotator-review` - Interactive code review
- `/ultrathink` - Deep thinking mode

### Custom Agents

Located in [`configs/claude/agents/`](configs/claude/agents/):

- `ai-slop-remover` - Remove AI-generated boilerplate and improve code quality

### Skills

**Local Marketplace Plugins** - Installed by `cli.sh` from [`.claude-plugin/plugins/`](.claude-plugin/plugins/):

- `adr` - Architecture Decision Records
- `codemap` - Parallel codebase analysis producing structured documentation
- `handoffs` - Create handoff plans for continuing work (provides `/handoffs` command)
- `pickup` - Resume work from previous handoff sessions (provides `/pickup` command)
- `pr-review` - Pull request review workflows
- `prd` - Generate Product Requirements Documents
- `qmd-knowledge` - Project knowledge management
- `ralph` - Convert PRDs to JSON for autonomous agent execution
- `slop` - AI slop detection and removal
- `tdd` - Test-Driven Development workflows

### Projects Built with AI

- [**CopilotKit Next OpenAI Template**](https://github.com/jellydn/copilotkit-next-openai-template)
- [**Screenshot To Code AI**](https://github.com/jellydn/screenshot-to-code-ai)
- [**Code Review Action**](https://github.com/jellydn/code-review-action)

### Recommended Community Skills

- [**AI-optimized prompt format (MCP Protocol)**](https://github.com/modelcontextprotocol/docs/issues/104) - Best practices for prompting AI tools

Install community skills:

```bash
# Clone skills to your local config directory
npx skills add vercel-labs/agent-browser
```

</details>

<details>
<summary><strong>📝 Configuration Files</strong></summary>

All configuration files are located in the [`configs/claude/`](configs/claude/) directory:

- [`settings.json`](configs/claude/settings.json) - Main Claude Code settings
- [`mcp-servers.json`](configs/claude/mcp-servers.json) - MCP server configurations
- [`commands/`](configs/claude/commands/) - Custom slash commands
- [`agents/`](configs/claude/agents/) - Custom agent definitions

Local marketplace plugins are in [`.claude-plugin/plugins/`](.claude-plugin/plugins/).

### Tips & Tricks

- Use `claude mcp add --scope user` for global MCP servers
- Enable hooks for auto-formatting on save
- Install language server plugins for better code navigation
- Use qmd for persistent knowledge management
- Create custom commands for frequent workflows

</details>

---

## 🎨 OpenCode (Optional)

OpenAI-powered AI coding assistant.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @opencode/cli
```

Or using Homebrew:

```bash
brew install opencode
```

### Configuration

Copy [`configs/opencode/opencode.json`](configs/opencode/opencode.json) to `~/.config/opencode/`:

```json
{
  "model": "o1-preview",
  "provider": "openai",
  "skills": [
    {
      "name": "atomic-commits",
      "path": "~/.config/opencode/skills/atomic-commits"
    },
    {
      "name": "zen-commit",
      "path": "~/.config/opencode/skills/zen-commit"
    }
  ]
}
```

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

Modular's AI coding assistant focused on speed.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
# macOS/Linux
curl -sSf https://get.amp.ai | sh

# Or using Homebrew
brew install amp
```

### Configuration

Copy [`configs/amp/settings.json`](configs/amp/settings.json) to `~/.config/amp/`:

```json
{
  "model": "claude-3.5-sonnet",
  "provider": "anthropic",
  "skills": []
}
```

See [`configs/amp/AGENTS.md`](configs/amp/AGENTS.md) for agent guidelines.

### MCP Servers

Amp uses the same MCP server configuration as Claude Code. MCP servers are typically configured globally.

</details>

---

## 🔄 CCS - Claude Code Switch (Optional)

Switch between multiple Claude Code accounts.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @kaitranntt/ccs
```

### Features

- Switch between multiple Claude Code accounts
- Share MCP servers across accounts
- Custom hooks per account
- CLI proxy for seamless switching

### Configuration

Located in [`configs/ccs/`](configs/ccs/):

- [`config.yaml`](configs/ccs/config.yaml) - Main CCS configuration with account profiles

### Usage

```bash
# List accounts
ccs list

# Switch account
ccs switch <account-name>

# Get current account
ccs current
```

</details>

---

## 🤖 OpenAI Codex CLI (Optional)

OpenAI's command-line coding assistant.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
npm install -g @openai/codex-cli
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

</details>

---

## 🔄 AI CLI Switcher (Optional)

Fast launcher for switching between AI coding assistants.

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jellydn/ai-cli-switcher/main/install.sh | sh
```

### Configuration

Copy [`configs/ai-switcher/config.json`](configs/ai-switcher/config.json) to `~/.config/ai-switcher/`:

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
