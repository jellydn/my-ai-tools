# Technology Stack

**Analysis Date:** 2026-04-07

## Languages

**Primary:**
- **Bash** - Shell scripting for CLI tools (cli.sh, generate.sh, install.sh, install.ps1)
- **PowerShell** - Windows installer (install.ps1)

**Secondary:**
- **JSON** - Configuration files for all AI tools
- **TOML** - Codex configuration (config.toml)
- **YAML** - CCS configuration (config.yaml)
- **Markdown** - Documentation (README.md, docs/, AGENTS.md)

## Runtime

**Environment:**
- Bash 4+ (POSIX-compliant scripts)
- PowerShell 5.1+ (Windows)

**Package Manager:**
- pip3 - For Python-based MCP servers (mempalace)
- npm/npx - For Node.js MCP servers
- Homebrew/winget - System package management

## Frameworks & Tools

**Core:**
- **jq** - JSON processing and validation
- **git** - Version control and installation
- **curl** - HTTP requests for installers

**MCP Servers:**
- **mempalace** - AI memory system (Python)
- **fff-mcp** - Fast file search (Rust)
- **qmd** - Knowledge management (Node.js)
- **context7** - Documentation lookup (Remote)
- **sequential-thinking** - Multi-step reasoning (Node.js)

**Build/Dev:**
- **pre-commit** - Git hooks for validation
- **biome** - JS/TS formatting
- **shfmt** - Shell script formatting

## Key Dependencies

**Critical:**
- **jq** - Required for all JSON config validation
- **git** - Required for cloning and installation
- **python3** - Required for mempalace MCP server
- **pip3** - Required for installing mempalace

**Infrastructure:**
- **gh** (GitHub CLI) - For PR review features
- **bun/node** - For JavaScript-based tools

## Configuration

**Environment:**
- Configs stored in `configs/<tool>/` directories
- Installation via `cli.sh` or one-liner curl install
- Export via `generate.sh`

**Build:**
- `.pre-commit-config.yaml` - Pre-commit hooks
- `renovate.json` - Dependency updates
- `.changeset/` - Version management

**Key Config Files:**
- `configs/claude/settings.json` - Claude Code config with hooks
- `configs/claude/mcp-servers.json` - MCP server definitions
- `configs/opencode/opencode.json` - OpenCode config
- `configs/gemini/settings.json` - Gemini CLI config
- `configs/amp/settings.json` - Amp config
- `configs/codex/config.toml` - Codex config
- `configs/ccs/config.yaml` - CCS config

## Platform Requirements

**Development:**
- macOS, Linux, or Windows (with Git Bash)
- Bash 4+ or Git Bash
- jq installed
- git installed

**Production (End User):**
- Same as development
- Python 3.9+ for mempalace
- Node.js/Bun for some MCP servers

---

*Stack analysis: 2026-04-07*
