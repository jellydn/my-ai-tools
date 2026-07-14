# Fly.io deploy (GitHub Actions)

The workflow [`.github/workflows/fly.yml`](../.github/workflows/fly.yml) deploys app `ai-tools-itman-fyi` on push to `main` or via **workflow_dispatch**.

## Required GitHub Actions secrets

Configure these under **Settings → Secrets and variables → Actions** for the repository:

| Secret | Value |
|--------|--------|
| `FLY_API_TOKEN` | Fly **deploy** token (not your personal login). Create with: `fly tokens create deploy` (while logged in with `flyctl auth login` locally). |
| `OPENROUTER_API_KEY` | **Recommended.** Your [OpenRouter](https://openrouter.ai/) API key (`sk-or-v1-...`). |
| `OPENAI_API_KEY` | **Optional (legacy).** Same OpenRouter key if you already use this name. If both are set, `OPENROUTER_API_KEY` wins. The app and Fly runtime still use the env name `OPENAI_API_KEY` (OpenAI-compatible client). **Not** an OpenAI `sk-proj-...` key. |

If `FLY_API_TOKEN` is missing, or neither OpenRouter secret is set, or the chosen key does not start with `sk-or-v1-`, the workflow fails at **Validate required secrets** (~12s on push). A **401 Missing Authentication header** during Docker build means the key was wrong or empty in the build secret — fix the GitHub secret, then re-run **Fly Deploy**. The message `no access token available. Please login with 'flyctl auth login'` means **`FLY_API_TOKEN` was empty** in CI — use the deploy token secret instead of interactive login.

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
