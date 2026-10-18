# Codebase Concerns

**Analysis Date:** 2026-08-04

## Tech Debt

**Monolithic orchestration scripts:**
- Issue: `cli.sh` and `generate.sh` coordinate many tools and contain large linear dispatch/export sections.
- Files: `cli.sh`, `generate.sh`, `lib/install.sh`, `lib/common.sh`.
- Impact: Changes can have broad blast radius; related install/export behavior is duplicated and difficult to review.
- Fix approach: Extract tool adapters into smaller modules while preserving the ordered `INSTALL_SEQUENCE`, dry-run wrappers, and existing fixture contracts.

**Dual application surfaces:**
- Issue: The repository contains the Bun/Hono service, GitHub bot, and separate Python document-QA application with separate dependency/test ecosystems.
- Files: `server.ts`, `src/github-bot/`, `document_qa/`, `package.json`, `document_qa/requirements.txt`.
- Impact: CI and onboarding must account for multiple runtimes; regressions in one surface can be invisible to the other.
- Fix approach: Add explicit per-surface CI jobs and documented local commands/health checks.

**Generated/configuration drift:**
- Issue: Tool configs are exported from user-local environments and include large managed/generated content.
- Files: `configs/`, `generate.sh`, `cli.sh`, `.planning/codebase/`.
- Impact: Formatting-only or host-specific changes can create noisy diffs and accidentally overwrite unrelated settings.
- Fix approach: Make ownership markers and generated-file policy more explicit; validate round-trip sync in fixtures.

## Known Bugs

**Local dependency/test environment drift:**
- Symptoms: TypeScript tests can fail when dependencies are absent or when the local environment does not match the committed Bun/npm lock state.
- Files: `package.json`, `bun.lock`, `package-lock.json`, `src/github-bot/github-bot.test.ts`.
- Trigger: Running `bun test` without a complete dependency install.
- Workaround: Run the project’s documented dependency setup first and use the lockfile-appropriate package manager.

**Deployment build depends on optional external indexing:**
- Symptoms: Dokku image builds fail if the BuildKit secret, provider key, model, network, or indexing dependency is unavailable.
- Files: `Dockerfile`, `.github/workflows/dokku.yml`, `docs/dokku-deploy.md`, `scripts/index-repo.ts`, `scripts/index-browser.ts`.
- Trigger: `OPENAI_API_KEY` is present and indexing executes during the Docker build.
- Workaround: Fix/supply the OpenRouter-compatible secret and model/network; the Docker step is guarded and skips indexing when no key is mounted.

## Security Considerations

**GitHub bot command execution:**
- Risk: The bot executes an external coding agent and Git commands based on repository/user-triggered requests.
- Files: `src/github-bot/agent.ts`, `src/github-bot/workspace.ts`, `src/github-bot/security.ts`, `src/github-bot/config.ts`.
- Current mitigation: HMAC webhook verification, collaborator authorization, command allowlists, path checks, protected workflow checks, diff limits, secret scanning, redacted logs, ephemeral workspaces, and draft-PR publication defaults.
- Recommendations: Keep policy defaults fail-closed, add CI tests for every new command/policy setting, and review changes to `.github/my-ai-bot.yml` as security-sensitive.

**Build/runtime secret handling:**
- Risk: AI provider keys are required for indexing and runtime; incorrect Docker/Dokku configuration can expose failures or accidentally persist secrets.
- Files: `Dockerfile`, `.github/workflows/dokku.yml`, `docs/dokku-deploy.md`, `.env.example`.
- Current mitigation: GitHub secret validation, OpenRouter prefix validation, BuildKit secret mount, and Dokku config synchronization.
- Recommendations: Avoid echoing secrets in debugging, periodically rotate deploy/provider keys, and verify Dokku Docker options after host changes.

**Public API exposure:**
- Risk: The chat/retrieval endpoints do not implement account authentication.
- Files: `server.ts`, `public/browser-chat.js`.
- Current mitigation: Request validation and IP-based rate limiting.
- Recommendations: Put the service behind an authenticated gateway or add application-level auth before treating it as a private data/API surface.

## Performance Bottlenecks

**Build-time embedding/index generation:**
- Problem: Repository indexing and model embedding happen during Docker image builds.
- Files: `Dockerfile`, `scripts/index-repo.ts`, `scripts/index-browser.ts`, `lib/indexer.ts`.
- Cause: Full repository scanning plus batched remote embeddings and local transformer inference on every build.
- Improvement path: Cache indexes by commit/content hash, move indexing to a separate job/artifact, or make server startup consume a prebuilt versioned index.

**In-memory cosine retrieval:**
- Problem: `lib/retriever.ts` loads the JSON index and computes similarity across chunks in-process.
- Files: `lib/retriever.ts`, `data/index.json`.
- Cause: Linear scan and JSON parsing; no ANN/vector database.
- Improvement path: Use a compact binary/ANN index or external vector store when corpus/query volume grows.

**Document-QA local vector store:**
- Problem: The standalone app rebuilds local indexes and uses local filesystem/FAISS operations.
- Files: `document_qa/service.py`, `document_qa/vector_store.py`.
- Cause: Designed for local/single-user workloads, not distributed serving.
- Improvement path: Separate ingestion from serving and use persistent managed vector storage for multi-user scale.

## Fragile Areas

**Shell portability and side effects:**
- Files: `lib/require_bash.sh`, `lib/common.sh`, `cli.sh`, `generate.sh`.
- Why fragile: Bash-only syntax, path differences, optional tools, and user-home mutations span macOS/Linux/Windows compatibility.
- Safe modification: Preserve the re-exec guard order, quote variables, use `execute_quoted`, test with temporary `HOME`, and run `bash -n` plus BATS.
- Test coverage: Good for selected config paths; many installer/export combinations remain environment-dependent.

**GitHub worker lifecycle:**
- Files: `src/github-bot/worker.ts`, `src/github-bot/store.ts`, `src/github-bot/workspace.ts`.
- Why fragile: It coordinates cancellation, retries, external processes, durable state, GitHub side effects, and cleanup.
- Safe modification: Extend focused tests for state transitions, aborts, retries, duplicate deliveries, and cleanup before changing orchestration.
- Test coverage: Strong targeted suite exists, but no live GitHub end-to-end test is appropriate/configured.

**Configuration schema compatibility:**
- Files: `configs/`, `cli.sh`, `generate.sh`, `tests/pr_*.bats`.
- Why fragile: External AI clients change native config formats; many configs are validated structurally rather than against vendor schemas.
- Safe modification: Add a targeted BATS test and preserve native keys/merge semantics for each client.
- Test coverage: Central JSON validation exists; TOML/native schema coverage is limited.

## Scaling Limits

**JSON job store:**
- Current capacity: Single-process, filesystem-backed queue/history in `BOT_DATA_DIR`.
- Limit: Concurrent replicas, high job volume, and shared storage are not supported robustly.
- Scaling path: Move queue/state to a transactional database or queue service and define distributed worker ownership.

**Single-process server:**
- Current capacity: One Bun process with in-process rate limits and bot worker orchestration.
- Limit: Rate limits, active jobs, and memory are not shared across replicas.
- Scaling path: Externalize rate limiting and job state, then add multi-instance coordination.

## Dependencies at Risk

**Bun/tsx execution boundary:**
- Risk: The project supports Bun and Node tooling while some package scripts still invoke `tsx`; earlier Dokku builds exposed a Bun/tsx CJS resolution failure.
- Impact: Runtime/build behavior can differ between local Node, local Bun, and the Docker image.
- Migration plan: Prefer direct Bun execution in Bun/Docker paths, keep Node-compatible scripts explicitly tested, and pin/document runtime versions when behavior matters.

**AI provider/model availability:**
- Risk: OpenRouter free models and Hugging Face model downloads can change availability, rate limits, or response schemas.
- Impact: Index builds, retrieval, and answer generation can fail without code changes.
- Migration plan: Add provider health checks, fallback models, and an index artifact strategy that decouples deploys from live provider availability.

## Missing Critical Features

**Deployment smoke test:**
- Problem: CI validates the Dockerfile syntax/check path but does not exercise a complete Dokku push/build/runtime health cycle.
- Blocks: Early detection of host-specific Docker options, BuildKit secrets, disk pressure, or runtime startup failures.

**Cross-runtime CI matrix:**
- Problem: The root CI workflow focuses on BATS and does not run the Bun TypeScript suite, typecheck, or Python tests.
- Blocks: Reliable regression detection across the actual application surfaces.

## Test Coverage Gaps

**TypeScript application and bot in CI:**
- What's not tested: `bun test` and `bun run typecheck` on every push/PR by the root workflow.
- Files: `.github/workflows/test.yml`, `package.json`, `src/github-bot/github-bot.test.ts`, `tests/fusion-watchdog.test.ts`.
- Risk: Server/bot/type regressions can merge while shell/config checks remain green.
- Priority: High.

**Python document-QA integration:**
- What's not tested: FastAPI/Streamlit service startup, file upload/index rebuild, and end-to-end citation behavior in CI.
- Files: `document_qa/api.py`, `document_qa/service.py`, `document_qa/tests/`.
- Risk: Local document-QA deployment or dependency drift may go unnoticed.
- Priority: Medium.

**Production retrieval/index artifacts:**
- What's not tested: A full keyed indexing run using the same Docker/Dokku build secret and model settings.
- Files: `Dockerfile`, `scripts/index-repo.ts`, `scripts/index-browser.ts`, `.github/workflows/dokku.yml`.
- Risk: Provider/network/runtime changes can break deployment after code CI passes.
- Priority: High.

---

*Concerns audit: 2026-08-04*
