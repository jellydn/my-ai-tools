# Tech Stack

**Analysis Date:** 2026-07-10

---

## Languages

| Language | Role |
|----------|------|
| **Bash 3.0+** | Primary — all scripts, orchestration, config management |
| **JSON** | Configuration format for MCP servers, settings, agent configs |
| **TOML** | Configuration format for CLI tools (Codex, Kimi Code, Grok, Conductor, ctx) |
| **Markdown** | Documentation, agent/skill definitions, wiki entries |
| **YAML** | CI/CD workflows, pre-commit hooks |

No TypeScript, JavaScript, Python, or compiled code in this repo. It's a pure shell-script monorepo.

---

## Runtime & Environment

| Dependency | Version/Constraint | Purpose |
|------------|-------------------|---------|
| **Bash** | 3.0+ | Script interpreter (process substitution, arrays, `${var//pat/repl}`) |
| **Git** | Any | Version control, commit hooks, clone operations |
| **jq** | Any | JSON parsing and merging in `cli.sh` and `generate.sh` |
| **Bun** | Preferred | Package/script runner (fallback: npm/npx) |
| **bats-core** | Any | Test framework (`brew install bats-core`) |
| **rsync** | Optional | Preferred copy mechanism in `safe_copy_dir()` |

---

## Development Tooling

| Tool | Config File | Purpose |
|------|------------|---------|
| **Biome** (`@biomejs/biome`) | `biome.json` | JS/JSON/TS formatting (tabs, 120 line width, double quotes) |
| **pre-commit** | `.pre-commit-config.yaml` | Git hooks: trailing-whitespace, end-of-file-fixer, check-yaml, oxfmt |
| **Renovate** | `renovate.json` | Automated dependency updates (`config:recommended`) |
| **EditorConfig** | `.editorconfig` | Cross-editor formatting (tabs for .sh/.json/.md, spaces for .yaml) |
| **microsandbox** (`msb`) | — | Ephemeral Linux VMs for safe testing (avoids macOS `getcwd` issues) |

---

## Script Libraries

| File | Lines | Purpose |
|------|-------|---------|
| `lib/require_bash.sh` | 32 | POSIX-compatible re-exec guard — sourced **first** in every entry script |
| `lib/common.sh` | 866 | Shared utilities: logging, dry-run wrappers, path helpers, validation, retry |
| `lib/install.sh` | 1,102 | Tool-specific installers for 20+ external CLIs |

---

## Entry Points

| File | Lines | Purpose |
|------|-------|---------|
| `cli.sh` | 2,574 | Install configs from repo → `$HOME` (primary workflow) |
| `generate.sh` | 961 | Export configs from `$HOME` → repo (reverse workflow) |
| `install.sh` | — | Quick-start installer (bootstraps tool detection + cli.sh invocation) |

---

## CI/CD

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/test.yml` | Push/PR | Syntax validation (`bash -n`), BATS tests, biome check |
| `.github/workflows/deploy-pages.yml` | Push to main | GitHub Pages deployment (wiki/docs) |

---

## Configuration Paradigm

The repo is a **configuration source of truth** — it manages config files for 14+ AI coding tools. The paradigm is bidirectional:

```
cli.sh     → copies configs from repo → $HOME (install)
generate.sh ← copies configs from $HOME → repo (export, for contributing back)
```

Configs are tool-specific directories under `configs/<tool>/` with formats matching each tool's native expectations (JSON settings, TOML config, Markdown agents, etc.).

_Last updated: 2026-07-10_
