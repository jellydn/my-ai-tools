# Architecture

**Analysis Date:** 2026-04-22

## Pattern Overview

**Overall:** Configuration-as-Code with Bidirectional Sync

**Key Characteristics:**
- Declarative configuration management for multiple AI tools
- Repository as source of truth (forward: `cli.sh`) and capture target (reverse: `generate.sh`)
- Skill-based extensibility - reusable prompt templates and workflows
- MCP server integration for enhanced AI capabilities
- Cross-platform shell scripts with Windows compatibility

## Layers

**Configuration Layer:**
- Purpose: Define AI tool settings, agents, skills, MCP servers
- Location: `configs/<tool>/`
- Contains: JSON settings, markdown agents/commands, skill definitions
- Depends on: AI tool installations on target system
- Used by: Installation scripts (`cli.sh`)

**Installation Layer:**
- Purpose: Deploy configurations to user's home directory
- Location: `cli.sh`, `lib/common.sh`
- Contains: Shell functions for copying, backing up, validating configs
- Depends on: Configuration layer, system tools (jq, git)
- Used by: End users, CI/CD pipelines

**Export Layer:**
- Purpose: Capture current user configurations back to repo
- Location: `generate.sh`
- Contains: Shell functions for reading installed configs and updating repo
- Depends on: User's home directory configs
- Used by: End users after customizing their setup

**Skill Layer:**
- Purpose: Reusable AI prompts and workflows
- Location: `skills/<skill-name>/`
- Contains: SKILL.md definitions, templates, scripts
- Depends on: AI tool's skill system
- Used by: AI tools during conversations

**Library Layer:**
- Purpose: Shared utilities for shell scripts
- Location: `lib/common.sh`, `lib/*.js`
- Contains: Path helpers, logging functions, OS detection, temp file management
- Depends on: POSIX shell environment
- Used by: `cli.sh`, `generate.sh`, test scripts

## Data Flow

**Forward Flow (Install):**
1. User runs `./cli.sh` or one-line installer
2. Script detects OS and validates prerequisites
3. Backup existing configs (optional)
4. Copy configs from `configs/<tool>/` to `~/.<tool>/`
5. Install MCP servers via npx
6. Validate JSON configurations

**Reverse Flow (Export):**
1. User runs `./generate.sh` after customizing setup
2. Script reads configs from home directories
3. Updates repository files with current settings
4. Creates backup of previous repo state
5. Ready for git commit and version control

**Skill Deployment:**
1. Skills defined in `skills/<name>/SKILL.md`
2. cli.sh copies skills to AI tool directories
3. AI tools parse SKILL.md for capabilities and triggers
4. Skills invoked via `/skill-name` commands in AI conversations

## Key Abstractions

**Configuration Provider:**
- Purpose: Normalize config access across different AI tools
- Examples: `configs/claude/settings.json`, `configs/amp/settings.json`
- Pattern: Each tool has unique structure but common concepts (agents, MCP, commands)

**Skill Definition:**
- Purpose: Standardized AI capability definition
- Examples: `skills/adr/SKILL.md`, `skills/tdd/SKILL.md`
- Pattern: YAML frontmatter with metadata, markdown body with usage instructions

**Cross-Platform Path Handler:**
- Purpose: Abstract Windows/Unix path differences
- Examples: `lib/common.sh` functions: `normalize_path()`, `convert_path()`, `to_unix_path()`
- Pattern: Detect OS at runtime, use appropriate path handling

**Dry-Run Executor:**
- Purpose: Preview changes without applying them
- Examples: `execute()` function in `lib/common.sh`
- Pattern: Check `$DRY_RUN` flag, log instead of executing when true

## Entry Points

**CLI Installer:**
- Location: `cli.sh`
- Triggers: Manual execution, one-line curl installer
- Responsibilities: Parse args, preflight checks, backup, install configs, MCP servers

**Export Generator:**
- Location: `generate.sh`
- Triggers: Manual execution after customizing AI tools
- Responsibilities: Backup repo configs, copy from home directories, update repository

**Windows PowerShell Installer:**
- Location: `install.ps1`
- Triggers: Windows users running `irm ... | iex`
- Responsibilities: Windows-specific prerequisites, Git Bash dependency checks

**Hook Entry Points:**
- Location: `configs/claude/hooks/index.ts`
- Triggers: Claude Code tool use events (PreToolUse, PostToolUse)
- Responsibilities: Transform prompts, auto-format code, web search transformation

## Error Handling

**Strategy:** Fail-fast with informative messages and rollback capability

**Patterns:**
- `set -e` at script start for immediate exit on errors
- `trap` for cleanup on script exit/interrupt
- Transaction logging for rollback support (`--rollback` flag)
- Color-coded log levels: `log_info`, `log_success`, `log_warning`, `log_error`
- Validation before destructive operations (JSON validation, dry-run mode)

## Cross-Cutting Concerns

**Logging:**
- Approach: Console output with color coding
- Functions: `log_info()` (blue), `log_success()` (green), `log_warning()` (yellow), `log_error()` (red)
- Verbose mode for detailed output

**Validation:**
- Approach: JSON schema validation, shellcheck for scripts
- Tools: `jq .` for JSON validation, `shellcheck` for bash scripts
- Pre-commit hooks enforce validation

**Authentication:**
- Approach: Not handled by this repo - delegated to AI tools
- Users authenticate directly with AI service providers

---

*Architecture analysis: 2026-04-22*
