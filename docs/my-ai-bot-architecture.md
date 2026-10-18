# my-ai-bot architecture

## Current reusable components

- `server.ts` is the existing Hono/Node HTTP entry point and remains the process owner.
- Zod is already used for request validation and will validate repository configuration and agent output.
- `configs/ai-launcher/config.json` establishes `codex exec` as a supported non-interactive coding-agent command.
- Root and nested `AGENTS.md` files, `configs/cline/AGENTS.md`, and repository `skills/*/SKILL.md` files are the
  existing instruction sources. The bot reads them from the trusted base checkout rather than copying their content.
- `configs/claude/hooks/git-guard.ts` and `configs/git-guidelines.md` define the dangerous Git operations that the bot's
  stricter command policy must block.
- The `code-review`, `pr-review`, `draft-pull-request`, and planning skills provide review and publication conventions.

The implementation now includes GitHub App authentication, API publication, a durable queue, isolated workspace runner,
and structured agent output. The remaining boundaries are deployment-level rather than missing core flows.

## Proposed modules

`src/github-bot/` owns the GitHub App. Modules are grouped by responsibility rather than mirroring every GitHub API
resource:

- app/config/types: composition, secure configuration defaults, and shared schemas.
- github: App JWT and installation-token authentication, a small injected API client, webhook verification, comments,
  reviews, and pull-request publication.
- commands: parsing, authorization, and command dispatch.
- jobs: persistent idempotent records, state transitions, per-issue locking, queueing, cancellation, and recovery.
- agent: provider-neutral contract, structured instruction bundles/output, an argv-based process runner, and one Codex
  adapter based on the repository's AI Launcher configuration.
- workspace/security: ephemeral clones, validation, diff limits, command policy, redaction, and secret scanning.
- observability: structured redacted logs and replaceable counters/timers.

The initial persistent backend is a locked JSON snapshot written atomically to `BOT_DATA_DIR`. Its interface is kept
independent of the storage format so a transactional SQLite/Postgres implementation can replace it without changing
command handlers. This avoids adding a native database dependency to the existing Node/Bun deployment.

## Data flow

1. Hono receives the raw webhook body and verifies `X-Hub-Signature-256` before JSON parsing.
2. `X-GitHub-Delivery` is reserved atomically. Unsupported events and messages without a command return immediately.
3. The installation-scoped GitHub client checks the actor's collaborator permission before a job is enqueued.
4. The HTTP request returns `202`; an in-process worker claims durable queued jobs up to configured concurrency.
5. Read-only jobs retrieve issue/PR data through GitHub APIs and send structured untrusted data to the agent.
6. Write jobs clone the trusted base branch into a unique workspace, run the agent and configured validation under
   policy, scan and bound the diff, then push only the approved bot branch and create a draft PR.
7. One marked progress comment is updated through each state transition. Logs and comments expose summaries, never
   raw prompts, agent logs, tokens, or environment values.
8. Shutdown stops intake, cancels active children, persists state, and cleans job workspaces.

## Security boundaries

- GitHub-controlled text and repository files are untrusted data and cannot override platform policy.
- App private keys mint short-lived installation tokens; tokens are scoped to a job, redacted, removed from remotes,
  and deleted from the child environment after publication.
- Authorization comes only from GitHub collaborator permission APIs plus an optional platform allowlist.
- PR review uses API-provided diffs and never executes fork code. Implementation starts from the trusted base branch.
- The process runner accepts argv, not a shell string. A mandatory command policy blocks destructive Git, credential
  access, environment dumping, privilege escalation, pipe-to-shell, and writes outside the workspace.
- Repository configuration can narrow behavior but cannot disable signature checks, authorization, token redaction,
  workspace isolation, force-push protection, workflow-file protection, or publication limits.
- Workspaces are unique and ephemeral. Network isolation and OS resource controls are deployment responsibilities and
  are documented explicitly; the application still limits environment, timeout, turns, files, and diff size.

## Assumptions

- The self-hosted worker has Git, the selected agent CLI, and repository validation tools installed.
- The App is installed on repositories it operates on and receives only the documented webhook events.
- The deployment gives `BOT_DATA_DIR` a persistent volume and `BOT_WORKSPACE_ROOT` ephemeral storage.
- Codex is the first supported provider. Other configured CLIs can be added behind the same adapter contract.
- `address-review` and `fix-ci` are conservative MVP flows: they act only on bot branches and decline ambiguous fixes.
