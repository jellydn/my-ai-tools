# Specialist Agents with MemPalace

Create agents that focus on specific areas. Each agent gets its own wing and diary in the palace — not in your CLAUDE.md. Add 50 agents, your config stays the same size.

## Directory Structure

```
~/.mempalace/agents/
  ├── reviewer.json       # code quality, patterns, bugs
  ├── architect.json      # design decisions, tradeoffs
  └── ops.json            # deploys, incidents, infra
```

Your CLAUDE.md just needs one line:

```markdown
You have MemPalace agents. Run mempalace_list_agents to see them.
```

The AI discovers its agents from the palace at runtime. Each agent:

- **Has a focus** — what it pays attention to
- **Keeps a diary** — written in AAAK, persists across sessions
- **Builds expertise** — reads its own history to stay sharp in its domain

## Example Agent Configuration

### reviewer.json

```json
{
  "name": "reviewer",
  "focus": [
    "code quality",
    "pattern violations",
    "security vulnerabilities",
    "performance regressions"
  ],
  "wings": ["code_reviews", "bug_patterns", "security_findings"],
  "diary_format": "AAAK",
  "triggers": [
    "before_commit",
    "on_pr_create",
    "after_test_failure"
  ]
}
```

### architect.json

```json
{
  "name": "architect",
  "focus": [
    "design decisions",
    "tradeoff analysis",
    "technical debt",
    "system boundaries"
  ],
  "wings": ["adr", "rfc", "tech_debt"],
  "diary_format": "AAAK",
  "triggers": [
    "on_adr_create",
    "on_rfc_submit",
    "before_refactor"
  ]
}
```

### ops.json

```json
{
  "name": "ops",
  "focus": [
    "deployments",
    "incidents",
    "infrastructure changes",
    "monitoring alerts"
  ],
  "wings": ["incidents", "deploys", "infra_changes"],
  "diary_format": "AAAK",
  "triggers": [
    "after_deploy",
    "on_incident",
    "on_alert"
  ]
}
```

## Usage Examples

### Agent writes to its diary after a code review

```python
mempalace_diary_write("reviewer",
    "PR#42|auth.bypass.found|missing.middleware.check|pattern:3rd.time.this.quarter|★★★★")
```

### Agent reads back its history

```python
mempalace_diary_read("reviewer", last_n=10)
# → last 10 findings, compressed in AAAK
```

## How It Works

Each agent is a specialist lens on your data:

- The **reviewer** remembers every bug pattern it's seen
- The **architect** remembers every design decision
- The **ops** agent remembers every incident

They don't share a scratchpad — they each maintain their own memory in dedicated wings of the palace.

## Benefits

1. **Scalable** — Add 50 agents without bloating CLAUDE.md
2. **Persistent** — Agent memory survives across sessions
3. **Specialized** — Each agent develops deep expertise in its domain
4. **Discoverable** — Agents are listed at runtime via `mempalace_list_agents`
5. **Compressed** — AAAK format keeps diary entries concise and meaningful

## Integration with Claude Code

With the mempalace MCP server configured, Claude Code can:

```markdown
1. Call `mempalace_list_agents` to discover available agents
2. Delegate tasks to the appropriate specialist agent
3. Query agent diaries for historical context
4. Let agents write findings back to their diaries
```

The agents become an extension of your team's collective memory, living in the palace alongside your code.
