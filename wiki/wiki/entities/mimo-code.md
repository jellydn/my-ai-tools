---
title: "MiMo-Code"
type: entity
category: tool
tags: [ai-tool, coding-assistant, opencode-fork, xiaomi]
created: 2026-07-10
---

# MiMo-Code

Xiaomi's open-source, terminal-native AI coding assistant. Forked from OpenCode with persistent memory, agentic orchestration, and self-improvement capabilities.

## Config Location

- Config dir: `~/.config/mimocode/` (repo: `configs/mimo/`)
- Config format: OpenCode-compatible JSON (mimocode.jsonc)
- Agent guidelines: `AGENTS.md`

## Key Features

- **Persistent Cross-Session Memory** — SQLite-powered with `MEMORY.md`, checkpoints, and task history
- **Intelligent Context Management** — Auto-ranked knowledge injection on resume
- **Agentic Orchestration** — Multiple agents (`build`, `plan`, `compose`) with subagents
- **Goal Tracking** — `/goal` command with independent judge model
- **Self-Improvement** — `/dream` extracts knowledge from sessions; `/distill` packages workflows
- **Voice Input** — TenVAD + MiMo ASR
- **Kanagawa theme** by default

## MCP Servers

Same as OpenCode: context7, qmd, fff, sequential-thinking, react-grab-mcp, logpilot, agentmemory

## Custom Commands

- `rmslop` — Remove AI-generated boilerplate and redundant code

## Related Pages

- [[sources/readme]] — Primary documentation source
- [[agent-teams]] — Multi-agent orchestration patterns
