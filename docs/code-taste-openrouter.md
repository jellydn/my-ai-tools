# Code taste with OpenRouter

`code-taste` uses the [OpenAI Node SDK](https://github.com/openai/openai-node) with an optional **`OPENAI_BASE_URL`**, so you can point analysis and embeddings at [OpenRouter](https://openrouter.ai/) instead of OpenAI directly. No code changes are required—only environment variables.

## Prerequisites

- **Bun** (`>=1.0.0`) — see [README § GitHub Coding Taste Generator](../README.md#-github-coding-taste-generator)
- An [OpenRouter API key](https://openrouter.ai/settings/keys) (`sk-or-v1-...`)
- Models on OpenRouter that support **chat completions** (preference extraction) and **embeddings** (chunk ranking)

## Quick setup

1. Copy the repo template (already tuned for OpenRouter):

   ```bash
   cp .env.example .env
   ```

2. Edit `.env`:

   ```bash
   OPENAI_BASE_URL=https://openrouter.ai/api/v1
   OPENAI_API_KEY=sk-or-v1-your-key-here
   OPENAI_MODEL=openrouter/free
   OPENAI_EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
   ```

3. Load env and run (Bun):

   ```bash
   bun install
   set -a && source .env && set +a   # or: export $(grep -v '^#' .env | xargs)

   bun run code-taste analyze jellydn
   bun run code-taste export --format markdown
   ```

   Optional: `GITHUB_TOKEN` increases GitHub API rate limits when listing repos and downloading files.

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `OPENAI_API_KEY` | Yes | OpenRouter key (same variable name as OpenAI; SDK convention) |
| `OPENAI_BASE_URL` | For OpenRouter | Set to `https://openrouter.ai/api/v1` |
| `OPENAI_MODEL` | No | Chat model for preference inference (default in code: `gpt-4o-mini`) |
| `OPENAI_EMBEDDING_MODEL` | No | Embedding model for chunk selection (default in code: `text-embedding-3-small`) |
| `GITHUB_TOKEN` | No | GitHub REST API (recommended for user-wide repo discovery) |

Implementation: `lib/code-taste/profile.ts` constructs the client with `apiKey` and `baseURL` from these variables.

## Choosing models

Browse [OpenRouter models](https://openrouter.ai/models) or the curated **[Free models collection](https://openrouter.ai/collections/free-models)** (rankings updated from real usage; capacity can change over time).

`code-taste` calls two APIs on the same base URL:

1. **Embeddings** — ranks repository chunks before LLM analysis (`OPENAI_EMBEDDING_MODEL`).
2. **Chat completions** — extracts preferences as JSON (`OPENAI_MODEL`, `response_format: json_object` in `lib/code-taste/profile.ts`).

### Recommended free stack (matches `.env.example`)

| Step | Variable | Suggested value | Notes |
|------|----------|-----------------|-------|
| API base | `OPENAI_BASE_URL` | `https://openrouter.ai/api/v1` | Required for OpenRouter |
| Key | `OPENAI_API_KEY` | `sk-or-v1-...` | From [OpenRouter keys](https://openrouter.ai/settings/keys) |
| Embeddings | `OPENAI_EMBEDDING_MODEL` | `nvidia/llama-nemotron-embed-vl-1b-v2:free` | [Llama Nemotron Embed VL 1B V2](https://openrouter.ai/collections/free-models) — text + image document embedding; works for text-only chunk strings |
| Analysis | `OPENAI_MODEL` | `openrouter/free` | [OpenRouter free router](https://openrouter.ai/openrouter/free) — picks an available free model per request |

Example `.env` (copy-paste):

```bash
OPENAI_BASE_URL=https://openrouter.ai/api/v1
OPENAI_API_KEY=sk-or-v1-...
OPENAI_MODEL=openrouter/free
OPENAI_EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
```

### If `openrouter/free` or embeddings fail

Try a **fixed free chat model** from the [free collection](https://openrouter.ai/collections/free-models) that supports tool calling / structured or JSON-style output, for example:

- `tencent/hy3:free` — reasoning / agent workflows, 262K context
- `nvidia/nemotron-3-ultra:free` — long context, strong on multi-step tasks
- `openai/gpt-oss-20b:free` — structured outputs / function calling
- Poolside **Laguna** variants (`poolside/...:free`) — agentic coding (check exact model id on OpenRouter)

Keep **`OPENAI_EMBEDDING_MODEL`** on an embedding-specific free model (e.g. `nvidia/llama-nemotron-embed-vl-1b-v2:free`). Do not point embeddings at chat-only models.

### Free tier caveats

- OpenRouter [documents free inference](https://openrouter.ai/collections/free-models) as capacity they support but do not guarantee forever.
- Some free providers (e.g. Poolside) may use inputs/outputs for training when used at $0 — read each model’s card before production use.
- Free routers can return different backends per call; for reproducible taste profiles, pin a single `OPENAI_MODEL` id instead of `openrouter/free`.

This repository’s `.env.example`, `fly.toml`, and Docker build args use the same OpenRouter defaults for the **repo chat** stack; those values apply to **`code-taste analyze`** when both embedding and chat models succeed on your account.

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| `OPENAI_API_KEY is required` | Export key after sourcing `.env` |
| 401 / invalid key | Key is OpenRouter `sk-or-v1-...`, not an OpenAI `sk-...` unless you use OpenAI’s URL |
| Embedding errors | `OPENAI_EMBEDDING_MODEL` must exist on OpenRouter (or switch `OPENAI_BASE_URL` back to OpenAI for embeddings only—mixed providers need two runs or a single provider that offers both) |
| GitHub rate limit | Set `GITHUB_TOKEN` with `public_repo` (or broader) scope |

## Related

- CLI help: `bun scripts/code-taste.ts --help`
- Repo assistant (same OpenRouter env): [README § Chat with the repo](../README.md#-chat-with-the-repo)
