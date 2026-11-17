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

## Optional installation (npm link)

The main installer does not install or configure this server. Existing qmd, codebase-memory-mcp, and agentmemory
integrations remain available. Opt in only if you also need a separate explicit-preference store.

Until the package is published to npm, install the binary from a persistent monorepo checkout:

```bash
# from the my-ai-tools repo root
npm ci
npm run link:user-memory
# exposes `user-memory-mcp` on your PATH via npm link
```

Keep the checkout: `npm link` points to its built package. After updating the checkout,
rerun `npm ci && npm run link:user-memory` to rebuild. On Windows, run the two npm commands separately in
PowerShell 5.1 and ensure npm's global prefix (`npm prefix -g`) is on PATH; on Unix, use its `bin` subdirectory.

Then register it only in the assistants where you want it. For Claude Code:

```bash
claude mcp add --scope user --transport stdio user-memory -- user-memory-mcp
```

For assistants with an `mcpServers` JSON map, merge this entry into your local configuration (do not replace
the rest of the file):

```json
{
  "mcpServers": {
    "user-memory": { "command": "user-memory-mcp", "args": [] }
  }
}
```

OpenCode uses `"mcp": { "user-memory": { "type": "local", "command": ["user-memory-mcp"], "enabled": true } }`.
To remove an existing registration, use each assistant's MCP settings. No binary uninstall or preference-store
deletion is performed by the main installer.

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
