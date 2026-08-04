# Technology Stack

**Analysis Date:** 2026-08-04

## Languages

**Primary:**
- **TypeScript** — HTTP server, repository indexing/retrieval, GitHub bot, Amp plugins, and tests in `server.ts`, `lib/`, `src/`, `scripts/`, and `configs/amp/`.
- **Bash** — configuration installation/export and dependency bootstrap in `cli.sh`, `generate.sh`, `install.sh`, `lib/`, and `tests/*.bats`.

**Secondary:**
- **Python** — local document Q&A service in `document_qa/` (FastAPI, Streamlit, FAISS-related code).
- **JavaScript** — browser client and standalone skill scripts in `public/browser-chat.js` and `skills/*/scripts/`.
- **JSON, JSONC, TOML, YAML, Markdown** — native configuration, workflows, agent instructions, and documentation throughout `configs/`, `.github/`, `skills/`, `docs/`, and `wiki/`.

## Runtime

**Environment:**
- **Bun 1.x** — preferred TypeScript runtime, package runner, test runner, and production container runtime (`Dockerfile`, `package.json`).
- **Node.js >=18** — declared compatibility in `package.json`; `tsx` remains available for Node-oriented scripts and local tooling.
- **Python** — required for the optional `document_qa/` application; versions and dependencies are declared in `document_qa/requirements.txt`.
- **Bash** — required for installer and configuration-sync workflows; entry points re-exec under Bash via `lib/require_bash.sh`.

**Package Manager:**
- **Bun** — primary lockfile is `bun.lock`; `package.json` scripts use `bun test` and Bun’s TypeScript execution.
- **npm-compatible metadata** — `package-lock.json` is also committed for dependency/security tooling and compatibility.
- **pip** — Python dependencies are isolated in `document_qa/requirements.txt`.

## Frameworks

**Core:**
- **Hono** `^4.6.3` with `@hono/node-server` `^2.0.8` — API server and middleware in `server.ts` and `src/github-bot/app.ts`.
- **FastAPI** — local document-Q&A HTTP API in `document_qa/api.py`.
- **Streamlit** — local document-Q&A UI in `document_qa/streamlit_app.py`.

**AI and retrieval:**
- **OpenAI SDK** `^6.0.0` — OpenAI-compatible chat and embedding calls through `lib/openai-client.ts` and `lib/retriever.ts`.
- **Hugging Face Transformers** `^4.2.0` and **onnxruntime-node** `^1.27.0` — browser/local embedding generation in `scripts/index-browser.ts` and related retrieval code.
- **Zod** `^4.0.0` — runtime validation for server payloads and GitHub bot configuration/results.
- **YAML** `^2.9.0` — parsing `.github/my-ai-bot.yml` in `src/github-bot/config.ts`.

**Testing:**
- **Bun test** — TypeScript unit/integration tests in `tests/*.test.ts` and `src/**/*.test.ts`.
- **BATS** — shell/configuration functional tests in `tests/*.bats`.
- **Python test suite** — document-QA tests in `document_qa/tests/`.

**Build/Dev:**
- **Biome** `^2.5.3` — formatting and checks, configured by `biome.json`.
- **TypeScript** `^7.0.0` — type checking through `package.json`’s `typecheck` script.
- **pre-commit** — whitespace, YAML, large-file, and oxfmt hooks in `.pre-commit-config.yaml`.
- **Docker BuildKit** — multi-stage image build in `Dockerfile`; build-time indexing receives an `OPENAI_API_KEY` secret.

## Key Dependencies

**Critical:**
- `hono`, `@hono/node-server` — production API serving.
- `openai`, `zod`, `yaml` — chat/retrieval and GitHub bot configuration/validation.
- `@huggingface/transformers`, `onnxruntime-node` — browser index generation and local embedding support.

**Infrastructure:**
- `bun-types` — Bun TypeScript declarations.
- `@biomejs/biome` — formatting/check tooling.
- Python packages in `document_qa/requirements.txt` — local document ingestion, embeddings, FAISS retrieval, FastAPI, and Streamlit.

## Configuration

**Environment:**
- Runtime values are supplied through `.env.example`, process environment, GitHub Actions secrets, or Dokku config.
- Core AI variables: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, and `OPENAI_EMBEDDING_MODEL`.
- GitHub bot variables: `GITHUB_APP_ID`, `GITHUB_APP_PRIVATE_KEY`, `GITHUB_APP_WEBHOOK_SECRET`, `GITHUB_BOT_LOGIN`, `BOT_DATA_DIR`, `BOT_WORKSPACE_ROOT`, and worker/security controls documented in `.env.example` and `src/github-bot/config.ts`.

**Build:**
- `package.json`, `bun.lock`, and `package-lock.json` — dependencies and scripts.
- `tsconfig.json` — TypeScript project configuration.
- `biome.json` — formatting/check configuration.
- `Dockerfile` — production image and build-time repository indexing.
- `.github/workflows/*.yml` — tests, GitHub Pages, and Dokku deployments.

## Platform Requirements

**Development:**
- Bun, Bash, Git, `jq`, and BATS for the primary project workflows.
- Python and dependencies from `document_qa/requirements.txt` only when using the local document-QA application.
- Docker is useful for validating the production image.

**Production:**
- Docker-compatible host running Bun image layers.
- Dokku app `ai-tools` on the configured Docklight host, or an equivalent Docker deployment.
- OpenRouter-compatible key and configured BuildKit secret when build-time indexing is enabled.

---

*Stack analysis: 2026-08-04*