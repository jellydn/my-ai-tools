# 🤖 Gemini CLI Agent Guidelines - my-ai-tools

This repository manages configurations, MCP servers, skills, and agents for a suite of AI coding tools (Claude Code, Gemini CLI, OpenCode, Amp, etc.).

## 🚀 Project Overview

- **Purpose**: Unified configuration management and bidirectional sync for AI development environments.
- **Core Stack**:
  - **Shell**: Bash scripts (`cli.sh`, `generate.sh`) for orchestration.
  - **Logic**: Node.js/Bun for hooks, plugins, and skills.
  - **Context**: Markdown-based instructions (`AGENTS.md`, `MEMORY.md`, `best-practices.md`).
  - **Integrations**: Extensive use of **MCP (Model Context Protocol)** servers (`context7`, `qmd`, `fff`, `sequential-thinking`).
- **Architecture**:
  - `configs/`: Source-of-truth configurations for each tool.
  - `skills/`: Local extensions compatible with AI agent "skill" systems.
  - `lib/`: Shared shell libraries (`common.sh`).
  - `cli.sh`: Deploys configs from repo to `~/.config/` or `~/.claude/`.
  - `generate.sh`: Exports local configs back to the repo for version control.

## 🛠️ Key Commands

### Installation & Sync

- **Install/Sync to System**: `./cli.sh`
  - `--dry-run`: Preview changes.
  - `--backup`: Backup current configs before overwrite.
  - `--yes`: Auto-accept prompts.
- **Export to Repo**: `./generate.sh`
  - `./generate.sh --dry-run`: Preview export.

### Development & Testing

- **Test Scripts**: `bats tests/` (Uses the BATS framework for shell testing).
- **Format Code**: Handled via hooks (e.g., `biome check --write` for JS/TS).

## 🎨 Development Conventions

### Bash Scripting Standards

- **POSIX Compliance**: Use `#!/bin/bash` and keep scripts portable.
- **Error Handling**: Always use `set -e`.
- **Preconditions**: Use guard clauses at the top of functions.
- **Dry Run Support**: Wrap destructive operations in the `execute()` function.
- **Local Scope**: Use `local` for all function variables.

### AI Interaction Standards

- **Tidy First**: Separate refactoring (tidying) from behavioral changes.
- **Session Management**: Use `tmux` for long-running processes (named after the directory).
- **Atomic Commits**: Prefer small, focused commits over large changes.
- **Formatting Hooks**: Assume `PostToolUse` hooks will auto-format files after edits (Biome, Ruff, Shfmt, etc.).

## 🧠 Knowledge Management (qmd)

- **Persistent Learnings**: Use the `qmd` MCP server for project-specific knowledge.
- **Recording**: Use the `/qmd-knowledge` skill to record insights to `~/.ai-knowledges/`.
- **Retrieval**: Use `mcp__qmd__query` for hybrid search across recorded knowledge.

## 📋 Directory Structure Highlights

- `configs/claude/`: Primary configurations for Claude Code (hooks, agents, settings).
- `configs/gemini/`: Configuration for Gemini CLI (agents, commands, settings).
- `skills/`: Reusable agent skills (PRD, TDD, ADR, Codemap).
- `lib/common.sh`: Central library for logging, prompt handling, and command execution.

## 🛡️ Git Safety

- **Git Guard**: A `PreToolUse` hook (`configs/claude/hooks/git-guard.ts`) blocks dangerous commands like `git push --force` or `git reset --hard` when triggered by agents.

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Load the shell integration in the shell that runs your commands: `eval "$(try init)"` for bash/zsh. Without it, `try` only prints shell commands. If the wrapper cannot run (for example, no `/dev/tty`), use the fallbacks below.
- Run `try . <name>` from the repository root for a worktree, or `try clone <url> [name]` for an external repository. Confirm that the new directory is a worktree or clone before editing; `try` can hide worktree creation failures. If creation fails, diagnose it and use the fallback with a new path.
- For a fresh experiment, run `try <name>` and press Ctrl-T in the interactive selector to create a directory; selecting an existing match does not create one. `try new <name>` is a search, not a creation subcommand. Without a terminal, create a new date-prefixed directory under `${TRY_PATH:-$HOME/src/tries}` with `mkdir` instead; choose an unused path.
- Worktrees and fresh experiments use date-prefixed names under `$TRY_PATH` (default: `~/src/tries`). A clone with a custom name uses that name without a date prefix; an unnamed clone uses `YYYY-MM-DD-<user>-<repo>`. Use the printed path in later commands; directory changes apply only to the invoking shell.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments under the tries directory instead of ad hoc `/tmp` folders. When `try` is unavailable or unsuitable, use `git worktree add -b <branch> <path>` for a repository with a commit, `git clone <url> <path>` for an external repository, or `mkdir` for a fresh experiment.
