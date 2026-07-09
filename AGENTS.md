# Agent Instructions

## What This Is

Monorepo for **my-ai-tools** — source-of-truth configs for 14+ AI coding assistants (Claude Code, OpenCode, Amp, Codex, Gemini, Antigravity, Cursor, Cline, etc.). It exports configs to `~/.claude/`, `~/.config/opencode/`, `~/.pi/`, etc. and imports them back via `generate.sh`. Per-tool configs live in `configs/<tool>/`.

## Essential Commands

```bash
bash -n cli.sh generate.sh          # Syntax-validate shell scripts (CI runs this)
./cli.sh --dry-run                  # Preview install plan (run this FIRST)
./cli.sh                            # Install configs into $HOME
./generate.sh --dry-run             # Preview export
./generate.sh                       # Export local configs from $HOME back to repo
biome check .                       # Format check (tabs, 120 width, double quotes)
biome check --write .               # Format in place
bats tests/                         # Run all functional tests locally
bats tests/cli.bats                 # Run a single test file
```

## Workflow

```bash
./cli.sh --dry-run  →  git diff  →  ./cli.sh  →  git diff  →  commit
```

Never run `./cli.sh` without `--dry-run` first. Config validation runs automatically and warns on failures.

## Testing — read this carefully

- CI only runs a **subset**: `bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats`. Running `bats tests/` locally runs many more files (skill/tool-specific tests) that CI does NOT execute — don't assume CI covers them.
- `bats` is required (`brew install bats-core`). On the cloud VM it is preinstalled — run `bats tests/` directly.
- `bash -n cli.sh generate.sh` is the cheapest check and is what CI gates on first.
- `biome check .` and `configs/claude/hooks` typecheck report pre-existing formatting/`tsconfig` deviations (tsconfig omits node/dom libs). These are repo-state issues, not environment failures.
- `pre-commit run --all-files` runs: trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files, oxfmt.

### macOS host: run bats via microsandbox

macOS `getcwd`/directory issues can break `bats` on the host. Use a read-only sandbox:

```bash
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats && cd /project && bats tests/'
```

## Shell Script Conventions (enforced in cli.sh, generate.sh, lib/)

- **Re-exec guard**: every entry point sources `lib/require_bash.sh` _before_ `lib/common.sh`. `common.sh` uses bash-only syntax (`<()`, arrays, `${var//pat/repl}`) that crashes under `sh`/`dash`.
- `set -e` goes _after_ the re-exec guard.
- **Dry-run**: wrap every side-effecting command in `execute()` / `execute_quoted()` (defined in `lib/common.sh`). Never run destructive commands directly.
- Paths: use `$HOME` / relative. **No absolute paths** in configs or scripts.
- Quote all variables, use `local`, and use `log_info`/`log_success`/`log_warning`/`log_error` for output.

## Key Gotchas

- `cli.sh` auto-detects installed tools and skips missing ones — it won't install configs for tools you don't have.
- `generate.sh` exports _from_ `$HOME` _to_ the repo; it only copies tools it finds installed.
- MCP servers come from the central registry `configs/mcp-registry.json`. Prefer it over the legacy fallback.
- Configs are validated with `jq` before install; failures warn but don't block (unless you decline the prompt).
- `safe_copy_dir()` (lib/common.sh) auto-excludes `node_modules`, `cache`, `*.sqlite`, etc.
- Backups go to `$HOME/ai-tools-backup-{timestamp}`; last 5 are kept.
- Gemini CLI is deprecated for Google One/unpaid tiers (June 18, 2026 cutoff). Migrate to Antigravity CLI.

## Git Safety

- Prefer `git add <specific-files>` over `git add -A`.
- Never force-push, rewrite history, or run destructive resets without explicit approval. See `configs/git-guidelines.md`.

## Cursor Cloud specific instructions

This is a Bash CLI tool, not a server — verify by invoking commands and checking exit codes / output. The VM has `bash`, `git`, `jq`, `node`, `bun`, `bats` preinstalled.

- **Ignore the microsandbox guidance above** on the cloud VM — run `bats tests/` directly.
- `./cli.sh` / `./generate.sh` mutate `$HOME`. In a non-TTY/CI shell, `cli.sh` auto-enables `--yes`, which tries to network-install ~20 external CLIs (many fail/hang without network) _before_ the core config copy at the end. To exercise the core sync deterministically, source the script and call its copy functions against a throwaway `HOME`, like the bats tests do:
  ```bash
  H=$(mktemp -d); mkdir -p "$H/.cursor" "$H/.config/opencode" "$H/.codex"
  ( export HOME="$H" DRY_RUN=false YES_TO_ALL=false; source ./cli.sh; copy_configurations )
  find "$H" -type f   # verify configs landed
  ```
  `copy_claude_configs` always runs; other tools only copy when detected. Do NOT run copy functions with `set -u` — `lib/common.sh` references optional vars like `MSYSTEM`.
- Use `./cli.sh --dry-run` for a full, side-effect-free preview.
