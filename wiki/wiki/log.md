# Wiki Log

Append-only chronological record of all wiki operations.

Format: `## [YYYY-MM-DD] <operation> | <title>`

Operations: `ingest` | `query` | `lint` | `init`

---

## Useful queries

```bash
# Last 5 operations
grep "^## \[" wiki/log.md | tail -5

# All ingests
grep "^## \[.*\] ingest" wiki/log.md

# All queries
grep "^## \[.*\] query" wiki/log.md

# Count ingests
grep -c "^## \[.*\] ingest" wiki/log.md
```

---

## Log

## [2026-07-03] init | LLM Wiki

## [2026-07-03] fix | add AGENTS.md and update CLAUDE.md to reference it

## [2026-07-04] ingest | README.md — my-ai-tools Main Documentation

Created source summary, entity pages (my-ai-tools-repo, ctx, pi-agent), concept page (mcp-registry). Updated overview and index.

## [2026-07-10] ingest | README.md — re-ingest (diff-only update)

Diff-only update. Updated source summary. Created entity pages (mimo-code, herdr, subagent-infrastructure) and concept pages (agent-teams, community-skills-ecosystem). Updated overview and index. 3 new entities, 2 new concepts.
