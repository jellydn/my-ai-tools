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
- `-y` / `--yes` — non-interactive; only processes your active tools. Auto-activated in CI/piped input. Triggers network installs of ~20 external CLIs before the core config copy.
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
- **New installers**: register in the ordered `INSTALL_SEQUENCE` table in `cli.sh` (`"<allowlist-key>:<installer>"`, or `always:` for cross-tool dependencies). The `-y` allowlist matches the `<allowlist-key>` portion. Do not add another `if tool_allowed` block.
- **PATH**: never `export PATH=` directly — call `ensure_dir_on_path "<dir>"` (defined in `lib/install.sh`).
- **Dry-run**: wrap every side-effecting command in `execute()` / `execute_quoted()` (defined in `lib/common.sh`). Never run destructive commands directly.
- Paths: use `$HOME` / relative. **No absolute paths** in configs or scripts.
- Quote all variables, use `local`, and use `log_info`/`log_success`/`log_warning`/`log_error` for output.

## Key Gotchas

- `cli.sh` auto-detects installed tools and skips missing ones — it won't install configs for tools you don't have.
- `generate.sh` exports _from_ `$HOME` _to_ the repo; it only copies tools it finds installed.
- `--yes` in CI/non-TTY shells triggers network installs of ~20 external CLIs that can fail/hang. To exercise core config copy deterministically, source the script and call its copy functions against a throwaway `HOME`:
  ```bash
  H=$(mktemp -d); mkdir -p "$H/.cursor" "$H/.config/opencode" "$H/.codex"
  ( export HOME="$H" DRY_RUN=false YES_TO_ALL=false; source ./cli.sh; copy_configurations )
  find "$H" -type f   # verify configs landed
  ```
  `copy_claude_configs` always runs; other tools only copy when detected. Do NOT run copy functions with `set -u` — `lib/common.sh` references optional vars like `MSYSTEM`.
- MCP servers come from the central registry `configs/mcp-registry.json`. Prefer it over the legacy fallback.
- Configs are validated with `jq` before install; failures warn but don't block (unless you decline the prompt).
- `safe_copy_dir()` (lib/common.sh) auto-excludes `node_modules`, `cache`, `*.sqlite`, etc.
- The `## Token Efficiency` section in `configs/**/AGENTS.md` and `configs/**/GEMINI.md` is generated from `configs/token-efficiency.md`. Edit the canonical file and run `./scripts/sync-token-efficiency.sh` — the profiles stay standalone on purpose, since eager `@file.md` imports cost tokens every session.
- Backups go to `$HOME/ai-tools-backup-{timestamp}`; last 5 are kept.
- Gemini CLI is deprecated for Google One/unpaid tiers (June 18, 2026 cutoff). Migrate to Antigravity CLI.

## Git Safety

- Prefer `git add <specific-files>` over `git add -A`.
- Never force-push, rewrite history, or run destructive resets without explicit approval. See `configs/git-guidelines.md`.
