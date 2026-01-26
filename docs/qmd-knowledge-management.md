# qmd Knowledge Management System

> **Alternative to claude-mem**: Project-specific knowledge capture using qmd MCP server and Agent Skills

## Overview

This system provides a lightweight, project-specific knowledge management solution that captures learnings, issue notes, and project conventions in a searchable knowledge base. Unlike `claude-mem`, it:

- ✅ Keeps knowledge **outside project directories** (no repository pollution)
- ✅ Uses **standard markdown files** (portable and version-controllable)
- ✅ Provides **AI-powered search** via qmd MCP server
- ✅ Follows **skills.sh specification** (self-documenting)
- ✅ Supports **multiple projects** with isolated knowledge bases

## Architecture

```
~/.ai-knowledges/
├── my-ai-tools/              # Project root = Skill folder
│   ├── SKILL.md              # Required: Metadata + instructions
│   ├── scripts/              # Executable scripts
│   │   └── record.sh         # Script to record learnings/issues
│   └── references/           # Knowledge base (learnings, issues)
│       ├── learnings/
│       │   ├── README.md
│       │   ├── 2024-01-26-qmd-integration.md
│       │   └── 2024-01-27-mcp-servers.md
│       └── issues/
│           ├── README.md
│           ├── 123.md
│           └── 456.md
└── another-project/
    ├── SKILL.md
    ├── scripts/
    └── references/
```

## Installation

### 1. Install qmd

qmd requires Rust. Install from source:

```bash
cargo install qmd
```

Or follow the [official installation guide](https://github.com/tobi/qmd).

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

### 3. Initialize Project Knowledge Base

```bash
# Create knowledge base directory
mkdir -p ~/.ai-knowledges/my-ai-tools

# Copy skill files
cp -r configs/opencode/skill/qmd-knowledge/* ~/.ai-knowledges/my-ai-tools/

# Initialize qmd collection
cd ~/.ai-knowledges/my-ai-tools
qmd init --collection my-ai-tools --path .
```

### 4. Install Configuration (Optional)

Run the setup script to install all configurations:

```bash
./cli.sh
```

This will copy the qmd skill to `~/.config/opencode/skill/qmd-knowledge/`.

## Usage

### Recording Knowledge

#### Record a Learning

```bash
~/.ai-knowledges/my-ai-tools/scripts/record.sh learning "qmd MCP integration"
```

This creates a timestamped file: `references/learnings/YYYY-MM-DD-qmd-mcp-integration.md`

#### Add Issue Note

```bash
~/.ai-knowledges/my-ai-tools/scripts/record.sh issue 123 "Fixed by updating dependencies"
```

This appends to `references/issues/123.md` (creating it if it doesn't exist).

#### Record General Note

```bash
~/.ai-knowledges/my-ai-tools/scripts/record.sh note "Consider using agent skills for extensibility"
```

### Querying Knowledge

#### From Claude or OpenCode

When qmd MCP server is configured, Claude can autonomously search the knowledge base:

> "What did I learn about MCP servers?"

Claude will use the qmd MCP server tools to query the knowledge base.

#### Manual Queries

```bash
# Search for MCP-related learnings
qmd query --collection my-ai-tools "MCP servers"

# List all collections
qmd list

# Update index after manual edits
qmd update --collection my-ai-tools
```

## Example Workflow

### 1. Capture Learning During Development

**You (in Claude):**
> "I just learned that qmd MCP server allows Claude to use tools autonomously for knowledge management."

**Claude recognizes the skill and executes:**
```bash
~/.ai-knowledges/my-ai-tools/scripts/record.sh learning "qmd MCP autonomous tool use"
```

### 2. Query Knowledge Later

**You (in Claude):**
> "What have I learned about MCP servers in this project?"

**Claude uses qmd MCP server:**
```
qmd query --collection my-ai-tools "MCP servers"
```

**Claude responds with relevant learnings from the knowledge base.**

### 3. Track Issue Resolution

**You (in Claude):**
> "Add a note to issue #123 that it was fixed by updating the qmd dependency."

**Claude executes:**
```bash
~/.ai-knowledges/my-ai-tools/scripts/record.sh issue 123 "Fixed by updating qmd dependency to latest version"
```

## Multiple Projects

Each project gets its own knowledge base:

```bash
# Initialize for a different project
mkdir -p ~/.ai-knowledges/another-project
cp -r configs/opencode/skill/qmd-knowledge/* ~/.ai-knowledges/another-project/
cd ~/.ai-knowledges/another-project
qmd init --collection another-project --path .
```

Claude can filter queries by project using the `--collection` flag.

## Benefits Over claude-mem

| Feature | claude-mem | qmd-knowledge |
|---------|-----------|---------------|
| **Repository Pollution** | ❌ Creates CLAUDE.md files in project dirs | ✅ Stores knowledge in `~/.ai-knowledges/` |
| **Search Quality** | Basic text search | ✅ AI-powered embedding search |
| **Project Scoping** | Global or per-repo | ✅ Isolated collections per project |
| **Portability** | Tied to Claude Code | ✅ Works with Claude, OpenCode, Amp |
| **Format** | Proprietary | ✅ Standard markdown files |
| **Version Control** | Hard to track | ✅ Can version knowledge separately |
| **Status** | ⚠️ Deprecated/Broken | ✅ Active development |

## Advanced Usage

### Custom Project Detection

Set the `QMD_PROJECT` environment variable to override project detection:

```bash
export QMD_PROJECT="another-project"
~/.ai-knowledges/my-ai-tools/scripts/record.sh learning "This goes to another-project"
```

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
qmd init --collection my-ai-tools --path my-ai-tools
```

## Troubleshooting

### qmd not found

Install qmd:
```bash
cargo install qmd
```

### Knowledge base not found

Initialize the knowledge base:
```bash
mkdir -p ~/.ai-knowledges/my-ai-tools
cp -r configs/opencode/skill/qmd-knowledge/* ~/.ai-knowledges/my-ai-tools/
```

### MCP server not working

1. Check that qmd is in your PATH: `which qmd`
2. Verify MCP server config in `~/.claude/mcp-servers.json` or `~/.config/amp/settings.json`
3. Restart Claude Code or Amp

### Index not updating

Manually update the index:
```bash
cd ~/.ai-knowledges/my-ai-tools
qmd update --collection my-ai-tools
```

## Resources

- **[qmd GitHub](https://github.com/tobi/qmd)** - Quick Markdown Search
- **[Agent Skills](https://skills.sh/)** - Open format for AI agent capabilities
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
