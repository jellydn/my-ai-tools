# Central Skills Directory

This directory contains **shared skills** that are used across multiple AI tools (Claude Code, OpenCode, Amp).

## Why Central Skills?

Previously, the same skill was duplicated in multiple places:
- `configs/claude/skills/qmd-knowledge/`
- `configs/amp/skills/qmd-knowledge/`
- `configs/opencode/skill/qmd-knowledge/`

This caused:
- **Maintenance overhead**: Changes required updating 2-3 copies
- **Inconsistency risk**: Skills could diverge over time
- **Storage duplication**: Same files stored multiple times

## How It Works

### Installation (`cli.sh`)

When you run `./cli.sh`, the script:
1. Copies tool-specific skills from `configs/{tool}/skills/` (if any)
2. Creates **symlinks** from central skills to each tool's skills directory

For example:
```bash
# Central skill location (source of truth)
skills/qmd-knowledge/

# Tool-specific installations (via symlinks)
~/.claude/skills/qmd-knowledge -> /path/to/my-ai-tools/skills/qmd-knowledge
~/.config/amp/skills/qmd-knowledge -> /path/to/my-ai-tools/skills/qmd-knowledge
~/.config/opencode/skill/qmd-knowledge -> /path/to/my-ai-tools/skills/qmd-knowledge
```

### Export (`generate.sh`)

When you run `./generate.sh`, the script:
1. Detects symlinks in tool directories
2. Copies symlinked skills back to `skills/` (central location)
3. Copies regular directories to `configs/{tool}/skills/` (tool-specific)

This ensures:
- Shared skills stay in one place
- Tool-specific skills remain separate
- No duplication in the repository

## Current Shared Skills

| Skill | Tools | Description |
|-------|-------|-------------|
| qmd-knowledge | Claude, AMP, OpenCode | Project knowledge management using qmd MCP server |
| prd | Claude, AMP | Generate Product Requirements Documents |
| ralph | Claude, AMP | Convert PRDs to Ralph autonomous agent format |

## Adding a New Shared Skill

1. Create the skill in `skills/[skill-name]/`
2. Run `./cli.sh` to deploy via symlinks to all tools
3. The skill will be automatically available in all configured AI tools

## Adding a Tool-Specific Skill

1. Create the skill in `configs/{tool}/skills/[skill-name]/`
2. Run `./cli.sh` to deploy only to that specific tool
3. The skill will only be available in that one tool

## Benefits

- ✅ **Single source of truth**: Update once, applies everywhere
- ✅ **Easy maintenance**: No need to synchronize multiple copies
- ✅ **Consistent behavior**: All tools use the exact same skill
- ✅ **Flexible**: Tool-specific skills still supported when needed
- ✅ **Version control friendly**: No duplicated files in git
