# Fly.io deploy (GitHub Actions)

The workflow [`.github/workflows/fly.yml`](../.github/workflows/fly.yml) deploys app `ai-tools-itman-fyi` on push to `main` or via **workflow_dispatch**.

## Required GitHub Actions secrets

Configure these under **Settings → Secrets and variables → Actions** for the repository:

| Secret | Value |
|--------|--------|
| `FLY_API_TOKEN` | Fly **deploy** token (not your personal login). Create with: `fly tokens create deploy` (while logged in with `flyctl auth login` locally). |
| `OPENAI_API_KEY` | Your [OpenRouter](https://openrouter.ai/) API key (`sk-or-v1-...`). **Not** an OpenAI `sk-proj-...` key — the app talks to `https://openrouter.ai/api/v1` (see `fly.toml`). |

If either secret is missing, or `OPENAI_API_KEY` is not an OpenRouter key (`sk-or-v1-...`), the workflow fails at **Validate required secrets** with an explicit error. A **401 Missing Authentication header** during Docker build almost always means the GitHub secret is still an OpenAI `sk-proj-...` key or the build secret was empty — fix the secret, then re-run **Fly Deploy**. The message `no access token available. Please login with 'flyctl auth login'` means **`FLY_API_TOKEN` was empty** in CI — do not add an interactive `flyctl auth login` step; use the deploy token secret instead.

## Runtime model configuration (already in repo)

Non-secret OpenAI-compatible settings are in [`fly.toml`](../fly.toml) and match [`.env.example`](../.env.example):

- `OPENAI_BASE_URL` = `https://openrouter.ai/api/v1`
- `OPENAI_MODEL` = `openrouter/free` ([free models collection](https://openrouter.ai/collections/free-models))
- `OPENAI_EMBEDDING_MODEL` = `nvidia/llama-nemotron-embed-vl-1b-v2:free`

No workflow change is required for OpenRouter free models once `OPENAI_API_KEY` is set.

## Local deploy (optional)

```bash
flyctl auth login
export OPENAI_API_KEY="sk-or-v1-..."
flyctl secrets set OPENAI_API_KEY="$OPENAI_API_KEY"
flyctl deploy --remote-only --build-secret "OPENAI_API_KEY=$OPENAI_API_KEY"
```
