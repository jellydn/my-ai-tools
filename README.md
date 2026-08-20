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

[![IT Man Channel](https://img.shields.io/badge/YouTube-IT%20Man%20Channel-red?logo=youtube)](https://github.com/jellydn/itman-channel)

[![IT Man - My AI Setup in 2026](https://i.ytimg.com/vi/ESudSFAyuuw/mqdefault.jpg)](https://www.youtube.com/watch?v=ESudSFAyuuw)

## 📋 Prerequisites

### All Platforms

- **Bash 3.0+** - Shell interpreter for `cli.sh` and `generate.sh` (the scripts use bash-only syntax — process substitution, arrays, pattern-parameter expansion — that `sh`/`dash` cannot parse; the entry-point scripts `source` [`lib/require_bash.sh`](./lib/require_bash.sh) which auto-relaunches under bash if invoked via `sh`/`dash` — see [Shell Interpreter](#-shell-interpreter) below)
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

# Non-interactive mode (auto-approve, only processes your active tools)
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --yes

# One-step Gemini→Antigravity CLI migration
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --migrate-gemini
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
- `-y` / `--yes` - Non-interactive mode; only installs/configures your active tool set (amp, codex, ctx, cursor, kilo, opencode, open_code_review, pi, omp, antigravity, ai-switcher, claude, reasonix). Shared infra (plugins, skills, global tools) still installed. Auto-activated in CI/piped input.
- `--migrate-gemini` - One-step Gemini→Antigravity CLI migration

## 🔄 Bidirectional Config Sync

### Forward: Install to Home (`cli.sh`)

Copy configurations from this repository to your home directory (`~/.claude/`, `~/.config/opencode/`, etc.):

```bash
./cli.sh [--dry-run] [--backup] [--no-backup] [-y|--yes] [--migrate-gemini]
```

### Reverse: Generate from Home (`generate.sh`)

Export your current configurations back to this repository for version control:

```bash
./generate.sh [--dry-run]
```

> **Tip:** Use `generate.sh` after customizing your local setup to save changes back to this repo.

## 🤖 Chat with the repo

The landing page includes a repository assistant that answers questions from the indexed README, docs, configs, and scripts.

To run it locally:

```bash
cp .env.example .env
# Add OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL, and OPENAI_EMBEDDING_MODEL to .env
npm install
npm run index          # build data/index.json (server mode)
npm run index:browser  # build public/index-browser.json (browser mode)
source .env            # load OPENAI_BASE_URL for server mode
npm run dev            # serve http://localhost:3000
```

The assistant only answers from the retrieved repository excerpts, cites the source file paths, and says "This is not documented in the repository." when the context is insufficient.

The landing page also has a browser mode that runs the embedding and an instruction-tuned model (Qwen2.5-Coder-0.5B-Instruct) in the browser via WebGPU. Browser mode downloads the ~9 MB index and the ~300 MB model on the user's device.

## 🐚 Shell Interpreter

`cli.sh` and `generate.sh` use bash-only syntax (process substitution, arrays, pattern-parameter expansion) and **require bash**. Both scripts `source` [`lib/require_bash.sh`](./lib/require_bash.sh) as their first non-shebang line; that shim is intentionally POSIX-compatible so `sh`/`dash` can source it and transparently re-launch the script under `bash` before `lib/common.sh` is reached. Prefer one of these invocations for clarity:

```bash
./cli.sh                # Uses the #!/bin/bash shebang (recommended)
bash cli.sh             # Explicit bash
bash generate.sh        # Explicit bash for the reverse-sync script
```

> If `bash` is not on `PATH`, the guard falls back to a clear error: `Error: cli.sh requires bash, but bash was not found in PATH`. See `lib/require_bash.sh` for the canonical guard implementation.

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
claude mcp add --scope user --transport stdio sem -- sem-mcp  # Requires: cargo install --git https://github.com/Ataraxy-Labs/sem sem-mcp
```

> **Auto-Install:** `./cli.sh` automatically installs Rust via `rustup` when these cargo-dependent MCP servers are selected, so you don't need to install Rust manually beforehand (manual `claude mcp add` still requires a pre-installed Rust toolchain).

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

claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman

# Install skills from this repository (jellydn/my-ai-tools)
# Recommended: Install all skills at once using npx skills add
npx skills add jellydn/my-ai-tools --yes --global --agent claude-code

# Or install interactively (select which skills to install)
npx skills add jellydn/my-ai-tools --global --agent claude-code

# Available skills: accountable-engineering, prd, ralph, qmd-knowledge, codemap, adr, handoffs, pickup, pr-review, slop, tdd, code-quality-review, commit-atomic, draft-pull-request, docs-update, llm-wiki, plannotator-setup-goal, portless-local, security-audit, tmux, blindspot-pass, implementation-logger, quiz-me, spec-interview, capability-experiments, code-review, context-discovery, doc-search, git-context, orchestrating-fusion
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

| Plugin                   | Description                             | Source            |
| ------------------------ | --------------------------------------- | ----------------- |
| `typescript-lsp`         | TypeScript language server              | Official          |
| `pyright-lsp`            | Python language server                  | Official          |
| `context7`               | Documentation lookup                    | Official          |
| `frontend-design`        | UI/UX design assistance                 | Official          |
| `learning-output-style`  | Interactive learning mode               | Official          |
| `swift-lsp`              | Swift language support                  | Official          |
| `lua-lsp`                | Lua language support                    | Official          |
| `code-simplifier`        | Code simplification                     | Official          |
| `rust-analyzer-lsp`      | Rust language support                   | Official          |
| `claude-md-management`   | Markdown management                     | Official          |
| `plannotator`            | Plan annotation tool                    | Community         |
| `plannotator-setup-goal` | Turn ideas into goal packages           | Local Marketplace |
| `prd`                    | Product Requirements Documents          | Local Marketplace |
| `ralph`                  | PRD to JSON converter                   | Local Marketplace |
| `qmd-knowledge`          | Project knowledge management            | Local Marketplace |
| `codemap`                | Parallel codebase analysis              | Local Marketplace |
| `code-quality-review`    | Extremely strict maintainability review | Local Marketplace |
| `claude-hud`             | Status line with usage monitoring       | Community         |
| `worktrunk`              | Work management                         | Community         |
| `codex`                  | Codex code review & task delegation     | Community         |
| `caveman`                | Concise, high-signal response mode      | Community         |

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
- `git clean -f