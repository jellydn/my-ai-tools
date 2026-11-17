# Plan: Migrate ai-tools deploy from Fly.io → Dokku

## Goal

Replace Fly.io GitHub Actions deploy with Dokku on `dokku@docklight.itman.fyi` so
`https://ai-tools.itman.fyi` is served by Dokku app `ai-tools`.

## Decisions (confirmed)

| Item | Choice |
|------|--------|
| App name | `ai-tools` |
| Domain | `ai-tools.itman.fyi` |
| Host | `dokku@docklight.itman.fyi` (VPS `95.111.232.131`) |
| CI auth | Deploy key → GitHub secret `DOKKU_SSH_PRIVATE_KEY` |
| Builder | Existing `Dockerfile` (port 3000) |

## Why Fly fails today

CI needs `FLY_API_TOKEN` (+ OpenRouter key). Migrating off Fly removes that dependency
and keeps hosting on the existing Docklight Dokku node.

## Implementation steps

1. **Repo packaging**
   - Keep `Dockerfile` BuildKit secret mount for `OPENAI_API_KEY` (index at build).
   - Document Dokku `docker-options` so build receives `--secret id=OPENAI_API_KEY,env=OPENAI_API_KEY`.
   - Map proxy port `80/443 → 3000`.
   - Move runtime env from `fly.toml` → `dokku config:set` (and document equivalents).

2. **CI**
   - Replace `.github/workflows/fly.yml` with `.github/workflows/dokku.yml`.
   - Use `dokku/github-action` (or equivalent git+ssh push) to `ssh://dokku@docklight.itman.fyi/ai-tools`.
   - Validate secrets: `DOKKU_SSH_PRIVATE_KEY`, `OPENROUTER_API_KEY` (or legacy `OPENAI_API_KEY`).
   - Sync OpenRouter key onto Dokku before push (`dokku config:set` over SSH) so build secret + runtime work.

3. **VPS one-time**
   - `dokku apps:create ai-tools` (if missing).
   - `dokku domains:set ai-tools ai-tools.itman.fyi`.
   - `dokku ports:set` / proxy for container port 3000.
   - `dokku docker-options:add ai-tools build '--secret id=OPENAI_API_KEY,env=OPENAI_API_KEY'`.
   - Install deploy public key for `dokku` user.
   - Enable Let's Encrypt after first successful deploy + DNS.

4. **Docs / cleanup**
   - Replace `docs/fly-deploy.md` with `docs/dokku-deploy.md`.
   - Remove `fly.toml` and Fly workflow.
   - Note DNS: `ai-tools.itman.fyi` A/CNAME must point at Docklight (`95.111.232.131`), not Fly.

5. **Secrets (never commit)**
   - GitHub: `DOKKU_SSH_PRIVATE_KEY`, `OPENROUTER_API_KEY` (recommended).
   - Dokku config: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL`.
   - Rotate any passphrase shared in chat after setup.

## Out of scope

- Changing the Hono/search app itself.
- Migrating away from OpenRouter.
- Destroying the Fly app (manual; optional follow-up).

## Verify

- Workflow dry path: secrets validation fails clearly when key missing.
- `git push dokku main` / Actions deploy builds image and starts process.
- `curl -fsSL https://ai-tools.itman.fyi/` returns 200.
- Install script URL still works: `https://ai-tools.itman.fyi/install.sh`.

## Progress (2026-07-30)

- [x] Dokku app `ai-tools` created; domain `ai-tools.itman.fyi`; ports `80→3000`; dockerfile builder; build secret docker-option; env models set; deploy-branch `main`.
- [x] GitHub secret `DOKKU_SSH_PRIVATE_KEY` set (reuses Dokku key `github-actions` / local `~/.ssh/dokku_deploy`).
- [x] Workflow `dokku.yml` + `docs/dokku-deploy.md`; removed `fly.yml` / `fly.toml` / `docs/fly-deploy.md`.
- [x] First deploy succeeded on VPS (healthchecks green); CI initially failed on shallow push — fixed with `fetch-depth: 0`.
- [x] DNS cutover to `95.111.232.131`.
- [x] `dokku letsencrypt:enable ai-tools` (HTTPS live).
- [ ] Confirm follow-up Actions run is green after unshallow fix.
