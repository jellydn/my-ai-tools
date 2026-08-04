# Codebase Structure

**Analysis Date:** 2026-08-04

## Directory Layout

```text
my-ai-tools/
├── cli.sh, generate.sh, install.sh, install.ps1  # Config install/export entry points
├── server.ts, index.html, public/                # Bun/Hono web application
├── lib/                                          # Shared TypeScript retrieval and shell libraries
├── scripts/                                      # Indexing and repository automation scripts
├── src/github-bot/                               # GitHub coding bot service
├── document_qa/                                  # Standalone Python document-QA app
├── configs/                                      # Tool-specific configs, hooks, agents, plugins
├── skills/                                       # Reusable agent skill definitions
├── tests/                                        # BATS and TypeScript tests
├── docs/, wiki/                                  # User/developer documentation and knowledge base
├── .github/workflows/                            # Test, Pages, and Dokku workflows
├── Dockerfile, .dockerignore                     # Container build/runtime
├── package.json, bun.lock, package-lock.json     # JS/Bun dependency metadata
└── .planning/codebase/                           # This generated codebase map
```

## Directory Purposes

**`lib/`:**
- Purpose: Shared application and shell helpers.
- Contains: `indexer.ts`, `retriever.ts`, `openai-client.ts`, `common.sh`, `install.sh`, `install-deps.sh`, and `require_bash.sh`.
- Key files: `lib/indexer.ts`, `lib/retriever.ts`, `lib/common.sh`.

**`src/github-bot/`:**
- Purpose: GitHub App webhook, queue, agent, workspace, security, and publication logic.
- Contains: `app.ts`, `worker.ts`, `agent.ts`, `github.ts`, `commands.ts`, `config.ts`, `security.ts`, `store.ts`, `workspace.ts`, `review.ts`, `types.ts`, and `github-bot.test.ts`.

**`document_qa/`:**
- Purpose: Separate local Python application for uploading documents and asking citation-aware questions.
- Contains: FastAPI API, Streamlit UI, loaders/chunkers, embeddings, retrieval/vector store, requirements, README, and Python tests.

**`configs/`:**
- Purpose: Source-of-truth configurations for supported AI coding clients.
- Contains: tool directories such as `claude/`, `codex/`, `pi/`, `amp/`, `kiro/`, `reasonix/`, `factory/`, and central registries/guidelines.
- Key files: `configs/mcp-registry.json`, `configs/token-efficiency.md`, per-tool `AGENTS.md`/settings/agent/plugin files.

**`skills/`:**
- Purpose: Reusable agent instructions and automation packages.
- Contains: one directory per skill with `SKILL.md` and optional templates/scripts.
- Key files: `skills/codemap/SKILL.md`, `skills/docs-update/SKILL.md`, `skills/orchestrating-fusion/SKILL.md`.

**`tests/`:**
- Purpose: Shell/config validation and integration-style checks.
- Contains: `tests/pr_*.bats`, core BATS suites, fixtures/helpers, and `fusion-watchdog.test.ts`.

**`docs/` and `wiki/`:**
- Purpose: Human-facing deployment/feature docs and generated/curated knowledge content.
- Key files: `docs/dokku-deploy.md`, `docs/fusion-orchestration.md`, `docs/TESTING.md` references, and wiki source/entity material.

**`.github/`:**
- Purpose: CI/CD workflow definitions and GitHub bot example configuration.
- Key files: `.github/workflows/test.yml`, `.github/workflows/dokku.yml`, `.github/workflows/deploy-pages.yml`, `.github/my-ai-bot.example.yml`.

## Key File Locations

**Entry Points:**
- `server.ts`: main Hono/Bun server.
- `cli.sh`: install repository configurations into `$HOME`.
- `generate.sh`: export user configurations into the repository.
- `install.sh` / `install.ps1`: bootstrap installers.
- `document_qa/api.py`: standalone FastAPI API.

**Configuration:**
- `package.json`, `bun.lock`, `package-lock.json`: JavaScript dependencies/scripts.
- `.env.example`: runtime configuration contract.
- `tsconfig.json`, `biome.json`: TypeScript and formatting configuration.
- `Dockerfile`: production build/runtime contract.
- `configs/mcp-registry.json`: shared MCP registry.

**Core Logic:**
- `lib/indexer.ts` and `lib/retriever.ts`: repository knowledge pipeline.
- `src/github-bot/worker.ts`: bot workflow orchestration.
- `src/github-bot/workspace.ts` and `security.ts`: execution/publication boundaries.
- `lib/common.sh`: shared shell operations and safety wrappers.

**Testing:**
- `tests/*.bats`: shell/config behavior and structural tests.
- `tests/fusion-watchdog.test.ts`: Bun watchdog tests.
- `src/github-bot/github-bot.test.ts`: GitHub bot unit/integration tests.
- `document_qa/tests/`: Python document-QA tests.

## Naming Conventions

**Files:**
- TypeScript modules use kebab-free descriptive names such as `openai-client.ts`, `fusion-watchdog.ts`, and `github-bot.test.ts`.
- Shell entry points and helpers use lowercase names with `.sh`.
- BATS files use `<area>.bats`; Python tests use `test_<area>.py`; skill docs use `SKILL.md`.
- Tool configurations retain the native client’s expected names (`settings.json`, `config.toml`, `mcp.json`).

**Directories:**
- Domain/application modules use lowercase directories (`lib`, `src/github-bot`, `document_qa`, `scripts`).
- Tool config directories use the tool/client name (`configs/<tool>`).
- Skills are grouped under `skills/<skill-name>`.

## Where to Add New Code

**New feature in the Bun web app:**
- Primary code: `server.ts` for route composition; a focused module under `lib/` or `src/` for logic.
- Tests: co-located `*.test.ts` for TypeScript logic, plus a BATS test only if configuration/CLI behavior changes.

**New GitHub bot capability:**
- Implementation: `src/github-bot/worker.ts` and the nearest focused module (`commands.ts`, `github.ts`, `workspace.ts`, `review.ts`, or `config.ts`).
- Tests: extend `src/github-bot/github-bot.test.ts` unless a new module warrants a focused test file.
- Policy/config: update `.github/my-ai-bot.example.yml` and `docs/my-ai-bot.md` when user-facing.

**New configuration/tool support:**
- Config: `configs/<tool>/` using the target tool’s native format.
- Installer/export integration: `cli.sh`, `generate.sh`, and `lib/install*.sh` according to `AGENTS.md`.
- Tests: `tests/pr_<tool>.bats` or the nearest existing suite.

**New document-QA capability:**
- Implementation: focused module under `document_qa/`.
- Tests: `document_qa/tests/test_<area>.py`.

**Utilities:**
- Shared TypeScript utility: `lib/` or the nearest domain module.
- Shared shell helper: `lib/common.sh`, keeping modules below the repository’s size boundary.

## Special Directories

**`data/` and generated indexes:**
- Purpose: runtime/generated retrieval artifacts.
- Generated: Yes.
- Committed: Usually no; inspect `.gitignore` before adding artifacts.

**`.planning/codebase/`:**
- Purpose: generated architectural map for onboarding/planning.
- Generated: Yes, by `skills/codemap/SKILL.md`.
- Committed: Yes in the current repository; refreshes should be reviewed as documentation changes.

**`.freebuff/`:**
- Purpose: local desktop/session state.
- Generated: Yes.
- Committed: No; preserve as local state and do not include in feature commits.

**`configs/` and `skills/`:**
- Purpose: managed source-of-truth content.
- Generated: Some exports are generated from user-local tool state; verify the owning sync path before hand-editing.
- Committed: Yes, except runtime artifacts excluded by repository rules.

---

*Structure analysis: 2026-08-04*