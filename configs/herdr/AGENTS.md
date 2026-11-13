# 🚀 herdr Agent Guidelines

## Communication

Use ASD-STE100 Simplified Technical English. Read a relevant `CONTEXT.md` when it governs terms or behavior you change.

[**herdr**](https://herdr.dev/) ([GitHub](https://github.com/ogulcancelik/herdr)) is a terminal-native agent multiplexer — like `tmux` but agent-aware. It gives you workspaces, tabs, and panes, each running its own shell, agent, server, or log stream, and tracks agent status automatically.

## Key Concepts

- **Workspaces** — Project contexts, each with one or more tabs
- **Tabs** — Subcontexts inside a workspace, each with one or more panes
- **Panes** — Terminal splits running a shell, agent, server, or log stream
- **Agent Status** — Detected automatically: `idle`, `working`, `blocked`, `done`, `unknown`

## Configuration

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Read only task-relevant files and instructions. Do not preload repository maps, architecture docs, memory, or skills.
- Scope searches and command output with paths, filters, and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.

## Learning Recording

Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.

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

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Prefer `try . <name>` for a worktree from the current repository, `try clone <url> [name]` for an external repository, and `try new <name>` for a fresh experiment.
- `try` creates `$TRY_PATH/YYYY-MM-DD-<name>` (default `TRY_PATH`: `~/src/tries`) and changes directory only in the invoking shell. Use the printed path in later commands.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments in `try`-managed directories instead of ad hoc `/tmp` folders. Fall back to `git worktree add -b <branch> <path>` only when `try` is unavailable or unsuitable.
