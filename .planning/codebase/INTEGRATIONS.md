# External Integrations

**Analysis Date:** 2026-04-22

## APIs & External Services

**MCP (Model Context Protocol) Servers:**
- **Context7** (`@upstash/context7-mcp`) - Documentation search and retrieval
  - Auth: None required
  - Usage: Library documentation queries

- **Sequential Thinking** (`@modelcontextprotocol/server-sequential-thinking`) - Structured reasoning
  - Auth: None required
  - Usage: Complex problem breakdown

- **qmd** (`qmd mcp`) - Knowledge management
  - Auth: Local filesystem
  - Usage: Project-specific learnings and notes

- **fff-mcp** - Fast file search (frecency-ranked)
  - Auth: None
  - Usage: File finding and content search

- **react-grab-mcp** (`@react-grab/mcp`) - React component extraction
  - Auth: None
  - Usage: React component analysis

- **Notion** (`mcp-remote`) - Notion workspace integration
  - Auth: OAuth via `https://mcp.notion.com/mcp`
  - Usage: Notion page access and updates

## Data Storage

**Databases:**
- None - All data stored as JSON/YAML files on local filesystem

**File Storage:**
- Local filesystem only
- Config locations:
  - Claude Code: `~/.claude/`
  - OpenCode: `~/.config/opencode/`
  - Amp: `~/.config/amp/`
  - CCS: `~/.ccs/`
  - Pi: `~/.config/pi/`

**Caching:**
- Claude plugin cache: `~/.claude/plugins/cache/`
- Bun/Node npm cache for MCP servers

**Backup:**
- Automatic backup to `$HOME/ai-tools-backup-{timestamp}`
- Retention: Last 5 backups kept

## Authentication & Identity

**Auth Provider:**
- AI tools handle their own authentication (Claude Code, OpenCode, etc.)
- This repo contains only configuration, not credentials
- Users authenticate with Anthropic, OpenAI, Google, etc. directly

**API Keys:**
- Not stored in this repository
- Users provide their own API keys during AI tool setup

## Monitoring & Observability

**Error Tracking:**
- None - Errors logged to console with color-coded output

**Logs:**
- Console output with color coding (RED, GREEN, YELLOW, BLUE)
- Verbose mode available (`-v|--verbose`)
- Transaction logging for rollback support

## CI/CD & Deployment

**Hosting:**
- GitHub repository: `jellydn/my-ai-tools`
- Documentation site: GitHub Pages (`ai-tools.itman.fyi`)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/`)
- Pre-commit hooks for shellcheck validation

**Distribution:**
- One-line installer: `curl -fsSL https://ai-tools.itman.fyi/install.sh | bash`
- PowerShell installer: `irm https://ai-tools.itman.fyi/install.ps1 | iex`

## Environment Configuration

**Required env vars:**
- `HOME` - User home directory (for config paths)
- `TMPDIR` - Temporary directory (optional, defaults to `/tmp`)
- `OSTYPE` - OS detection for Windows compatibility
- `MSYSTEM` - Windows environment detection

**Secrets location:**
- Not managed by this repository
- AI tools store credentials in their own config directories

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- Claude Code hooks (PostToolUse, PreToolUse) trigger formatting commands
- WebSearch hook transforms via `~/.ccs/hooks/websearch-transformer.cjs`

---

*Integration audit: 2026-04-22*
