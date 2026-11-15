# 🤖 Delta Agent Guidelines

## Communication

Use ASD-STE100 Simplified Technical English. Read a relevant `CONTEXT.md` when it governs terms or behavior you change.

## Session Management with tmux

Use tmux for long-running development servers, watch processes, and interactive CLIs. Use the **current directory name as the session name** for easy debugging:

```bash
SESSION=$(basename "$PWD")
tmux new -d -s "$SESSION" 2>/dev/null || true

# Run dev server with portless if available, otherwise fallback to npm
if command -v portless &>/dev/null; then
    tmux send-keys -t "$SESSION" 'portless run npm run dev' Enter
else
    tmux send-keys -t "$SESSION" 'npm run dev' Enter
fi

tmux capture-pane -p -t "$SESSION" -S -20  # check output
```

## 🔧 AI Tool Guidelines

- Prefer the fff MCP tools for file search operations when available; otherwise use the environment's native tools.
- Prefer the sem MCP tools for semantic version control and git operations when available; otherwise use the environment's native tools.
- When using shell commands for file or content search, prefer `fd` (fdfind) and `rg` (ripgrep) over standard `find` and `grep` for better performance and git awareness.

## Token Efficiency

- Keep responses concise and actionable; lead with conclusions, file paths, and verification.
- Read only task-relevant files and instructions. Do not preload repository maps, architecture docs, memory, or skills.
- Scope searches and command output with paths, filters, and line ranges.
- Use `~/.local/bin/rtk` for supported shell commands when available; bypass it with `RTK_DISABLED=1` when raw output is required.
- Prefer `codebase-memory-mcp` graph tools for structural code discovery when available.

## Decision and Safety

- Follow explicit user requests and the most specific applicable project instructions.
- Inspect relevant context, conventions, and existing tests before changing files.
- Prefer the simplest solution that fully meets the requirement. Avoid speculative abstractions and unrelated refactoring.
- Preserve existing behaviour unless a change is required; fix root causes rather than symptoms.
- Clearly distinguish verified facts from assumptions.
- Ask before destructive or irreversible operations.
- Do not expose secrets, credentials, personal data, or sensitive project details in responses, logs, or files.

## Verification

- Run the most relevant available checks after changes, such as tests, typecheck, lint, formatting, or build.
- Report what was verified and identify checks that were not run.

## 📋 General Practices

- Read `~/.ai-tools/best-practices.md` only when the repository lacks equivalent guidance or the task needs its detailed workflow.
- Read `~/.ai-tools/MEMORY.md` and `~/.ai-tools/agent-memory.md` only when deciding whether or where to persist a learning.
- Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing git operations.
- Prefer clear names and simple structure. Comments should explain why, not what.
- Keep designs modular where change is likely, without overengineering speculative needs.
- For JavaScript or TypeScript changes, run the relevant typecheck, lint, formatting, and tests. Use Biome when the project configures it.
- Prefer Bun when the project supports it; otherwise use the project's configured runtime and package manager.

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Load the shell integration in the shell that runs your commands: `eval "$(try init)"` for bash/zsh. Without it, `try` only prints shell commands. If the wrapper cannot run (for example, no `/dev/tty`), use the fallbacks below.
- Run `try . <name>` from the repository root for a worktree, or `try clone <url> [name]` for an external repository. Confirm that the new directory is a worktree or clone before editing; `try` can hide worktree creation failures. For a PR clone, also verify that HEAD matches the requested PR revision; a failed fetch can leave the default branch checked out. If creation fails, diagnose it and use the fallback with a new path.
- For a fresh experiment, run `try <name>` and press Ctrl-T in the interactive selector to create a directory; selecting an existing match does not create one. `try new <name>` is a search, not a creation subcommand. Without a terminal, create a new date-prefixed directory under `${TRY_PATH:-$HOME/src/tries}` with `mkdir` instead; choose an unused path.
- Worktrees and fresh experiments use date-prefixed names under `$TRY_PATH` (default: `~/src/tries`). A clone with a custom name uses that name without a date prefix; an unnamed clone uses `YYYY-MM-DD-<user>-<repo>`. Use the printed path in later commands; directory changes apply only to the invoking shell.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments under the tries directory instead of ad hoc `/tmp` folders. When `try` is unavailable or unsuitable, use `git worktree add -b <branch> <path>` for a repository with a commit, `git clone <url> <path>` for an external repository, or `mkdir` for a fresh experiment.
