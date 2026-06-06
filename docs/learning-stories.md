# My AI Coding Tools Learning Notes

Personal notes from experimenting with AI coding tools, workflows, and frameworks.

---

## Keybinder

**A modern, intuitive macOS app for managing skhd keyboard shortcuts.**

- **Repository:** [jellydn/keybinder](https://github.com/jellydn/keybinder)
- **Built with:** [Claude](https://claude.com/product/claude-code) + [spec-kit](https://github.com/github/spec-kit)
- **Tech Stack:** Svelte 5, Rust 1.75+, Tauri v2, Vite 5, Bun

### Features

- **Auto-Detection** - Finds skhd config from standard locations
- **Visual Editor** - Clean interface for editing keyboard shortcuts
- **Safety Controls** - Confirmation for destructive commands
- **Real-time Log Viewer** - Live streaming of service logs
- **System Theme Integration** - Automatic light/dark mode

### Development Approach

Used **spec-kit** for specification-driven development:

1. Initial feature planning with structured specs
2. Implementation tasks generated from specifications
3. Pragmatic deviation during actual development (specs as reference, not strict rules)

---

## SealCode (VS Code Extension)

**Smart Code Review with AI-Powered Insights**

- **Repository:** [jellydn/vscode-seal-code](https://github.com/jellydn/vscode-seal-code)
- **Marketplace:** [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=jellydn.seal-code)
- **Built with:** [Amp](https://ampcode.com/) + [Ralph](https://github.com/snarktank/ralph)
- **Tech Stack:** TypeScript, VS Code Extension API, reactive-vscode

### Features

- **AI-Powered Review** - Send comments to Claude, Copilot, OpenCode, or Amp
- **Prompt Templates** - Built-in templates for review, security, refactor workflows
- **Categorized Comments** - Bug, Question, Suggestion, Nitpick, Note
- **Rich Visual Feedback** - Inline decorations, gutter icons, line backgrounds
- **Export Options** - Export reviews to Markdown or HTML

### Development Approach

Built autonomously using **Ralph** (AI agent system) with **Amp** as the coding assistant:

- PRD-driven development with task decomposition
- Autonomous implementation of extension features
- Integrated testing and quality validation

---

## Ralph

**Autonomous AI agent loop for PRD-driven development.**

- **Repository:** [jellydn/ralph](https://github.com/jellydn/ralph)
- **Upstream:** [snarktank/ralph](https://github.com/snarktank/ralph)
- **Status:** Temporary fork pending upstream PRs ([#6](https://github.com/snarktank/ralph/pull/6), [#21](https://github.com/snarktank/ralph/pull/21))
- **Tech Stack:** TypeScript, Shell, JavaScript

Minimal Ralph implementation: PRD → task decomposition → autonomous execution → loop until complete. Used in SealCode development. Will deprecate once upstream PRs land.

---

## AI Launcher

**Fast launcher for switching between AI coding assistants.**

- **Repository:** [jellydn/ai-launcher](https://github.com/jellydn/ai-launcher)

Fuzzy search interface for Claude Code, OpenCode, Amp, etc. Quick switching without managing multiple terminals.

---

## Tiny Coding Agent

**Minimal coding agent focused on simplicity.**

- **Repository:** [jellydn/tiny-coding-agent](https://github.com/jellydn/tiny-coding-agent)

Lightweight agent with minimal dependencies. Response to heavy frameworks that waste tokens on orchestration overhead.

---

## HermesHub

**Web app for deploying and managing a self-hosted Hermes AI Agent on any VPS — no terminal required.**

- **Repository:** [jellydn/hermes-hub](https://github.com/jellydn/hermes-hub)
- **Website:** [hermes-hub.itman.fyi](https://hermes-hub.itman.fyi/)
- **Built with:** GPT-5.5 (planning) + [Grok CLI](https://x.ai/cli) Composer 2.5 (implementation)
- **Tech Stack:** TanStack Start, Tailwind CSS v4, shadcn/ui, Hono, PostgreSQL, Drizzle ORM, Better Auth, Vitest

### Features

- **Guided VPS setup** — Step-by-step server connection wizard for non-technical users
- **One-click Hermes deployment** — Install Docker, Compose, and Hermes from the dashboard with live SSE progress
- **AI provider configuration** — OpenAI, Anthropic, OpenRouter, Ollama, and custom endpoints without editing env files
- **Telegram onboarding** — Connect a bot, verify the token, and approve pairing codes from one screen
- **Agent persona editor** — Define how Hermes speaks via `SOUL.md`, then deploy to a chosen VPS
- **MCP server manager** — Add stdio or HTTP MCP servers (with presets) and deploy to Hermes `config.yaml`
- **Built-in Hermes Web UI** — Deploy and open the Hermes browser interface from the server detail page

### Development Approach

Split planning and implementation across two models:

1. **GPT-5.5 for planning** — Architecture, API design, feature specs, and execution plans before writing code
2. **Grok CLI Composer 2.5 for implementation** — Fast iteration on TanStack Start routes, Hono API handlers, SSH deploy pipelines, and Vitest coverage

The planner produced bite-sized tasks with file paths and verification steps; Composer 2.5 executed them in focused sessions. Review and docs passes stayed in the same Grok CLI workflow.

---

## Key Takeaways

| Tool Combination                      | Best For                                                    |
| ------------------------------------- | ----------------------------------------------------------- |
| **Claude + spec-kit**                 | Greenfield projects requiring structured planning           |
| **GPT-5.5 + Grok CLI Composer 2.5**   | Plan-heavy web apps with fast, tool-aware implementation    |
| **Amp + Ralph**                       | Autonomous development with PRD-to-implementation pipelines |
| **AI CLI Switcher**                   | Developers working with multiple AI tools                   |
| **Tiny Agent**                        | Cost-conscious development with minimal overhead            |

Focused, single-purpose solutions > heavy, all-in-one frameworks.

---

## Tools I Tried But Didn't Keep

Not every tool fits every workflow. Here are tools I evaluated but chose not to adopt:

### Task Master (claude-task-master)

**Repository:** [eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master)

An AI-powered task management system designed for Cursor, Windsurf, and other editors.

**Why I didn't keep it:**

- **Complexity** - Requires multiple API keys (Anthropic, OpenAI, Perplexity, etc.)
- **Heavy setup** - MCP configuration, environment variables, PRD structure
- **Overkill** - 36 tools available, ~21,000 tokens context usage in full mode
- **Too structured** - Strict PRD-to-task workflow doesn't fit iterative development

### SuperClaude

**Website:** [superclaude.netlify.app](https://superclaude.netlify.app/)

A meta-programming configuration framework for Claude Code.

**Why I didn't keep it:**

- **Context hungry** - Uses too much context for the framework overhead
- **Mental overhead** - Learning the framework's abstractions vs just coding
- **Over-engineered** - Adds complexity without proportional benefit

### Oh My OpenCode

**Repository:** [code-yeongyu/oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

A feature-rich plugin for OpenCode with multi-model orchestration, background agents, and "Sisyphus" workflow.

**Why I didn't keep it:**

- **Too opinionated** - Enforces specific workflows (ultrawork, ralph-loop, Sisyphus mode)
- **Multi-model complexity** - Requires multiple API keys (Claude, GPT, Gemini, Grok)
- **Magic keywords** - `ultrawork`, `ulw`, `ultrathink` - adds cognitive overhead
- **Feature bloat** - LSP tools, AST-grep, background agents, keyword detectors
- **Not my style** - Aggressive automation doesn't fit my iterative workflow

---

## Worth Learning From

These tools aren't for me daily, but are valuable references for understanding AI-assisted workflows:

### Superpowers

**Repository:** [obra/superpowers](https://github.com/obra/superpowers)

A complete software development workflow for coding agents with composable "skills".

**Key concepts worth studying:**

- **Brainstorming phase** - Agent asks questions before coding, refines specs iteratively
- **Writing plans** - Bite-sized tasks (2-5 min each) with exact file paths and verification steps
- **Subagent-driven development** - Fresh subagent per task with two-stage review
- **TDD enforcement** - RED-GREEN-REFACTOR cycle, deletes code written before tests
- **Git worktrees** - Isolated workspaces on new branches

**Why it's a good reference:**

- Well-structured skill composition patterns
- Philosophy: systematic over ad-hoc, evidence over claims
- Shows how to build layered agent workflows

---

## My Philosophy: Keep It Simple

> **"Add only if needed"**

Instead of adopting heavy frameworks, I prefer:

| Approach               | Why                                             |
| ---------------------- | ----------------------------------------------- |
| **Minimal tooling**    | Less context usage, more tokens for actual work |
| **AGENTS.md**          | Simple, portable project guidance               |
| **Native AI features** | Use built-in Claude/Amp capabilities first      |
| **Add incrementally**  | Only add tools when there's clear friction      |

The best tool is the one you don't have to think about.
