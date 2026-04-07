# Skills

Local marketplace skills available in this repository.

## Overview

Skills are pre-configured prompts for specific tasks. The repository includes 11 local skills for distribution.

## Available Skills

| Skill | Description | Directory |
|-------|-------------|-----------|
| adr | Architecture Decision Records | `skills/adr/` |
| codemap | Parallel codebase analysis producing structured docs | `skills/codemap/` |
| handoffs | Create handoff plans for continuing work | `skills/handoffs/` |
| pickup | Resume work from previous handoff sessions | `skills/pickup/` |
| plannotator-review | Interactive code review | `skills/plannotator-review/` |
| pr-review | Pull request review workflows | `skills/pr-review/` |
| prd | Generate Product Requirements Documents | `skills/prd/` |
| qmd-knowledge | Project knowledge management | `skills/qmd-knowledge/` |
| ralph | Convert PRDs to JSON for autonomous agent execution | `skills/ralph/` |
| slop | AI slop detection and removal | `skills/slop/` |
| tdd | Test-Driven Development workflows | `skills/tdd/` |

## Installation

Skills are automatically installed by `cli.sh` from the `skills/` folder.

## Skill Format

Each skill is a directory with a `SKILL.md` file:

```markdown
---
name: skill-name
description: Brief description
allowed-tools: Read, Grep, Bash(git:*)
model: claude-sonnet-4-20250514
---

# Skill Content
```

## Recommended Community Skills

| Framework | Repository | Description |
|-----------|------------|-------------|
| UI/UX Design | interface-design.dev | Comprehensive design guide |
| Expo | expo/skills | React Native development |
| Next.js | vercel-labs/agent-skills | Next.js and React development |
| Claude Skills | jezweb/claude-skills | 97 production-ready skills |
