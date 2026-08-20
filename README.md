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
| **babysit-pr**                    | Continuously monitor open PRs, auto-fix CI failures, surface review feedback | After pushing a PR — hands-off monitoring until it's ready to merge                                             |
| **improve**                       | Frontier model plans, cheap model executes — audit and plan improvements     | When you need senior-level analysis with actionable plans for cheaper models to run (from shadcn)               |
| **improve-codebase-architecture** | Codebase architecture deepening — find structural improvement opportunities  | When you want to improve modularity, patterns, and architecture of an existing codebase (from Matt Pocock)      |

## 🧭 Fusion Orchestration

Inspired by [opencode-fusion](https://github.com/mihneaptu/opencode-fusion) and complementary evidence-gating ideas from [Gentle AI](https://github.com/Gentleman-Programming/gentle-ai), the `orchestrating-fusion` skill separates senior planning and review from lower-cost mechanical implementation. The installer provides native `fusion-lead` and `fusion-executor` roles for active tools and shares the portable workflow with every assistant through `~/.agents/skills/`.

| Tool         | Start Fusion                                                                  | Enforced boundary                                                                                                 |
| ------------ | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **OpenCode** | Select the `fusion-lead` primary                                              | Lead has no edit or shell permission and delegates directly to `fusion-executor`                                  |
| **Amp**      | Select the `fusion` agent mode                                                | Lead's tool surface omits mutation/shell and exposes `fusion_executor`                                            |
| **Codex**    | Ask the root session to run `fusion-lead`, then its sibling `fusion-executor` | Lead uses a read-only sandbox; the writable root mediates sibling execution                                       |
| **Pi**       | Ask the root `Agent` tool for `fusion-lead`, then `fusion-executor`           | `pi-subagents` enforces role tool allowlists; the root mediates sibling execution and non-inspection verification |
| **Others**   | Invoke the `orchestrating-fusion` skill                                       | Uses native delegation when available; otherwise the split is prompt-advisory                                     |

The lead hands off exact skill paths plus `OBJECTIVE / FILES / INTERFACES / CONSTRAINTS / VERIFICATION`. The executor returns an evidence envelope covering changes, verification, skills loaded, risks, questions, and key learnings. The lead reads artifacts back, permits one targeted correction, and stops rather than entering an unbounded fix loop. Durable PRDs or plans remain opt-in when they materially reduce ambiguity.

## 🔌 MCP Servers & Plugins Overview

| Tool            | MCP Servers                                                                                                                | Plugins/Extensions                                                                                                                                                                                                                             |
| --------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Claude Code** | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Official + Community (plannotator, claude-hud, worktrunk, codex)                                                                                                                                                                               |
| **OpenCode**    | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | @plannotator/opencode                                                                                                                                                                                                                          |
| **Codex**       | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, node_repl, ctx   | -                                                                                                                                                                                                                                              |
| **Kimi Code**   | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, logpilot, sem, ctx                              | Skills, MCP servers, and hooks via `~/.kimi-code/`                                                                                                                                                                                             |
| **Pi**          | context7, sequential-thinking, qmd, codebase-memory-mcp, fff, react-grab-mcp, agentmemory, sem, ctx                        | Packages (pi-extension, pi-subagents, autoresearch, fff, mcp-adapter, simplify, rpiv-todo, btw, code-previews, codex-goal, commandcode-provider, pi-web-access, footer, tps-meter, pi-qwencloud-provider, pi-cursor-sdk) |
| **Oh My Pi**  | Pi-compatible layout; MCP servers via `~/.omp/agent/mcp.json` when present                                                  | Pi fork (`@oh-my-pi/pi-coding-agent`); configs managed under `configs/omp/`                                                                                                                                          |
| **Amp**         | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Agent modes: fusion, glm-5.2, grok45, inkling, cursor-composer-2.5; plannotator; orca-agent-status                                                                                                                                             |
| **Gemini**      | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Deprecated for Google One/unpaid tiers; migrate to Antigravity                                                                                                                                                                                 |
| **Antigravity** | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx (via plugin) | my-ai-tools-gemini-migration                                                                                                                                                                                                                   |
| **Kilo**        | (uses OpenCode config)                                                                                                     | (uses OpenCode plugins)                                                                                                                                                                                                                        |
| **CommandCode** | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | -                                                                                                                                                                                                                                              |
| **Copilot**     | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | -                                                                                                                                                                                                                                              |
| **Cursor**      | context7 (via bunx), sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx   | -                                                                                                                                                                                                                                              |
| **Conductor**   | Per-harness (Claude Code, Codex, Cursor MCP configs)                                                                       | Orchestrates parallel agents in isolated workspaces                                                                                                                                                                                            |
| **Factory**     | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | core, security-engineer, droid-evolved, autoresearch                                                                                                                                                                                           |
| **Orca**        | -                                                                                                                          | Agent hooks (claude, gemini, codex, cursor, droid)                                                                                                                                                                                             |
| **Cline**       | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Global rules (AGENTS.md → ~/.cline/rules/, ~~/.agents/AGENTS.md), universal skills (~~/.agents/skills)                                                                                                                                         |
| **Grok**        | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Default model `grok-4.5` (high reasoning); UI auto + `rosepine-moon`; Kanagawa theme staged                                                                                                                                                    |
| **MiMo-Code**   | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | @plannotator/opencode, opencode-chrome-annotation                                                                                                                                                                                              |
| **Qoder CLI**   | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | -                                                                                                                                                                                                                                              |
| **Kiro CLI**    | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | Steering files (AGENTS.md), slash commands, MCP servers, ACP                                                                                                                                                                                   |
| **Reasonix**    | context7, sequential-thinking, qmd, codebase-memory-mcp, agentmemory, fff, react-grab-mcp, logpilot, sem, ctx              | DeepSeek-native; prefix-cache loop; `[[plugins]]` MCP in config.toml; ACP (`reasonix acp`); `REASONIX.md`/`AGENTS.md` memory; Kanagawa theme staged                                                                                            |
| **Codiff**      | — (desktop app — uses configured agent backend via settings)                                                               | —                                                                                                                                                                                                                                              |

### 📋 MCP Server Details

| Server                | Purpose                                                                                   | Package                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `context7`            | Documentation lookup for any library                                                      | `@upstash/context7-mcp`                                                 |
| `sequential-thinking` | Multi-step reasoning for complex analysis                                                 | `@modelcontextprotocol/server-sequential-thinking`                      |
| `qmd`                 | Knowledge management with AI-powered search                                               | `qmd`                                                                   |
| `codebase-memory-mcp` | High-performance code intelligence and structural search                                  | `codebase-memory-mcp`                                                   |
| `agentmemory`         | "Persistent memory" per the tool; we use it session-only (qmd = durable; see `MEMORY.md`) | `@agentmemory/mcp`                                                      |
| `fff`                 | Fast file search with frecency ranking                                                    | `fff-mcp`                                                               |
| `react-grab-mcp`      | React component capture and inspection                                                    | `@react-grab/mcp`                                                       |
| `logpilot`            | AI-powered log analysis and tmux monitoring                                               | `logpilot`                                                              |
| `sem`                 | Semantic version control - entity-level diffs, blame, and impact analysis                 | `sem-mcp` (via [Ataraxy-Labs/sem](https://github.com/Ataraxy-Labs/sem)) |
| `ctx`                 | Local agent-history search across coding sessions                                         | `ctx mcp serve`                                                         |

## 🎬 Demo

[![IT Man Channel](https://img.sh