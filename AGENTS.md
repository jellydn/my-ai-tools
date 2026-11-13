# Agent Instructions

## What This Is

Monorepo for **my-ai-tools** — source-of-truth configs for 14+ AI coding assistants (Claude Code, OpenCode, Amp, Codex, Gemini, Antigravity, Cursor, Cline, Grok, etc.). It installs configs to `~/.claude/`, `~/.config/opencode/`, `~/.pi/`, etc. and exports them back via `generate.sh`. Per-tool configs live in `configs/<tool>/`.

## Essential Commands

```bash
bash -n cli.sh generate.sh lib/*.sh lib/install.sh  # Syntax gate (CI runs this)
bash -n cli.sh generate.sh install.sh scripts/*.sh   # CI gates this exact set
./cli.sh --dry-run                                    # Preview install plan — ALWAYS run first
./cli.sh                                              # Install configs into $HOME
./generate.sh --dry-run                               # Preview export
./generate.sh                                         # Export local configs from $HOME back to repo
./scripts/sync-token-efficiency.sh --check            # Verify profiles are in sync (exit 1 if stale)
biome check .                                         # Format check (tabs, 120 width, double quotes)
biome check --write .                                 # Format in place
bats tests/                                           # Run ALL functional tests locally
bats tests/cli.bats                                   # Run a single test file
```

## Workflow

```bash
./cli.sh --dry-run  →  git diff  →  ./cli.sh  →  git diff  →  commit
```

Never run `./cli.sh` without `--dry-run` first. Config validation runs automatically and warns on failures.

## cli.sh Flags

- `--dry-run` — side-effect-free preview
- `--backup` / `--no-backup` — backup existing configs (auto-prompted interactively)
- `-y` / `--yes` — non-interactive; installs Amp, Pi, Codex, OpenCode, Claude, Grok, qmd, rtk, ctx, open-cursor, ai-switcher, open_code_review, and Plannotator, plus shared skills, applicable MCP/plugin config, and declared integration dependencies. ctx installs without history import. Auto-activated in CI/piped input. Other standalone catalog entries remain optional; user-memory stays opt-in.
- `--with-tools=name,...` — opt into extra catalog CLIs such as fx or cursor.
- `--with-integrations` — bundled config, plugins, skills, MCPs, and their prerequisites (default); can replace existing config.
- `--without-integrations` — standalone CLIs only; leaves existing config unchanged.
- `--migrate-gemini` — one-step Gemini→Antigravity CLI migration
- `--rollback` — restore from the most recent `$HOME/ai-tools-backup-{timestamp}`
- `-v` / `--verbose` — verbose logging
- `-h` / `--help` — print usage options and exit

## Testing

- CI runs **only**: `bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats`
- Running `bats tests/` locally executes many more files (skill/tool-specific) that CI does NOT run — don't assume CI coverage is complete.
- `bash -n cli.sh generate.sh` is the cheapest syntax check and is what CI gates on first.
- `biome check .` and `configs/claude/hooks` typecheck report pre-existing formatting/`tsconfig` deviations (tsconfig omits node/dom libs). These are repo-state issues, not environment failures.
- `pre-commit run --all-files` runs: trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files, oxfmt.
- `lib/` modules must stay **under 1000 lines** — `tests/pr_install_deps.bats` enforces it.

### macOS host: run bats via microsandbox

macOS `getcwd`/directory issues can break `bats` on the host. Use a read-only sandbox:

```bash
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats && cd /project && bats tests/'
```

On the cloud VM `bats` is preinstalled — run `bats tests/` directly.

## Shell Script Conventions (enforced in cli.sh, generate.sh, lib/)

- **Re-exec guard**: every entry point sources `lib/require_bash.sh` _before_ `lib/common.sh`. `common.sh` uses bash-only syntax (`<()`, arrays, `${var//pat/repl}`) that crashes under `sh`/`dash`.
- `set -e` goes _after_ the re-exec guard.
- **Installer layout**: per-tool installers live in `lib/install.sh`; prerequisites (runtimes, formatters, MCP binaries) live in `lib/install-deps.sh`, which `lib/install.sh` **must source** (`source "$(dirname "${BASH_SOURCE[0]}")/install-deps.sh"`).
- **New installers**: register in the ordered `INSTALL_SEQUENCE` table in `cli.sh` (`"<allowlist-key>:<installer>"`). The `-y` allowlist matches the `<allowlist-key>` portion; extra tools must be optional. Do not add another `if tool_allowed` block.
- **PATH**: never `export PATH=` directly — call `ensure_dir_on_path "<dir>"` (defined in `lib/install-deps.sh`, sourced by `lib/install.sh`).
- **Dry-run**: wrap every side-effecting command in `execute()` / `execute_quoted()` (defined in `lib/common.sh`). Never run destructive commands directly.
- Paths: use `$HOME` / relative. **No absolute paths** in configs or scripts.
- Quote all variables, use `local`, and use `log_info`/`log_success`/`log_warning`/`log_error` for output.

## Key Gotchas

- `cli.sh` auto-detects installed tools and skips missing ones — it won't install configs for tools you don't have.
- `generate.sh` exports _from_ `$HOME` _to_ the repo; it only copies tools it finds installed.
- `--yes` in CI/non-TTY shells can install the default CLIs (Amp, Pi, Codex, OpenCode, Claude, Grok, qmd, rtk, ctx, open-cursor, ai-switcher, open_code_review, Plannotator) and integration dependencies over the network and copy config/skills. Use `--without-integrations` for standalone CLIs only. To exercise config copy deterministically, source the script and call its copy functions against a throwaway `HOME`:
  ```bash
  H=$(mktemp -d); mkdir -p "$H/.cursor" "$H/.config/opencode" "$H/.codex"
  ( export HOME="$H" DRY_RUN=false YES_TO_ALL=false; source ./cli.sh; copy_configurations )
  find "$H" -type f   # verify configs landed
  ```
  `copy_claude_configs` always runs; other tools only copy when detected. Do NOT run copy functions with `set -u` — `lib/common.sh` references optional vars like `MSYSTEM`.
- MCP servers come from the central registry `configs/mcp-registry.json`. Prefer it over the legacy fallback.
- Configs are validated with `jq` before install; failures warn but don't block (unless you decline the prompt).
- `safe_copy_dir()` (lib/common.sh) auto-excludes `node_modules`, `cache`, `*.sqlite`, etc.
- The `## Token Efficiency` section in `configs/**/AGENTS.md` and `configs/**/GEMINI.md` is generated from `configs/token-efficiency.md`, and the `## Experiment Workspaces` section in those profiles, `configs/claude/CLAUDE.md`, and the root `AGENTS.md`/`GEMINI.md` is generated from `configs/experiment-workspaces.md`. Edit the canonical file and run `./scripts/sync-token-efficiency.sh` — the profiles stay standalone on purpose, since eager `@file.md` imports cost tokens every session.
- Backups go to `$HOME/ai-tools-backup-{timestamp}`; last 5 are kept.
- Gemini CLI is deprecated for Google One/unpaid tiers (June 18, 2026 cutoff). Migrate to Antigravity CLI.

## Git Safety

- Prefer `git add <specific-files>` over `git add -A`.
- Never force-push, rewrite history, or run destructive resets without explicit approval. See `configs/git-guidelines.md`.

## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Load the shell integration in the shell that runs your commands: `eval "$(try init)"` for bash/zsh. Without it, `try` only prints shell commands. If the wrapper cannot run (for example, no `/dev/tty`), use the fallbacks below.
- Run `try . <name>` from the repository root for a worktree, or `try clone <url> [name]` for an external repository. Confirm that the new directory is a worktree or clone before editing; `try` can hide worktree creation failures. For a PR clone, also verify that HEAD matches the requested PR revision; a failed fetch can leave the default branch checked out. If creation fails, diagnose it and use the fallback with a new path.
- For a fresh experiment, run `try <name>` and press Ctrl-T in the interactive selector to create a directory; selecting an existing match does not create one. `try new <name>` is a search, not a creation subcommand. Without a terminal, create a new date-prefixed directory under `${TRY_PATH:-$HOME/src/tries}` with `mkdir` instead; choose an unused path.
- Worktrees and fresh experiments use date-prefixed names under `$TRY_PATH` (default: `~/src/tries`). A clone with a custom name uses that name without a date prefix; an unnamed clone uses `YYYY-MM-DD-<user>-<repo>`. Use the printed path in later commands; directory changes apply only to the invoking shell.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments under the tries directory instead of ad hoc `/tmp` folders. When `try` is unavailable or unsuitable, use `git worktree add -b <branch> <path>` for a repository with a commit, `git clone <url> <path>` for an external repository, or `mkdir` for a fresh experiment.
