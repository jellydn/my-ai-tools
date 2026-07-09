# Directory Structure: my-ai-tools

## Root Layout

```
my-ai-tools/
├── .changeset/                  # Changeset release notes (22 markdown files)
├── .claude-plugin/              # Claude Code marketplace definition
│   └── marketplace.json         # Plugin registry for Claude marketplace
├── .commandcode/                # Command Code config
│   └── taste/                   # Taste preferences
├── .conductor/                  # Conductor macOS app config
│   └── settings.toml
├── .github/                     # GitHub CI/CD
│   └── workflows/
│       ├── deploy-pages.yml     # GitHub Pages deployment
│       └── test.yml             # BATS + jq config validation
├── .planning/                   # Planning artifacts (codemap output target)
│   └── codebase/                # Architecture/Structure docs destination
├── configs/                     # ★ Core: tool config templates (25+ tool dirs)
│   ├── ai-launcher/
│   ├── amp/
│   ├── antigravity-cli/
│   ├── ccs/
│   ├── claude/
│   ├── cline/
│   ├── codiff/
│   ├── codex/
│   ├── commandcode/
│   ├── conductor/
│   ├── copilot/
│   ├── cursor/
│   ├── ctx/
│   ├── factory/
│   ├── gemini/
│   ├── grok/
│   ├── herdr/
│   ├── kilo/
│   ├── kimi-code/
│   ├── kiro/
│   ├── mimo/
│   ├── opencode/
│   ├── orca/
│   ├── pi/
│   ├── qodercli/
│   ├── agent-memory-guidelines.md
│   ├── best-practices.md
│   ├── git-guidelines.md
│   ├── mcp-registry.json
│   └── recommend-skills.json
├── docs/                        # Documentation
│   ├── adr/                     # Architecture Decision Records
│   ├── agent-teams-examples.md
│   ├── claude-code-teams.md
│   ├── learning-stories.md
│   └── qmd-knowledge-management.md
├── lib/                         # ★ Shared shell libraries
│   ├── common.sh                # Core utilities (867 lines)
│   ├── install.sh               # Tool installation functions (1103 lines)
│   └── require_bash.sh          # Bash re-exec guard (33 lines)
├── skills/                      # ★ Local skill marketplace (18 skills)
│   ├── adr/
│   ├── codemap/
│   ├── commit-atomic/
│   ├── docs-update/
│   ├── draft-pull-request/
│   ├── handoffs/
│   ├── llm-wiki/
│   ├── pickup/
│   ├── plannotator-setup-goal/
│   ├── portless-local/
│   ├── pr-review/
│   ├── prd/
│   ├── qmd-knowledge/
│   ├── ralph/
│   ├── slop/
│   ├── tdd/
│   ├── code-quality-review/
│   └── tmux/
├── tests/                       # BATS functional test suite (23 files)
│   ├── helpers.bash             # Shared test utilities
│   ├── cli.bats
│   ├── generate.bats
│   ├── install.bats
│   ├── cursor_configs.bats
│   ├── lib_common.bats
│   ├── recommend_skills.bats
│   ├── sh_reexec.bats
│   └── pr_*.bats                # Per-tool config validation tests (15 files)
├── wiki/                        # LLM Wiki (persistent knowledge base)
│   ├── wiki/                    # Wiki content directory
│   ├── raw/                     # Immutable raw source documents
│   ├── AGENTS.md                # Wiki-specific agent instructions
│   └── CLAUDE.md                # Wiki-specific Claude instructions
├── AGENTS.md                    # ★ Primary agent instructions (117 lines)
├── GEMINI.md                    # Gemini-specific agent instructions
├── MEMORY.md                    # Project memory / context
├── CONTRIBUTING.md              # Contributor guide
├── LICENSE                      # License file
├── README.md                    # Project README
├── TESTING.md                   # Testing guide
├── cli.sh                       # ★ Main installer (2283 lines)
├── generate.sh                  # ★ Config exporter (907 lines)
├── install.sh                   # Bootstrap installer (90 lines)
├── install.ps1                  # Windows PowerShell bootstrap
├── biome.json                   # Biome formatter config
├── .editorconfig                # Editor settings
├── .gitignore
├── .nojekyll                    # GitHub Pages config
├── .pre-commit-config.yaml      # Pre-commit hooks (trailing-whitespace, yaml, oxfmt)
├── helmor.json                  # Helmor script runner config
├── renovate.json                # Renovate dependency bot config
├── CNAME                        # GitHub Pages custom domain
└── index.html                   # GitHub Pages landing page
```

## Key Locations

### Entry Points (where execution begins)

| Path          | Purpose                           | Lines |
| ------------- | --------------------------------- | ----- |
| `cli.sh`      | Install configs from repo to home | 2283  |
| `generate.sh` | Export configs from home to repo  | 907   |
| `install.sh`  | Bootstrap: git clone + run cli.sh | 90    |
| `install.ps1` | Windows PowerShell bootstrap      | —     |

### Core Library (`lib/`)

| Path                  | Purpose                                                      | Lines |
| --------------------- | ------------------------------------------------------------ | ----- |
| `lib/common.sh`       | Logging, dry-run, paths, validation, safe-copy, transactions | 867   |
| `lib/install.sh`      | Tool installers (25+ tools), package manager detection       | 1103  |
| `lib/require_bash.sh` | POSIX re-exec guard for sh→bash                              | 33    |

### Config Templates (`configs/`)

Each tool directory follows a consistent pattern:

- **AGENTS.md** — Agent instructions (shared across tools via `~/.agents/AGENTS.md`)
- **settings.json** — Tool-specific settings (some use TOML)
- _*mcp*.json_* — MCP server configuration
- **skills/** — Tool-specific skills (symlinked to `~/.agents/skills/` at install time)
- **commands/** — Custom slash commands
- **agents/** — Custom agent definitions
- **plugins/** — Tool plugins
- **themes/** — UI themes
- **hooks/** — Event hooks

Not all tools have all directories — each has only what's applicable.

### Skills (`skills/`)

18 local skill plugins, each a directory containing:

- `SKILL.md` — Skill definition with frontmatter (name, description, allowed-tools, model)
- Supporting files as needed by the skill

Skills are also listed in `.claude-plugin/marketplace.json` for Claude Code plugin marketplace discovery and installable via `bunx/npx skills add`.

### Tests (`tests/`)

Naming convention: `pr_<tool>.bats` for per-tool PR config validation, `<feature>.bats` for feature tests.

| Pattern                 | What it tests                                                     |
| ----------------------- | ----------------------------------------------------------------- |
| `pr_*.bats`             | Config validation: file existence, JSON validity, required fields |
| `cli.bats`              | CLI behavior, backup, dry-run                                     |
| `generate.bats`         | Config export functionality                                       |
| `install.bats`          | Installation flow                                                 |
| `lib_common.bats`       | Shared library functions                                          |
| `recommend_skills.bats` | Skill recommendations                                             |
| `sh_reexec.bats`        | Re-exec guard behavior                                            |
| `helpers.bash`          | Test utilities (require_jq helper)                                |

## Naming Conventions

### Scripts & Libraries

| Convention                             | Example                                         |
| -------------------------------------- | ----------------------------------------------- |
| Entry-point scripts: `*.sh` at root    | `cli.sh`, `generate.sh`, `install.sh`           |
| Libraries: `lib/*.sh`, snake_case      | `lib/common.sh`, `lib/require_bash.sh`          |
| Test files: `tests/*.bats`, snake_case | `tests/pr_claude.bats`, `tests/lib_common.bats` |
| Test helpers: `tests/helpers.bash`     | `tests/helpers.bash`                            |

### Shell Functions

| Convention                                            | Example                                                      |
| ----------------------------------------------------- | ------------------------------------------------------------ |
| Public functions: `snake_case`                        | `copy_configurations`, `detect_tool`, `safe_copy_dir`        |
| Private helpers: `_prefix` underscore                 | `_detect_os`, `_verify_package_manager`, `_run_kiro_install` |
| Tool installers: `install_<tool>`                     | `install_claude_code`, `install_amp`, `install_kiro`         |
| Tool handlers: `handle_<tool>_installation_if_needed` | `handle_qmd_installation_if_needed`                          |
| Config generators: `generate_<tool>_configs`          | `generate_claude_configs`, `generate_grok_configs`           |
| Config copiers: `copy_<tool>_configs`                 | `copy_claude_configs`, `copy_mimo_configs`                   |
| Logging: `log_<level>`                                | `log_info`, `log_success`, `log_warning`, `log_error`        |

### Config Directories

| Convention                                      | Example                                          |
| ----------------------------------------------- | ------------------------------------------------ |
| Tool names in `configs/`: lowercase, hyphenated | `configs/antigravity-cli/`, `configs/kimi-code/` |
| Home-dir configs: dot-prefixed, lowercase       | `~/.claude/`, `~/.cursor/`, `~/.commandcode/`    |
| Universal agents: `~/.agents/`                  | `~/.agents/skills/`, `~/.agents/AGENTS.md`       |
| Backup pattern: `ai-tools-backup-{timestamp}`   | `~/ai-tools-backup-20260704-120000`              |

### Config Files

| Convention                            | Example                                                 |
| ------------------------------------- | ------------------------------------------------------- |
| Agent instructions: `AGENTS.md`       | `configs/claude/CLAUDE.md` (also copied as `AGENTS.md`) |
| Settings: `settings.json`             | `configs/claude/settings.json`                          |
| MCP config: `mcp*.json`               | `mcp-servers.json`, `mcp.json`, `mcp-config.json`       |
| Tool-specific config: per-tool format | `config.toml`, `opencode.json`, `mimocode.jsonc`        |
| CI config: `.yml`                     | `.github/workflows/test.yml`                            |

## File Size Summary

| File                  | Lines     | Role            |
| --------------------- | --------- | --------------- |
| `cli.sh`              | 2283      | Main installer  |
| `lib/install.sh`      | 1103      | Tool installers |
| `generate.sh`         | 907       | Config exporter |
| `lib/common.sh`       | 867       | Core utilities  |
| `lib/require_bash.sh` | 33        | Re-exec guard   |
| `install.sh`          | 90        | Bootstrap       |
| **Total Shell**       | **~5283** |                 |

## Change Management

- **Changesets**: 22 markdown files in `.changeset/` tracking feature additions (tool support, skill additions, CLI fixes)
- **Pre-commit hooks**: trailing-whitespace, YAML check, oxfmt formatting
- **Biome**: Formatter config with tabs, 120 line width, double quotes
- **Renovate**: Automated dependency updates
