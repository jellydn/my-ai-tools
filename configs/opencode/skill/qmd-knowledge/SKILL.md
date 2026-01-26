---
name: qmd-knowledge
description: Project-specific knowledge management system using qmd MCP server. Captures learnings, issue notes, and conventions in a searchable knowledge base.
license: MIT
compatibility: opencode, claude
metadata:
  audience: all
  workflow: knowledge-management
---

## What I do

- Record and retrieve project learnings and insights
- Capture issue-specific notes and resolutions
- Build a growing, AI-searchable knowledge base
- Provide context about project architecture and decisions

## When to use me

Use this skill when you need to:

- **Record learnings**: Capture new insights, patterns, or best practices discovered during development
- **Track issues**: Add notes to ongoing or resolved issues
- **Query knowledge**: Search for previous decisions, learnings, or solutions
- **Maintain context**: Build institutional memory for the project

## How it works

This skill uses a standardized directory structure within `~/.ai-knowledges/` to store project-specific knowledge:

```
~/.ai-knowledges/
└── my-ai-tools/              # Project root
    ├── SKILL.md              # This file (symlinked from config)
    ├── scripts/              # Executable scripts
    │   └── record.sh         # Record learnings/issues/notes
    └── references/           # Knowledge base
        ├── learnings/        # Project learnings
        └── issues/           # Issue-specific notes
```

The `qmd` MCP server provides AI-powered search across all stored knowledge, allowing Claude to autonomously query and update the knowledge base.

## Available scripts

### Recording knowledge

```bash
# Record a learning
~/.ai-knowledges/my-ai-tools/scripts/record.sh learning "qmd MCP integration"

# Add a note to an issue
~/.ai-knowledges/my-ai-tools/scripts/record.sh issue 123 "Fixed by updating dependencies"

# Record a general note
~/.ai-knowledges/my-ai-tools/scripts/record.sh note "Consider using agent skills for extensibility"
```

### Querying knowledge

Use the qmd MCP server tools directly from Claude or OpenCode:

```bash
# Search for MCP-related learnings
qmd query --collection my-ai-tools "MCP servers"

# List all collections
qmd list
```

## Setup

1. **Install qmd** (requires Rust):
   ```bash
   cargo install qmd
   ```

2. **Configure MCP server** (see installation docs for Claude/OpenCode/Amp)

3. **Initialize project knowledge base**:
   ```bash
   mkdir -p ~/.ai-knowledges/my-ai-tools
   cp -r configs/opencode/skill/qmd-knowledge/* ~/.ai-knowledges/my-ai-tools/
   qmd init --collection my-ai-tools --path ~/.ai-knowledges/my-ai-tools
   ```

## Knowledge structure

- `references/learnings/`: Time-stamped markdown files with project insights
  - Format: `YYYY-MM-DD-topic-slug.md`
  - Contains learnings, patterns, architectural decisions

- `references/issues/`: Issue-specific notes and resolutions
  - Format: `<issue-id>.md`
  - Append-only log of notes related to specific issues

## Integration with qmd MCP server

The qmd MCP server allows Claude to:

- **Search knowledge**: Use natural language queries to find relevant context
- **Auto-update index**: Automatically reindex after adding new knowledge
- **Filter by project**: Use `--collection` flag to scope searches to specific projects

## Example workflow

1. **During development**, you discover something useful:
   > "I learned that qmd MCP server allows Claude to use tools autonomously."

2. **Claude recognizes the skill and executes**:
   ```bash
   ~/.ai-knowledges/my-ai-tools/scripts/record.sh learning "qmd MCP autonomous tool use"
   ```

3. **Later, you ask**:
   > "What did I learn about MCP servers?"

4. **Claude queries the knowledge base** using qmd MCP tools:
   ```bash
   qmd query --collection my-ai-tools "MCP servers"
   ```

## Benefits over claude-mem

- **Portable**: Standard markdown files in `~/.ai-knowledges/`
- **Project-scoped**: Each project has its own isolated knowledge base
- **AI-searchable**: Powered by qmd's embedding-based search
- **Self-documenting**: Follows skills.sh specification
- **No repository pollution**: Knowledge stored outside project directories
- **Version controllable**: Can optionally track knowledge in separate git repos
