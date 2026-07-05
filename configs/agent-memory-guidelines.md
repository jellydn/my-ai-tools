# Agent Memory & History Guidelines

## When to use what

### qmd (durable) — months horizon
- Project-specific learnings, architecture decisions, gotchas, patterns
- Issue resolution notes, project conventions
- Use via `/qmd-knowledge` skill or `mcp__qmd__*`

### agentmemory (session) — today, same project
- Discoveries made in _this_ run: "the build is blocked on env var X"
- Pre-commit / post-commit findings the current agent needs on the next pass
- Hints the next session today will need but no one will need in a month
- Use via `mcp__agentmemory__memory_save`

### /handoffs — cross-session task continuity
- "Continue debugging tomorrow" / "resume X"
- Use `/handoffs` to write, `/pickup` to resume

### ctx (provenance) — when source matters
- "Where did we decide to reject this fallback?"
- "Which command produced this error?"
- "Was this migration already attempted?"
- "Can I cite the exact event before editing?"
- Use `ctx search "<query>"`, `ctx show event <id> --window 3`
- ctx indexes real coding-agent sessions and returns cited results with session IDs
- Does NOT replace qmd/agentmemory for facts — it answers "where does this knowledge come from?"

## Decision rule

> "Will the next agent working on this project benefit from this in 3 months?"
> - **Yes** → qmd
> - **No, but the next session today might** → agentmemory
> - **No at all** → don't record
> - **"I need to keep working on this tomorrow"** → write a /handoffs plan
> - **"Where did this decision come from?"** → ctx search

## Three memory lanes + ctx

| Lane | Horizon | Tool |
|------|---------|------|
| qmd | Months | `mcp__qmd__save` via `/qmd-knowledge` skill |
| agentmemory | Today, same project | `mcp__agentmemory__memory_save` |
| /handoffs | Cross-session task | `/handoffs` → `/pickup` |
| ctx | Provenance/audit | `ctx search`, `ctx show event`, `ctx show session` |
