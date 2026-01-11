# 📝 My AI Coding Tools Learning Notes

Personal notes from experimenting with AI coding tools, workflows, and frameworks.

---

## 🎹 Keybinder

**A modern, intuitive macOS app for managing skhd keyboard shortcuts.**

|                |                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------- |
| **Repository** | [github.com/jellydn/keybinder](https://github.com/jellydn/keybinder)                              |
| **Built with** | [Claude](https://claude.com/product/claude-code) + [spec-kit](https://github.com/github/spec-kit) |
| **Tech Stack** | Svelte 5, Rust 1.75+, Tauri v2, Vite 5, Bun                                                       |

### Features

- 🔍 **Auto-Detection** - Finds skhd config from standard locations
- ✏️ **Visual Editor** - Clean interface for editing keyboard shortcuts
- 🛡️ **Safety Controls** - Confirmation for destructive commands
- 📊 **Real-time Log Viewer** - Live streaming of service logs
- 🎨 **System Theme Integration** - Automatic light/dark mode

### Development Approach

Used **spec-kit** for specification-driven development:

1. Initial feature planning with structured specs
2. Implementation tasks generated from specifications
3. Pragmatic deviation during actual development (specs as reference, not strict rules)

---

## 🔒 SealCode (VS Code Extension)

**Smart Code Review with AI-Powered Insights**

|                 |                                                                                              |
| --------------- | -------------------------------------------------------------------------------------------- |
| **Repository**  | [github.com/jellydn/vscode-seal-code](https://github.com/jellydn/vscode-seal-code)           |
| **Marketplace** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=jellydn.seal-code) |
| **Built with**  | [Amp](https://ampcode.com/) + [Ralph](https://github.com/snarktank/ralph)                    |
| **Tech Stack**  | TypeScript, VS Code Extension API, reactive-vscode                                           |

### Features

- 🤖 **AI-Powered Review** - Send comments to Claude, Copilot, OpenCode, or Amp
- 📝 **Prompt Templates** - Built-in templates for review, security, refactor workflows
- 🏷️ **Categorized Comments** - Bug, Question, Suggestion, Nitpick, Note
- 🎨 **Rich Visual Feedback** - Inline decorations, gutter icons, line backgrounds
- 📤 **Export Options** - Export reviews to Markdown or HTML

### Development Approach

Built autonomously using **Ralph** (AI agent system) with **Amp** as the coding assistant:

- PRD-driven development with task decomposition
- Autonomous implementation of extension features
- Integrated testing and quality validation

---

## 💡 Key Takeaways

| Tool Combination      | Best For                                                             |
| --------------------- | -------------------------------------------------------------------- |
| **Claude + spec-kit** | Greenfield projects requiring structured planning and specifications |
| **Amp + Ralph**       | Autonomous development with PRD-to-implementation pipelines          |

Both approaches demonstrate that AI coding tools can successfully ship production-ready applications when paired with appropriate development methodologies.

---

## ⚠️ Tools I Tried But Didn't Keep

Not every tool fits every workflow. Here are tools I evaluated but chose not to adopt:

### Task Master (claude-task-master)

**Repository:** [github.com/eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master)

An AI-powered task management system with 24k+ stars, designed for Cursor, Windsurf, and other editors.

**Why I didn't keep it:**

- 🔧 **Complexity** - Requires multiple API keys (Anthropic, OpenAI, Perplexity, etc.)
- 📦 **Heavy setup** - MCP configuration, environment variables, PRD structure
- 🎯 **Overkill** - 36 tools available, ~21,000 tokens context usage in full mode
- 🔄 **Too structured** - Strict PRD-to-task workflow doesn't fit iterative development

### SuperClaude

**Website:** [superclaude.netlify.app](https://superclaude.netlify.app/)

A meta-programming configuration framework for Claude Code.

**Why I didn't keep it:**

- 📊 **Context hungry** - Uses too much context for the framework overhead
- 🧠 **Mental overhead** - Learning the framework's abstractions vs just coding
- 🎛️ **Over-engineered** - Adds complexity without proportional benefit

### Oh My OpenCode

**Repository:** [github.com/code-yeongyu/oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

A feature-rich plugin for OpenCode with multi-model orchestration, background agents, and "Sisyphus" workflow.

**Why I didn't keep it:**

- 🎨 **Too opinionated** - Enforces specific workflows (ultrawork, ralph-loop, Sisyphus mode)
- 🤖 **Multi-model complexity** - Requires multiple API keys (Claude, GPT, Gemini, Grok)
- 📜 **Magic keywords** - `ultrawork`, `ulw`, `ultrathink` - adds cognitive overhead
- 🔧 **Feature bloat** - LSP tools, AST-grep, background agents, keyword detectors
- 🚫 **Not my style** - Aggressive automation doesn't fit my iterative workflow

---

## 📚 Worth Learning From

These tools aren't for me daily, but are valuable references for understanding AI-assisted workflows:

### Superpowers

**Repository:** [github.com/obra/superpowers](https://github.com/obra/superpowers) (16k ⭐)

A complete software development workflow for coding agents with composable "skills".

**Key concepts worth studying:**

- 🧠 **Brainstorming phase** - Agent asks questions before coding, refines specs iteratively
- 📋 **Writing plans** - Bite-sized tasks (2-5 min each) with exact file paths and verification steps
- 🤖 **Subagent-driven development** - Fresh subagent per task with two-stage review
- 🔴 **TDD enforcement** - RED-GREEN-REFACTOR cycle, deletes code written before tests
- 🌳 **Git worktrees** - Isolated workspaces on new branches

**Why it's a good reference:**

- Well-structured skill composition patterns
- Philosophy: systematic over ad-hoc, evidence over claims
- Shows how to build layered agent workflows

---

## 🎯 My Philosophy: Keep It Simple

> **"Add only if needed"**

Instead of adopting heavy frameworks, I prefer:

| Approach               | Why                                             |
| ---------------------- | ----------------------------------------------- |
| **Minimal tooling**    | Less context usage, more tokens for actual work |
| **AGENTS.md**          | Simple, portable project guidance               |
| **Native AI features** | Use built-in Claude/Amp capabilities first      |
| **Add incrementally**  | Only add tools when there's clear friction      |

The best tool is the one you don't have to think about.
