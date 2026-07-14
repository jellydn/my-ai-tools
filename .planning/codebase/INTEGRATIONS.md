# External Integrations

**Analysis Date:** 2026-07-14

## APIs & External Services

**LLM / embeddings (first-party app code):**
- **OpenAI-compatible API** — chat completions (`server.ts`), embeddings (`lib/retriever.ts`, `scripts/index-repo.ts`, `lib/code-taste/profile.ts`)
  - SDK/Client: `openai` npm package
  - Auth: `OPENAI_API_KEY` (required at runtime for server and index scripts)
  - Optional routing: `OPENAI_BASE_URL` (default in `.env.example` and `fly.toml`: OpenRouter `https://openrouter.ai/api/v1`)
  - Models: `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL` (defaults in `.env.example`, `fly.toml`, and code fallbacks)

**GitHub REST API:**
- Repository listing, tree/blob fetch for `code-taste` (`lib/code-taste/github.ts`)
  - Client: native `fetch` to `https://api.github.com`
  - Auth: optional `GITHUB_TOKEN` (Bearer header); unauthenticated rate limits apply without it
  - API version header: `2022-11-28`

**Hugging Face (local inference, no API key in repo):**
- **Xenova/all-MiniLM-L6-v2** — browser index embeddings via `@huggingface/transformers` in `scripts/index-browser.ts`

**MCP & CLIs (installed/configured for end users, not runtime of `server.ts`):**
- Central registry: `configs/mcp-registry.json` — servers launched via `npx`, or binaries such as `qmd`, `ctx`, `fff-mcp`, `sem-mcp`, `codebase-memory-mcp`, `logpilot`
- Installation orchestration: `cli.sh`, `lib/install.sh` (curl-based installers, `npx`/`bunx` for MCP packages)
- Per-tool MCP settings under `configs/<tool>/` (e.g. `configs/cline/mcp-settings.json`)

**Remote install/bootstrap URLs (shell):**
- Various vendor install scripts referenced in `lib/install.sh` (e.g. Cursor, Grok CLI, fff-mcp, sem) via `curl -fsSL`

## Data Storage

**Databases:**
- None — no SQL/NoSQL server in this repository

**File Storage:**
- **Local filesystem** — primary persistence
  - RAG index: `data/index.json` (read by `lib/retriever.ts`, built by `scripts/index-repo.ts`)
  - Browser search index: `public/index-browser.json` (built by `scripts/index-browser.ts`)
  - Coding taste state: `.code-taste/profile.json` and `CODING_TASTE.md` (`lib/code-taste/profile.ts`, `scripts/code-taste.ts`)
  - User machine targets: `$HOME/.claude`, `$HOME/.config/opencode`, `$HOME/.pi`, etc. (via `cli.sh` / `generate.sh`)
  - Backups: `$HOME/ai-tools-backup-{timestamp}` (`cli.sh`, `lib/common.sh`)

**Caching:**
- In-memory index cache in `lib/retriever.ts` (mtime/size keyed)
- In-memory rate-limit map in `server.ts` (`RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX`)

## Authentication & Identity

**Auth Provider:**
- **None for the public chat UI** — no user login in `server.ts`
- **API key auth** to upstream LLM provider using `OPENAI_API_KEY`
- **Optional GitHub token** for higher GitHub API quotas in `code-taste`

**Fly deployment:**
- `FLY_API_TOKEN` and `OPENAI_API_KEY` as GitHub Actions secrets (`.github/workflows/fly.yml` → `flyctl secrets import`)

## Monitoring & Observability

**Error Tracking:**
- None integrated (no Sentry/Datadog in app code)

**Logs:**
- `console.error` / `console.log` in `server.ts` and scripts
- Structured logging helpers in shell: `log_info`, `log_warning`, `log_error` in `lib/common.sh`
- MCP **logpilot** entry in `configs/mcp-registry.json` (optional agent-side log analysis, not repo server)

## CI/CD & Deployment

**Hosting:**
- **Fly.io** — app `ai-tools-itman-fyi` (`fly.toml`, `.github/workflows/fly.yml`)
- **GitHub Pages** — full-repo artifact deploy (`.github/workflows/deploy-pages.yml`, `CNAME`)

**CI Pipeline:**
- **GitHub Actions** — `.github/workflows/test.yml` (BATS + Bun typecheck/biome/code-taste tests)
- Deploy workflows on `main` push and `workflow_dispatch`

## Environment Configuration

**Required env vars (TypeScript services):**
- `OPENAI_API_KEY` — mandatory for `server.ts`, `scripts/index-repo.ts`, `code-taste` analyze path

**Commonly set / optional:**
- `OPENAI_BASE_URL`, `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL` — `.env.example`, `fly.toml`, `Dockerfile` ARGs
- `PORT` — HTTP listen port (`server.ts`)
- `GITHUB_TOKEN` — `code-taste` GitHub access (`lib/code-taste/github.ts`)

**Secrets location:**
- Local: `.env` (from `.env.example`; excluded from indexing in `lib/indexer.ts`)
- CI/CD: GitHub repository secrets (`FLY_API_TOKEN`, `OPENAI_API_KEY` in `.github/workflows/fly.yml`)
- Fly: `flyctl secrets import` for `OPENAI_API_KEY`
- Docker build: BuildKit secret `OPENAI_API_KEY` in `Dockerfile` for index generation

## Webhooks & Callbacks

**Incoming:**
- `POST /api/chat` — JSON chat + streaming NDJSON response (`server.ts`); not a third-party webhook
- Static routes: `/`, `/install.sh`, `/install.ps1`, `/public/*`
- `GET /data/*` — explicitly forbidden (403) in `server.ts`

**Outgoing:**
- HTTPS to OpenAI-compatible chat/embeddings endpoints (`openai` client)
- HTTPS to `api.github.com` (`lib/code-taste/github.ts`)
- Shell installers: outbound `curl` to vendor URLs during `cli.sh` / `lib/install.sh` runs
- Fly deploy: `flyctl deploy` from GitHub Actions (`.github/workflows/fly.yml`)

---

*Integration audit: 2026-07-14*
