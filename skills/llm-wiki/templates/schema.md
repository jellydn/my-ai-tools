# LLM Wiki — Schema

This file tells the LLM how this wiki is structured, what conventions to follow, and what to do during ingestion, querying, and maintenance. Edit it as your domain and workflow evolve.

## Domain

<!-- Describe what this wiki is about. What topic or domain are you building knowledge about? -->

**Domain:** [e.g., "AI research papers", "Personal health and fitness", "Project X competitive landscape"]

**Purpose:** [e.g., "Build a structured, compounding knowledge base on X so I can synthesize insights across sources without re-reading everything."]

**Owner:** [Your name or handle]

**Started:** [YYYY-MM-DD]

---

## Directory Structure

```
raw/           # Immutable source documents — add files here, never delete
  assets/      # Downloaded images referenced by sources
wiki/          # LLM-generated and maintained pages
  index.md     # Catalog of all pages (update on every ingest)
  log.md       # Append-only operation log
  overview.md  # Big-picture synthesis (update when fundamentals shift)
  entities/    # Pages for key people, organizations, places
  concepts/    # Pages for key ideas, themes, methodologies
  sources/     # One summary page per ingested source
CLAUDE.md or AGENTS.md  # This file (wiki schema)
```

---

## Page Conventions

### Frontmatter (optional but recommended)

Add YAML frontmatter to wiki pages to enable Dataview queries in Obsidian:

```yaml
---
title: "Page Title"
type: concept | entity | source | synthesis | overview
tags: [tag1, tag2]
sources: 3          # Number of sources that informed this page
updated: YYYY-MM-DD
---
```

### Cross-references

Always link to other wiki pages using Obsidian-style wiki links: `[[Page Name]]`

When a concept or entity is first mentioned on a page, link it. Don't repeat the link on subsequent mentions on the same page.

### Contradiction notes

When a new source contradicts an existing claim, add a note block to the relevant page:

```markdown
> [!NOTE] Contradiction (YYYY-MM-DD)
> Source [Source Title] (wiki/sources/source-slug.md) contradicts the claim above: [brief description]. See both sources for context.
```

---

## Ingest Workflow

When I give you a new source to ingest, follow this sequence:

1. **Read and summarize**: Read the source carefully. Share key takeaways with me and ask if there's anything to emphasize or de-emphasize.
2. **Source page**: Create `wiki/sources/<slug>.md` with a structured summary (see Source Page Template below).
3. **Overview**: Update `wiki/overview.md` if the source meaningfully changes the big picture.
4. **Entities**: Create or update pages in `wiki/entities/` for key people, organizations, and places mentioned.
5. **Concepts**: Create or update pages in `wiki/concepts/` for key ideas and themes.
6. **Contradiction check**: If any new information contradicts existing wiki content, add contradiction notes on the affected pages.
7. **Index**: Update `wiki/index.md` — add new pages and update summaries for changed pages.
8. **Log**: Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Source Title>`

Typical ingest touches 5–15 pages. Be thorough with cross-references.

### Source Page Template

```markdown
---
title: "<Source Title>"
type: source
tags: []
updated: YYYY-MM-DD
---

# <Source Title>

**Author(s):** [Author names]
**Published:** [Date or year]
**Type:** [Article | Paper | Book chapter | Podcast | Video | ...]
**Original:** [URL or file path in raw/]

## Summary

[2–4 paragraph summary of the source's main argument or content]

## Key Points

- [Key point 1]
- [Key point 2]
- [Key point 3]

## Entities Mentioned

- [[Entity 1]] — [brief note on their role in this source]
- [[Entity 2]] — [brief note]

## Concepts Introduced or Developed

- [[Concept 1]] — [how this source treats this concept]
- [[Concept 2]] — [how this source treats this concept]

## Integration with Wiki

[How does this source relate to, confirm, challenge, or extend what's already in the wiki?]

## Notable Quotes

> "[Direct quote from the source]" — [Author, page/timestamp]

## Open Questions

- [Question this source raises that isn't answered]
- [Thread to pull on]
```

---

## Query Workflow

When I ask a question:

1. Read `wiki/index.md` to identify the most relevant pages.
2. Read those pages in full.
3. Synthesize an answer with citations to specific wiki pages.
4. If the answer is a valuable synthesis (comparison table, analysis, discovered connection), ask if I'd like to file it as a new page.
5. If filing: create the page, update `wiki/index.md`, and append to `wiki/log.md`: `## [YYYY-MM-DD] query | <Question slug>`

---

## Lint Workflow

When I ask for a wiki health check:

1. Read all pages or use search to scan for issues.
2. Report:
   - **Contradictions**: Conflicting claims across pages
   - **Stale content**: Claims superseded by newer ingested material
   - **Orphan pages**: Pages with no inbound links
   - **Missing pages**: Concepts mentioned multiple times but lacking their own page
   - **Broken links**: `[[Page Name]]` links pointing to non-existent pages
   - **Data gaps**: Areas where a targeted source or web search could fill in missing knowledge
3. Suggest new questions to investigate and new sources to look for.
4. Ask before making any fixes — report first, then fix with permission.
5. Append to `wiki/log.md`: `## [YYYY-MM-DD] lint | health check`

---

## Style Preferences

<!-- Customize to your preferences -->

- **Voice**: Neutral, informative, encyclopedic — like Wikipedia
- **Page length**: Aim for focused pages (300–800 words). Split if a page grows too large.
- **Images**: Reference images from `raw/assets/` using relative paths: `![description](../raw/assets/image.png)`
- **Tables**: Use markdown tables for comparisons; Dataview for dynamic lists
- **Citations**: Always cite which source supports a claim, linking to `wiki/sources/<slug>`
