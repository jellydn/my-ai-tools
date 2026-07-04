# 🚀 herdr Agent Guidelines

[**herdr**](https://herdr.dev/) ([GitHub](https://github.com/ogulcancelik/herdr)) is a terminal-native agent multiplexer — like `tmux` but agent-aware. It gives you workspaces, tabs, and panes, each running its own shell, agent, server, or log stream, and tracks agent status automatically.

## Key Concepts

- **Workspaces** — Project contexts, each with one or more tabs
- **Tabs** — Subcontexts inside a workspace, each with one or more panes
- **Panes** — Terminal splits running a shell, agent, server, or log stream
- **Agent Status** — Detected automatically: `idle`, `working`, `blocked`, `done`, `unknown`

## Configuration

## Learning Recording

Read @~/.ai-tools/MEMORY.md and @~/.ai-tools/agent-memory.md for the full decision rule.

After fixing a bug (confirmed by human), introducing a new tech choice, or encountering something important, ask the user:

> "Would you like me to record this as a learning?"

If yes:
- **qmd** (durable) — project-specific gotchas, architecture decisions, conventions
- **agentmemory** (session) — transient context only the current session needs

- User config: `~/.config/herdr/config.toml` (generate defaults with `herdr --default-config`)
- Agent detection overrides: `~/.config/herdr/agent-detection/<agent>.toml`
- Changes require reload: `herdr server reload-config` or the global menu

## Integrations

Herdr installs integrations for detected coding agents to enable session restoration and richer state tracking:

```bash
herdr integration install claude    # Claude Code
herdr integration install codex     # OpenAI Codex CLI
herdr integration install copilot   # GitHub Copilot CLI
herdr integration status            # Check installed integrations
```

## Agent Skill

The official agent skill file (`SKILL.md`) teaches agents how to control herdr from inside a herdr-managed pane. Install it from the upstream source of truth:

- Docs: https://herdr.dev/docs/agent-skill/
- Source: https://github.com/ogulcancelik/herdr/blob/master/SKILL.md

For agents with a skill system, install as a skill named `herdr`. The skill activates when `HERDR_ENV=1` is set (agent is running inside a herdr-managed pane).

## Usage

```bash
herdr                              # Start herdr
herdr pane list                    # List panes in current workspace
herdr pane split 1-2 --direction right --no-focus  # Split a pane
herdr wait agent-status 1-1 --status done --timeout 60000  # Wait for agent
```

See the full [herdr docs](https://herdr.dev/docs/) for details.
