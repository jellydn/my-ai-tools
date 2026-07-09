# Directory Structure

**Analysis Date:** 2026-07-10

---

## Top-Level Layout

```
cli.sh                  # Install configs from repo → $HOME (2,574 lines)
generate.sh             # Export configs from $HOME → repo (961 lines)
install.sh              # Quick-start bootstrap installer
install.ps1             # Windows PowerShell installer
lib/                    # Shell script libraries
configs/                # Per-tool configuration directories (20+ tools)
skills/                 # Reusable skill plugins (30+ skills)
tests/                  # BATS functional tests (23 test files)
wiki/                   # LLM Wiki knowledge base
docs/                   # User-facing documentation
.planning/              # Codemap and planning artifacts
.github/                # CI/CD workflows
```

---

## `lib/` — Core Libraries

| File | Lines | Purpose |
|------|-------|---------|
| `require_bash.sh` | 32 | POSIX re-exec guard — sources first in every entry script |
| `common.sh` | 866 | Shared utilities: logging, dry-run, paths, validation, retry |
| `install.sh` | 1,102 | Tool detection and installation for 20+ CLIs |

---

## `configs/` — Per-Tool Configurations

Each subdirectory contains tool-native configuration files:

```
configs/
├── ai-launcher/           # AI Launcher config.json
├── amp/                   # Amp settings.json, AGENTS.md
├── antigravity-cli/       # Antigravity CLI settings.json, statusline.sh
├── ccs/                   # CCS config.yaml
├── claude/                # Claude Code settings.json, CLAUDE.md, agents/, hooks/
├── cline/                 # Cline skills/ (SKILL.md format)
├── codex/                 # Codex CLI config.json, config.toml, AGENTS.md, agents/
├── codiff/                # Codiff codiff.jsonc
├── commandcode/           # CommandCode settings.json, AGENTS.md, mcp.json, agents/
├── conductor/             # Conductor settings.toml, AGENTS.md
├── copilot/               # Copilot AGENTS.md, mcp-config.json, agents/
├── ctx/                   # ctx config.toml
├── cursor/                # Cursor AGENTS.md, mcp.json, agents/
├── factory/               # Factory settings.json, config.json, AGENTS.md, droids/
├── grok/                  # Grok config.toml, AGENTS.md, hooks/
├── herdr/                 # Herdr AGENTS.md
├── kimi-code/             # Kimi Code skills/, AGENTS.md
├── kiro/                  # Kiro settings.json, cli.json, AGENTS.md, mcp.json, agents/, shared/
├── opencode/              # OpenCode agent/ (subagents), opencode.json
├── pi/                    # Pi settings.json, AGENTS.md, mcp.json, agents/, models.json
├── qodercli/              # Qoder CLI config
├── agent-memory-guidelines.md   # Memory storage scoping (qmd, agentmemory, handoffs)
├── best-practices.md             # Tidy First philosophy, testing strategy
├── fable-guide.md                # Working with next-gen AI models
├── git-guidelines.md             # Git safety rules
├── mcp-registry.json             # Central MCP server install registry
└── recommend-skills.json         # Community skill recommendations
```

---

## `skills/` — Skill Plugins

30+ reusable skills, each in its own directory with a `SKILL.md`:

```
skills/
├── adr/                          # Architecture Decision Records
├── blindspot-pass/               # Find unknown unknowns
├── capability-experiments/       # Experiment with model capabilities
├── code-review/                  # Two-axis code review (Conventions + Intent)
├── codemap/                      # Map codebase structure
├── commit-atomic/                # Group changes into atomic commits
├── context-discovery/            # Discover context via MCP tools
├── doc-search/                   # Search project documentation
├── docs-update/                  # Sync docs with code changes
├── draft-pull-request/           # Draft PRs with structured descriptions
├── git-context/                  # Search git history for context
├── handoffs/                     # Create handoff plans across sessions
├── implementation-logger/        # Track implementation decisions
├── llm-wiki/                     # Build compounding wiki from raw sources
├── plannotator-setup-goal/       # Turn ideas into executable goal packages
├── portless-local/               # Replace ports with .localhost URLs
├── prd/                          # Generate Product Requirements Documents
├── pr-review/                    # Fix PR review comments
├── pickup/                       # Resume work from previous handoffs
├── qmd-knowledge/                # Manage project knowledge with qmd
├── quiz-me/                      # Verify understanding with quizzes
├── ralph/                        # Convert PRDs to ralph format
├── slop/                         # Remove AI-generated code slop
├── spec-interview/               # Clarify requirements through questions
├── tdd/                          # Red-Green-Refactor cycle
├── thermo-nuclear-code-quality-review/  # Strict structural code quality review
├── tmux/                         # Control tmux sessions remotely
└── README-DISCOVERY.md           # Skill discovery guide
```

---

## `tests/` — Test Suite

23 BATS test files organized by feature:

```
tests/
├── cli.bats                      # Core CLI tests
├── helpers.bash                  # Shared test helpers
├── install.bats                  # Installation tests
├── cursor_configs.bats           # Cursor config tests
├── generate.bats                 # Generate script tests
├── lib_common.bats               # lib/common.sh tests
├── pr_ai_launcher.bats           # AI Launcher tests
├── pr_antigravity.bats           # Antigravity CLI tests
├── pr_claude.bats                # Claude Code tests
├── pr_cline.bats                 # Cline tests
├── pr_codebase_memory_mcp.bats   # Codebase memory MCP tests
├── pr_codiff.bats                # Codiff tests
├── pr_copilot.bats               # Copilot tests
├── pr_ctx.bats                   # ctx tests
├── pr_grok.bats                  # Grok tests
├── pr_kimi_code.bats             # Kimi Code tests
├── pr_kiro.bats                  # Kiro tests
├── pr_pi_models.bats             # Pi models tests
├── pr_pi_settings.bats           # Pi settings tests
├── pr_pre_commit.bats            # Pre-commit hooks tests
├── pr_qodercli.bats              # Qoder CLI tests
├── pr_readme.bats                # README validation tests
├── recommend_skills.bats         # Skill recommendation tests (47 tests — largest)
└── sh_reexec.bats                # Shell re-exec guard tests
```

---

## `docs/` and `wiki/`

```
docs/
├── agent-teams-examples.md       # Multi-agent team examples
├── claude-code-teams.md          # Claude Code team patterns
├── fable-quick-start.md          # Fable Field Guide quick start
├── learning-stories.md           # Learning stories from usage
└── qmd-knowledge-management.md   # QMD knowledge management guide

wiki/
└── raw/                          # LLM Wiki raw source files
```

---

## Naming Conventions

| Category | Convention | Examples |
|----------|-----------|----------|
| **Entry scripts** | Short lowercase | `cli.sh`, `generate.sh` |
| **Libraries** | `kebab-case.sh` | `common.sh`, `require_bash.sh` |
| **Config dirs** | Lowercase tool names | `claude/`, `codex/`, `factory/` |
| **Agent files** | `kebab-case.md` | `code-reviewer.md`, `test-generator.md` |
| **Skill files** | Always `SKILL.md` | `skills/code-review/SKILL.md` |
| **Top-level docs** | `UPPERCASE.md` | `AGENTS.md`, `MEMORY.md`, `README.md` |
| **Guide docs** | `kebab-case.md` | `best-practices.md`, `git-guidelines.md` |
| **JSON configs** | `camelCase` keys | `mcpServers`, `defaultModel` |
| **Test files** | `<feature>.bats` | `pr_claude.bats`, `cli.bats` |

---

## Key Locations

| What | Where |
|------|-------|
| Re-exec guard | `lib/require_bash.sh` |
| Logging functions | `lib/common.sh` |
| Dry-run wrappers | `lib/common.sh` (`execute()`, `execute_quoted()`) |
| Tool detection | `lib/install.sh` (`detect_tool()`) |
| Config install dispatch | `cli.sh` (`copy_configurations()`) |
| Config export dispatch | `generate.sh` (`generate_configurations()`) |
| MCP server registry | `configs/mcp-registry.json` |
| Central skill index | `skills/README-DISCOVERY.md` |
| Agent instructions | `AGENTS.md`, `GEMINI.md` |
| Conventions docs | `.planning/codebase/CONVENTIONS.md` |
| CI config | `.github/workflows/test.yml` |

_Last updated: 2026-07-10_
