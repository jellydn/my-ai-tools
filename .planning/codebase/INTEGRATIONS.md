# Integrations

**Analysis Date:** 2026-04-07

## MCP Servers (Primary Integration)

### Core MCP Servers

All 9 AI tools integrate with the following MCP servers:

| MCP Server | Type | Purpose | Tools Integrated |
|------------|------|---------|------------------|
| **mempalace** | Local Python | AI memory with palace structure | All 9 tools |
| **fff** | Local Binary | Fast file search with memory | All 9 tools |
| **qmd** | Local Node.js | Knowledge management (qmd) | All 9 tools |
| **context7** | Remote HTTP | Documentation lookup | All 9 tools |
| **sequential-thinking** | Local Node.js | Multi-step reasoning | All 9 tools |

### MCP Server Configuration by Tool

**Claude Code:**
- Config: `configs/claude/mcp-servers.json`
- Permissions: `configs/claude/settings.json` (19 mempalace tools pre-approved)
- Hooks: Auto-save via `Stop` and `PreCompact` hooks

**Gemini CLI:**
- Config: `configs/gemini/settings.json`
- Hooks: `BeforeAgent`, `AfterAgent`, `BeforeTool`, `AfterTool`
- Checkpoint hook: `configs/gemini/hooks/mempal_checkpoint.sh`

**OpenCode:**
- Config: `configs/opencode/opencode.json`
- Local MCP servers with stdio transport

**Amp:**
- Config: `configs/amp/settings.json`
- AMP-specific MCP configuration

**Codex:**
- Config: `configs/codex/config.toml`
- TOML-based MCP server definitions

**Copilot:**
- Config: `configs/copilot/mcp-config.json`
- GitHub Copilot CLI integration

**Cursor:**
- Config: `configs/cursor/mcp.json`
- Cursor Agent MCP configuration

**Factory:**
- Config: `configs/factory/mcp.json`
- Imports Claude hooks
- Hook: `configs/factory/hooks/mempal_save_hook.sh`

**Kilo:**
- Config: `configs/kilo/config.json`
- Kilo CLI MCP configuration

**Pi:**
- Config: `configs/pi/settings.json`
- Pi agent framework MCP

## External Services

### GitHub Integration
- **gh CLI** - PR reviews, API calls
- **GitHub Copilot** - AI assistant (via copilot CLI)
- **GitHub Actions** - CI/CD (implied by configs)

### Package Registries
- **npm** - Node.js packages for MCP servers
- **PyPI** - Python packages (mempalace)
- **GitHub Releases** - fff-mcp binary distribution

### Installation Sources
- `https://ai-tools.itman.fyi/install.sh` - One-liner install
- `https://github.com/jellydn/my-ai-tools` - Repository
- `https://mcp.context7.com/mcp` - Context7 MCP endpoint

## Authentication

### OAuth/Personal Access
- GitHub Copilot: OAuth personal auth
- Various tools: Personal API keys

### Local Authentication
- Claude Code: Claude API key
- Gemini: Google OAuth
- OpenCode: Various providers

## Data Flow

```
User → AI Tool (Claude/Gemini/etc.) → MCP Server → External Service
                                          ↓
                                    MemPalace (local memory)
                                          ↓
                                    File System (~/.mempalace/)
```

## MemPalace Integration Details

### Configuration Files
- `~/.mempalace/config.json` - Global settings
- `~/.mempalace/wing_config.json` - Wing mappings
- `~/.mempalace/identity.txt` - AI identity
- `~/.mempalace/agents/*.json` - Specialist agent configs

### Auto-Save Hooks
- **Save Hook** - Every 15 messages
- **PreCompact Hook** - Before context compression
- **Checkpoint Hook** - Tool execution boundaries

### 19 Available Tools
Status, search, list_wings, list_rooms, get_taxonomy, check_duplicate, get_aaak_spec, kg_query, kg_timeline, kg_stats, traverse, find_tunnels, graph_stats, diary_read (read-only pre-approved)

---

*Integrations analysis: 2026-04-07*
