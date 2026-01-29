# Agent Skill Standard

This document defines the standard format for Agent skills in this repository.

## Required Structure

All skills must follow this structure:

```
my-skill/
├── SKILL.md          # Required: instructions + metadata
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
└── assets/           # Optional: templates, resources
```

## YAML Frontmatter

Every SKILL.md must include YAML frontmatter with the following fields:

```yaml
---
name: skill-name
description: One-sentence description of what the skill does
license: MIT
compatibility: claude, opencode, amp, codex
hint: Use when [context for using this skill]
metadata:
  audience: all
  workflow: category
---
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | The skill identifier (kebab-case) |
| `description` | Yes | Brief one-sentence description of the skill's purpose |
| `license` | Yes | License identifier (typically MIT) |
| `compatibility` | Yes | Comma-separated list of compatible platforms |
| `hint` | Yes | Usage suggestion - when to use this skill |
| `metadata.audience` | Yes | Target audience (typically "all") |
| `metadata.workflow` | Yes | Category: testing, documentation, code-quality, workflow, etc. |

### Workflow Categories

Common workflow categories include:
- `testing` - Test-related skills
- `documentation` - Documentation generation
- `code-quality` - Code review, refactoring, cleanup
- `workflow` - Development workflow helpers
- `knowledge-management` - Knowledge base tools
- `codebase-mapping` - Codebase analysis

## Skill Location

All skills are located in `.claude-plugin/plugins/`:

```
.claude-plugin/plugins/
├── adr/
├── codemap/
├── handoffs/
├── pickup/
├── pr-review/
├── prd/
├── qmd-knowledge/
├── ralph/
├── slop/
└── tdd/
```

## Adding a New Skill

To add a new skill:

1. **Create the skill folder:**
   ```bash
   mkdir -p .claude-plugin/plugins/my-skill
   ```

2. **Create SKILL.md with proper frontmatter:**
   ```bash
   cat > .claude-plugin/plugins/my-skill/SKILL.md << 'EOF'
   ---
   name: my-skill
   description: Brief description of what the skill does
   license: MIT
   compatibility: claude, opencode, amp, codex
   hint: Use when [context for using this skill]
   metadata:
     audience: all
     workflow: category
   ---

   # My Skill

   Detailed description of the skill...
   EOF
   ```

3. **Add optional folders if needed:**
   ```bash
   mkdir -p .claude-plugin/plugins/my-skill/templates
   mkdir -p .claude-plugin/plugins/my-skill/scripts
   ```

4. **Test the skill:**
   ```bash
   ./cli.sh --dry-run
   ```

## Platform Compatibility

Skills are automatically installed to multiple platforms:

| Platform | Installation Path | Usage |
|----------|-------------------|-------|
| Claude Code | `~/.claude/skills/` | Skill invocation |
| OpenCode | `~/.config/opencode/skill/` | Command files + skills |
| Amp | `~/.config/amp/skills/` | Skill invocation |
| Codex CLI | Reads from `.claude-plugin/plugins/` | Invoke via `$skill-name` |

## Examples

### Simple Skill (No Templates)

```yaml
---
name: slop
description: Removes AI-generated code slop from git diffs
license: MIT
compatibility: claude, opencode, amp, codex
hint: Use when cleaning up AI-generated code slop in git diffs
metadata:
  audience: all
  workflow: code-quality
---

# Remove AI Code Slop

...
```

### Skill with Templates

```yaml
---
name: adr
description: Manages Architecture Decision Records
license: MIT
compatibility: claude, opencode, amp, codex
hint: Use when managing architecture decisions, creating ADRs, or tracking architectural choices
metadata:
  audience: all
  workflow: documentation
---

# Architecture Decision Records

The template is available at `$SKILL_PATH/templates/adr-template.md`.
```

### Skill with Scripts

```yaml
---
name: qmd-knowledge
description: Project-specific knowledge management system
license: MIT
compatibility: claude, opencode, amp, codex
metadata:
  audience: all
  workflow: knowledge-management
---

## Available scripts

### Recording knowledge
```bash
$SKILL_PATH/scripts/record.sh learning "topic"
```
```

## Validation

To validate a skill:

```bash
# Check for SKILL.md
test -f .claude-plugin/plugins/my-skill/SKILL.md

# Check for YAML frontmatter
head -10 .claude-plugin/plugins/my-skill/SKILL.md | grep -q "^---"

# Check for required fields
grep -q "^name:" .claude-plugin/plugins/my-skill/SKILL.md
grep -q "^description:" .claude-plugin/plugins/my-skill/SKILL.md
```

## See Also

- [Agent Skills Specification](https://github.com/anthropics/claude-code)
- [Skills CLI](https://skills.sh/)
