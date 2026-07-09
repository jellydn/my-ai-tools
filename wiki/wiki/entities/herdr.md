---
title: "herdr"
type: entity
category: tool
tags: [ai-tool, terminal-multiplexer, agent-aware]
created: 2026-07-10
---

# herdr

Terminal-native agent multiplexer — like `tmux` but agent-aware. Manages workspaces, tabs, and panes, each running its own shell, agent, or server, with automatic agent status tracking and a local socket API.

## Config Location

- Config dir: `~/.config/herdr/` (repo: `configs/herdr/`)
- Agent guidelines: `AGENTS.md`

## Key Features

- **Workspace management** — tabs, panes, split layouts
- **Agent awareness** — tracks agent status (running, done, error)
- **Socket API** — local unix socket for programmatic control
- **Session restoration** — save and restore workspace layouts
- **Integration hooks** — per-agent state tracking (Claude, Codex, Copilot)

## Related Pages

- [[sources/readme]] — Primary documentation source
- [[tmux]] — Remote tmux control skill (related terminal multiplexing)
