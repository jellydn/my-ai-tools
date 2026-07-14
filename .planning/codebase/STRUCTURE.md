# Codebase Structure

**Analysis Date:** 2026-07-14

## Directory Layout

```
my-ai-tools/
├── cli.sh                 # Install orchestrator (repo → $HOME)
├── generate.sh            # Export orchestrator ($HOME → repo)
├── server.ts              # Hono site + /api/chat RAG
├── install.sh / install.ps1 # Remote bootstrap installers
├── index.html             # Landing page served by server.ts
├── package.json           # TS/Bun scripts and dependencies
├── lib/
│   ├── require_bash.sh    # POSIX re-exec guard for bash-only libs
│   ├── common.sh          # Logging, execute*, copy, validation, backup
│   ├── install.sh         # install_* functions for external CLIs
│   ├── indexer.ts         # Repo walk + chunking for RAG index
│   ├── retriever.ts       # Load index, embed query, top-K retrieve
│   ├── vector-similarity.ts
│   └── code-taste/        # GitHub fetch, chunker, profile builder
├── scripts/
│   ├── index-repo.ts      # Build data/index.json
│   ├── index-browser.ts   # Browser-oriented index helper
│   └── code-taste.ts      # Bun CLI entry (analyze / export)
├── configs/               # Per-tool source-of-truth configs
│   ├── mcp-registry.json
│   ├── recommend-skills.json
│   └── <tool>/            # claude, opencode, pi, cursor, …
├── skills/                # Shared skill packages
├── tests/                 # bats (*.bats) + bun test (code-taste)
├── data/                  # Generated index.json (not always committed)
├── docs/                  # Human documentation
├── wiki/                  # Supplementary wiki content
├── public/                # Static assets for server
└── .planning/codebase/    # Architecture/structure notes (this folder)
```

## Directory Purposes

**`configs/`:**
- Purpose: Canonical copies of assistant settings, agents, commands, hooks, MCP snippets, themes.
- Contains: One subdirectory per product (`configs/claude/`, `configs/codex/`, `configs/pi/`, etc.) plus shared JSON registries at the root of `configs/`.
- Key files: `configs/mcp-registry.json`, `configs/recommend-skills.json`, per-tool `settings.json` / `AGENTS.md` / `mcp.json` variants.

**`lib/`:**
- Purpose: Shared implementation for shell tooling and TypeScript indexing/RAG/code-taste.
- Contains: Bash libraries and `.ts` modules included by `server.ts`, `scripts/*`, and tests.
- Key files: `lib/common.sh`, `lib/install.sh`, `lib/indexer.ts`, `lib/retriever.ts`, `lib/code-taste/profile.ts`.

**`scripts/`:**
- Purpose: Thin CLI entrypoints that are not the main shell installers.
- Contains: TypeScript runnable via `tsx` or `bun`.
- Key files: `scripts/index-repo.ts`, `scripts/code-taste.ts`.

**`skills/`:**
- Purpose: Skill content synced into tool-specific skill directories during install.
- Contains: Named skill folders with `SKILL.md` and supporting files.
- Key files: Per-skill directories referenced by `skill_exists_in_plugins` in `generate.sh`.

**`tests/`:**
- Purpose: Regression tests for `cli.sh`, `generate.sh`, skills, and code-taste.
- Contains: `*.bats` (bash-test), `code-taste.test.ts`.
- Key files: `tests/cli.bats`, `tests/generate.bats`, `tests/code-taste.test.ts`.

**`configs/claude/hooks/`:**
- Purpose: TypeScript hook bundle for Claude Code (git guard, session hooks).
- Contains: `index.ts`, `package.json`, shell hook wrappers.
- Key files: `configs/claude/hooks/git-guard.ts`, `configs/claude/hooks/index.ts`.

## Key File Locations

**Entry Points:**
- `cli.sh`: Forward install and config deployment.
- `generate.sh`: Reverse export from installed tools.
- `server.ts`: HTTP server and RAG chat.
- `scripts/index-repo.ts`: Offline index generation.
- `scripts/code-taste.ts`: GitHub coding-style analysis (Bun).

**Configuration:**
- `configs/mcp-registry.json`: Central MCP server definitions for install.
- `configs/recommend-skills.json`: Npx/marketplace skill recommendations.
- `biome.json`, `tsconfig.json`, `.pre-commit-config.yaml`: Repo tooling config.
- `.env.example`: Template for `OPENAI_API_KEY` and related env vars.

**Core Logic:**
- `lib/common.sh`: Cross-cutting shell utilities (dry-run, copy, validate, rollback).
- `lib/install.sh`: External binary installers invoked from `cli.sh` `main`.
- `cli.sh` (`copy_configurations`, `validate_all_configs`): Per-tool install mapping.
- `lib/indexer.ts` + `lib/retriever.ts`: RAG data path.
- `lib/code-taste/*.ts`: External-repo analysis pipeline.

**Testing:**
- `tests/*.bats`: Shell integration tests (CI runs `pr_*.bats`, `generate.bats`, `sh_reexec.bats`).
- `tests/code-taste.test.ts`: Bun unit/integration tests for chunking and profile helpers.

## Naming Conventions

**Files:**
- Shell entrypoints: `*.sh` at repo root or `lib/`; PowerShell `install.ps1`.
- Per-tool settings: often `settings.json`, `config.json`, `config.toml`, or `opencode.json` under `configs/<tool>/`.
- Agents/commands: kebab-case `.md` or tool-specific extensions (e.g. `.agent.md`, `.toml`).
- TypeScript modules: kebab-case filenames (`vector-similarity.ts`, `index-repo.ts`).

**Directories:**
- Tool configs: lowercase or hyphenated (`antigravity-cli`, `kimi-code`, `commandcode`).
- Skills: directory per skill name matching marketplace slug.
- Tests: `tests/<feature>.bats` or `tests/<feature>.test.ts`.

## Where to Add New Code

**New AI tool support:**
- Primary code: new `configs/<tool>/` tree; add `copy_<tool>_configs` and `install_<tool>` in `cli.sh` / `lib/install.sh`; mirror `generate_<tool>_configs` in `generate.sh`.
- Tests: `tests/` bats covering copy with temp `HOME`.

**New MCP server defaults:**
- Implementation: entry in `configs/mcp-registry.json`; optional hook in `install_mcp_servers_from_registry` usage inside relevant `copy_*_configs`.

**RAG / docs assistant changes:**
- Chunking or exclusions: `lib/indexer.ts`
- Retrieval or caching: `lib/retriever.ts`
- API behavior: `server.ts`
- Rebuild index: run `npm run index` → updates `data/index.json`

**Code-taste features:**
- Chunking rules: `lib/code-taste/chunker.ts`
- GitHub selection/fetch: `lib/code-taste/github.ts`
- Profile format/export: `lib/code-taste/profile.ts`
- CLI flags: `scripts/code-taste.ts`
- Tests: `tests/code-taste.test.ts`

**Utilities:**
- Shared shell helpers: `lib/common.sh`
- Shared TS math/helpers: `lib/vector-similarity.ts` or new modules under `lib/`

## Special Directories

**`data/`:**
- Purpose: Stores `index.json` embedding index for `server.ts`.
- Generated: Yes (via `scripts/index-repo.ts`).
- Committed: Often gitignored or built in deploy; chat returns 503 if missing.

**`.code-taste/`:**
- Purpose: Local analysis state (`profile.json`).
- Generated: Yes (via `code-taste analyze`).
- Committed: No (listed in `.gitignore`).

**`node_modules/`:**
- Purpose: npm/bun dependencies for TS tooling.
- Generated: Yes.
- Committed: No.

**`configs/claude/hooks/node_modules/`:**
- Purpose: Hook package deps when developing Claude hooks.
- Generated: Yes (local to hooks package).
- Committed: No (excluded via copy filters / standard ignore patterns).

---

*Structure analysis: 2026-07-14*
