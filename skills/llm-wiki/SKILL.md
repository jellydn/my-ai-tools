---
name: llm-wiki
description: Build and maintain a persistent, LLM-driven knowledge wiki from raw sources. Based on Karpathy's LLM Wiki pattern — incremental ingestion, compounding synthesis, and zero-maintenance cross-referencing.
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

Inspired by [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): the LLM incrementally builds and maintains a structured, interlinked collection of markdown files — so knowledge compounds across sessions instead of being re-derived from scratch on every query.

## Usage

`/llm-wiki <ACTION> [ARGUMENTS]`

## Actions

- **init [DIRECTORY]** - Initialize a new LLM Wiki in the given directory (default: `wiki/`)
- **ingest <SOURCE>** - Process a new source file and integrate it into the wiki
- **query <QUESTION>** - Answer a question using the wiki as the knowledge base
- **lint** - Health-check the wiki for contradictions, orphan pages, and stale content
- **status** - Show a summary of the wiki's current state
- **help** - Show this help

---

## The Core Idea

Most LLM+document workflows are stateless: documents are retrieved at query time and the LLM re-derives synthesis from scratch on every question. **Nothing compounds.**

The LLM Wiki pattern is different. The LLM **incrementally builds and maintains a persistent wiki** — a structured directory of markdown files that sits between you and your raw sources. When you add a new source:

- The LLM reads it, extracts key information, and **integrates it into the existing wiki**
- It updates entity pages, revises topic summaries, flags contradictions, strengthens cross-references
- The synthesis is compiled once and kept current — not re-derived on every query

**The wiki is a persistent, compounding artifact.** Cross-references are already there. Contradictions have already been flagged. Synthesis already reflects everything you've read.

You never write the wiki yourself — the LLM writes and maintains all of it. You curate sources, explore, and ask good questions.

> **Obsidian = IDE; LLM = programmer; Wiki = codebase.**

---

## Architecture

A wiki has three layers:

```
your-wiki/
├── raw/           # Immutable source documents (you add these)
│   ├── article-1.md
│   ├── paper-2.pdf
│   └── assets/    # Downloaded images
├── wiki/          # LLM-generated and maintained pages (LLM writes these)
│   ├── index.md   # Catalog of all pages with one-line summaries
│   ├── log.md     # Append-only chronological record of operations
│   ├── overview.md
│   ├── entities/  # Pages for people, places, organizations
│   ├── concepts/  # Pages for ideas, topics, themes
│   └── sources/   # Summary pages per source
└── CLAUDE.md      # Schema: wiki conventions and LLM workflow instructions
```

**raw/** — Your curated source documents. Immutable — the LLM reads from them but never modifies them.

**wiki/** — LLM-generated markdown files. Summaries, entity pages, concept pages, comparisons, synthesis. The LLM owns this layer entirely.

**CLAUDE.md / AGENTS.md** — The schema that tells the LLM how the wiki is structured, what conventions to follow, and what workflows to run during ingest, query, and lint. Co-evolve this with the LLM over time.

Templates for all of these are available in `$SKILL_PATH/templates/`.

---

## Operations

### For "init [DIRECTORY]":

1. Create the directory structure (`raw/`, `wiki/`, `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`)
2. Copy `$SKILL_PATH/templates/schema.md` to `CLAUDE.md` (or `AGENTS.md`) as the starting schema
3. Create `wiki/index.md` from `$SKILL_PATH/templates/index.md`
4. Create `wiki/log.md` from `$SKILL_PATH/templates/log.md`
5. Create a starter `wiki/overview.md` summarizing the wiki's domain and purpose
6. Print next steps: add sources to `raw/`, then run `/llm-wiki ingest <file>`

### For "ingest <SOURCE>":

1. Read the source file from `raw/<SOURCE>`
2. Discuss key takeaways — what's new, what's important, what's surprising
3. Write a source summary page in `wiki/sources/<slug>.md`
4. Update `wiki/overview.md` if the source changes the big picture
5. Create or update entity pages (`wiki/entities/`) for key people, places, organizations
6. Create or update concept pages (`wiki/concepts/`) for key ideas and themes
7. Flag any contradictions with existing wiki content (note them on the affected pages)
8. Update `wiki/index.md` with all new/modified pages
9. Append an entry to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Source Title>`

A single source typically touches 5–15 wiki pages. Stay involved — read the summaries, check the updates, and guide the LLM on emphasis.

### For "query <QUESTION>":

1. Read `wiki/index.md` to identify the most relevant pages
2. Read the relevant pages in full
3. Synthesize an answer with citations to specific wiki pages
4. If the answer is a valuable synthesis (comparison, analysis, new connection), offer to file it as a new wiki page
5. If filed, update `wiki/index.md` and append to `wiki/log.md`

Good answers compound in the wiki just like ingested sources do.

### For "lint":

Scan the entire wiki and report on:

- **Contradictions**: Claims on different pages that conflict with each other
- **Stale content**: Pages superseded by newer ingested material
- **Orphan pages**: Pages with no inbound links from other wiki pages
- **Missing pages**: Important concepts mentioned across multiple pages but lacking their own page
- **Broken references**: Links to pages that don't exist
- **Data gaps**: Areas where a targeted web search or new source could meaningfully fill in missing knowledge

Suggest new questions to investigate and new sources to look for. Optionally fix issues in place.

### For "status":

Report:

- Total source count in `raw/`
- Total wiki page count
- Recent entries in `wiki/log.md` (last 10)
- Any obvious health issues (orphan pages, missing index entries)

---

## Index and Log

Two special files help navigate the wiki as it grows:

**wiki/index.md** — Content-oriented catalog. Every page listed with a link, one-line summary, and optional metadata (date added, source count). Organized by category. Updated on every ingest. The LLM reads this first when answering queries to find relevant pages.

**wiki/log.md** — Chronological, append-only record. Each entry starts with `## [YYYY-MM-DD] <operation> | <title>`. Parseable with standard tools:

```bash
# Last 5 operations
grep "^## \[" wiki/log.md | tail -5

# All ingests
grep "^## \[.*\] ingest" wiki/log.md

# All queries
grep "^## \[.*\] query" wiki/log.md
```

---

## Optional: Search with qmd

At small scale the index file is enough. As the wiki grows, add proper search using [qmd](https://github.com/tobi/qmd) — local hybrid BM25/vector search with an MCP server:

```bash
# Install
bun install -g @tobilu/qmd

# Add your wiki as a collection
qmd collection add ./wiki --name my-wiki
qmd embed

# Search from CLI
qmd query "how does X relate to Y" -c my-wiki

# Or use the MCP server for native tool access in Claude/OpenCode
```

---

## Tips

- **Obsidian Web Clipper**: Browser extension that converts web articles to clean markdown — ideal for quickly adding sources to `raw/`.
- **Obsidian graph view**: Best way to see the shape of your wiki — which pages are hubs, which are orphans.
- **Download images locally**: In Obsidian → Settings → Files and links, set attachment folder to `raw/assets/`. Use "Download attachments for current file" (bind to a hotkey) after clipping.
- **Marp slides**: Ask the LLM to generate a Marp slide deck from wiki content for presentations.
- **Version control**: The wiki is just a git repo of markdown files — you get history, branching, and collaboration for free.
- **Ingest one at a time**: Stay involved during ingestion. Read the summaries, check the updates, guide emphasis. You can batch-ingest with less supervision, but you'll get more value staying in the loop.
- **File good answers**: Valuable query results (comparisons, analyses, new connections) should be filed back as wiki pages. Your explorations compound the knowledge base.

---

## Use Cases

- **Personal**: Tracking goals, health, self-improvement — filing journal entries, articles, podcast notes, building a structured picture over time
- **Research**: Going deep on a topic — reading papers and incrementally building a comprehensive wiki with an evolving thesis
- **Reading a book**: Filing each chapter, building pages for characters, themes, plot threads. By the end you have a rich companion wiki.
- **Business/team**: Internal wiki fed by meeting transcripts, project documents, Slack threads — maintained by LLMs, reviewed by humans
- **Competitive analysis, due diligence, trip planning, course notes, hobby deep-dives** — anything where knowledge accumulates over time
