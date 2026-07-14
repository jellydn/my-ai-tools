# Technology Stack

**Analysis Date:** 2026-07-14

## Languages

**Primary:**
- Bash — `cli.sh`, `generate.sh`, `lib/common.sh`, `lib/install.sh`, `lib/require_bash.sh`, `install.sh`, and BATS tests under `tests/*.bats`
- TypeScript (ESNext) — `server.ts`, `lib/*.ts`, `lib/code-taste/*.ts`, `scripts/*.ts`, `tests/code-taste.test.ts`

**Secondary:**
- JSON / YAML — tool configs under `configs/`, `configs/mcp-registry.json`, `biome.json`, `.github/workflows/*.yml`, `fly.toml`
- Markdown — `AGENTS.md`, `skills/`, `wiki/`, exported agent instructions
- PowerShell — `install.ps1` (served by `server.ts`)

## Runtime

**Environment:**
- **Bun** `>=1.0.0` — declared in `package.json` `engines`; used for `code-taste` CLI (`scripts/code-taste.ts`), `bun test`, and `bun install` in CI (`.github/workflows/test.yml`, `.github/workflows/fly.yml`)
- **Node.js 20** — `Dockerfile` base image `node:20-slim`; production chat server runs via `tsx` (`npm start` / `npm run dev` in container)

**Package Manager:**
- **Bun** — primary for local/CI TypeScript tooling; lockfile: `bun.lock` (present)
- **npm** — Docker build and runtime in `Dockerfile` (`npm ci`, `npm run index`); lockfile: `package-lock.json` (present)

## Frameworks

**Core:**
- **Hono** `^4.6.3` with **@hono/node-server** `^2.0.8` — HTTP app in `server.ts` (static assets, `/api/chat`, install script routes)
- **OpenAI SDK** `^4.65.0` — embeddings and chat in `lib/retriever.ts`, `scripts/index-repo.ts`, `lib/code-taste/profile.ts`, `server.ts`
- **Zod** `^3.23.8` — request validation in `server.ts`; LLM output parsing in `lib/code-taste/profile.ts`
- **web-tree-sitter** `0.26.11` + **@vscode/tree-sitter-wasm** `0.3.1` — semantic chunking in `lib/code-taste/chunker.ts`

**Testing:**
- **BATS** — shell/config regression tests in `tests/`; CI subset in `.github/workflows/test.yml` (`tests/pr_*.bats`, `tests/generate.bats`, `tests/sh_reexec.bats`)
- **Bun test** — `tests/code-taste.test.ts` via `package.json` script `test:code-taste`

**Build/Dev:**
- **tsx** `^4.23.0` — runs `server.ts` and indexing scripts without emit (`package.json` `dev` / `start` / `index`)
- **TypeScript** `^5.6.2` — `tsconfig.json` (`noEmit`, strict, `bun-types`)
- **@biomejs/biome** `^2.5.3` — formatting in `biome.json` (tabs, 120 cols, double quotes); linter disabled in repo config
- **@huggingface/transformers** `^4.2.0` + **onnxruntime-node** `^1.27.0` — local browser index embeddings in `scripts/index-browser.ts`

## Key Dependencies

**Critical:**
- `hono` / `@hono/node-server` — production RAG chat API and static hosting (`server.ts`)
- `openai` — vector index build (`scripts/index-repo.ts`), retrieval (`lib/retriever.ts`), coding-taste analysis (`lib/code-taste/profile.ts`)
- `web-tree-sitter` / `@vscode/tree-sitter-wasm` — GitHub repo semantic extraction for `code-taste` (`lib/code-taste/chunker.ts`)

**Infrastructure / tooling (install path):**
- **jq** — JSON validation and MCP registry handling in `lib/common.sh`, `generate.sh`, `cli.sh`; auto-install hooks in `lib/install.sh`
- **curl** — remote installers and schema fetch in `lib/common.sh`, `lib/install.sh`
- **npx / bunx** — MCP servers and recommended skills from `configs/mcp-registry.json` and `configs/recommend-skills.json` (wired in `cli.sh` / `lib/install.sh`)

## Configuration

**Environment:**
- Local secrets: copy `.env.example` → `.env` (`OPENAI_API_KEY`, optional `OPENAI_BASE_URL`, `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL`)
- Fly.io defaults in `fly.toml` `[env]` for OpenRouter model URLs (runtime secret `OPENAI_API_KEY` imported in `.github/workflows/fly.yml`)
- Optional `GITHUB_TOKEN` for `code-taste` GitHub API rate limits (`lib/code-taste/github.ts`)
- `PORT` for HTTP server (`server.ts`, default `3000`)

**Build:**
- `tsconfig.json` — TS sources: `scripts/**/*.ts`, `lib/**/*.ts`, `server.ts`
- `biome.json` — repo-wide formatter settings
- `fly.toml` — Fly app `ai-tools-itman-fyi`, region `sin`, 1024MB VM
- `Dockerfile` — build-time index generation with mounted `OPENAI_API_KEY` secret
- `.pre-commit-config.yaml` — whitespace/YAML hooks + `oxfmt` (see `tests/pr_pre_commit.bats`)

**Shell CLI:**
- `cli.sh` — install configs to `$HOME` (`--dry-run`, `--yes`, backup/rollback via `lib/common.sh`)
- `generate.sh` — export from `$HOME` back into `configs/` and `skills/`

## Platform Requirements

**Development:**
- Bash 4+ (re-exec guard in `lib/require_bash.sh`)
- Bun and/or Node for TypeScript services and tests
- `jq` recommended (installed by `cli.sh` when `-y`)
- `bats-core` for full shell test suite (`AGENTS.md`, `TESTING.md`)

**Production:**
- **Fly.io** — chat/RAG deployment (`.github/workflows/fly.yml`, `Dockerfile`, `fly.toml`)
- **GitHub Pages** — static site from repo root (`.github/workflows/deploy-pages.yml`, `CNAME`)
- Prebuilt indexes: `data/index.json` (server retrieval), `public/index-browser.json` (client-side search pipeline)

---

*Stack analysis: 2026-07-14*
