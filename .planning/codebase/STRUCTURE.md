# Codebase Structure

**Analysis Date:** 2026-04-22

## Directory Layout

```
my-ai-tools/
├── cli.sh                    # Main installer script
├── generate.sh               # Export configs from home to repo
├── install.sh                # One-line installer entry point
├── install.ps1               # Windows PowerShell installer
├── lib/                      # Shared utilities
│   ├── common.sh             # Core shell functions (768 lines)
│   ├── extract-pr-comments.js # PR comment processing
│   └── migrate-mcp.js        # MCP configuration migration
├── configs/                  # AI tool configurations
│   ├── claude/               # Claude Code settings, agents, MCP, hooks
│   ├── opencode/             # OpenCode agents and settings
│   ├── amp/                  # Amp settings and agents
│   ├── ccs/                  # CCS (Claude Code Switch) config
│   ├── codex/                # OpenAI Codex CLI config
│   ├── gemini/               # Google Gemini CLI config
│   ├── pi/                   # Pi AI tool config
│   ├── cursor/               # Cursor editor config
│   ├── copilot/              # GitHub Copilot CLI config
│   ├── kilo/                 # Kilo CLI config
│   ├── ai-launcher/          # AI Launcher config
│   ├── factory/              # Factory Droid config
│   ├── best-practices.md     # General best practices guide
│   ├── git-guidelines.md     # Git safety guidelines
│   └── recommend-skills.json # Recommended skill list
├── skills/                   # Reusable AI skills
│   ├── adr/                  # Architecture Decision Records
│   ├── codemap/              # Codebase mapping
│   ├── handoffs/             # Session handoff planning
│   ├── pickup/               # Resume from handoff
│   ├── pr-review/            # PR review automation
│   ├── prd/                  # Product Requirements Document
│   ├── qmd-knowledge/        # Knowledge management
│   ├── ralph/                # PRD to Ralph format conversion
│   ├── slop/                 # AI slop removal
│   ├── tdd/                  # Test-Driven Development
│   └── tmux/                 # tmux session management
├── tests/                    # Test suite
│   ├── cli.bats              # CLI script tests
│   ├── install.bats          # Installer tests
│   └── lib_common.bats       # Common library tests
├── docs/                     # Documentation
│   ├── agent-teams-examples.md
│   ├── claude-code-teams.md
│   ├── qmd-knowledge-management.md
│   └── learning-stories.md
├── .changeset/               # Version management
├── .github/                  # GitHub workflows
└── .planning/                # Planning documents
    └── codebase/             # This codebase map
```

## Directory Purposes

**Root (`./`):**
- Purpose: Entry points and project metadata
- Contains: Main scripts (`cli.sh`, `generate.sh`), install scripts, README, LICENSE
- Key files: `cli.sh` (main installer), `README.md` (comprehensive docs)

**`lib/`:**
- Purpose: Shared shell utilities and helper scripts
- Contains: `common.sh` (768 lines of utilities), JavaScript helpers
- Key files: `common.sh` (path handling, logging, temp files, OS detection)

**`configs/`:**
- Purpose: AI tool configuration templates
- Contains: One subdirectory per supported AI tool
- Key files: `claude/settings.json`, `claude/mcp-servers.json`, `amp/settings.json`

**`skills/`:**
- Purpose: Reusable AI skill definitions
- Contains: SKILL.md files with metadata and instructions
- Key files: `*/SKILL.md` - each skill is self-contained

**`tests/`:**
- Purpose: Automated testing for shell scripts
- Contains: Bats test files
- Key files: `lib_common.bats` (most comprehensive), `cli.bats`

**`docs/`:**
- Purpose: Additional documentation beyond README
- Contains: Feature guides and learning materials

**`.changeset/`:**
- Purpose: Version and changelog management
- Contains: Changeset files for release notes

## Key File Locations

**Entry Points:**
- `cli.sh`: Main installation script with all tool support
- `generate.sh`: Export user configs back to repository
- `install.sh`: One-line curl installer wrapper
- `install.ps1`: Windows PowerShell installer

**Configuration:**
- `configs/claude/settings.json`: Claude Code main settings
- `configs/claude/mcp-servers.json`: MCP server definitions
- `configs/amp/settings.json`: Amp configuration with MCP servers
- `configs/recommend-skills.json`: Cross-tool skill recommendations

**Core Logic:**
- `lib/common.sh`: Shared utilities (logging, paths, OS detection, backups)
- `cli.sh`: `install_*()` functions for each tool
- `generate.sh`: `copy_claude_*()` functions for export

**Testing:**
- `tests/lib_common.bats`: 150+ lines testing common.sh functions
- `tests/cli.bats`: CLI behavior tests
- `.pre-commit-config.yaml`: Pre-commit hooks (shellcheck)

## Naming Conventions

**Files:**
- Scripts: `kebab-case.sh` (e.g., `cli.sh`, `generate.sh`)
- Configs: `kebab-case.json` or lowercase (e.g., `settings.json`, `mcp-servers.json`)
- Documentation: `UPPERCASE.md` for main docs, `lowercase.md` for guides
- Skills: `SKILL.md` (always uppercase)

**Directories:**
- Tool configs: lowercase (e.g., `claude/`, `amp/`, `opencode/`)
- Skills: lowercase (e.g., `adr/`, `tdd/`, `codemap/`)

**Functions (Bash):**
- `snake_case` for all function names (e.g., `install_claude_code()`, `backup_configs()`)
- Verbose descriptive names (e.g., `copy_claude_subdirectory()`)

**Variables:**
- Environment: `UPPER_CASE` (e.g., `DRY_RUN`, `BACKUP_DIR`)
- Local: `snake_case` with `local` keyword
- Constants: `UPPER_CASE` with descriptive names

## Where to Add New Code

**New AI Tool Support:**
- Primary code: Create `configs/<tool>/` directory
- Settings: `configs/<tool>/settings.json`
- Agents: `configs/<tool>/agents/*.md`
- Installation: Add `install_<tool>()` function in `cli.sh`
- Export: Add `copy_<tool>_configs()` function in `generate.sh`

**New Skill:**
- Implementation: Create `skills/<skill-name>/SKILL.md`
- Templates: `skills/<skill-name>/templates/` (optional)
- Scripts: `skills/<skill-name>/scripts/` (optional)
- Registration: Update `configs/recommend-skills.json`

**New Utility Function:**
- Shared helpers: Add to `lib/common.sh`
- Tool-specific: Add to relevant `install_*()` function in `cli.sh`

**New Test:**
- Bats tests: Add to `tests/<feature>.bats`
- Fixtures: Create `tests/fixtures/` directory if needed

## Special Directories

**`configs/claude/hooks/:`**
- Purpose: Claude Code TypeScript hooks for auto-formatting
- Contains: `index.ts`, `package.json`, `tsconfig.json`
- Generated: No (source files)
- Committed: Yes
- Notes: Auto-formats code on file write (biome, prettier, ruff, etc.)

**`skills/*/`:**
- Purpose: Self-contained skill packages
- Each skill is portable and can be installed to any AI tool
- Structure: `SKILL.md` required, plus optional `templates/`, `scripts/`, `references/`

**`.changeset/:`**
- Purpose: Version management with Changesets
- Generated: No (manually created)
- Committed: Yes

---

*Structure analysis: 2026-04-22*
