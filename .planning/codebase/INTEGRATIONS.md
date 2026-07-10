# Integrations

**Analysis Date:** 2026-07-10

---

## MCP Servers (Central Registry)

The central MCP registry at `configs/mcp-registry.json` defines all MCP server installations. Key servers include:

| Server | Purpose | Install Method |
|--------|---------|---------------|
| `ctx` | Coding-agent history search | `npm install -g @anthropic-ai/ctx` |
| `sem` | Semantic code understanding | `npm install -g @anthropic-ai/sem` |
| `codebase-memory-mcp` | Codebase knowledge graph | `npx` registry |
| `github` | GitHub API (issues, PRs, code search) | Built-in MCP |
| `playwright` | Browser automation | `npx @anthropic-ai/mcp-playwright` |
| `qmd` | Knowledge management | `bun add` |
| `fff` | Fast file finder | Platform-specific install |
| `logpilot` | AI log analysis | Community install |

See `configs/mcp-registry.json` for the complete list and full install configuration.

---

## External CLIs Managed

The repo installs and configures 20+ AI coding tool CLIs. The `lib/install.sh` library handles detection and installation for each:

| Tool CLI | Config Dir | Native Path | Install Method |
|----------|-----------|-------------|---------------|
| **Claude Code** | `configs/claude/` | `~/.claude/` | `npm install -g @anthropic-ai/claude-code` |
| **OpenCode** | `configs/opencode/` | `~/.config/opencode/` | `npm install -g @opencode-ai/cli` |
| **Amp** | `configs/amp/` | `~/.amp/` | `npm install -g @anthropic-ai/amp` |
| **Pi** | `configs/pi/` | `~/.pi/agent/` | `npm install -g @anthropic-ai/pi` |
| **Codex CLI** | `configs/codex/` | `~/.codex/` | `npm install -g @openai/codex` |
| **Antigravity CLI** | `configs/antigravity-cli/` | `~/.gemini/` | `npm install -g @anthropic-ai/antigravity-cli` |
| **Kiro CLI** | `configs/kiro/` | `~/.kiro/` | `npm install -g @kiro-ai/cli` |
| **Kimi Code** | `configs/kimi-code/` | `~/.kimi-code/` | `npm install -g @moonshot-ai/kimi-code` |
| **Factory Droid** | `configs/factory/` | `~/.factory/` | `npm install -g @factory-ai/cli` |
| **CommandCode** | `configs/commandcode/` | `~/.commandcode/` | `npm install -g commandcode` |
| **Cursor** | `configs/cursor/` | `~/.cursor/` | VS Code extension (system-level) |
| **Cline** | `configs/cline/` | `~/.cline/` | VS Code extension (system-level) |
| **Copilot CLI** | `configs/copilot/` | `~/.copilot/` | `npm install -g @github/copilot-cli` |
| **Grok CLI** | `configs/grok/` | `~/.grok/` | `npm install -g @xai/grok-cli` |
| **CCS** | `configs/ccs/` | `~/.ccs/` | `npm install -g @anthropic-ai/ccs` |
| **Conductor** | `configs/conductor/` | `~/.conductor/` | `npm install -g @conductor-ai/cli` |
| **Orca** | `configs/orca/` | `~/.orca/` | `npm install -g @orca/cli` |
| **AI Launcher** | `configs/ai-launcher/` | `~/.ai-launcher/` | `npm install -g ai-launcher` |
| **Codiff** | `configs/codiff/` | `~/.codiff/` | `brew install codiff` |
| **CTX** | `configs/ctx/` | `~/.ctx/` | `npm install -g @anthropic-ai/ctx` |
| **Herdr** | `configs/herdr/` | `~/.herdr/` | `npm install -g @herdr/cli` |
| **Qoder CLI** | `configs/qodercli/` | `~/.qoder/` | `npm install -g @qoder/cli` |
| **Mimo** | `configs/mimo/` | `~/.mimo/` | `npm install -g @mimo-ai/cli` |

---

## GitHub Integration

- **GitHub CLI** (`gh`): Used by skills (`draft-pull-request`, `babysit-pr`, `gh-stack`) and the `autoreview` workflow
- **GitHub MCP**: Issues, PRs, commits, code search, file contents access
- **CI/CD**: `.github/workflows/test.yml` (test on push/PR), `.github/workflows/deploy-pages.yml` (GitHub Pages)
- **Renovate**: Automated dependency bumps via `renovate.json`

---

## Package Managers

| Manager | Preference | Usage |
|---------|-----------|-------|
| **Bun** | Preferred | `bunx` for script running, `bun add` for packages |
| **npm** | Fallback | `npx` when bun unavailable |
| **Homebrew** | macOS | `brew install` for tools like bats, codiff |
| **cargo** | Rust | `sem-mcp` and Rust-based tools |

The `_detect_package_manager()` and `_detect_script_runner()` helpers in `lib/install.sh` implement the bun→npm fallback pattern.

---

## Cross-Platform Support

- **macOS**: Homebrew (primary), cargo (fallback)
- **Linux**: `apt-get`, cargo, curl piped installers
- **Windows**: PowerShell (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm ... | iex"`), `winget` for jq
- **Windows detection**: `IS_WINDOWS` flag via `uname -s` (MINGW*, MSYS*, CYGWIN*) + `MSYSTEM` env var

---

## External Documentation Platforms

The repo's own documentation is deployed via **GitHub Pages** (`.github/workflows/deploy-pages.yml`). The `.nojekyll` file and `CNAME` file indicate custom domain configuration.

_Last updated: 2026-07-10_
