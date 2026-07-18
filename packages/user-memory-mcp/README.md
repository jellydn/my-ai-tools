# User Memory MCP

An MCP stdio server for durable user preferences shared across projects and coding agents.

Unlike project knowledge or session memory, this server stores only preferences that the user explicitly states or
confirms. It does not infer preferences and does not use embeddings.

## Tools

- `memory_preference_set`
- `memory_preference_get`
- `memory_preference_list`
- `memory_preference_delete`
- `memory_preference_reset`

`memory_preference_set` requires the caller to attest with `confirmed: true`. Callers must only provide that attestation
after an explicit user statement. The server also performs best-effort rejection of common secret-like keys and values,
including API keys, tokens, passwords, credentials, and private keys. This heuristic is an additional guardrail, not a
secret scanner or encryption boundary.

## Storage

The server stores user-level state independently from any project:

```text
~/.ai-tools/user-memory/
├── preferences.json
└── audit.jsonl
```

Files are written with user-only permissions. Best-effort audit entries contain the operation and preference key, but
never the preference value. Preference state is committed atomically; an audit write failure does not roll back or
misreport a successful preference update. Set `USER_MEMORY_HOME` to override the storage directory, including for tests.

## Install (npm link)

Until the package is published to npm, install the binary from this monorepo:

```bash
# from the my-ai-tools repo root
npm install
npm run link:user-memory
# exposes `user-memory-mcp` on your PATH via npm link
```

`./cli.sh` also auto-links the binary when the MCP registry prerequisite `user-memory-mcp` is missing.

## Run

```bash
user-memory-mcp
```

For local development:

```bash
npm install
npm run build --workspace @jellydn/user-memory-mcp
npm run test:user-memory
```
