# Architecture

**Analysis Date:** 2026-08-04

## Pattern Overview

**Overall:** A multi-surface monorepo combining a configuration-management CLI with a Bun/Hono application, a GitHub coding bot, and an optional local Python document-QA application.

**Key Characteristics:**
- The repository is both a source of truth for AI-tool configurations and a runnable web service.
- TypeScript/Bun services are modularized by concern: HTTP composition in `server.ts`, retrieval in `lib/`, and GitHub automation in `src/github-bot/`.
- The GitHub bot uses a durable JSON queue plus ephemeral, security-checked workspaces rather than a hosted job/database platform.
- Build-time indexing is optional and guarded by an `OPENAI_API_KEY` BuildKit secret in `Dockerfile`.

## Layers

**Configuration/CLI layer:**
- Purpose: Install repo-managed tool configs into `$HOME` and export local configs back to the repository.
- Location: `cli.sh`, `generate.sh`, `install.sh`, `install.ps1`, `lib/`.
- Contains: tool detection, backups, dry-run wrappers, validation, installers, config merge/copy functions, and Bash re-exec guards.
- Depends on: Bash, Git, `jq`, package managers, and optional external CLIs.
- Used by: contributors and users installing the managed AI-tool environment.

**HTTP/application layer:**
- Purpose: Serve the chat UI/API, retrieval endpoints, health checks, static assets, and GitHub webhooks.
- Location: `server.ts`, `index.html`, `public/`.
- Contains: Hono routes, rate limiting, request validation, streaming responses, static file serving, and application wiring.
- Depends on: `lib/retriever.ts`, `lib/openai-client.ts`, Hono, and GitHub bot composition.
- Used by: browser clients, deployment health probes, and GitHub webhook delivery.

**Repository knowledge layer:**
- Purpose: Scan source/docs, chunk text, generate embeddings, persist indexes, and retrieve relevant context.
- Location: `lib/indexer.ts`, `lib/retriever.ts`, `scripts/index-repo.ts`, `scripts/index-browser.ts`, `public/browser-chat.js`.
- Contains: exclusion rules, Markdown/file-type chunking, OpenAI-compatible embeddings, local transformer embeddings, and cosine-similarity retrieval.
- Depends on: local filesystem, OpenAI/OpenRouter, Hugging Face Transformers, and ONNX runtime.
- Used by: `/api/chat`, retrieval routes, and browser-side search.

**GitHub bot layer:**
- Purpose: Receive addressed issue-comment commands and run plan/review/implementation workflows.
- Location: `src/github-bot/`.
- Contains: webhook adapter (`app.ts`), command/auth logic (`commands.ts`), GitHub client (`github.ts`), configuration (`config.ts`), worker (`worker.ts`), agent execution (`agent.ts`), security (`security.ts`), state (`store.ts`), and workspace operations (`workspace.ts`).
- Depends on: GitHub REST API, GitHub App credentials, local Git, external coding-agent executable, and configured repository policy.
- Used by: the mounted webhook route in `server.ts`.

**Document-QA layer:**
- Purpose: Provide a separate local FastAPI/Streamlit document ingestion, retrieval, and citation-answering application.
- Location: `document_qa/`.
- Contains: loaders, chunking, embeddings, FAISS vector store, service orchestration, API, UI, and Python tests.
- Depends on: Python packages in `document_qa/requirements.txt` and local filesystem.
- Used by: local operators; it is not mounted into the main Hono server.

**Deployment layer:**
- Purpose: Build and deploy the TypeScript service as a Docker image.
- Location: `Dockerfile`, `.github/workflows/dokku.yml`, `docs/dokku-deploy.md`.
- Contains: multi-stage Bun image, optional index generation, runtime storage directories, Dokku SSH push, secret validation, and health/runtime configuration.
- Depends on: Docker BuildKit, Dokku, GitHub Actions secrets, and OpenRouter-compatible credentials.

## Data Flow

**Browser chat flow:**
1. Browser posts a message to `/api/chat` from `index.html`/`public/browser-chat.js`.
2. `server.ts` validates input and applies rate limiting.
3. `lib/retriever.ts` loads `data/index.json`, embeds the query, and returns top matching chunks.
4. The server builds a system/user prompt containing retrieved sources and streams the AI response.
5. The browser consumes text/source events and renders the answer.

**Repository index flow:**
1. `scripts/index-repo.ts` calls `indexRepository()` from `lib/indexer.ts`.
2. Files are filtered and chunked.
3. OpenAI-compatible embeddings are generated in batches.
4. The result is written to `data/index.json`.
5. `scripts/index-browser.ts` separately creates a local-transformer browser index at `public/index-browser.json`.

**GitHub bot flow:**
1. GitHub sends `issue_comment` to `/api/github/webhooks`.
2. `app.ts` verifies HMAC, ignores irrelevant/bot senders, parses an addressed command, and loads `.github/my-ai-bot.yml`.
3. `JsonJobStore` deduplicates deliveries, persists the job, and queues it for `BotWorker`.
4. The worker obtains an installation token, creates an ephemeral workspace, clones an exact ref, runs the configured agent, and validates the result.
5. Secure diff inspection/secret scanning gates publication; the worker pushes a branch, creates/updates a draft PR, or posts review findings.

**Configuration install flow:**
1. `cli.sh` sources `lib/require_bash.sh`, then shared libraries.
2. It detects installed tools and processes the ordered installer/configuration sequence.
3. Config files are copied with dry-run/backup/validation helpers.
4. Tool-specific configs, skills, MCP entries, hooks, and agents are synchronized into `$HOME`.
5. `generate.sh` performs the reverse export path for installed tools.

**State Management:**
- HTTP request state is in-process.
- Retrieval indexes are immutable/generated JSON files.
- GitHub bot jobs and history are atomically persisted as JSON in `BOT_DATA_DIR`.
- Workspaces are temporary directories cleaned after execution.
- CLI installation state is represented by filesystem contents and backup/transaction logs.

## Key Abstractions

**`createOpenAIClient()`**
- Purpose: Centralize OpenAI-compatible endpoint and API-key configuration.
- Examples: `lib/openai-client.ts`, `server.ts`, `lib/retriever.ts`.
- Pattern: Small environment-driven factory.

**`indexRepository()` / `retrieve()`**
- Purpose: Separate corpus construction from query-time ranking.
- Examples: `lib/indexer.ts`, `lib/retriever.ts`.
- Pattern: Pure-ish file scanning/chunking plus persisted index and cosine similarity.

**`BotWorker` and `JsonJobStore`**
- Purpose: Decouple webhook acceptance, durable job state, concurrency, recovery, and command execution.
- Examples: `src/github-bot/worker.ts`, `src/github-bot/store.ts`.
- Pattern: Queue/worker with atomic JSON persistence and per-issue locking.

**Workspace security boundary**
- Purpose: Restrict commands, paths, changed files, secrets, and diff size before publication.
- Examples: `src/github-bot/security.ts`, `src/github-bot/workspace.ts`.
- Pattern: Allowlist and validation gates around an ephemeral Git workspace.

**`execute()` / `execute_quoted()`**
- Purpose: Make shell side effects dry-run aware and safer for paths.
- Examples: `lib/common.sh`, calls throughout `cli.sh` and `generate.sh`.
- Pattern: shared command wrapper plus explicit quoted variant.

## Entry Points

**Main Bun server:**
- Location: `server.ts`.
- Triggers: `bun run server.ts`, Docker `CMD`, or `bun run dev`/`start`.
- Responsibilities: compose Hono routes, static files, chat/retrieval, health checks, and optional GitHub bot.

**Repository indexing:**
- Location: `scripts/index-repo.ts`, `scripts/index-browser.ts`.
- Triggers: Docker build when `OPENAI_API_KEY` is mounted, or explicit local invocation.
- Responsibilities: generate server and browser retrieval artifacts.

**Configuration installer/exporter:**
- Location: `cli.sh`, `generate.sh`, `install.sh`, `install.ps1`.
- Triggers: direct CLI invocation or quick-start installer.
- Responsibilities: sync tool configs and skills between repository and user home.

**Document-QA services:**
- Location: `document_qa/api.py`, `document_qa/streamlit_app.py`.
- Triggers: Python/FastAPI and Streamlit commands documented in `document_qa/README.md`.
- Responsibilities: local document ingestion, retrieval, and citation-aware answers.

## Error Handling

**Strategy:** Fail fast at boundaries, validate untrusted inputs, preserve durable job state, and return structured HTTP errors where appropriate.

**Patterns:**
- TypeScript entry scripts call `main().catch(...)` and exit non-zero (`scripts/index-*.ts`).
- Hono routes validate request bodies with Zod and use explicit status responses (`server.ts`).
- GitHub API errors carry status/code metadata (`src/github-bot/github.ts`).
- Bot worker catches failures, records state/history, redacts logs, and attempts status reporting (`src/github-bot/worker.ts`).
- Shell scripts use `set -e`, precondition checks, logging helpers, and dry-run wrappers.

## Cross-Cutting Concerns

**Logging:** Console logs for server/indexing; structured JSON logging for bot operations; GitHub Actions logs for CI/deploy.

**Validation:** Zod for TypeScript payload/config/result validation, `jq` for JSON config validation, BATS structural/behavioral checks, and security/diff gates for bot publication.

**Authentication:** OpenAI-compatible API keys, GitHub App JWT/installation tokens, webhook HMAC verification, and GitHub collaborator authorization.

---

*Architecture analysis: 2026-08-04*