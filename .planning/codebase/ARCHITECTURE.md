# Architecture

**Analysis Date:** 2026-07-10

---

## System Pattern

This is a **bidirectional configuration management system** following a **source-of-truth → mirror** pattern. The repo is the canonical source of AI tool configurations; scripts sync them to and from the user's home directory.

```
┌─────────────────────────────┐
│   Repo (source of truth)    │
│   configs/<tool>/*          │
│   skills/*                  │
└──────────┬──────────────────┘
           │ cli.sh (install)
           ▼
┌──────────────────────────┐
│  User's $HOME            │
│  ~/.claude/, ~/.codex/,  │
│  ~/.pi/agent/, etc.      │
└──────────┬───────────────┘
           │ generate.sh (export)
           ▼
┌──────────────────────────┐
│  Repo (updated)          │
│  configs/<tool>/*        │
└──────────────────────────┘
```

---

## Layers

### 1. Entry Point Layer (`cli.sh`, `generate.sh`)

- Parse CLI arguments (`--dry-run`, `--yes`, `--verbose`, `--rollback`, tool filters)
- Orchestrate the full install or export workflow
- Call individual `copy_<tool>_configs()` or `generate_<tool>_configs()` functions
- Handle transaction logging, rollback, and backup management

### 2. Library Layer (`lib/`)

| File | Role |
|------|------|
| `lib/require_bash.sh` | **Re-exec guard** — ensures scripts run under bash, not sh/dash. Must be sourced first. |
| `lib/common.sh` | **Shared utilities** — logging (`log_info`, `log_success`, `log_warning`, `log_error`), dry-run wrappers (`execute()`, `execute_quoted()`), path helpers (`safe_copy_dir()`, `copy_config_file()`), validation (`validate_json()`, `validate_yaml()`), transaction log |
| `lib/install.sh` | **Tool installers** — detection (`detect_tool()`), installation (`install_<tool>_now()`), package manager resolution, cross-platform support |

### 3. Configuration Layer (`configs/<tool>/`)

Each tool directory contains tool-native config files:

| Tool Type | Typical Files |
|-----------|--------------|
| **Claude-compatible** | `AGENTS.md`, `settings.json`, `mcp.json`, `agents/*.md` |
| **SKILL.md-based** | `skills/*/SKILL.md` with frontmatter |
| **JSON-config** | `*.json` agent configs, `settings.json` |
| **TOML-config** | `config.toml` for Codex, Kimi Code, Grok |

### 4. Skill Layer (`skills/`)

30+ reusable skill plugins (`SKILL.md` files with frontmatter). Each skill is a self-contained instruction set for a specific task (code review, TDD, PR management, documentation, etc.). Skills are installed via the `npx skills` CLI tool.

### 5. Documentation Layer

| Location | Purpose |
|----------|---------|
| `AGENTS.md` | Root agent instructions (CI commands, conventions, testing guide) |
| `GEMINI.md` | Synced copy for Gemini CLI compatibility |
| `MEMORY.md` | Persistent compounding knowledge base |
| `docs/` | User-facing documentation (agent teams, quick starts) |
| `wiki/` | LLM Wiki — raw source knowledge |
| `.planning/codebase/` | Codemap output (these 7 documents) |
| `TESTING.md` | BATS testing guide |

---

## Data Flow

### Install Flow (`cli.sh`)

```
1. Source lib/require_bash.sh (re-exec guard)
2. set -e
3. Source lib/common.sh, lib/install.sh
4. Parse CLI args
5. Detect installed tools (via detect_tool())
6. For each detected tool:
   a. Create backup (if not --dry-run)
   b. Create target directories
   c. Copy config files via safe_copy_dir() / copy_config_file()
   d. Validate JSON configs via validate_json()
   e. Log success/failure
7. Copy global best-practices, agent-memory-guidelines
8. Report summary
```

### Export Flow (`generate.sh`)

```
1. Source lib/require_bash.sh
2. set -e
3. Source lib/common.sh
4. Parse CLI args
5. For each detected tool in $HOME:
   a. Check source dir exists
   b. Copy files from $HOME → repo via copy_single()
   c. Skip if source missing (log warning)
6. Report summary
```

---

## Key Abstractions

### `execute()` / `execute_quoted()`

All side-effecting commands must use these wrappers. They respect `DRY_RUN` mode, log the command, and handle errors:

- `execute()` — uses `eval` for simple commands
- `execute_quoted()` — passes `"$@"` directly for path-safe execution

### `safe_copy_dir()`

Copies directories while excluding runtime artifacts (`node_modules/`, `*.sqlite`, `cache/`, etc.). Uses rsync when available, falls back to manual find+cp.

### `copy_config_file()`

Copies a single file with dry-run support, existence checking, and success/failure logging.

### `detect_tool()`

Checks if a tool's CLI is on PATH or its config directory exists. Returns status code and optional detail string. Used by both `cli.sh` and `generate.sh` to skip uninstalled tools.

### Transaction System

`start_transaction()`, `record_action()`, `rollback_transaction()`, `end_transaction()` provide atomic rollback via `--rollback` flag. Actions are logged to a temp file; on rollback, they're reversed in order.

---

## Aging & Deprecation

- **Gemini CLI**: Deprecated for Google One/unpaid tiers (cutoff: June 18, 2026). Users should migrate to Antigravity CLI. `generate.sh` warns on export.
- **Legacy MCP**: Old MCP server format handled as fallback in `cli.sh`; prefer the central `configs/mcp-registry.json`.

---

## Extension Points

To add a new tool:
1. Create `configs/<newtool>/` with appropriate config files
2. Add `copy_<newtool>_configs()` to `cli.sh`
3. Add `generate_<newtool>_configs()` to `generate.sh`
4. Add installer to `lib/install.sh` (optional)
5. Register in `copy_configurations()` dispatch table

_Last updated: 2026-07-10_
