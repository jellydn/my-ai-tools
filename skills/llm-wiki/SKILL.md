---
name: llm-wiki
description: Build and maintain a persistent, compounding knowledge wiki from raw sources. Use when the user wants to create a knowledge base, ingest documents into a wiki, query a wiki, health-check a wiki, or set up Karpathy's LLM Wiki pattern.
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when building a personal knowledge base, researching a topic over time, or maintaining a structured wiki from raw documents
user-invocable: true
metadata:
  audience: all
  workflow: knowledge-management
---

# LLM Wiki

Build and maintain a persistent, compounding knowledge wiki from raw sources.

Based on [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): the LLM incrementally integrates each new source into a structured wiki of markdown files — updating entity pages, flagging contradictions, strengthening cross-references. Synthesis is compiled once and kept current, not re-derived on every query.

## Usage

`/llm-wiki <ACTION> [ARGUMENTS]`

## Actions

- **init [DIRECTORY]** - Initialize a new wiki (default: `.` — current directory)
- **ingest <SOURCE>** - Process a source file and integrate it into the wiki
- **query <QUESTION>** - Answer a question using the wiki as the knowledge base
- **lint** - Health-check the wiki for contradictions, orphan pages, and stale content
- **status** - Show a summary of the wiki's current state

---

## Architecture

```
your-wiki/
├── raw/           # Immutable source documents — you add, LLM never modifies
│   └── assets/    # Downloaded images referenced by sources
├── wiki/          # LLM-generated and maintained pages
│   ├── index.md   # Catalog of all pages with one-line summaries
│   ├── log.md     # Append-only record of all operations
│   ├── overview.md
│   ├── entities/  # People, places, organizations
│   ├── concepts/  # Ideas, topics, themes
│   ├── synthesis/ # Filed query answers and analyses
│   └── sources/   # One summary page per source
└── CLAUDE.md      # Schema: wiki conventions and per-operation workflows
```

Templates for all three layers are in `$SKILL_PATH/templates/`.

---

## For "init [DIRECTORY]":

1. Create the directory structure: `raw/`, `wiki/`, `wiki/entities/`, `wiki/concepts/`, `wiki/synthesis/`, `wiki/sources/`
2. Copy `$SKILL_PATH/templates/schema.md` to `CLAUDE.md` (or `AGENTS.md`)
3. Create `wiki/index.md` from `$SKILL_PATH/templates/index.md`
4. Create `wiki/log.md` from `$SKILL_PATH/templates/log.md`
5. Create a starter `wiki/overview.md` stating the wiki's domain and purpose
6. Tell the user to add sources to `raw/` and run `/llm-wiki ingest <file>` next

**Done when:** `raw/`, `wiki/`, `wiki/entities/`, `wiki/concepts/`, `wiki/synthesis/`, `wiki/sources/`, `CLAUDE.md` (or `AGENTS.md`), `wiki/index.md`, `wiki/log.md`, and `wiki/overview.md` exist, and the user has been told the next step.

---

## For "ingest <SOURCE>":

1. Read the source file; share key takeaways and ask the user what to emphasize
2. Create `wiki/sources/<slug>.md` with a structured summary
3. Update `wiki/overview.md` if the source shifts the big picture
4. Create or update entity pages in `wiki/entities/` for key people, places, organizations
5. Create or update concept pages in `wiki/concepts/` for key ideas and themes
6. Add a contradiction note on any existing page where this source conflicts with current content
7. Update `wiki/index.md` — every new or modified page must appear with a one-line summary
8. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Source Title>`

**Done when:** every affected page is updated, every new or changed page appears in `index.md`, and the log entry is appended. A single ingest typically touches 5–15 pages.

---

## For "query <QUESTION>":

1. Read `wiki/index.md` to identify the most relevant pages
2. Read those pages in full
3. Synthesize an answer with citations to specific wiki pages
4. If the answer is a valuable synthesis (comparison, analysis, discovered connection), offer to file it as a new wiki page under `wiki/synthesis/`; if filed, update `wiki/index.md` and append to `wiki/log.md`

**Done when:** the question is answered with citations, and any filing decision (page created or skipped) is resolved.

---

## For "lint":

Scan the entire wiki and report on each of the following:

- **Contradictions** — conflicting claims across pages
- **Stale content** — pages superseded by newer ingested material
- **Orphan pages** — pages with no inbound links
- **Missing pages** — concepts mentioned on multiple pages but lacking their own page
- **Broken links** — `[[Page Name]]` links pointing to non-existent pages
- **Data gaps** — areas a targeted source or web search could fill

Suggest new questions and sources. Ask before making any fixes.

Append to `wiki/log.md`: `## [YYYY-MM-DD] lint | health check`

**Done when:** all six issue types are checked and reported, suggestions are given, and the log entry is appended.

---

## For "status":

Report: source count in `raw/`, wiki page count, last 10 entries in `wiki/log.md`, and any obvious health issues (orphan pages, missing index entries).

**Done when:** all four items are reported.

---

## Index and log

**wiki/index.md** — content catalog, updated on every ingest. Every page with a link and one-line summary, organized by category. The LLM reads this first when answering queries.

**wiki/log.md** — append-only operation log. Entry format: `## [YYYY-MM-DD] <operation> | <title>`. Grep-parseable:

```bash
grep "^## \[" wiki/log.md | tail -5          # last 5 operations
grep "^## \[.*\] ingest" wiki/log.md          # all ingests
grep "^## \[.*\] query" wiki/log.md           # all queries
```

---

## Optional: qmd search

For larger wikis, add [qmd](https://github.com/tobi/qmd) — local hybrid BM25/vector search with an MCP server:

```bash
bun install -g @tobilu/qmd
qmd collection add ./wiki --name my-wiki
qmd embed
qmd query "how does X relate to Y" -c my-wiki
```

---

## Tips

- **Obsidian Web Clipper** converts web articles to markdown — fast source collection for `raw/`.
- **File good answers**: valuable query results (comparisons, analyses, new connections) should become wiki pages — explorations compound the knowledge base just like ingested sources do.
- **Ingest one source at a time** — read the summaries, check the updates, guide emphasis. You get more value staying in the loop than batch-ingesting unattended.
- The wiki is a git repo of markdown files — version history and collaboration come free.
