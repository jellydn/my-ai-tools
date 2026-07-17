# Architecture

**Analysis Date:** 2026-07-14

## Pattern Overview

**Overall:** Multi-runtime monorepo with Bash-orchestrated config sync plus TypeScript services for RAG chat and optional GitHub “coding taste” analysis.

**Key Characteristics:**
- Repo is source of truth for per-tool AI assistant configs under `configs/`; `cli.sh` pushes to `$HOME`, `generate.sh` pulls from `$HOME`.
- Shared Bash library (`lib/common.sh`, `lib/install.sh`) centralizes dry-run, copying, validation, backups, and external CLI installers.
- Two embedding pipelines share cosine similarity (`lib/vector-similarity.ts`) but differ in chunking: local repo walk (`lib/indexer.ts`) vs Tree-sitter semantic units on GitHub (`lib/code-taste/`).
- Public site (`server.ts`) is a small Hono app that grounds LLM answers in `data/index.json` via `lib/retriever.ts`.

## Layers

**Config sync (Bash):**
- Purpose: Install/update tool CLIs and copy normalized configs into user home directories.
- Location: `cli.sh`, `generate.sh`, `lib/common.sh`, `lib/install.sh`, `install.sh`, `install.ps1`
- Contains: Entry scripts, `copy_*_configs` / `generate_*_configs`, MCP registry wiring, skill marketplace filtering.
- Depends on: `jq`, `curl`, optional per-tool CLIs; `configs/mcp-registry.json`, `configs/recommend-skills.json`.
- Used by: Developers and CI (bats tests source functions with isolated `HOME`).

**Per-tool config tree:**
- Purpose: Version-controlled settings, agents, commands, hooks, skills, themes per assistant product.
- Location: `configs/<tool>/` (e.g. `configs/claude/`, `configs/opencode/`, `configs/pi/`)
- Contains: JSON/TOML/YAML/MD manifests; tool-specific layout mirrors install targets under `$HOME` or `$HOME/.config/`.
- Depends on: Shared docs in `configs/best-practices.md`, `configs/git-guidelines.md`, central `configs/mcp-registry.json`.
- Used by: `copy_configurations()` in `cli.sh` and inverse generators in `generate.sh`.

**Repository indexing (TypeScript, Node/tsx):**
- Purpose: Build searchable embedding index of this repo for the docs assistant.
- Location: `lib/indexer.ts`, `scripts/index-repo.ts`, `scripts/index-browser.ts`, `data/index.json` (generated)
- Contains: File walk with exclusions, text/markdown chunking, batch OpenAI embeddings.
- Depends on: `OPENAI_API_KEY`, OpenAI embeddings API.
- Used by: `server.ts` through `lib/retriever.ts`.

**RAG HTTP API:**
- Purpose: Serve static landing page and streaming chat grounded in indexed excerpts.
- Location: `server.ts`, `lib/retriever.ts`, `lib/vector-similarity.ts`
- Contains: Hono routes (`/api/chat`, static assets, install script mirrors), rate limiting, Zod request validation.
- Depends on: `data/index.json`, `OPENAI_API_KEY`, optional `OPENAI_MODEL` / `OPENAI_EMBEDDING_MODEL`.
- Used by: `npm run dev` / `npm run start` (tsx), Docker/Fly deploy (`Dockerfile`, `fly.toml`).

**Code-taste pipeline (TypeScript, Bun):**
- Purpose: Analyze public GitHub repos and emit evidence-backed `CODING_TASTE.md` + `.code-taste/profile.json`.
- Location: `scripts/code-taste.ts`, `lib/code-taste/chunker.ts`, `lib/code-taste/github.ts`, `lib/code-taste/profile.ts`
- Contains: GitHub API fetch, Tree-sitter semantic chunking, embedding-ranked sample selection, LLM preference extraction.
- Depends on: Bun runtime, `OPENAI_*`, optional `GITHUB_TOKEN`.
- Used by: `bun run code-taste`, package `bin.code-taste`; tested via `tests/code-taste.test.ts`.

**Skills & plugins (content):**
- Purpose: Reusable skill packages and plugin metadata copied or referenced during install.
- Location: `skills/`, `configs/*/skills/`, `configs/antigravity-cli/plugins/`, etc.
- Contains: `SKILL.md` trees, plugin JSON, hook scripts (some TypeScript under `configs/claude/hooks/`).
- Depends on: `copy_skills_with_filter`, marketplace detection in `cli.sh` / `generate.sh`.
- Used by: Claude, Cline, Amp, and other tools during `copy_configurations`.

## Data Flow

**Install (`cli.sh`):**
1. `lib/require_bash.sh` re-execs under Bash if invoked as `sh`.
2. Parse flags (`--dry-run`, `--yes`, `--rollback`, etc.); non-interactive shells force `--yes`.
3. `preflight_check` → optional `backup_configs` → per-tool `install_*` from `lib/install.sh` (skipped when CLI missing or not in `-y` allowlist).
4. `copy_configurations` runs `validate_all_configs` then tool-specific `copy_*_configs` using `safe_copy_dir` / `execute_quoted`.
5. `enable_plugins` and success messaging; backups land in `$HOME/ai-tools-backup-*`.

**Export (`generate.sh`):**
1. Same Bash bootstrap and `DRY_RUN` via `execute` / `copy_single`.
2. `main` calls `generate_*_configs` only for tools detected installed under `$HOME`.
3. Writes back into `configs/` and may refresh root `MEMORY.md` from `~/.ai-tools/MEMORY.md`.

**Index build (`bun run index`):**
1. `scripts/index-repo.ts` calls `indexRepository(REPO_ROOT)` → list of `{ path, text }` chunks.
2. Embeddings created in batches → `data/index.json` with `generatedAt`, `model`, `chunks[]`.

**Chat (`POST /api/chat`):**
1. Rate limit by client IP → validate body with Zod.
2. `retrieve(message, 5)` embeds query, cosine-scores against cached index, returns top chunks.
3. System prompt constrains answers to excerpts; OpenAI streams JSON-lines text + source paths.

**Code-taste analyze:**
1. `resolveRepositories` picks representative public repos for a user or `owner/repo`.
2. `fetchRepositoryChunks` downloads and semantically chunks TS/TSX/MD via `chunker.ts`.
3. `buildProfile` ranks chunks, calls LLM, `saveProfile` to `.code-taste/profile.json`, writes `CODING_TASTE.md`.

**State Management:**
- Bash: globals `DRY_RUN`, `YES_TO_ALL`, `SCRIPT_DIR`, transaction log for `rollback_transaction` in `lib/common.sh`.
- Retriever: in-memory index cache invalidated on `data/index.json` mtime/size change.
- Code-taste: persistent profile under `.code-taste/` (gitignored).

## Key Abstractions

**Dry-run execution:**
- Purpose: Preview installs without mutating the filesystem.
- Examples: `lib/common.sh` (`execute`, `execute_quoted`)
- Pattern: Branch on `DRY_RUN`; log `[DRY RUN]` instead of running commands.

**Safe directory copy:**
- Purpose: Sync config trees while excluding caches and heavy artifacts.
- Examples: `safe_copy_dir` in `lib/common.sh`, used throughout `cli.sh` `copy_*_configs`
- Pattern: `mkdir -p` + filtered `cp -r`; some tools use rm-then-copy for full replacement (e.g. MiMo agent dirs).

**Tool allowlist (`-y` mode):**
- Purpose: Limit automated installs to a personal subset in CI/non-interactive runs.
- Examples: `TOOL_ALLOWLIST_YES` and `tool_allowed()` in `cli.sh`
- Pattern: Skip both installers and validators for non-allowlisted tools when `YES_TO_ALL=true`.

**Chunk:**
- Purpose: Atomic text unit for embedding (path + text, optionally embedding vector).
- Examples: `lib/indexer.ts`, `lib/retriever.ts`, `lib/code-taste/chunker.ts`
- Pattern: Repo indexer uses size/overlap splitting; code-taste uses syntax-aware units.

**MCP registry:**
- Purpose: Declarative list of MCP servers to register with a tool CLI.
- Examples: `configs/mcp-registry.json`, `install_mcp_servers_from_registry` in `cli.sh`
- Pattern: Iterate registry with `jq`; fall back to interactive `install_mcp_interactive` prompts when not `--yes`.

## Entry Points

**`cli.sh`:**
- Location: `cli.sh`
- Triggers: `./cli.sh` with optional flags; sourced by bats tests.
- Responsibilities: Full setup orchestration ending in `copy_configurations`; `--migrate-gemini` short path; `--rollback`.

**`generate.sh`:**
- Location: `generate.sh`
- Triggers: `./generate.sh [--dry-run]`
- Responsibilities: Reverse sync from user home into `configs/` and related repo files.

**`server.ts`:**
- Location: `server.ts`
- Triggers: `tsx server.ts` (`dev`/`start` scripts), container entry.
- Responsibilities: Static site, install script endpoints, RAG chat API.

**`scripts/index-repo.ts`:**
- Location: `scripts/index-repo.ts`
- Triggers: `npm run index`
- Responsibilities: Produce `data/index.json` for the chat server.

**`scripts/code-taste.ts`:**
- Location: `scripts/code-taste.ts`
- Triggers: `bun scripts/code-taste.ts` / `code-taste` bin
- Responsibilities: CLI subcommands `analyze` and `export`.

**`install.sh` / `install.ps1`:**
- Location: repo root
- Triggers: curl one-liner from site; served by `server.ts` at `/install.sh` and `/install.ps1`
- Responsibilities: Bootstrap clone + invoke `cli.sh` on Unix or PowerShell equivalent on Windows.

## Error Handling

**Strategy:** Fail fast on missing API keys for TS services; warn-and-continue for optional tool installs and config validation in non-interactive mode.

**Patterns:**
- Bash: `set -e` after re-exec; validation failures prompt to abort unless `--yes` or non-TTY.
- Index/chat: ENOENT on missing index → HTTP 503 with message to run `bun run index`.
- Code-taste: per-repo fetch errors logged as warnings; empty chunk set throws.
- MCP installs: retry with backoff in `install_mcp_server`.

## Cross-Cutting Concerns

**Logging:** `log_info` / `log_success` / `log_warning` / `log_error` in `lib/common.sh` (ANSI colors).

**Validation:** `validate_config` / `validate_config_with_schema` (jq-based) before copy; JSON schemas where defined.

**Authentication:** Chat and indexing require `OPENAI_API_KEY`; GitHub API optionally uses `GITHUB_TOKEN`. No end-user auth on public chat (rate limit only).

---

*Architecture analysis: 2026-07-14*
