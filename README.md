# Welcome to my-ai-tools 👋

[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/jellydn/my-ai-tools/pulls)

> **Comprehensive configuration management for AI coding tools** - Replicate my complete setup for Claude Code, OpenCode, Amp, Kilo CLI, Codex, Devin CLI, Kimi Code, Gemini CLI, Antigravity CLI, Pi, Oh My Pi, GitHub Copilot CLI, Cursor Agent CLI, Factory Droid, Cline, Grok CLI, MiMo-Code, Qoder CLI, Kiro CLI, Hunk, Delta, Codiff, ctx, Open Code Review, CCS, and Reasonix with custom configurations, MCP servers, skills, plugins, and commands.

📖 **[View Documentation Website](https://ai-tools.itman.fyi)** - Interactive landing page with full documentation and search.

## ✨ Features

- 🚀 **One-line installer** - Get started in seconds
- 🔄 **Bidirectional sync** - Install configs or export your current setup
- 🤖 **Multiple AI tools** - Claude Code, OpenCode, Amp, CCS, Devin, Kimi Code, Gemini, Antigravity, Grok, MiMo-Code, Qoder CLI, Kiro CLI, Hunk, Delta, Codiff, ctx, Open Code Review, Reasonix, and more
- 🔌 **MCP Server integration** - Context7, Sequential-thinking, qmd, codebase-memory-mcp, agentmemory, sem, ctx
- 🎯 **Custom agents & skills** - Pre-configured for maximum productivity
- 🤝 **Agent Teams** - Coordinate specialized agents for complex workflows (code review, testing, docs)
- 📦 **Plugin support** - Official and community plugins
- 🛡️ **Git Guard Hook** - Prevents dangerous git commands (force push, hard reset, etc.)

## 🖥️ Devin CLI (Optional)

Cognition AI's autonomous coding agent with deep cloud integration. [Homepage](https://devin.ai) | [Docs](https://docs.devin.ai)

<details>
<summary><strong>Installation & Configuration</strong></summary>

### Installation

```bash
curl -fsSL https://cli.devin.ai/install.sh | bash
```

### Configuration

Run the setup script to install configurations to `~/.config/devin/`:

```bash
./cli.sh
```

The setup script automatically deploys MCP servers and agent guidelines.

### MCP Servers

Configuration in [`configs/devin/config.json`](configs/devin/config.json):

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
		},
		"agentmemory": {
			"command": "npx",
			"args": ["-y", "@agentmemory/mcp"]
		},
		"sem": {
			"command": "sem-mcp",
			"args": []
		},
		"ctx": {
			"command": "ctx",
			"args": ["mcp", "serve"]
		},
		"codebase-memory-mcp": {
			"command": "codebase-memory-mcp",
			"args": []
		}
	}
}
```

### Agent Guidelines

Installed to `~/.config/devin/AGENTS.md` with instructions for:

- Session management with tmux
- Using fff MCP for file search
- Following best practices from `~/.ai-tools/best-practices.md`
- qmd knowledge management integration
- Git safety guidelines

### Usage

```bash
# Start Devin CLI
devin

# Run with a specific task
devin -- "check out this code and suggest a feasible, helpful feature"
```

</details>

## ⭐ Top 5 Skills

The most-used skills across Claude Code, OpenCode, and other AI tools:

| Skill                             | What it does                                                                 | When to use it                                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| **adr**                           | Generate Architecture Decision Records from design discussions               | Before implementing significant technical changes — captures the why, alternatives considered, and consequences |
| **codemap**                       | Parallel codebase analysis producing 7 structured documents                  | Onboarding to a new project, or before major refactoring — gives you the full picture fast                      |
| **code-quality-review**           | Extremely strict maintainability and structural code quality review          | Before merging PRs — catches issues that regular linters miss                                                   |
| **babysit-pr**                    | Continuously monitor open PRs, auto-fix CI failures, surface review feedback | After pushing a PR — hands-off monitoring until it's r