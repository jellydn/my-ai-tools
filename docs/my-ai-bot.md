# my-ai-bot

`my-ai-bot` is a self-hosted GitHub App that turns authorized issue and pull-request comments into durable, isolated
jobs. The design baseline and trust boundaries are in [my-ai-bot-architecture.md](my-ai-bot-architecture.md).

## Register and install the App

Create a GitHub App with a webhook URL ending in `/api/github/webhooks` and an independently generated webhook secret.

Grant only these repository permissions:

- Metadata: read
- Contents: read and write
- Issues: read and write
- Pull requests: read and write
- Checks: read
- Actions: read
- Commit statuses: read

Do not grant Workflows permission unless a future platform release explicitly supports workflow changes; the current
mandatory policy rejects them. Subscribe to **Issue comment**, **Issues**, **Pull request**, **Pull request review**,
**Pull request review comment**, **Installation**, and **Installation repositories**. The current command ingress uses
Issue comment; the other events allow lifecycle-aware follow-up without broad subscriptions. Do not grant
Administration or expose a Docker socket. Install the App on selected repositories rather than all repositories unless
every repository is trusted.

Copy `.env.example`; set `GITHUB_APP_ID`, the PEM `GITHUB_APP_PRIVATE_KEY` (literal newlines or escaped `\n`), and
`GITHUB_APP_WEBHOOK_SECRET`. All three are required to enable bot mode. Chat remains optional. Copy
`.github/my-ai-bot.example.yml` to `.github/my-ai-bot.yml` in a target repository and narrow commands and validation.
Repository configuration cannot turn off mandatory controls.

Rotate a private key by adding a second GitHub App key, deploying it, testing readiness, then deleting the old key.
Rotate a webhook secret by coordinating the GitHub setting and deployment during a maintenance window; GitHub does
not support two webhook secrets simultaneously. Never log either value.

Local setup from a clean checkout:

```bash
bun install --frozen-lockfile
cp .env.example .env
# Fill GITHUB_APP_ID, GITHUB_APP_PRIVATE_KEY, and GITHUB_APP_WEBHOOK_SECRET.
mkdir -p .data/my-ai-bot .work/my-ai-bot
BOT_DATA_DIR="$PWD/.data/my-ai-bot" BOT_WORKSPACE_ROOT="$PWD/.work/my-ai-bot" bun run bot:dev
```

Expose port 3000 through a trusted HTTPS tunnel (for example `cloudflared tunnel --url http://localhost:3000`) and
place its HTTPS URL in the App settings. A signed fixture can be sent with:

```bash
body='{"action":"created","installation":{"id":1},"sender":{"login":"alice"},"comment":{"body":"/my-ai-bot help"},"issue":{"number":1},"repository":{"name":"demo","owner":{"login":"acme"}}}'
sig="sha256=$(printf %s "$body" | openssl dgst -sha256 -hmac "$GITHUB_APP_WEBHOOK_SECRET" -hex | awk '{print $2}')"
curl -i -X POST http://localhost:3000/api/github/webhooks -H "X-GitHub-Event: issue_comment" \
  -H "X-GitHub-Delivery: local-1" -H "X-Hub-Signature-256: $sig" -H 'Content-Type: application/json' -d "$body"
```

## Commands

Comments may use `@my-ai-bot <command>`; `plan`, `implement`, and `review` also accept `/my-ai-bot` aliases. Commands
are `help`, `status`, `plan`, `implement`, `review`, `review security`, `fix-ci`, `address-review`, and `cancel`.

- `help` and `status` require read permission.
- `plan` and `review` require triage permission.
- `implement`, `fix-ci`, `address-review`, and `cancel` require write permission.
- `authorization.allowUsers` can narrow access. Repository settings cannot lower these mandatory minimums.

Reviews use the immutable API diff and never execute PR code. Implementations start from the trusted base SHA, use a
unique `my-ai-bot/issue-N-*` branch, pass configured validation plus secret/diff/workflow policy, and open a draft PR.
Address/fix commands accept only a recorded bot-created PR branch; ambiguous or human-decision feedback is reported
rather than edited.

Example sequence:

1. On issue #42, comment `@my-ai-bot plan` and inspect the seven-section grounded plan.
2. After approval, comment `@my-ai-bot implement`; follow the durable progress comment to the generated draft PR.
3. On that PR, comment `@my-ai-bot review` or `@my-ai-bot review security`.
4. After reviewers leave actionable inline feedback, comment `@my-ai-bot address-review`; the bot validates and pushes
   only the recorded bot branch, then replies only to comments it actually addressed.

Use `@my-ai-bot status` at any point or `@my-ai-bot cancel` to signal an active worker. One marker-bearing progress
comment is updated rather than posting progress spam.

## Production deployment

Build and run on a VPS with:

```bash
DOCKER_BUILDKIT=1 docker build --secret id=OPENAI_API_KEY,env=OPENAI_API_KEY -t my-ai-bot .
docker volume create my-ai-bot-data
docker run -d --name my-ai-bot --restart unless-stopped \
  --env-file .env -p 3000:3000 \
  -v my-ai-bot-data:/var/lib/my-ai-bot \
  --tmpfs /tmp/my-ai-bot:rw,noexec,nosuid,size=4g \
  my-ai-bot
curl --fail https://bot.example.com/healthz
curl --fail https://bot.example.com/readyz
```

The image runs as a non-root user. Keep only `/var/lib/my-ai-bot` persistent; `/tmp/my-ai-bot` is ephemeral. Inject
App secrets through the VPS secret manager, publish the service only behind TLS, back up the data volume, and restart
one instance at a time. Active jobs recover to queued. `/healthz` is liveness and `/readyz` is readiness. Build a
derived worker image containing Codex and validation binaries required by configured repositories.

OS/network resource isolation remains a deployment responsibility. The JSON store is suitable for one process only;
use a transactional backend before horizontal scaling. The MVP does not merge, auto-approve by default, resolve
ambiguous review requests, or guarantee arbitrary repository validation dependencies are available. The regex secret
scan is a blocking safeguard, not a proof that every possible secret format has been detected. GitHub interactions in
the automated suite are mocked; validate registration and installation-token permissions in a staging repository
before production rollout.
