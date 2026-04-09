# Directory Structure

**Analysis Date:** 2026-04-07

## Root Layout

```
my-ai-tools/
├── cli.sh                      # Main installation script
├── generate.sh                 # Export user configs to repo
├── install.sh                  # One-liner bootstrap
├── install.ps1                 # Windows PowerShell installer
├── lib/
│   └── common.sh               # Shared shell functions
├── configs/                    # AI tool configurations
│   ├── claude/                 # Most comprehensive setup
│   ├── gemini/
│   ├── opencode/
│   ├── amp/
│   ├── codex/
│   ├── copilot/
│   ├── cursor/
│   ├── factory/
│   ├── kilo/
│   ├── pi/
│   ├── ccs/
│   └── ai-launcher/
├── docs/                       # Documentation
├── skills/                     # Shared skill definitions
├── tests/                      # Test files
├── .planning/                  # Planning documents
│   └── codebase/               # Codebase map (this directory)
├── .github/                    # GitHub workflows
├── .changeset/                 # Version management
└── [standard files]            # README.md, LICENSE, etc.
```

## Key Locations

### Configuration Templates

**`configs/claude/`** - Most comprehensive tool configuration
- `settings.json` - Main settings with hooks
- `mcp-servers.json` - MCP server definitions
- `CLAUDE.md` - System prompt
- `commands/` - Custom slash commands
- `agents/` - Agent definitions
- `hooks/` - Lifecycle hooks (mempal_*.sh)
- `skills/` - Skill directories

**`configs/gemini/`**
- `settings.json` - Gemini CLI config
- `hooks/` - MemPalace checkpoint hooks
- `AGENTS.md` - Agent guidelines

**`configs/opencode/`**
- `opencode.json` - Main configuration
- `agent/` - Agent configurations
- `command/` - Custom commands

### Shell Scripts

**Root Level:**
- `cli.sh` - Main CLI (63827 bytes) - Installation orchestration
- `generate.sh` - Export configs
- `install.sh` - Bootstrap wrapper
- `install.ps1` - Windows installer

**Hooks:**
- `configs/claude/hooks/mempal_save_hook.sh` - Auto-save every 15 messages
- `configs/claude/hooks/mempal_precompact_hook.sh` - Emergency save
- `configs/gemini/hooks/mempal_checkpoint.sh` - Gemini checkpoint
- `configs/factory/hooks/mempal_save_hook.sh` - Factory wrapper

### Documentation

**`docs/`** - Project documentation
- `mempalace-specialist-agents.md` - Agent pattern documentation
- `mempalace-auto-save-hooks.md` - Hook documentation for all 9 tools
- `agent-teams-examples.md` - Team coordination patterns
- `claude-code-teams.md` - Claude-specific teams
- `qmd-knowledge-management.md` - QMD documentation
- `learning-stories.md` - Learning documentation

### Library Code

**`lib/common.sh`** - Shared utilities (~500 lines)
- Logging functions
- File operations with dry-run support
- Platform detection
- Validation helpers

## Naming Conventions

### Files
- **Shell scripts**: `*.sh` (kebab-case: `cli.sh`, `generate.sh`)
- **PowerShell**: `*.ps1` (PascalCase: `install.ps1`)
- **Configs**: `*.json`, `*.toml`, `*.yaml` (lowercase with hyphens)
- **Docs**: `*.md` (UPPERCASE for important: `README.md`, `AGENTS.md`)

### Directories
- **AI tool configs**: lowercase (`claude/`, `gemini/`, `opencode/`)
- **Documentation**: lowercase (`docs/`, `skills/`)
- **Special**: UPPERCASE for standards (`.github/`, `.changeset/`)

### Configuration Keys
- **JSON**: camelCase (`mcpServers`, `defaultMode`)
- **TOML**: snake_case (`[mcp_servers.mempalace]`)
- **YAML**: camelCase or snake_case depending on tool

## Directory Sizes (Approximate)

```
configs/claude/        ~150KB (largest, most comprehensive)
configs/gemini/        ~25KB
configs/opencode/      ~20KB
docs/                  ~35KB
skills/                ~15KB
lib/                   ~15KB
```

## Important Paths

### User Installation Targets
- `~/.claude/` - Claude Code config
- `~/.gemini/` - Gemini CLI config
- `~/.config/opencode/` - OpenCode config
- `~/.config/amp/` - Amp config
- `~/.codex/` - Codex config
- `~/.copilot/` - Copilot config
- `~/.cursor/` - Cursor config
- `~/.factory/` - Factory config
- `~/.config/kilo/` - Kilo config
- `~/.pi/agent/` - Pi config
- `~/.ccs/` - CCS config

### Repository Source
- `configs/<tool>/` - Template configurations
- Copied to user home during installation

---

*Structure analysis: 2026-04-07*
