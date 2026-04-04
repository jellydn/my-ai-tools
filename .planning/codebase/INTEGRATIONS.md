# External Integrations

## AI Providers & APIs

### Primary Providers

| Provider | Integration Method | Config Location |
|----------|-------------------|-----------------|
| **Anthropic (Claude)** | Direct subscription | Claude Code |
| **OpenAI** | API key, OAuth | OpenCode, Codex |
| **Google AI (Gemini)** | OAuth / API key | Gemini CLI, CCS |
| **GLM (Zhipu)** | API profile | CCS |
| **Ollama** | Local API | CCS, Codex |
| **OpenRouter** | API profile | CCS |

### OAuth Providers (via CCS)

| Provider | ID | Description |
|----------|-----|-------------|
| **Gemini** | `gemini` | Google Gemini (OAuth) |
| **Codex** | `codex` | OpenAI Codex (OAuth) |
| **Agy** | `agy` | AI provider |
| **Qwen** | `qwen` | Alibaba Qwen |
| **iFlow** | `iflow` | Flow provider |
| **Kiro** | `kiro` | AI provider |
| **GitHub Copilot** | `ghcp` | Copilot API (unofficial) |

## MCP Server Integrations

### Documentation & Search

| Service | Package | Endpoint | Purpose |
|---------|---------|----------|---------|
| **Context7** | `@upstash/context7-mcp` | `npx` stdio | Library documentation lookup |
| **qmd** | `qmd` | Local command | Knowledge base search |

### Reasoning & Analysis

| Service | Package | Endpoint | Purpose |
|---------|---------|----------|---------|
| **Sequential Thinking** | `@modelcontextprotocol/server-sequential-thinking` | npx stdio | Multi-step reasoning |

### Browser Automation

| Service | Package | Endpoint | Purpose |
|---------|---------|----------|---------|
| **Chrome DevTools** | `chrome-devtools-mcp` | npx stdio | Headless browser control |

## External Services

### Formatter Services

| Service | Installation | Purpose |
|---------|-------------|---------|
| **biome** | `npm install -g @biomejs/biome` | JS/TS formatting & linting |
| **gofmt** | Go installation | Go formatting |
| **prettier** | `npx prettier` | Markdown formatting |
| **ruff** | `pip install ruff` | Python formatting |
| **rustfmt** | Rust installation | Rust formatting |
| **shfmt** | `go install mvdan.cc/sh/v3/cmd/shfmt` | Shell formatting |
| **stylua** | `cargo install stylua` | Lua formatting |

### CLI Tools

| Tool | Installation | Purpose |
|------|-------------|---------|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | AI coding assistant |
| **OpenCode** | `curl -fsSL https://opencode.ai/install \| bash` | AI coding assistant |
| **Amp** | `curl -fsSL https://ampcode.com/install.sh \| bash` | AI coding assistant |
| **Gemini CLI** | `npm install -g @google/gemini-cli` | Google AI CLI |
| **Codex CLI** | `npm install -g @openai/codex` | OpenAI Codex CLI |
| **CCS** | `npm install -g @kaitranntt/ccs` | Claude Code Switch |
| **Factory Droid** | `npm install -g @factory/cli` | AI agent |
| **backlog.md** | `npm install -g backlog.md` | Task management |

## Local Integrations

### Knowledge Management

| Service | Storage Location | Purpose |
|---------|-----------------|---------|
| **qmd** | `~/.ai-knowledges/` | Project knowledge base |
| **qmd collections** | `~/.ai-knowledges/<project>/` | Per-project knowledge |

### Configuration Storage

| Service | Default Location | Backup Location |
|---------|------------------|-----------------|
| **Claude Code** | `~/.claude/` | `$HOME/ai-tools-backup-{timestamp}/` |
| **OpenCode** | `~/.config/opencode/` | - |
| **Amp** | `~/.config/amp/` | - |
| **CCS** | `~/.ccs/` | - |
| **Factory Droid** | `~/.factory/` | - |
| **Cursor** | `~/.cursor/rules/` | - |

## Authentication Methods

| Provider | Method | Configuration |
|----------|--------|---------------|
| **Anthropic** | Subscription | Claude Code app |
| **Google** | OAuth | Gemini CLI browser flow |
| **GitHub** | OAuth | Copilot API auth |
| **API Keys** | Env vars | GLM, Ollama, OpenRouter |

## Webhooks & Events

### PostToolUse Hooks (Auto-formatting)

Triggered after file edits:
- `Write`, `Edit`, `MultiEdit` tools match
- Runs formatters based on file extension
- Supports: TS, JS, Go, Markdown, Python, Rust, Shell, Lua

### PreToolUse Hooks (Git Guard)

Triggered before Bash commands:
- Blocks dangerous git commands
- Patterns: force push, hard reset, branch delete
- Implementation: `configs/claude/hooks/git-guard.ts`

### WebSearch Transformer

Transforms WebSearch queries:
- Location: `~/.ccs/hooks/websearch-transformer.cjs`
- Timeout: 120s

## Plugin Marketplaces

| Marketplace | URL | Plugins |
|-------------|-----|---------|
| **Anthropic Official** | `anthropics/claude-plugins-official` | typescript-lsp, pyright-lsp, context7, etc. |
| **Community** | Various GitHub repos | plannotator, claude-hud, worktrunk, codex |
| **Local Skills** | `skills/` folder | adr, codemap, handoffs, prd, qmd-knowledge, etc. |

## Reference Configuration

- MCP servers: `configs/claude/mcp-servers.json`
- CCS config: `configs/ccs/config.yaml`
- Factory MCP: `configs/factory/mcp.json`
- Gemini settings: `configs/gemini/settings.json`
