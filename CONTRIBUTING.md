# Contributing to AI Tools Setup Guide

Thank you for your interest in contributing! This guide helps others replicate your AI development environment setup.

## How to Contribute

### 1. Adding New Tools

To add a new AI tool to the setup guide:

1. Create a new directory under `configs/` (e.g., `configs/newtool/`)
2. Add configuration files to that directory
3. Update `README.md` with installation and configuration instructions
4. Update `cli.sh` to support installing and configuring the new tool

### 2. Improving Existing Configs

If you want to improve or add features to existing configurations:

1. Update the relevant config file in `configs/<tool>/`
2. Update `README.md` if the changes affect user workflow
3. Test changes with `./cli.sh --dry-run` first

### 3. Adding Best Practices

This guide includes software development best practices. To contribute:

1. Add markdown content to `configs/best-practices.md`
2. Reference it in OpenCode configurations if applicable

## Submission Guidelines

1. Keep configurations portable and self-contained
2. Use relative paths (avoid absolute paths like `/Users/username/`)
3. Add comments to explain non-obvious settings
4. Test the setup script before submitting changes

## Style Guide

- Follows zed-101-setup README format pattern
- Use emoji headers for visual hierarchy
- Include copy-paste ready code blocks
- Keep installation commands simple and verified

## Questions?

Open an issue or reach out via support channels listed in README.md.

## How to Add New Skills

1. **Create skill directory**: Create a new directory under `.claude/skills/{skill-name}/`
2. **Create SKILL.md file**: Add `SKILL.md` with skill frontmatter and content
3. **Update skill-rules.json**: Add triggers and keywords for your new skill
4. **Document**: Add skill to `skills/README.md` if it exists

### Skill Frontmatter Format

```markdown
---
name: skill-name
description: Brief description of what this skill does and when to use it. Include keywords users would mention.
allowed-tools: Read, Grep, Bash(git:*)
model: claude-sonnet-4-20250514
---

# Skill Content

Your skill documentation here...
```

### Best Practices

- Keep skills focused on a specific domain or pattern
- Include examples (good and bad patterns)
- Reference related skills
- Keep descriptions under 1024 characters

## How to Add New Agents

1. **Create agent file**: Add `.md` file to `.claude/agents/{agent-name}.md`
2. **Define frontmatter**: Include name, description, model
3. **Document process**: What is agent does and when to invoke it
4. **Create checklist**: Organize review criteria by severity (Critical, Warning, Suggestion)
5. **Integration**: Reference related skills or commands

### Agent Format

```markdown
---
name: agent-name
description: When to use this agent and what it does.
model: opus
---

# Agent Content

Your agent documentation here...

## Process

Your step-by-step process here...
```

## How to Modify Hooks

1. **Edit settings.json**: Add or modify hook definitions
2. **Test hooks**: Run hooks manually to verify they work
3. **Update settings.md**: Document any new or modified hooks

## How to Add New Commands

1. **Create command file**: Add `.md` file to `.claude/commands/{command-name}.md`
2. **Define frontmatter**: Include description, allowed-tools
3. **Document process**: Step-by-step instructions
4. **Use variables**: `$ARGUMENTS`, `$1`, `$2`, etc.

## How to Customize Skill Rules

Edit `.claude/hooks/skill-rules.json` to:
- Adjust `minConfidenceScore` (3-7)
- Add new skills with triggers
- Update directory mappings
- Add exclusion patterns

## Testing Changes

Before submitting a PR or commit:

1. **Test skill evaluation**: Run `/onboard <test>` to verify skills activate
2. **Test hooks**: Edit a file on main branch to verify branch protection
3. **Test agents**: Run `/code-reviewer` to verify review quality
4. **Test commands**: Try new commands in a test directory

## Code Style Guidelines

- Follow your project's existing style
- Keep documentation concise
- Use meaningful names for files and functions
- Avoid over-engineering solutions or overcomplicating things unnecessarily

Remember: **Software design is an exercise in human relationships.** Make your contributions clear, well-documented, and respectful of existing code.
## Questions?

Open an issue or reach out via the support channels listed in README.md.
