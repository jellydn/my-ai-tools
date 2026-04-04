# Architecture

## Overview

my-ai-tools is a configuration management repository for AI coding tools (Claude Code, OpenCode, Amp, CCS, and others). It provides bidirectional synchronization between the repository configurations and the user's home directory.

## Design Pattern

### Bidirectional Config Sync

The system follows a **source-to-destination** pattern with two operational modes:

```
┌─────────────────┐     cli.sh      ┌─────────────────┐
│   Repository   │ ──────────────▶ │  Home Directory│
│  (configs/)    │    (install)    │  (~/.claude/)  │
└─────────────────┘                 └─────────────────┘
       ▲                                 │
       │     generate.sh                 │
       │    (export)                     │
└─────────────────┴───────────────────────┘
```

## Layers

### 1. Entry Point Layer

| File | Purpose |
|------|---------|
| `cli.sh` | Main installer - copies configs from repo to home directory |
| `generate.sh` | Export utility - copies configs from home directory to repo |
| `install.sh` | Standalone installer for one-line curl installation |

### 2. Shared Library Layer

The `lib/common.sh` provides reusable utilities:

- **Logging**: `log_info()`, `log_success()`, `log_warning()`, `log_error()`
- **Execution**: `execute()` - wrapper with dry-run support
- **Download**: `download_and_verify_script()`, `execute_installer()`
- **Error handling**: Cross-device link error handling via TMPDIR

### 3. Configuration Layer

Located in `configs/` - tool-specific configurations:

| Tool | Config Location | Target Directory |
|------|-----------------|------------------|
| Claude Code | `configs/claude/` | `~/.claude/` |
| OpenCode | `configs/opencode/` | `~/.config/opencode/` |
| Amp | `configs/amp/` | `~/.config/amp/` |
| CCS | `configs/ccs/` | `~/.ccs/` |
| Codex | `configs/codex/` | `~/.codex/` |
| Gemini CLI | `configs/gemini/` | `~/.gemini/` |
| Cursor | `configs/cursor/` | `~/.cursor/` |
| Factory | `configs/factory/` | `~/.factory/` |
| Pi | `configs/pi/` | `~/.pi/` |
| Kilo | `configs/kilo/` | `~/.config/kilo/` |
| Copilot | `configs/copilot/` | `~/.copilot/` |

### 4. Skills/Marketplace Layer

Located in `skills/` - local marketplace plugins providing specialized capabilities:

- `prd` - Product Requirements Document generation
- `ralph` - PRD to JSON conversion
- `qmd-knowledge` - Knowledge management
- `codemap` - Codebase analysis
- `adr` - Architecture Decision Records
- `tdd` - Test-driven development
- `pr-review` - Pull request review
- `handoffs/pickup` - Session handoff management

### 5. Hooks Layer

Located in `configs/claude/hooks/` - TypeScript-based hooks for Claude Code:

| File | Purpose |
|------|---------|
| `index.ts` | Main hook entry point |
| `git-guard.ts` | Prevents dangerous git commands |
| `session.ts` | Session management |
| `lib.ts` | Shared hook utilities |

### 6. Documentation Layer

Located in `docs/` - user guides and tutorials.

## Data Flow

### Forward Sync (cli.sh)

```
1. Parse CLI args (--dry-run, --backup, --yes, etc.)
2. Preflight check (git, required tools)
3. Check prerequisites (bun/node, jq)
4. For each tool in configs/:
   a. Install global tools (jq, formatters)
   b. Copy config files to target directory
   c. Install MCP servers
   d. Install plugins/skills
   e. Setup hooks (if applicable)
5. Handle backup (if requested)
6. Post-install cleanup
```

### Reverse Sync (generate.sh)

```
1. Parse CLI args (--dry-run)
2. For each tool directory:
   a. Read existing configs from home directory
   b. Copy back to configs/ directory
   c. Preserve as source for future installs
```

## Abstraction Patterns

### Dry-Run Support

All destructive operations support `--dry-run`:

```bash
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

### Prerequisite Checking

```bash
check_prerequisites() {
    if ! command -v git &>/dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
}
```

### MCP Server Installation

```bash
install_mcp_server() {
    local server_name="$1"
    local install_cmd="$2"
    # Execute with error handling
}
```

### Cross-Device Link Error Handling

```bash
setup_tmpdir() {
    local tmp_dir="$HOME/.claude/tmp"
    mkdir -p "$tmp_dir" 2>/dev/null || true
    export TMPDIR="$tmp_dir"
}
```

## Entry Points

| Entry Point | Trigger | Description |
|-------------|---------|-------------|
| `cli.sh` | Manual | Primary installer |
| `generate.sh` | Manual | Config exporter |
| `install.sh` | curl pipe | Standalone installer |

## Configuration Format Standards

- **JSON**: Standard formatting (no trailing commas), use `jq` for parsing
- **YAML**: 2-space indentation (no tabs)
- **Markdown**: Include language tags for code blocks
- **Shell**: POSIX-compliant (`#!/bin/bash`), use `set -e`

## Dependencies

### Runtime Dependencies
- bash (shell)
- git (version control)
- bun or node (script execution)
- jq (JSON parsing)
- curl (downloads)

### Optional Tools (auto-installed)
- biome (JS/TS formatting)
- gofmt (Go formatting)
- prettier (Markdown formatting)
- ruff (Python formatting)
- rustfmt (Rust formatting)
- shfmt (Shell formatting)
- stylua (Lua formatting)
