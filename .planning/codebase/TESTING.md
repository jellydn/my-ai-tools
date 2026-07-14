# Testing Patterns

**Analysis Date:** 2026-07-14

## Test Framework

**Runner:**
- **BATS** (Bash Automated Testing System) for shell/config validation — system package (`bats-core` / `apt-get install bats`)
- **Bun test** for TypeScript unit tests (`bun:test`)

**Assertion Library:**
- BATS: built-in `run`, `[ "$status" -eq 0 ]`, `[[ "$output" == *"..."* ]]`, `grep` / `jq` in tests
- Bun: `describe`, `test`, `expect` from `bun:test`

**Run Commands:**
```bash
bash -n cli.sh generate.sh     # Shell syntax (cheap CI gate)
bats tests/                    # All BATS tests locally
bats tests/cli.bats            # Single BATS file
bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats   # CI subset
bun run typecheck              # TypeScript strict check
bunx biome check lib/code-taste lib/vector-similarity.ts lib/retriever.ts scripts/code-taste.ts tests/code-taste.test.ts
bun test tests/code-taste.test.ts   # or: bun run test:code-taste
pre-commit run --all-files     # Hooks (whitespace, yaml, oxfmt, etc.)
biome check .                  # Format check repo-wide
```

## Test File Organization

**Location:**
- BATS: dedicated `tests/` directory at repo root (not co-located with shell sources)
- TypeScript: `tests/code-taste.test.ts` alongside `lib/code-taste/` implementation

**Naming:**
- `*.bats` for shell tests; `pr_<feature>.bats` for config contract tests per tool/PR
- `*.test.ts` for Bun unit tests

**Structure:**
```text
tests/
  helpers.bash          # REPO_ROOT, require_jq, shared helpers
  cli.bats              # cli.sh / install behaviors
  lib_common.bats       # execute, validate_json, backups
  generate.bats
  sh_reexec.bats        # require_bash.sh POSIX + re-exec
  pr_*.bats             # JSON/config invariants per tool
  code-taste.test.ts    # chunking / profile logic
```

## Test Structure

**Suite Organization:**
```bash
#!/usr/bin/env bats

load helpers

setup() {
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    export DRY_RUN=false
}

@test "configs/claude/settings.json is valid JSON" {
    require_jq
    run jq empty "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
}
```

```typescript
import { describe, expect, test } from "bun:test";

describe("semantic chunking", () => {
	test("keeps TypeScript declarations intact", async () => {
		const chunks = await chunkTypeScript(/* ... */);
		expect(chunks.map((chunk) => chunk.symbol)).toEqual(["Options", "run"]);
	});
});
```

**Patterns:**
- **Setup:** `setup()` sources libs and sets `DRY_RUN`, `SCRIPT_DIR`, or isolated `HOME` for copy tests (`AGENTS.md` pattern)
- **Teardown:** `rm -rf` temp dirs in-test; BATS runs each test in subprocess
- **Assertion:** BATS `run` captures status/output; strip ANSI in some tests with `sed` when matching log text

## Mocking

**Framework:** Manual stubs in TypeScript (`mockAnalysisClient` in `tests/code-taste.test.ts`); shell tests mock environment (`PATH` without `jq`, temp `HOME`, `DRY_RUN=true`)

**Patterns:**
```typescript
function mockAnalysisClient(content: string): AnalysisClient {
	return {
		embeddings: { create: async (request) => ({ /* fixed vectors */ }) },
		chat: { completions: { create: async () => ({ choices: [{ message: { content } }] }) } },
	};
}
```

**What to Mock:**
- External APIs (OpenAI embeddings/chat) in code-taste tests
- Filesystem layout under `mktemp` / fixture dirs for `copy_configurations`
- `command -v` behavior via `PATH` manipulation for missing-tool cases

**What NOT to Mock:**
- `jq` validation when installed — prefer real `jq empty` on committed JSON configs
- `lib/require_bash.sh` behavior — tested with real `sh -n` and static grep assertions

## Fixtures and Factories

**Test Data:**
- Inline strings for markdown/TypeScript chunk fixtures in `code-taste.test.ts`
- Ephemeral dirs: `/tmp/test-backup-$$`, `mktemp -d` for install/copy tests
- `tests/fixtures/` referenced in some `cli.bats` cases (created in-test)

**Location:**
- No large shared fixture tree; config truth is `configs/` validated by `pr_*.bats`

## Coverage

**Requirements:** None enforced in CI (no coverage threshold in workflows)

**View Coverage:**
```bash
# Not configured — add bun coverage flags locally if needed
bun test tests/code-taste.test.ts
```

## Test Types

**Unit Tests:**
- `lib_common.bats`, `sh_reexec.bats`: isolated shell helpers and guard
- `code-taste.test.ts`: chunker, profile selection, GitHub file selection with mocked client

**Integration Tests:**
- `cli.bats`, `install.bats`, `generate.bats`: source real scripts, exercise copy/backup/preflight with temp HOME
- `pr_*.bats`: integration with committed config files + `jq` schema checks

**E2E Tests:**
- Not used; no browser/server E2E in CI (`server.ts` dev is manual)

## CI (GitHub Actions)

**Workflow:** `.github/workflows/test.yml`

- **bats job:** `bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats` on `ubuntu-latest` with `jq` + `bats`
- **code-taste job:** `bun install --frozen-lockfile`, `bun run typecheck`, scoped `biome check`, `bun test tests/code-taste.test.ts`

Local `bats tests/` runs **more** files than CI (e.g. `cli.bats`, `install.bats`, skill-specific tests) — do not assume CI runs full suite (`AGENTS.md`).

## Common Patterns

**Async Testing:**
```typescript
test("keeps TypeScript declarations intact", async () => {
	const chunks = await chunkTypeScript("owner/repo", "src/example.ts", source);
	expect(chunks[1]?.text).toContain("interface Options");
});
```

**Error Testing:**
```bash
@test "preflight_check fails on missing jq" {
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/jq' | tr '\n' ':')
    run preflight_check
    [ "$status" -ne 0 ]
}
```

**Skip when tool missing:**
```bash
require_jq() {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
}
```

**macOS note:** Host BATS may fail on directory issues; use microsandbox per `AGENTS.md` — cloud VM runs `bats tests/` directly.

---

*Testing analysis: 2026-07-14*
