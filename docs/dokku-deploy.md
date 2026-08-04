# Dokku deploy (GitHub Actions)

The workflow [`.github/workflows/dokku.yml`](../.github/workflows/dokku.yml) deploys Dokku app `ai-tools` to `dokku@docklight.itman.fyi` on push to `main` or via **workflow_dispatch**. Public URL: `https://ai-tools.itman.fyi`.

## Required GitHub Actions secrets

Configure under **Settings → Secrets and variables → Actions**:

| Secret                  | Value                                                                                                                                                                                                                                     |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DOKKU_SSH_PRIVATE_KEY` | Private key whose public half is registered on the Dokku host (`dokku ssh-keys:list`). Prefer a dedicated deploy key with no passphrase.                                                                                                  |
| `OPENROUTER_API_KEY`    | **Recommended.** Your [OpenRouter](https://openrouter.ai/) API key (`sk-or-v1-...`).                                                                                                                                                      |
| `OPENAI_API_KEY`        | **Optional (legacy).** Same OpenRouter key if you already use this name. If both are set, `OPENROUTER_API_KEY` wins. Dokku config + the Docker build secret still use the env name `OPENAI_API_KEY`. **Not** an OpenAI `sk-proj-...` key. |

If `DOKKU_SSH_PRIVATE_KEY` is missing, or neither OpenRouter secret is set, or the chosen key does not start with `sk-or-v1-`, the workflow fails at **Validate required secrets**.

## One-time Dokku host setup

Already applied for this migration (re-run if recreating the app):

```bash
dokku apps:create ai-tools
dokku domains:set ai-tools ai-tools.itman.fyi
dokku ports:set ai-tools http:80:3000
dokku git:set ai-tools deploy-branch main
dokku builder:set ai-tools selected dockerfile
dokku config:set --no-restart ai-tools \
  OPENAI_BASE_URL=https://openrouter.ai/api/v1 \
  OPENAI_MODEL=openrouter/free \
  OPENAI_EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free \
  PORT=3000
dokku docker-options:add ai-tools build '--secret id=OPENAI_API_KEY,env=OPENAI_API_KEY'
```

Register the CI public key (requires root / `dokku` sudo):

```bash
echo 'ssh-ed25519 AAAA... github-actions-ai-tools-dokku' | dokku ssh-keys:add github-actions-ai-tools
```

After the first successful HTTP deploy and DNS cutover:

```bash
dokku letsencrypt:enable ai-tools
```

## DNS cutover

`ai-tools.itman.fyi` must resolve to the Docklight VPS (`95.111.232.131`), not Fly.

1. Remove the Fly CNAME (`*.fly.dev`).
2. Add an A record: `ai-tools.itman.fyi` → `95.111.232.131` (or a CNAME to `docklight.itman.fyi` if you prefer).
3. Wait for TTL, then enable Let's Encrypt as above.

## Runtime model configuration

Non-secret OpenAI-compatible settings live in Dokku config (same values as [`.env.example`](../.env.example)):

- `OPENAI_BASE_URL` = `https://openrouter.ai/api/v1`
- `OPENAI_MODEL` = `openrouter/free`
- `OPENAI_EMBEDDING_MODEL` = `nvidia/llama-nemotron-embed-vl-1b-v2:free`

The Dockerfile indexes the repo at build time using a BuildKit secret `OPENAI_API_KEY`. Dokku passes that secret from app config via `docker-options` (`--secret id=OPENAI_API_KEY,env=OPENAI_API_KEY`). The deploy workflow re-syncs the **full** config above (key, base URL, models) into Dokku before `git push`, so host-side drift cannot break the build — a bare `OPENAI_API_KEY` alone used to fail with `401 invalid_api_key` because the OpenAI SDK defaulted to `api.openai.com`, which rejects `sk-or-v1-...` keys.

The code is defensive too: [`lib/openai-client.ts`](../lib/openai-client.ts) detects `sk-or-v1-...` keys and automatically targets `https://openrouter.ai/api/v1` when `OPENAI_BASE_URL` is unset, and picks a matching embedding default — OpenRouter's free `nvidia/llama-nemotron-embed-vl-1b-v2:free` for OpenRouter keys, OpenAI's `text-embedding-3-small` otherwise (indexed at build and queried at runtime with the same default).

## Local deploy (optional)

With SSH access as `dokku@docklight.itman.fyi`:

```bash
export OPENAI_API_KEY="sk-or-v1-..."
ssh dokku@docklight.itman.fyi config:set --no-restart ai-tools "OPENAI_API_KEY=$OPENAI_API_KEY"
git remote add dokku dokku@docklight.itman.fyi:ai-tools 2>/dev/null || true
git push dokku main:main
```

## Disk space warning

The Docklight node was near full disk during migration. If builds fail with "no space left on device", free Docker leftovers on the host (`dokku cleanup`) before retrying.
