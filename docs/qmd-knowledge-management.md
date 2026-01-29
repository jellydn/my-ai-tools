# qmd Knowledge Management System

> **Alternative to claude-mem**: Project-specific knowledge capture using qmd MCP server and Agent Skills

## Overview

This system provides a lightweight, project-specific knowledge management solution that captures learnings, issue notes, and project conventions in a searchable knowledge base. Unlike `claude-mem`, it:

- ✅ Keeps knowledge **outside project directories** (no repository pollution)
- ✅ Uses **standard markdown files** (portable and version-controllable)
- ✅ Provides **AI-powered search** via qmd MCP server
- ✅ Follows **skills.md specification** (self-documenting)
- ✅ Supports **multiple projects** with isolated knowledge bases

## Architecture

The qmd-knowledge skill follows the Agent Skills specification:

```
# The skill (one SKILL.md defines the capability)
~/.config/opencode/skill/qmd-knowledge/
├── SKILL.md              # Skill definition
├── scripts/              # Executable scripts
│   └── record.sh         # Record learnings/issues/notes
└── references/           # Documentation and examples
    ├── learnings/
    │   └── README.md
    └── issues/
        └── README.md

# Knowledge storage (qmd collections per project)
~/.ai-knowledges/
├── my-ai-tools/          # Collection for my-ai-tools project
│   ├── learnings/
│   │   ├── 2024-01-26-qmd-integration.md
│   │   └── 2024-01-27-mcp-servers.md
│   └── issues/
│       ├── 123.md
│       └── 456.md
└── another-project/      # Collection for another-project
    ├── learnings/
    └── issues/
```

**Key concept**: One skill (`qmd-knowledge`) manages knowledge for multiple projects. Each project is a qmd collection, not a separate skill.

## Installation

### 1. Install qmd

Install qmd globally via bun:

```bash
bun install -g https://github.com/tobi/qmd
```

### 2. Configure MCP Server

The MCP server configuration is already included in this repository.

**For Claude Code** (`~/.claude/mcp-servers.json`):
```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

**For Amp** (`~/.config/amp/settings.json`):
```json
{
  "amp.mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

### 3. Install the Skill

The skill is installed when you run the setup script:

```bash
./cli.sh
```

This copies the qmd-knowledge skill to `~/.config/opencode/skill/qmd-knowledge/`.

### 4. Create a Knowledge Collection for Your Project

```bash
# Create storage directory for your project
mkdir -p ~/.ai-knowledges/my-ai-tools/learnings
mkdir -p ~/.ai-knowledges/my-ai-tools/issues

# Add qmd collection for this project
qmd collection add ~/.ai-knowledges/my-ai-tools --name my-ai-tools

# Add context to improve search results
qmd context add qmd://my-ai-tools "Knowledge base for my-ai-tools project: learnings, issue notes, and project conventions"

# Generate embeddings for semantic search
qmd embed
```

**Note**: The skill is installed once. Each project gets its own qmd collection for storing knowledge.

### 5. Install Configuration (Optional)

Run the setup script to install all configurations:

```bash
./cli.sh
```

This will copy the qmd skill to `~/.config/opencode/skill/qmd-knowledge/`.

**Automatic Setup Feature**: 

Starting from the latest version, the `qmd-knowledge` skill includes automatic setup. When you first run a record command, the script will:
- Auto-detect your project name from git remote URL (most reliable)
- Create necessary directories
- Add qmd collection (or verify if already exists - no errors!)
- Add context for better search
- Generate embeddings

This means you can start using the skill immediately without manual collection setup.

## Usage

### Recording Knowledge

#### Record a Learning

```bash
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh learning "qmd MCP integration"
```

This creates a timestamped file: `references/learnings/YYYY-MM-DD-qmd-mcp-integration.md`

#### Add Issue Note

```bash
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh issue 123 "Fixed by updating dependencies"
```

This appends to `references/issues/123.md` (creating it if it doesn't exist).

#### Record General Note

```bash
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh note "Consider using agent skills for extensibility"
```

### Querying Knowledge

#### From Claude or OpenCode

When qmd MCP server is configured, Claude can autonomously search the knowledge base:

> "What did I learn about MCP servers?"

Claude will use the qmd MCP server tools to query the knowledge base.

#### Manual Queries

```bash
# Fast keyword search within a collection
qmd search "MCP servers" -c my-ai-tools

# Semantic search using AI embeddings
qmd vsearch "how to configure MCP"

# Hybrid search with reranking (best quality)
qmd query "quarterly planning process"

# Get a specific document
qmd get "references/learnings/2024-01-26-qmd-integration.md"

# Get document by docid (shown in search results)
qmd get "#abc123"

# Get multiple documents by glob pattern
qmd multi-get "references/learnings/2025-05*.md"

# Search with minimum score filter
qmd search "API" --all --files --min-score 0.3 -c my-ai-tools

# Update embeddings after manual edits
qmd embed
```

## Example Workflow

### 1. Capture Learning During Development

**You (in Claude):**
> "I just learned that qmd MCP server allows Claude to use tools autonomously for knowledge management."

**Claude recognizes the skill and executes:**
```bash
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh learning "qmd MCP autonomous tool use"
```

### 2. Query Knowledge Later

**You (in Claude):**
> "What have I learned about MCP servers in this project?"

**Claude uses qmd MCP server:**
```
qmd query "MCP servers"
```

Or with collection filter:
```
qmd search "MCP servers" -c my-ai-tools
```

**Claude responds with relevant learnings from the knowledge base.**

### 3. Track Issue Resolution

**You (in Claude):**
> "Add a note to issue #123 that it was fixed by updating the qmd dependency."

**Claude executes:**
```bash
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh issue 123 "Fixed by updating qmd dependency to latest version"
```

## Multiple Projects

The qmd-knowledge skill manages knowledge for multiple projects. Each project gets its own qmd collection:

```bash
# Create storage for a different project
mkdir -p ~/.ai-knowledges/another-project/learnings
mkdir -p ~/.ai-knowledges/another-project/issues

# Add collection and context
qmd collection add ~/.ai-knowledges/another-project --name another-project
qmd context add qmd://another-project "Knowledge base for another-project"

# Generate embeddings
qmd embed
```

Use the same skill script for all projects - it will use the `QMD_PROJECT` environment variable or detect the project automatically.

## Advanced Usage

### Project Name Detection

The skill automatically detects your project name using the following priority:

1. **QMD_PROJECT environment variable** (highest priority)
2. **Git remote URL** (most reliable - extracts repo name from origin)
3. **Git repository folder name** (fallback if remote URL unavailable)
4. **Current directory name** (last resort)

This ensures consistent project naming even if your local folder has a non-standard name (e.g., `2026-01-08-my-ai-tools.qmd-skill` will still be detected as `my-ai-tools`).

### Custom Project Detection

Set the `QMD_PROJECT` environment variable to override automatic detection:

```bash
export QMD_PROJECT="another-project"
~/.config/opencode/skill/qmd-knowledge/scripts/record.sh learning "This goes to another-project"
```

### Handling Existing Collections

The skill now automatically handles existing collections gracefully. If a collection already exists:

- The script will verify its presence and continue without error
- No manual intervention is needed
- The knowledge base will be ready to use immediately

This prevents the "Collection already exists" error that previously occurred.

### Backup Knowledge Base

```bash
# Backup to git
cd ~/.ai-knowledges/my-ai-tools
git init
git add .
git commit -m "Backup knowledge base"
git remote add origin <your-backup-repo>
git push -u origin main
```

### Sync Across Machines

```bash
# On machine 1
cd ~/.ai-knowledges/my-ai-tools
git push

# On machine 2
cd ~/.ai-knowledges
git clone <your-backup-repo> my-ai-tools

# Add collection and generate embeddings
qmd collection add ~/.ai-knowledges/my-ai-tools --name my-ai-tools
qmd context add qmd://my-ai-tools "Knowledge base for my-ai-tools project"
qmd embed
```

## Troubleshooting

### qmd not found

Install qmd:
```bash
bun install -g https://github.com/tobi/qmd
```

### Knowledge collection not found

Create the collection for your project:
```bash
mkdir -p ~/.ai-knowledges/my-ai-tools/learnings
mkdir -p ~/.ai-knowledges/my-ai-tools/issues
qmd collection add ~/.ai-knowledges/my-ai-tools --name my-ai-tools
qmd context add qmd://my-ai-tools "Knowledge base for my-ai-tools project"
qmd embed
```

### MCP server not working

1. Check that qmd is in your PATH: `which qmd`
2. Verify MCP server config in `~/.claude/mcp-servers.json` or `~/.config/amp/settings.json`
3. Restart Claude Code or Amp

### Embeddings not updating

Manually regenerate embeddings:
```bash
qmd embed
```

This will update the semantic search index for all collections.

## Resources

- **[qmd GitHub](https://github.com/tobi/qmd)** - Quick Markdown Search
- **[How to create custom Skills](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills)** - Official documentation
- **[Skills Specification](https://agentskills.io/what-are-skills)** - Technical details
- **[MCP Documentation](https://mcp.so)** - Model Context Protocol

## Contributing

Contributions welcome! To add features:

1. Fork the repository
2. Create a feature branch
3. Add your changes to `configs/opencode/skill/qmd-knowledge/`
4. Submit a pull request

## License

MIT - Same as the parent repository
