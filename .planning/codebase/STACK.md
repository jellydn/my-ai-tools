# Technology Stack

## Languages

| Language                  | Usage                                       | Details                                                                        |
| ------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------ |
| **Bash 3.0+**             | Primary (orchestration)                     | Entry points `cli.sh` (2283 lines), `generate.sh` (907 lines), library modules |
| **PowerShell 5.1**        | Windows installer                           | `install.ps1` (299 lines) — wraps bash installer for Windows                   |
| **Markdown**              | Documentation, agent instructions, wiki     | AGENTS.md, GEMINI.md, MEMORY.md, README.md, wiki/, docs/                       |
| **JSON**                  | Configuration files                         | Settings, MCP servers, marketplace manifests, registry files                   |
| **TOML**                  | Conductor config                            | `.conductor/settings.toml`                                                     |
| **YAML**                  | CI workflows, pre-commit config, CCS config | `.github/workflows/`, `.pre-commit-config.yaml`, `configs/ccs/config.yaml`     |
| **TypeScript/JavaScript** | Hook scripts (via Node/Bun)                 | CCS websearch transformer, HUD statusline                                      |

## Runtime & Environment

- **Shell**: Bash 3.0+ (POSIX re-exec guard via `lib/require_bash.sh` for sh/dash compatibility)
- **Package Managers** (preferred order): Bun, npm
- **Script Runners** (preferred order): bunx, npx
- **Node.js/Bun**: Required for Claude Code, plugin installation, hooks
- **Windows**: Git Bash (required), winget (for jq), PowerShell 5.1+
- **macOS**: Homebrew (for codiff, tools)

## Core Framework

| Component       | Technology                       | Purpose                                                                                                                                                                                                            |
| --------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Shell Libraries | `lib/common.sh` (867 lines)      | Logging, validation, dry-run, path helpers, safe copy, transaction support, OS detection                                                                                                                           |
| Shell Libraries | `lib/install.sh` (1103 lines)    | All AI tool installers (Claude, OpenCode, Amp, Codex, Kimi, Gemini, Antigravity, Kilo, Pi, CommandCode, Copilot, Cursor, Grok, MiMo, etc.) + global tools (jq, biome, ruff, rustfmt, shfmt, stylua, logpilot, sem) |
| Shell Libraries | `lib/require_bash.sh` (33 lines) | POSIX-compatible re-exec guard for bash-only scripts                                                                                                                                                               |
| Installer entry | `install.sh` (90 lines)          | Bootstrap: clones repo and runs `cli.sh`                                                                                                                                                                           |
| Windows entry   | `install.ps1` (299 lines)        | PowerShell wrapper: finds Git Bash, installs jq via winget, runs bash installer                                                                                                                                    |
| Sync opposite   | `generate.sh` (907 lines)        | Reverse sync — exports `~/.claude/`, `~/.config/opencode/`, etc. back to the repo                                                                                                                                  |

## Configuration & Formatting

| Tool             | Config                    | Purpose                                                                                       |
| ---------------- | ------------------------- | --------------------------------------------------------------------------------------------- |
| **Biome**        | `biome.json`              | JSON/TS/JS formatter (tabs, 120 line width, double quotes)                                    |
| **Pre-commit**   | `.pre-commit-config.yaml` | Git hooks: trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files, oxfmt |
| **EditorConfig** | `.editorconfig`           | Tabs for TS/JS/JSON/Shell/Markdown, spaces for YAML                                           |
| **Renovate**     | `renovate.json`           | Automated dependency updates (config:recommended)                                             |
| **Oxfmt**        | pre-commit hook `v0.51.0` | Rust-based fast formatter (pre-commit mirror)                                                 |

## Development Tools

| Tool                                     | Purpose                                                  |
| ---------------------------------------- | -------------------------------------------------------- |
| **Bats (Bash Automated Testing System)** | Functional tests — 23 test files in `tests/`             |
| **jq**                                   | JSON parsing/validation (required dependency)            |
| **shellcheck**                           | Referenced in allowed Claude permissions                 |
| **shfmt**                                | Shell script formatting (PostToolUse hook)               |
| **biome**                                | TypeScript/JavaScript/JSON formatting (PostToolUse hook) |
| **gofmt**                                | Go formatting (PostToolUse hook)                         |
| **ruff**                                 | Python formatting (PostToolUse hook)                     |
| **rustfmt**                              | Rust formatting (PostToolUse hook)                       |
| **stylua**                               | Lua formatting (PostToolUse hook)                        |
| **prettier**                             | Markdown formatting (PostToolUse hook, via npx)          |

## Testing

| Technology         | Usage                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------ |
| **Bats**           | 23 test files (`tests/pr_*.bats`, `tests/*.bats`), helper framework (`tests/helpers.bash`) |
| **microsandbox**   | Isolated test environment via `msb run` for testing on macOS (avoid getcwd issues)         |
| **bash -n**        | Syntax validation in CI and locally                                                        |
| **GitHub Actions** | CI: `tests/pr_*.bats`, `tests/generate.bats`, `tests/sh_reexec.bats` on ubuntu-latest      |

## AI Coding Tools Supported (23+ tools)

Config files maintained per tool under `configs/<tool>/`:

| Tool             | Config dir                 | Binary     | Config files                                                                                   |
| ---------------- | -------------------------- | ---------- | ---------------------------------------------------------------------------------------------- |
| Claude Code      | `configs/claude/`          | `claude`   | settings.json, mcp-servers.json, CLAUDE.md, commands/, agents/, hooks/, skills/                |
| OpenCode         | `configs/opencode/`        | `opencode` | opencode.json, agent/, command/, skills/                                                       |
| Amp              | `configs/amp/`             | `amp`      | settings.json, AGENTS.md, plugins/, skills/                                                    |
| Codex CLI        | `configs/codex/`           | `codex`    | config.json, config.toml, AGENTS.md, themes/                                                   |
| Kimi Code        | `configs/kimi-code/`       | `kimi`     | config.toml, mcp.json, AGENTS.md, skills/                                                      |
| Gemini CLI       | `configs/gemini/`          | `gemini`   | settings.json, AGENTS.md, GEMINI.md, agents/, commands/, policies/                             |
| Antigravity CLI  | `configs/antigravity-cli/` | `agy`      | settings.json, keybindings.json, statusline.sh, plugins/                                       |
| Kilo CLI         | `configs/kilo/`            | `kilo`     | config.json, AGENTS.md                                                                         |
| Pi               | `configs/pi/`              | `pi`       | settings.json, AGENTS.md, mcp.json, models.json, themes/                                       |
| Command Code     | `configs/commandcode/`     | `cmd`      | settings.json, AGENTS.md, mcp.json, agents/, commands/, skills/, hooks/                        |
| Copilot CLI      | `configs/copilot/`         | `copilot`  | AGENTS.md, mcp-config.json                                                                     |
| Cursor           | `configs/cursor/`          | `agent`    | AGENTS.md, mcp.json, agents/, commands/, skills/                                               |
| Cline            | `configs/cline/`           | `cline`    | mcp-settings.json, models.json, providers.json, AGENTS.md, kanban-config.json, skills/, hooks/ |
| Grok CLI         | `configs/grok/`            | `grok`     | config.toml, AGENTS.md, themes/                                                                |
| MiMo-Code        | `configs/mimo/`            | `mimo`     | mimocode.jsonc, tui.json, AGENTS.md, agent/, command/, themes/, plugins/                       |
| Factory Droid    | `configs/factory/`         | `droid`    | settings.json, AGENTS.md, mcp.json, config.json, droids/                                       |
| CCS              | `configs/ccs/`             | `ccs`      | config.yaml                                                                                    |
| Qoder CLI        | `configs/qodercli/`        | `qodercli` | settings.json, AGENTS.md                                                                       |
| Kiro CLI         | `configs/kiro/`            | `kiro`     | settings.json, cli.json, mcp.json, AGENTS.md                                                   |
| Codiff           | `configs/codiff/`          | `codiff`   | codiff.jsonc                                                                                   |
| ctx              | `configs/ctx/`             | `ctx`      | config.toml                                                                                    |
| herdr            | `configs/herdr/`           | `herdr`    | AGENTS.md                                                                                      |
| Orca             | `configs/orca/`            | macOS app  | agent-hooks/                                                                                   |
| Conductor        | `configs/conductor/`       | macOS app  | settings.toml, AGENTS.md                                                                       |
| AI Launcher      | `configs/ai-launcher/`     | `ai`       | config.json                                                                                    |
| Open Code Review | —                          | `ocr`      | npm package only                                                                               |

## Central Configuration Files

| File                                 | Purpose                                                                               |
| ------------------------------------ | ------------------------------------------------------------------------------------- |
| `configs/mcp-registry.json`          | Central MCP server registry (9 servers) — used by `install_mcp_servers_from_registry` |
| `configs/recommend-skills.json`      | 16 recommended community skills from GitHub                                           |
| `configs/best-practices.md`          | Software development best practices                                                   |
| `configs/git-guidelines.md`          | Git safety rules for AI agents                                                        |
| `configs/agent-memory-guidelines.md` | Agent memory/knowledge management patterns                                            |

## Documentation & Website

| Technology        | Usage                                                                                   |
| ----------------- | --------------------------------------------------------------------------------------- |
| **Docsify v4**    | Documentation site (`index.html`) with vue theme, search, copy-code, zoom-image plugins |
| **Prism.js**      | Syntax highlighting for bash, json, yaml, markdown                                      |
| **GitHub Pages**  | Deployment target (`.github/workflows/deploy-pages.yml`)                                |
| **Custom domain** | `ai-tools.itman.fyi` (CNAME record)                                                     |

## Version Control & CI

| Technology         | Usage                                                                     |
| ------------------ | ------------------------------------------------------------------------- |
| **Git**            | Version control, hosted on `github.com/jellydn/my-ai-tools`               |
| **GitHub Actions** | CI: `test.yml` (bats + jq validation on ubuntu-latest)                    |
| **GitHub Pages**   | `deploy-pages.yml` (deploys on push to main)                              |
| **Changesets**     | 22 changeset markdown files in `.changeset/`                              |
| **Conductor**      | `.conductor/settings.toml` — repo setup via `prek install && prek run`    |
| **Helmor**         | `helmor.json` — script runner with `prek install && prek run --all-files` |

_Last updated: 2026-07-04_
