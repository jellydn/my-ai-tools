# Architecture: my-ai-tools

## Overview

**my-ai-tools** is a shell-script monorepo that manages configuration and installation for 25+ AI coding assistants. It provides a bidirectional sync mechanism — pushing curated configs from the repo to user home directories (`cli.sh`) and pulling user-local configs back into the repo (`generate.sh`).

## Architectural Pattern

### Pattern: Bidirectional Configuration Hub

The codebase follows a **hub-and-spoke** pattern where the repo is the central source of truth ("hub") and each supported tool's home-directory config is a "spoke."

```
┌─────────────────────────────────────────────────────────┐
│                    REPO (source of truth)                │
│                                                         │
│  configs/  ←── generate.sh (export from home → repo)    │
│  skills/   ←── generate.sh                              │
│  lib/                                                  │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  cli.sh ──→ configs/ → home dirs (repo → home)         │
│  install.sh ──→ git clone → cli.sh (bootstrap)          │
└─────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   ~/.claude/         ~/.config/opencode/     ~/.cursor/
   ~/.gemini/         ~/.codex/               ~/.kiro/
   ~/.commandcode/    ~/.pi/agent/            ~/.grok/
   ~/.cline/          ~/.config/amp/          ~/.config/mimocode/
   ~/.copilot/        ~/.config/kilo/         ~/.qoder/
   ~/.config/ai-launcher/   ~/.conductor/     ~/.codiff/
   ~/.factory/        ~/.herdr/               ~/.ctx/
      ... 25+ tools
```

### Key Insight: Two Scripts, Opposite Directions

| Script        | Direction   | Purpose                                  |
| ------------- | ----------- | ---------------------------------------- |
| `cli.sh`      | REPO → HOME | Install/apply configs to user's machine  |
| `generate.sh` | HOME → REPO | Capture user's current configs into repo |

## Layers

### Layer 1: Entry Points (Root scripts)

| File          | Role                                                                                  |
| ------------- | ------------------------------------------------------------------------------------- |
| `cli.sh`      | Main installer: detects tools, installs CLI binaries, copies configs, enables plugins |
| `generate.sh` | Reverse exporter: reads user's home-dir configs and writes them back to `configs/`    |
| `install.sh`  | Bootstrap: clones repo from GitHub, then runs `cli.sh`                                |
| `install.ps1` | Windows PowerShell bootstrap equivalent                                               |

### Layer 2: Shared Libraries (`lib/`)

| File                  | Purpose                                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------------ |
| `lib/common.sh`       | Core utilities: logging, dry-run, path handling, JSON/YAML validation, transaction tracking, safe copy |
| `lib/require_bash.sh` | POSIX-compatible re-exec guard — ensures scripts run under bash (not sh/dash)                          |
| `lib/install.sh`      | Tool installation functions: package manager detection, npm/bun/curl-based installers for each AI tool |

**Dependency order**: `require_bash.sh` → `common.sh` → `install.sh` → entry-point scripts

### Layer 3: Configuration Templates (`configs/`)

Each tool has a subdirectory in `configs/` with its canonical config files:

```
configs/
  claude/           settings.json, mcp-servers.json, CLAUDE.md, commands/, agents/, hooks/, skills/
  opencode/         opencode.json, agent/, command/, skills/
  amp/              settings.json, AGENTS.md, plugins/
  codex/            AGENTS.md, config.json, config.toml
  kimi-code/        AGENTS.md, config.toml, mcp.json, skills/
  gemini/           AGENTS.md, GEMINI.md, settings.json, agents/, commands/
  antigravity-cli/  settings.json, keybindings.json, statusline.sh, plugins/
  pi/               settings.json, mcp.json, themes/
  cursor/           AGENTS.md, mcp.json, agents/, commands/, skills/
  grok/             AGENTS.md, config.toml, themes/
  mimo/             AGENTS.md, mimocode.jsonc, tui.json, agent/, command/, themes/
  ... (25+ tool directories)
  mcp-registry.json         Central MCP server definitions
  recommend-skills.json     Community skill recommendations
  best-practices.md         Shared coding best practices
  git-guidelines.md         Git safety rules
  agent-memory-guidelines.md Agent memory conventions
```

### Layer 4: Skills Marketplace (`skills/`)

Local plugin marketplace for Claude Code — 18 skill directories packaged as plugins. Each skill is a directory with a `SKILL.md` file. Published via `skills/*/` → `~/.agents/skills/` (universal location) with symlinks from tool-specific directories.

### Layer 5: Testing (`tests/`)

BATS (Bash Automated Testing System) functional tests — 23 test files covering config validation, tool installers, and shell re-exec behavior.

### Layer 6: CI/CD (`.github/workflows/`)

Two workflows:

- `test.yml`: BATS config validation tests + shell syntax checks
- `deploy-pages.yml`: GitHub Pages deployment

## Data Flow

### Install Flow (`cli.sh`)

```
User runs cli.sh
  → require_bash.sh (POSIX guard)
  → Parse flags (--dry-run, --backup, --yes, --migrate-gemini)
  → Preflight check (awk, sed, grep, etc.)
  → Check prerequisites (git, bun/node, qmd, fff-mcp, sem-mcp, logpilot)
  → Backup existing configs (~/ai-tools-backup-{timestamp})
  → For each tool (claude, opencode, amp, codex, ...):
      detect_tool → if installed:
        install_tool (if not already installed)
        copy_configs (safe_copy_dir from configs/ → home dir)
        install_mcp_servers_from_registry (from mcp-registry.json)
  → enable_plugins (Claude Code marketplace + community + recommended)
  → Install skills to ~/.agents/skills/ (universal directory)
  → Create symlinks: ~/.claude/skills → ~/.agents/skills (and all other tools)
```

### Export Flow (`generate.sh`)

```
User runs generate.sh
  → require_bash.sh
  → For each tool (claude, opencode, amp, ...):
      Check if home config exists
      If yes: copy_single / copy_claude_subdirectory / copy_skills_with_filter
      Skills filter: skip marketplace plugins (prd, ralph, qmd-knowledge, codemap)
                     skip npx-installed skills (from recommend-skills.json)
  → Copy best-practices.md, MEMORY.md, ai-launcher configs
```

### Skills Architecture

```
Source: skills/                        Target: ~/.agents/skills/
  ├── adr/                               ├── adr/
  ├── commit-atomic/                     ├── commit-atomic/
  ├── draft-pull-request/                ├── ... (all 18 skills)
  ├── ...                               └── .my-ai-tools-managed (marker)

Tool-specific symlinks:
  ~/.claude/skills/         → ~/.agents/skills/
  ~/.config/opencode/skills/ → ~/.agents/skills/
  ~/.gemini/skills/         → ~/.agents/skills/
  ~/.cursor/skills/         → ~/.agents/skills/
  ~/.cline/skills/          → ~/.agents/skills/
  ... (all supported tools)
```

## Key Abstractions

### 1. Tool Detection (`detect_tool`)

Checks for tool presence via command availability and config directory existence. Returns detailed status: `command`, `directory`, `file`, or `missing`.

### 2. Dry-Run Wrappers (`execute` / `execute_quoted`)

All side-effecting operations go through wrappers that respect `DRY_RUN` mode. `execute` uses eval for simple commands; `execute_quoted` passes arguments directly (safe for paths with spaces).

### 3. Safe Copy (`safe_copy_dir`)

Copies directories while excluding runtime artifacts (node_modules, *.sqlite, cache, sessions, etc.). Prefers rsync; falls back to manual find+cp.

### 4. MCP Registry (`mcp-registry.json`)

Central JSON registry defining all MCP servers with their commands, args, prerequisites, and categories. Both `cli.sh` and `generate.sh` use this as the single source of truth.

### 5. Transaction Tracking

Optional rollback support via `start_transaction` / `record_action` / `rollback_transaction`. Actions are logged and can be reversed LIFO.

### 6. Skill Filtering

`copy_skills_with_filter` in `generate.sh` excludes marketplace-managed plugins and npx-installed skills from export, preventing duplication.

### 7. Universal Skills Directory (`~/.agents/skills/`)

All skills live in one universal location. Tool-specific directories are symlinks to it. This avoids duplication and ensures consistency across tools.

## Shell Script Conventions

- **Bash 3.0+** required (process substitution, arrays, `${var//pat/repl}`)
- **Re-exec guard** (`require_bash.sh`) on every entry point before any bash-only syntax
- **`set -e`** after the re-exec guard
- **All variables quoted**: `"$variable"`
- **`local`** for function-scoped variables
- **Colors/logging**: `log_info`, `log_success`, `log_warning`, `log_error` to stderr
- **No absolute paths** — use `$HOME`, relative paths
- **POSIX compatibility** in helper functions that may be sourced from sh

## Supported Tools (25+)

| Tool             | Config Dir                            | CLI Binary          |
| ---------------- | ------------------------------------- | ------------------- |
| Claude Code      | `~/.claude/`                          | `claude`            |
| OpenCode         | `~/.config/opencode/`                 | `opencode`          |
| Amp              | `~/.config/amp/`                      | `amp`               |
| CCS              | npm global                            | `ccs`               |
| AI Launcher      | `~/.config/ai-launcher/`              | `ai`                |
| Codex CLI        | `~/.codex/`                           | `codex`             |
| Kimi Code        | `~/.kimi-code/`                       | `kimi`              |
| Gemini CLI       | `~/.gemini/`                          | `gemini`            |
| Antigravity CLI  | `~/.gemini/antigravity-cli/`          | `agy`               |
| Kilo CLI         | `~/.config/kilo/`                     | `kilo`              |
| Pi               | `~/.pi/agent/`                        | `pi`                |
| Command Code     | `~/.commandcode/`                     | `cmd`               |
| Copilot CLI      | `~/.copilot/`                         | `copilot`           |
| Cursor           | `~/.cursor/`                          | `agent`             |
| Conductor        | `~/.conductor/`                       | macOS app           |
| Factory Droid    | `~/.factory/`                         | `droid`             |
| Orca             | `~/Library/Application Support/orca/` | macOS app           |
| Cline            | `~/.cline/`                           | `cline`             |
| Grok CLI         | `~/.grok/`                            | `grok`              |
| MiMo-Code        | `~/.config/mimocode/`                 | `mimo`              |
| Open Code Review | npm global                            | `ocr`               |
| herdr            | `~/.config/herdr/`                    | `herdr`             |
| ctx              | `~/.ctx/`                             | `ctx`               |
| Qoder CLI        | `~/.qoder/`                           | `qodercli`          |
| Kiro CLI         | `~/.kiro/`                            | `kiro-cli` / `kiro` |
| Codiff           | `~/.codiff/`                          | `codiff`            |

## Dependency Graph

```
install.sh
  └─ git clone → cli.sh
       ├─ lib/require_bash.sh
       ├─ lib/common.sh
       ├─ lib/install.sh
       └─ configs/**/* (read)
            └─ copies to ~/.claude/, ~/.config/opencode/, ...

generate.sh
  ├─ lib/require_bash.sh
  ├─ lib/common.sh
  └─ reads from ~/.claude/, ~/.config/opencode/, ...
       └─ writes to configs/**/*
```
