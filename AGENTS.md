# Agent Instructions

## What This Is

Monorepo for **my-ai-tools** — configuration management for 14+ AI coding assistants (Claude Code, OpenCode, Amp, CCS, Gemini CLI, Antigravity CLI, Pi, Codex CLI, Kilo CLI, Kimi Code, CommandCode, Cursor, Factory Droid, Cline, Grok CLI). Exports configs to `~/.claude/`, `~/.config/opencode/`, `~/.pi/`, etc.

## Essential Commands

Use microsandbox when testing or working with shell scripts.

```bash
# Validate shell scripts (CI and local)
bash -n cli.sh generate.sh

# Preview changes, then apply
./cli.sh --dry-run          # Preview install
./cli.sh                    # Install to home

# Export local configs back to repo
./generate.sh --dry-run     # Preview export
./generate.sh               # Export

# Code quality
biome check .               # Check formatting
biome check --write .       # Format in-place
bats tests/                 # Run functional tests
bats tests/cli.bats         # Run a single test file
```

## Workflow

```bash
./cli.sh --dry-run  →  git diff  →  ./cli.sh  →  git diff  →  commit
```

Never run `./cli.sh` without `--dry-run` first. Config validation runs automatically and warns on failures.

## Shell Script Conventions

These are enforced across `cli.sh`, `generate.sh`, and `lib/`:

- **Re-exec guard**: Every entry-point script must `source lib/require_bash.sh` before `lib/common.sh`. This is non-negotiable — `lib/common.sh` uses bash-only syntax that crashes under `sh`/`dash`.
- **Error handling**: `set -e` goes _after_ the re-exec guard.
- **Dry-run**: Use `execute()` or `execute_quoted()` wrapper for any side-effecting command. Never run destructive commands directly.
- **Paths**: Use `$HOME`, relative paths. **No absolute paths** in configs or scripts.
- **Quoting**: Always quote variables: `"$variable"`.
- **Locals**: Use `local` for function-scoped variables.
- **Colors/logging**: Use `log_info`, `log_success`, `log_warning`, `log_error` from `lib/common.sh`.

## Testing

- `bash -n cli.sh generate.sh` — syntax validation (CI runs this)
- `bats tests/` — functional tests (requires `bats-core`: `brew install bats-core`)
- `biome check .` — TS/JS/JSON formatting (tabs, 120 line width, double quotes)
- `pre-commit run --all-files` — trailing whitespace, YAML check, oxfmt

### Running bats tests in microsandbox

Use microsandbox to avoid macOS `getcwd` / directory-access issues that can break `bats` on the host:

```bash
# Run all tests
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats && cd /project && bats tests/'

# Run a single test file
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats && cd /project && bats tests/pr_codiff.bats'

# Run syntax validation only (no bats install needed)
msb run -m 256M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'cd /project && bash -n cli.sh generate.sh lib/install.sh'
```

The `:ro` mount flag keeps the project read-only inside the sandbox, preventing accidental writes.
The sandbox is ephemeral (no `--name` flag) — it's destroyed automatically after the command exits.

## Prerequisites

- Bash 3.0+ (scripts use process substitution, arrays, `${var//pat/repl}`)
- Git
- Bun (preferred) or Node.js
- `jq` for JSON parsing

## Directory Structure

```text
cli.sh, generate.sh              # Entry points
lib/common.sh                    # Shared utilities (execute(), logging, validation)
lib/require_bash.sh              # Re-exec guard for sh/dash
lib/install.sh                   # Installation helpers
configs/<tool>/                  # Source configs per tool
  claude/, opencode/, amp/, codex/, gemini/, etc.
configs/mcp-registry.json        # Central MCP server registry
configs/best-practices.md        # Exported to ~/.ai-tools/
configs/git-guidelines.md        # Git safety rules
skills/                          # Local marketplace plugins
wiki/                            # LLM Wiki — persistent, compounding knowledge base
tests/                           # BATS functional tests
```

## Key Gotchas

- `cli.sh` auto-detects installed tools and skips missing ones. It won't install configs for tools you don't have.
- `generate.sh` exports _from_ your home directory _to_ the repo. Only copies configs for tools it finds installed.
- MCP server installation uses a central registry (`configs/mcp-registry.json`). Legacy fallback exists but prefer registry.
- Config files are validated with `jq` before install. Failures warn but don't block (unless you say no to the prompt).
- `safe_copy_dir()` excludes `node_modules`, `cache`, `*.sqlite`, and other runtime dirs automatically.
- Backup location: `$HOME/ai-tools-backup-{timestamp}`. Auto-cleanup keeps last 5.
- Gemini CLI is deprecated for Google One/unpaid tiers (June 18, 2026 cutoff). Migrate to Antigravity CLI.

## Working with Advanced Models

See `configs/fable-guide.md` for comprehensive guidance on:
- **Capability Overhang**: Understanding what's newly possible
- **Finding Unknowns**: Discovery techniques before implementation
- **Context over Constraints**: Positive guidance patterns
- **Being Unreasonable**: Challenging false tradeoffs

Key skills for discovery-first development:
- `skills/blindspot-pass/` - Find unknown unknowns before starting
- `skills/context-discovery/` - Proactively gather context using MCP tools
- `skills/git-context/` - Search git history for patterns and decisions
- `skills/doc-search/` - Find ADRs, wiki entries, and project documentation
- `skills/spec-interview/` - Clarify requirements through targeted questions
- `skills/implementation-logger/` - Track decisions and deviations
- `skills/quiz-me/` - Verify understanding after implementation

## Learning Recording

After fixing a bug (confirmed by human), introducing a new tech choice, or encountering something important, ask the user:

> "Would you like me to record this as a learning?"

If yes, decide which lane (see `~/.ai-tools/MEMORY.md`):
- **qmd** (durable) — project-specific gotchas, architecture decisions, conventions
- **agentmemory** (session) — transient context only the current session needs

Read `@~/.ai-tools/agent-memory.md` and `@~/.ai-tools/MEMORY.md` for the full decision rule.

## Git Safety

- Prefer `git add <specific-files>` over `git add -A`
- Never force push, rewrite history, or run destructive resets without explicit approval
- See `configs/git-guidelines.md` for full rules

## Cursor Cloud specific instructions

This is a Bash CLI tool, not a long-running server — there is nothing to keep running. You verify it by invoking commands and checking exit codes / file output. The Linux VM already has `bash`, `git`, `jq`, `node`, `bun`, and `bats` provisioned (bun is on PATH via `~/.bashrc`; the update script refreshes `configs/claude/hooks` deps).

- **Ignore the microsandbox (`msb`) guidance above** on the cloud VM — it only exists to dodge macOS `getcwd`/directory issues. Run `bats tests/` directly.
- **Tests / lint / typecheck** — see the `## Testing` section above for the canonical commands (`bash -n cli.sh generate.sh`, `bats tests/`, `biome check .` via `npx @biomejs/biome`, and `bun run typecheck` in `configs/claude/hooks`).
  - `biome check .` and the hooks `typecheck` report pre-existing formatting/`tsconfig` deviations (the tsconfig omits node/dom lib types); these are repo-state issues, not environment failures. The toolchains themselves run fine.
- **Running the app safely** — `./cli.sh` / `./generate.sh` mutate `$HOME`. In a non-TTY/CI shell `cli.sh` auto-enables `--yes`, which tries to network-install ~20 external CLIs (many will fail/hang without network) *before* the core config copy at the very end. To exercise the core config-sync deterministically without that noise, source the script and call its copy functions against a throwaway `HOME`, exactly like the bats tests do:
  ```bash
  H=$(mktemp -d); mkdir -p "$H/.cursor" "$H/.config/opencode" "$H/.codex"
  ( export HOME="$H" DRY_RUN=false YES_TO_ALL=false; source ./cli.sh; copy_configurations )
  find "$H" -type f   # verify configs landed in the sandbox home
  ```
  `copy_claude_configs` always runs; other tools only copy when detected (their CLI is on PATH or their config dir exists — hence pre-creating dirs above). Do NOT run the copy functions with `set -u`; `lib/common.sh` references optional vars like `MSYSTEM`.
- Use `./cli.sh --dry-run` for a full, side-effect-free preview of the install plan.
