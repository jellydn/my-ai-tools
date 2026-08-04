# Coding Conventions

**Analysis Date:** 2026-08-04

## Naming Patterns

**Files:**
- TypeScript uses descriptive lowercase names with hyphens where needed (`openai-client.ts`, `github-bot.test.ts`).
- Shell scripts use lowercase names and `.sh`; BATS tests use area-oriented names such as `pr_fusion.bats`.
- Python tests use `test_<subject>.py`; tool configs use native filenames.

**Functions:**
- TypeScript functions use `camelCase` (`createOpenAIClient`, `parseRepoConfig`, `inspectDiff`).
- Shell functions use `snake_case` (`copy_configurations`, `execute_quoted`, `safe_copy_dir`).
- Python follows standard `snake_case`.

**Variables:**
- TypeScript local variables and parameters use `camelCase`; constants use descriptive `UPPER_SNAKE_CASE` where module-wide.
- Shell variables are uppercase for exported/environment values and lowercase `local` variables inside functions.
- Configuration keys follow the native client’s naming conventions.

**Types:**
- TypeScript interfaces/types use `PascalCase` (`BotConfig`, `RepoConfig`, `Job`, `ReviewFinding`).
- Zod schemas are lower camel-case values with inferred exported types where useful.
- Domain unions and literal tuples are preferred for constrained bot commands/states.

## Code Style

**Formatting:**
- Biome is configured in `biome.json` for JavaScript/TypeScript/JSON-family files: tabs, 120-column width, and double quotes.
- Shell formatting follows the repository’s existing tab/quoting style and is checked primarily through syntax/BATS/pre-commit workflows.
- YAML uses spaces and standard GitHub Actions formatting.

**Linting:**
- Biome formatting/checking is enabled, but the Biome linter is disabled in `biome.json`; do not assume lint rules catch semantic issues.
- Shell correctness is protected by `bash -n`, BATS tests, and explicit repository instructions in `AGENTS.md`.
- Python style is conventional but is not governed by a root-level Python formatter configuration.

## Import Organization

**Order:**
1. Node/Bun built-ins (`node:fs`, `node:path`, `node:crypto`).
2. External packages (`hono`, `openai`, `zod`, `yaml`).
3. Relative project modules.
4. Type-only imports are marked with `import type` where appropriate.

**Path Aliases:**
- No TypeScript path aliases are used; relative imports include explicit `.ts` extensions in the Bun application.
- Shell paths use `$HOME` or repository-relative paths; absolute paths are discouraged in managed configs.

## Error Handling

**Patterns:**
- Throw `Error` (often with a code/status property) for unrecoverable TypeScript boundary failures (`lib/openai-client.ts`, `src/github-bot/github.ts`).
- Validate external/user input before work: Zod schemas in `server.ts` and `src/github-bot/config.ts`, command allowlists in `security.ts`, and diff/secret checks in `workspace.ts`.
- Async entry scripts terminate through `main().catch(...)` and non-zero exit (`scripts/index-repo.ts`, `scripts/index-browser.ts`).
- GitHub worker failures are recorded in durable job history and reported to the issue/PR when possible (`src/github-bot/worker.ts`).
- Shell entry points source the Bash guard before `set -e`; side effects use `execute()`/`execute_quoted()` for dry-run and quoting support.

## Logging

**Framework:** Console output for server/indexing; structured JSON logger for the GitHub bot; named shell logging helpers (`log_info`, `log_success`, `log_warning`, `log_error`).

**Patterns:**
- Log useful operational state but redact secrets before structured output (`src/github-bot/security.ts`).
- Shell output should use the shared helpers rather than ad hoc `echo` for status messages.
- Errors should include enough context to diagnose the failed boundary without exposing keys/tokens.

## Comments

**When to Comment:**
- Explain non-obvious safety constraints, generated sections, deployment workarounds, or compatibility decisions.
- Keep comments close to the guarded behavior; avoid narrating obvious code.
- Managed/generated regions in config files are marked and should not be hand-edited outside their owning sync workflow.

**JSDoc/TSDoc:**
- Lightweight comments are used for exported security/runtime contracts and tricky algorithms; broad documentation is kept in `docs/`, `README.md`, and skill files.
- Every significant finding in generated planning docs should cite a concrete repository path.

## Function Design

**Size:** Keep functions focused on one operation; large orchestrators remain in `server.ts`, `cli.sh`, `generate.sh`, and `src/github-bot/worker.ts` because they coordinate workflows.

**Parameters:** Prefer typed objects/config interfaces for multi-value TypeScript operations; use explicit `AbortSignal` parameters for cancellable GitHub/agent work. Shell functions use positional parameters with `local` declarations.

**Return Values:** Use explicit typed results, discriminated unions, or `undefined` for optional lookups. Preserve status/error metadata across API and worker boundaries.

## Module Design

**Exports:** Export focused functions/classes/interfaces from domain modules; compose them at `server.ts` or `src/github-bot/app.ts` rather than hiding all behavior in one file.

**Barrel Files:** No broad barrel-file convention; imports generally target the implementation module directly.

**Shell modules:** Shared operations live in `lib/`; entry points source helpers rather than duplicating command wrappers.

---

*Convention analysis: 2026-08-04*