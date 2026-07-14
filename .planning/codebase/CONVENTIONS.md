# Coding Conventions

**Analysis Date:** 2026-07-14

## Naming Patterns

**Files:**
- Shell entry points and libraries: `cli.sh`, `generate.sh`, `install.sh`, `lib/common.sh`, `lib/require_bash.sh`, `lib/install.sh`
- BATS tests: `tests/<area>.bats` (e.g. `cli.bats`, `pr_claude.bats`, `sh_reexec.bats`); PR-focused config tests use `pr_<tool>.bats`
- TypeScript: `lib/**/*.ts`, `scripts/*.ts`, `tests/*.test.ts` (e.g. `code-taste.test.ts`)
- Tool configs under `configs/<tool>/` (e.g. `configs/claude/settings.json`)

**Functions:**
- Shell: `snake_case` (`log_info`, `copy_configurations`, `safe_copy_dir`, `execute_quoted`)
- TypeScript: `camelCase` for functions and variables; `PascalCase` for types (`SemanticChunk`, `TasteProfile`)

**Variables:**
- Shell: `UPPER_SNAKE` for exported flags and globals (`DRY_RUN`, `SCRIPT_DIR`, `YES_TO_ALL`, `REPO_ROOT` in tests)
- Shell locals: `local` + `snake_case` inside functions
- TypeScript: `camelCase`; exported types use `type` / `interface` with `PascalCase`

**Types:**
- TypeScript: explicit `export type` / `interface` in `lib/`; strict mode enabled (`tsconfig.json`)

## Code Style

**Formatting:**
- **Biome** (`biome.json`): tabs, indent width 1, line width 120
- JavaScript/TypeScript strings: **double quotes**
- JSON formatted with tabs
- **oxfmt** via pre-commit for TS/JS (with excludes for `lib/code-taste/`, `scripts/code-taste.ts`, `tests/code-taste.test.ts`)

**Linting:**
- Biome linter **disabled** in repo (`"linter": { "enabled": false }`); formatting is the primary automated gate
- TypeScript: `bun run typecheck` (`tsc --noEmit`, strict options)
- Shell: `bash -n cli.sh generate.sh` (and other scripts as needed) before merge

## Import Organization

**Order:**
1. Node built-ins (`node:path`, `node:url`)
2. Third-party packages (`web-tree-sitter`, `hono`, `openai`, etc.)
3. Relative project imports (`../lib/code-taste/...`)

**Path Aliases:**
- No path aliases in `tsconfig.json`; use relative imports with `.ts` extensions (`allowImportingTsExtensions`, `moduleResolution: "bundler"`)

## Error Handling

**Patterns:**
- Shell: `set -e` on entry points **after** `lib/require_bash.sh`; side effects wrapped in `execute()` / `execute_quoted()` for dry-run safety
- Shell failures: `log_error` to stderr; many helpers return non-zero and rely on `set -e` or explicit `[ "$status" -eq 0 ]` in BATS
- TypeScript: `async`/`await` with thrown errors or early returns; tests use `expect(...).toThrow` / status checks where applicable
- Config install: `jq` validation warns; interactive prompts may allow proceed (see `AGENTS.md`)

## Logging

**Framework:** Shell — `log_info`, `log_success`, `log_warning`, `log_error` in `lib/common.sh` (colored `printf` to **stderr**). TypeScript — mostly `console.log` / `console.error` in tooling (e.g. `lib/indexer.ts`).

**Patterns:**
- Do not mix log output with stdout used for data piping in shell
- Dry-run paths log `[DRY RUN]` via `execute` helpers instead of performing mutations

## Comments

**When to Comment:**
- Shell: file headers explain purpose and sourcing order (`require_bash.sh` before `common.sh`); security notes on `eval` in `execute()`
- TypeScript: brief section comments for non-obvious algorithms (e.g. markdown fence handling in chunker tests)

**JSDoc/TSDoc:**
- Light usage; types preferred over heavy doc blocks in `lib/code-taste/`

## Function Design

**Size:** Shell functions grouped by concern in `lib/common.sh` / `lib/install.sh`; CLI orchestration stays in `cli.sh` / `generate.sh`

**Parameters:** Quote all shell variables; use `local` in functions; prefer `execute_quoted` when paths may contain spaces

**Return Values:** Shell: exit codes; BATS asserts `[ "$status" -eq 0 ]`. TypeScript: return values and typed promises

## Module Design

**Exports:** TypeScript uses named `export` of functions and types; `"type": "module"` in `package.json`

**Barrel Files:** No widespread barrel pattern; import concrete modules under `lib/`

## Shell-Specific Conventions

- **Re-exec guard:** Every bash entry point sources `lib/require_bash.sh` **before** `lib/common.sh`
- **Paths:** Use `$HOME` and paths relative to repo; avoid hard-coded absolute paths in configs/scripts (`AGENTS.md`)
- **Dry-run:** `DRY_RUN=true` — never run destructive commands outside `execute` / `execute_quoted`
- **Sourcing vs executing:** `cli.sh` guards CLI parsing with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so tests can `source` functions
- **Git safety:** Prefer `git add <files>`; no force-push without approval (`configs/git-guidelines.md`)

---

*Convention analysis: 2026-07-14*
