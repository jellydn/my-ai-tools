# Cline Hooks

Cline supports lifecycle hooks via the SDK plugin system. Hooks let you observe and control agent behavior at key lifecycle stages.

## How Cline Hooks Work

Cline hooks are TypeScript/JavaScript files that export an `AgentPlugin` object with lifecycle handlers:

```typescript
import { type AgentPlugin } from "@cline/sdk"

const myPlugin: AgentPlugin = {
  name: "my-plugin",
  hooks: {
    beforeTool(context) { /* audit/block tool calls */ },
    afterRun(context) { /* log metrics, cleanup */ },
  },
}
```

## Installation

Install hooks via the CLI plugin system:

```bash
# Install from a file URL
cline plugin install https://raw.githubusercontent.com/path/to/plugin.ts

# Install from npm
cline plugin install --npm @scope/my-plugin

# Install from local path
cline plugin install ./path/to/plugin.ts
```

## Available Hook Events

| Stage | Purpose |
|-------|--------|
| `before_agent_start` | Inject context or modify prompt/messages |
| `run_start` | Logging, timers, rate limits |
| `tool_call_before` | Audit or block tool calls |
| `tool_call_after` | Log results, trigger side effects |
| `run_end` | Metrics, notifications, cleanup |
| `error` | Error reporting |

## Hook Policies

Hooks support blocking/async modes, timeouts, retries, and failure behavior:

| Policy | Options |
|--------|--------|
| `mode` | `"blocking"` or `"async"` |
| `failureMode` | `"fail_open"` or `"fail_closed"` |

Use `fail_closed` for security/policy hooks where bypassing is unsafe.

## Git Guard Hook

A shell-based Git Guard script is provided at `git-guard.sh` for blocking dangerous git commands. This works with any hook system that supports shell scripts receiving JSON on stdin.

## See Also

- [Cline Plugins Docs](https://docs.cline.bot/customization/plugins)
- [SDK Hooks Reference](https://docs.cline.bot/sdk/plugins)
