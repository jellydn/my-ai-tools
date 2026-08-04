# Testing Patterns

**Analysis Date:** 2026-08-04

## Test Framework

**Runner:**
- **Bun test** — TypeScript tests using Bun’s built-in runner.
- **BATS** — shell and configuration tests.
- **Python test tooling** — tests under `document_qa/tests/`, driven by the Python dependencies/project documentation.
- Config: `package.json`, `tests/`, `src/github-bot/github-bot.test.ts`, `document_qa/tests/`, `.github/workflows/test.yml`.

**Assertion Library:**
- Bun’s `expect` from `bun:test` for TypeScript.
- BATS assertions and shell commands for shell/config tests.
- Python test assertions/framework conventions in `document_qa/tests/`.

**Run Commands:**
```bash
bun test                                      # TypeScript tests
bun run typecheck                             # TypeScript type check
bash -n cli.sh generate.sh lib/*.sh           # Shell syntax validation
bats tests/                                   # Full local BATS suite
bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats  # CI BATS subset
biome check .                                 # Formatting/check validation
pre-commit run --all-files                    # Repository hooks
```

## Test File Organization

**Location:**
- TypeScript tests are co-located with the GitHub bot (`src/github-bot/github-bot.test.ts`) or placed in `tests/` for shared modules (`tests/fusion-watchdog.test.ts`).
- BATS tests are centralized in `tests/`.
- Python tests are in `document_qa/tests/`.

**Naming:**
- TypeScript: `*.test.ts`.
- BATS: `<area>.bats`, with PR-focused suites named `pr_<feature>.bats`.
- Python: `test_<area>.py`.

**Structure:**
```text
tests/*.bats
 tests/fusion-watchdog.test.ts
src/github-bot/github-bot.test.ts
document_qa/tests/test_*.py
```

## Test Structure

**Suite Organization:**
```typescript
import { afterEach, describe, expect, test } from "bun:test";

describe("GitHub bot MVP", () => {
	test("verifies raw webhook HMAC", () => {
		expect(verifyWebhook(raw, signature, "secret")).toBeTrue();
	});
});
```

**Patterns:**
- Tests cover pure parsing/security functions plus filesystem-backed stores/workspaces.
- Temporary directories are created under the OS temp directory and cleaned with `afterEach`/explicit cleanup.
- Async behavior is tested with `await expect(promise).rejects...` and controlled abort signals.
- BATS suites source the target shell modules, set temporary homes/fixtures, and assert output/files/exit status.
- Security tests assert both rejection of dangerous inputs and acceptance of exact configured prefixes.

## Mocking

**Framework:**
- No separate mocking library; Bun tests inject fetcher/client functions and use temporary filesystem fixtures.
- BATS uses shell fixtures, environment overrides, and stub commands where needed.

**Patterns:**
```typescript
const fetcher = async (input: RequestInfo | URL, init?: RequestInit) => {
	requests.push({ method: init?.method ?? "GET", body: init?.body });
	return new Response(JSON.stringify({ ok: true }), { status: 200 });
};
const client = new GitHubClient("secret", fetcher);
```

**What to Mock:**
- GitHub `fetch` calls, timers/abort behavior, external agent execution boundaries, and temporary filesystem state.

**What NOT to Mock:**
- Pure command parsing, HMAC verification, config validation, redaction, diff parsing, and other deterministic security logic.

## Fixtures and Factories

**Test Data:**
```typescript
const config = {
	...defaultRepoConfig,
	validation: { ...defaultRepoConfig.validation, commands: ["bash -n"] },
};
```

**Location:**
- BATS fixtures/helpers: `tests/fixtures/` and `tests/helpers.bash`.
- TypeScript test setup is mostly inline in `src/github-bot/github-bot.test.ts`.
- Python fixtures are in `document_qa/tests/` or constructed per test.

## Coverage

**Requirements:** No numeric repository-wide coverage threshold is enforced. CI covers a deliberate BATS subset; TypeScript/Python test execution is not part of `.github/workflows/test.yml`.

**View Coverage:**
```bash
# No standard coverage script is currently defined.
# Use the relevant runner/tooling manually when investigating a module.
```

## Test Types

**Unit Tests:**
- Pure TypeScript parsing, validation, security, HMAC, retrieval/watchdog logic, and Python chunking/answering/retrieval behavior.

**Integration Tests:**
- GitHub bot store/worker/workspace tests with temporary directories and injected fetchers.
- BATS tests exercise shell functions, generated config layouts, validation, and installer behavior.

**E2E Tests:**
- No browser E2E framework is configured in the current repository. `public/browser-chat.js` and the Hono routes are primarily validated through source/config checks and targeted tests.

## Common Patterns

**Async Testing:**
```typescript
await expect(new GitHubClient("app", fetcher).installationToken(1, undefined, controller.signal)).rejects.toThrow();
```

**Error Testing:**
```typescript
try {
	await operation();
	throw new Error("should have rejected");
} catch (error) {
	expect(error).toBeInstanceOf(ExecutorWaitError);
}
```

**CI boundary:**
- `.github/workflows/test.yml` installs `bats` and `jq` and runs `tests/pr_*.bats`, `tests/generate.bats`, and `tests/sh_reexec.bats`.
- `.github/my-ai-bot.example.yml` documents `bun test` and `bun run typecheck` as repository validation commands for bot changes.

---

*Testing analysis: 2026-08-04*