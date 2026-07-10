---
title: "Subagent Infrastructure"
type: entity
category: architecture
tags: [subagents, agents, multi-tool, standardization]
created: 2026-07-10
---

# Subagent Infrastructure

Standardized subagent configurations deployed across 12 AI coding tools. Each tool gets 5 agents with tool-specific formats and tool restrictions.

## The 5 Standard Agents

| Agent | Role | Tool Access |
|-------|------|-------------|
| **code-reviewer** | Read-only code quality review | Read, Grep, Glob, Bash (git only) |
| **test-generator** | Generate comprehensive tests | Read, Write, Edit, Bash (test commands) |
| **documentation-writer** | Create clear documentation | Read, Write, Edit (no Bash) |
| **ai-slop-remover** | Remove AI-generated patterns | Read, Write, Edit, Bash (quality checks) |
| **security-audit** | Read-only security audit | Read, Grep, Glob, Bash (npm audit) |

## Tool Coverage

| Tool | Format | Count |
|------|--------|-------|
| **Claude Code** | `.md` with frontmatter + "Available Tools" | 9 agents |
| **OpenCode** | `.md` with `permission:` blocks | 5 agents |
| **Pi** | `.md` with `tools:` frontmatter + `prompt_mode: replace` | 5 agents |
| **Amp** | SKILL.md with tool guidance | 5 skills |
| **Cursor** | Task subagent `.md` | 1 agent |
| **Codex** | `.md` with `tools` array + `model: inherit` | 5 agents |
| **Kiro** | `.json` configs + `.md` shared prompts | 5 agents |
| **Copilot** | `.agent.md` with `tools` arrays | 5 agents |
| **Factory** | `.md` droids with `tools: read-only`/`edit` | 5 droids |
| **Kimi Code** | SKILL.md with `tools:` frontmatter | 5 skills |
| **Cline** | SKILL.md with frontmatter | 5 skills |
| **Grok** | Plugin marketplace (not file-based) | — |

## Related Pages

- [[agent-teams]] — Multi-agent orchestration patterns
- [[sources/readme]] — Primary documentation source
