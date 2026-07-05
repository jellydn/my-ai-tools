# External Integrations

## AI Coding Tools (Direct Config Management)

This project manages configurations for 23+ AI coding assistants, deploying configs to their respective config directories and installing them via package managers:

| Tool                 | Install Source                                                            | Config Home                           | Status                                    |
| -------------------- | ------------------------------------------------------------------------- | ------------------------------------- | ----------------------------------------- |
| **Claude Code**      | `npm install -g @anthropic-ai/claude-code`                                | `~/.claude/`                          | Primary                                   |
| **OpenCode**         | `https://opencode.ai/install`                                             | `~/.config/opencode/`                 | Active                                    |
| **Amp**              | `https://ampcode.com/install.sh`                                          | `~/.config/amp/`                      | Active                                    |
| **Codex CLI**        | `npm install -g @openai/codex`                                            | `~/.codex/`                           | Active                                    |
| **Kimi Code**        | `https://code.kimi.com/kimi-code/install.sh` (or `.ps1`)                  | `~/.kimi-code/`                       | Active                                    |
| **Gemini CLI**       | `npm install -g @google/gemini-cli`                                       | `~/.gemini/`                          | Deprecated (free tier ends June 18, 2026) |
| **Antigravity CLI**  | `https://antigravity.google/cli/install.sh` (or `.ps1`)                   | `~/.gemini/antigravity-cli/`          | Migration target                          |
| **Kilo CLI**         | `npm install -g @kilocode/cli`                                            | `~/.config/kilo/`                     | Active                                    |
| **Pi**               | `npm install -g @mariozechner/pi-coding-agent`                            | `~/.pi/`                              | Active                                    |
| **Command Code**     | `npm install -g command-code`                                             | `~/.commandcode/`                     | Active                                    |
| **Copilot CLI**      | `npm install -g @github/copilot`                                          | `~/.copilot/`                         | Active                                    |
| **Cursor**           | `curl https://cursor.com/install \| bash`                                 | `~/.cursor/`                          | Active                                    |
| **Factory Droid**    | `npm install -g @factory/cli`                                             | `~/.factory/`                         | Active                                    |
| **Cline**            | `npm install -g cline`                                                    | `~/.cline/`                           | Active                                    |
| **Grok CLI**         | `npm install -g @xai-official/grok` or `curl https://x.ai/cli/install.sh` | `~/.grok/`                            | Active                                    |
| **MiMo-Code**        | `npm install -g @mimo-ai/cli` or `curl https://mimo.xiaomi.com/install`   | `~/.config/mimocode/`                 | Active                                    |
| **CCS**              | `npm install -g @kaitranntt/ccs`                                          | (managed separately)                  | Active                                    |
| **Qoder CLI**        | `https://qoder.com/install`                                               | `~/.qoder/`                           | Active                                    |
| **Kiro CLI**         | `https://cli.kiro.dev/install`                                            | `~/.kiro/`                            | Active                                    |
| **Codiff**           | `brew install --cask nkzw-tech/tap/codiff` (macOS only)                   | `~/.codiff/`                          | Active                                    |
| **ctx**              | `https://ctx.rs/install`                                                  | `~/.ctx/`                             | Active                                    |
| **herdr**            | `https://herdr.dev/install.sh`                                            | `~/.config/herdr/`                    | Active                                    |
| **Open Code Review** | `npm install -g @alibaba-group/open-code-review`                          | —                                     | Active                                    |
| **AI Launcher**      | `https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh`   | `~/.config/ai-launcher/`              | Active                                    |
| **Conductor**        | macOS app from `https://www.conductor.build`                              | `~/.conductor/`                       | Active                                    |
| **Orca**             | macOS app                                                                 | `~/Library/Application Support/orca/` | Active                                    |

## MCP (Model Context Protocol) Servers

Central registry at `configs/mcp-registry.json` with 9 servers, installed via `claude mcp add --scope user --transport stdio`:

| Server                  | Command                                                   | Category                 | Requires       |
| ----------------------- | --------------------------------------------------------- | ------------------------ | -------------- |
| **context7**            | `npx -y @upstash/context7-mcp@latest`                     | Documentation            | —              |
| **sequential-thinking** | `npx -y @modelcontextprotocol/server-sequential-thinking` | Reasoning                | —              |
| **qmd**                 | `qmd mcp`                                                 | Knowledge                | `qmd` CLI      |
| **fff**                 | `fff-mcp`                                                 | Search                   | `fff-mcp` CLI  |
| **react-grab-mcp**      | `npx -y @react-grab/mcp --stdio`                          | Frontend                 | —              |
| **logpilot**            | `logpilot mcp-server`                                     | Monitoring               | `logpilot` CLI |
| **agentmemory**         | `npx -y @agentmemory/mcp`                                 | Knowledge (session)      | —              |
| **sem**                 | `sem-mcp`                                                 | Version Control          | `sem-mcp` CLI  |
| **ctx**                 | `ctx mcp serve`                                           | Search (session history) | `ctx` CLI      |

## Claude Code Plugin Marketplaces

Configured in `configs/claude/settings.json` via `extraKnownMarketplaces`:

| Marketplace                 | GitHub Repo                          | Plugins                                                                                                                                                     |
| --------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **claude-plugins-official** | `anthropics/claude-plugins-official` | typescript-lsp, pyright-lsp, context7, frontend-design, learning-output-style, swift-lsp, lua-lsp, code-simplifier, rust-analyzer-lsp, claude-md-management |
| **plannotator**             | `backnotprop/plannotator`            | plannotator, plannotator-copilot                                                                                                                            |
| **claude-hud**              | `jarrodwatts/claude-hud`             | claude-hud                                                                                                                                                  |
| **worktrunk**               | `max-sixty/worktrunk`                | worktrunk                                                                                                                                                   |
| **openai-codex**            | `openai/codex-plugin-cc`             | codex                                                                                                                                                       |

## Custom Plugin Marketplace (This Repo)

Defined in `.claude-plugin/marketplace.json` — 18 local skills published as Claude Code plugins:

| Plugin                             | Category            | Description                                          |
| ---------------------------------- | ------------------- | ---------------------------------------------------- |
| adr                                | productivity        | Architecture Decision Records management             |
| codemap                            | productivity        | Parallel codebase analysis → .planning/codebase/     |
| commit-atomic                      | productivity        | Atomic commits with commitizen convention            |
| docs-update                        | productivity        | Automated documentation updates                      |
| draft-pull-request                 | productivity        | Creates draft PRs with what/why/how                  |
| handoffs                           | productivity        | Session handoff plans for continuation               |
| llm-wiki                           | productivity        | Persistent compounding knowledge wiki                |
| pickup                             | productivity        | Resume from previous handoff sessions                |
| plannotator-setup-goal             | productivity        | Turn ideas into structured Plannotator goal packages |
| portless-local                     | productivity        | Named .localhost URLs for local dev                  |
| pr-review                          | productivity        | Fix PR review comments                               |
| prd                                | productivity        | Generate Product Requirements Documents              |
| qmd-knowledge                      | productivity        | Knowledge management via qmd MCP                     |
| ralph                              | productivity        | Convert PRDs to Ralph agent JSON format              |
| slop                               | productivity        | Remove AI-generated code slop from diffs             |
| tdd                                | productivity        | Red-Green-Refactor TDD workflow                      |
| thermo-nuclear-code-quality-review | code-quality        | Strict maintainability review                        |
| tmux                               | terminal-automation | Remote control tmux sessions, LogPilot integration   |

## Recommended Community Skills

From `configs/recommend-skills.json` — 16 recommended skills from GitHub:

- `shadcn/improve` — Plan-then-execute architecture for cheap models
- `mvanhorn/last30days-skill` — Research what people say in last 30 days
- `vercel-labs/agent-skills` — Vercel's Next.js/React skills
- `factory-ai/factory-plugins` → `no-use-effect` — Replace useEffect patterns
- `mattpocock/skills` → `grill-with-docs`, `improve-codebase-architecture`
- `github/gh-stack` — Stacked branches and PRs
- `expo/skills` — React Native development
- `blader/humanizer` — Remove AI-generated writing patterns
- `jezweb/claude-skills` — 97 production-ready skills
- `openclaw/agent-skills` → `autoreview` — Automated PR review
- `av/facts` — Track project specs with lifecycle stages
- `privatenumber/mac-ocr` — macOS OCR via Vision framework
- `GoogleChrome/modern-web-guidance` → `modern-web-guidance`
- `openai/codex` → `babysit-pr` — Automated PR monitoring
- `Gentleman-Programming/engram` → `engram-memory` — Persistent agent memory

## External APIs & Services

| Service          | Usage                                | Details                                                                  |
| ---------------- | ------------------------------------ | ------------------------------------------------------------------------ |
| **GitHub API**   | PR management, repository operations | Via `gh` CLI (allowed in Claude permissions)                             |
| **npm registry** | Package installation                 | `@anthropic-ai/claude-code`, `@openai/codex`, `@google/gemini-cli`, etc. |
| **GitHub Pages** | Documentation hosting                | `ai-tools.itman.fyi` — deployed on push to main                          |
| **jsDelivr CDN** | Frontend dependencies                | Docsify v4, Prism.js, docsify-copy-code, docsify zoom-image              |

## Knowledge Management

| System          | Storage                             | Purpose                                  | Protocol                  |
| --------------- | ----------------------------------- | ---------------------------------------- | ------------------------- |
| **qmd**         | `~/.ai-knowledges/{project-name}/`  | Durable, project-specific knowledge base | MCP (`qmd mcp`)           |
| **agentmemory** | Per-session, per-project            | Session-only learnings                   | MCP (`@agentmemory/mcp`)  |
| **LLM Wiki**    | `wiki/` in repo                     | Compounding knowledge from raw sources   | Slash command `/llm-wiki` |
| **MEMORY.md**   | Repo root + `~/.ai-tools/MEMORY.md` | Agent memory/knowledge guidelines        | File-based                |

## External CLI Tool Dependencies (Installed by Setup)

| Tool              | Install Method                                 | Purpose                                  |
| ----------------- | ---------------------------------------------- | ---------------------------------------- |
| **jq**            | brew/apt/winget                                | JSON parsing (required)                  |
| **Bun**           | `https://bun.sh/install`                       | JavaScript runtime (preferred over Node) |
| **biome**         | npm/bun global install                         | Formatting hook                          |
| **ruff**          | pipx/pip3/pip                                  | Python formatting hook                   |
| **rustfmt**       | rustup                                         | Rust formatting hook                     |
| **shfmt**         | brew/go install                                | Shell formatting hook                    |
| **stylua**        | brew/cargo                                     | Lua formatting hook                      |
| **qmd**           | `npm install -g @tobilu/qmd`                   | Knowledge management                     |
| **fff-mcp**       | `https://dmtrkovalenko.dev/install-fff-mcp.sh` | Fast file search                         |
| **logpilot**      | `cargo install logpilot`                       | Log analysis                             |
| **sem / sem-mcp** | install script + cargo                         | Semantic version control                 |
| **backlog.md**    | npm/bun global install                         | Amp backlog integration                  |
| **Plannotator**   | `https://plannotator.ai/install.sh`            | Project planning                         |
| **Worktrunk**     | `brew install worktrunk`                       | Git worktree management                  |

## Version Control Hosting

| Platform           | Details                                           |
| ------------------ | ------------------------------------------------- |
| **GitHub**         | Primary repo: `github.com/jellydn/my-ai-tools`    |
| **GitHub Actions** | CI: bats tests + jq validation on PR/push to main |
| **GitHub Pages**   | Documentation site deployment on push to main     |

## Webhooks & Automation

| System                      | File                                 | Trigger                                                          |
| --------------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| **GitHub Actions (CI)**     | `.github/workflows/test.yml`         | Push/PR to main                                                  |
| **GitHub Actions (Deploy)** | `.github/workflows/deploy-pages.yml` | Push to main + manual dispatch                                   |
| **Pre-commit hooks**        | `.pre-commit-config.yaml`            | Git commit (trailing-whitespace, end-of-file, check-yaml, oxfmt) |
| **Renovate**                | `renovate.json`                      | Automated dependency PRs (config:recommended)                    |
| **Conductor**               | `.conductor/settings.toml`           | Repo setup via `prek install && prek run`                        |
| **Changesets**              | `.changeset/*.md`                    | 22 tracked changeset entries                                     |

_Last updated: 2026-07-04_
