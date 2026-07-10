---
title: "Agent Teams"
type: concept
tags: [agents, orchestration, multi-agent, coordination]
created: 2026-07-10
---

# Agent Teams

A pattern for coordinating multiple specialized AI agents to complete complex workflows. Agents are spawned as subagents with role-specific tool restrictions, while a coordinator agent orchestrates the overall task.

## Architecture

```
Coordinator Agent (feature-team-coordinator)
  ├── code-reviewer (read-only analysis)
  ├── test-generator (write tests, run commands)
  ├── documentation-writer (write docs, no shell)
  ├── ai-slop-remover (clean AI patterns)
  └── security-audit (read-only audit)
```

## Key Principles

- **Role-specific tool access** — Each agent only gets the tools it needs
- **Parallel execution** — Independent agents run concurrently
- **Coordinator delegates, not micromanages** — Agents receive context and autonomy
- **Structured output** — Each agent returns a consistent format

## Tools Supporting Agent Teams

- **Claude Code** — `feature-team-coordinator` agent with `Task` tool for spawning subagents
- **Conductor** — Orchestrates parallel agents in isolated workspaces
- **Orca** — Per-workspace environments with agent hooks

## Related Pages

- [[subagent-infrastructure]] — Standardized agents across 12 tools
- [[sources/readme]] — Primary documentation source
