# Architecture

**Analysis Date:** 2026-04-07

## System Pattern

**Configuration Management Repository**
- Bidirectional sync: Install configs → Export user configs
- Template-based: Source configs in `configs/` → User home directories
- Multi-tool support: 9 AI tools with unified configuration patterns

## Layers

### Layer 1: CLI Scripts (Entry Points)

**`cli.sh`** - Installation orchestrator
- Parses arguments (--dry-run, --backup, --yes, --verbose)
- Validates prerequisites (git, jq, python3)
- Detects installed AI tools
- Copies configurations with validation
- Sets up MCP servers interactively
- Installs hooks and skills

**`generate.sh`** - Export generator
- Reverse operation: User configs → Repository configs
- Preserves existing user customizations
- Filters skills by tool type

**`install.sh`** - One-liner bootstrap
- Temporary clone to avoid repository dependency
- Delegates to cli.sh
- Cleans up temp directory

### Layer 2: Configuration Templates

**Per-Tool Structure:**
```
configs/
├── claude/          # Most comprehensive
│   ├── settings.json
│   ├── mcp-servers.json
│   ├── CLAUDE.md
│   ├── commands/
│   ├── agents/
│   ├── hooks/
│   └── skills/
├── gemini/
│   ├── settings.json
│   └── hooks/
├── opencode/
│   ├── opencode.json
│   └── agent/
└── [7 more tools...]
```

### Layer 3: Library Functions

**`lib/common.sh`** - Shared utilities
- Logging functions (log_info, log_success, log_warning, log_error)
- File operations with dry-run support
- Validation functions
- Platform detection (is_macos, is_linux, is_windows)

## Data Flow

### Installation Flow
```
1. User runs ./cli.sh
2. Parse arguments → Set flags (DRY_RUN, YES_TO_ALL, etc.)
3. Validate prerequisites
4. Detect which AI tools are installed
5. For each installed tool:
   a. Copy configurations
   b. Validate JSON/TOML/YAML
   c. Set up MCP servers (if --yes or interactive)
   d. Copy hooks
   e. Copy skills (filtered by tool)
6. Log completion
```

### Export Flow
```
1. User runs ./generate.sh
2. Read user configs from home directories
3. Copy to configs/<tool>/ directories
4. Filter and deduplicate
5. Preserve tool-specific formatting
```

## Key Abstractions

### Configuration Inheritance
- Base patterns in `AGENTS.md` files
- Tool-specific overrides in configs
- User customizations preserved during export

### MCP Server Normalization
Same MCP servers configured differently per tool:
- Claude: `mcp-servers.json` + permissions in `settings.json`
- Codex: `[mcp_servers]` section in TOML
- OpenCode: `"mcp"` object in JSON
- Gemini: `"mcpServers"` object in JSON

### Hook System Abstraction
- **Native Hooks** (Claude, Gemini, Factory): Event-driven
- **Polling Mode** (Amp, Codex, OpenCode, Pi, Kilo, CCS): Periodic saves
- **Hybrid** (CCS): Imports Claude hooks

## Entry Points

| Script | Purpose | Key Functions |
|--------|---------|---------------|
| `cli.sh` | Install configs | `main()`, `copy_claude_configs()`, `setup_claude_mcp_servers()` |
| `generate.sh` | Export configs | `main()`, `generate_claude_configs()`, `copy_single()` |
| `install.sh` | One-liner install | `main()`, `check_prerequisites()` |

## Component Interactions

```
cli.sh
├── lib/common.sh (logging, file ops)
├── configs/claude/ (templates)
│   ├── hooks/mempal_*.sh
│   └── skills/*/
└── User home directory (~/.claude/, ~/.gemini/, etc.)

generate.sh (reverse)
├── User configs (~/.claude/settings.json)
└── configs/claude/ (exported)
```

---

*Architecture analysis: 2026-04-07*
