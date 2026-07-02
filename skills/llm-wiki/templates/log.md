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

<!-- New entries are appended below, most recent at the bottom -->
