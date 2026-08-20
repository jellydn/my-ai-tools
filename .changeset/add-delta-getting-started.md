---
"my-ai-tools": minor
---

Add Delta getting-started documentation

Documents [Delta](https://delta.dev) — Zed's collaborative agent workspace — for private-beta users.

**New files**
- `docs/delta-getting-started.md` — install (macOS/Linux/Windows), sign-in, models, threads, terminals, command palette, review/sync workflow, troubleshooting

**Updated files**
- `README.md` — Delta optional section, intro/features mentions, Resources links

**Tests**
- `tests/pr_delta.bats` — doc structure, README links, changeset presence

No `./cli.sh` integration yet; Delta has no stable shared config path in this repo.
