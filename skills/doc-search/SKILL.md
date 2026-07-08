---
name: "doc-search"
description: "Find and navigate existing project documentation — ADRs, wiki entries, conventions, and knowledge base using ripgrep, qmd, fff, and ctx"
license: "MIT"
compatibility: "claude, opencode, codex, gemini, cursor, pi"
hint: "Use when you need to find existing documentation before writing new docs"
user-invocable: true
---

# Documentation Search

## When to Use

Use this skill when:
- Starting work on a feature that may have existing decisions or ADRs
- Need to understand project conventions or patterns
- Looking for past design discussions or trade-off analyses
- Want to find relevant wiki entries or knowledge base articles
- Need to understand how existing documentation is structured
- Planning to write documentation and want to match existing style

## What It Does

Helps you find and navigate existing project documentation using available tools (grep, qmd, fff, ctx). Documentation is often scattered across multiple locations — this skill provides a systematic approach to find what you need.

## Where Documentation Lives

This project stores documentation in several locations:

| Location | Content | Best For |
|----------|---------|----------|
| `docs/` | User-facing guides (quick-start, tutorials) | Getting started, feature guides |
| `ADRs` via `configs/adr/*` | Architecture Decision Records | Why decisions were made |
| `wiki/` | LLM wiki — entities, concepts, log | Knowledge base, cross-references |
| `MEMORY.md` | Durable project learnings and gotchas | Known issues, conventions |
| `skills/*/SKILL.md` | Agent skill definitions | Tool capabilities |
| `configs/*.md` | Tool-specific documentation | Per-tool behavior |
| `AGENTS.md` | Agent instructions and guidelines | Development workflow |
| qmd knowledge base | Indexed project knowledge | Searchable, AI-powered retrieval |

## How to Search

### Step 1: Find Relevant Documents

Use `fff` to locate documentation files:

```bash
fff "*.md" docs/         # All documentation files
fff "*adr*"              # Architecture Decision Records
fff "*auth*" docs/       # Auth-related documentation
fff "*wiki*"             # Wiki entries
```

Use `rg` (ripgrep) to search documentation content:

```bash
rg "decision" docs/                   # Find decisions in docs
rg "ADR-0" . --glob "*.md"           # Find ADR references
rg "rate.limiting" --glob "*.md"     # Find docs about rate limiting
```

### Step 2: Query Knowledge Base

Use `qmd` to search durable project knowledge:

```bash
qmd search "authentication decisions"     # Find related knowledge
qmd query "What architecture exists for X?"  # Get structured answers
qmd get ADR-001                           # Get a specific ADR
```

The qmd knowledge base indexes project learnings, ADRs, conventions, and gotchas that persist across agent sessions.

### Step 3: Search Past Sessions

Use `ctx` to find previous discussions about documentation:

```bash
ctx search "documentation" "decision"       # Past doc discussions
ctx search "ADR" "architecture" path/docs/  # Past ADR discussions
ctx search "convention" "pattern"            # Past convention discussions
```

### Step 4: Explore by Pattern

Project documentation follows consistent patterns:

**Architecture Decision Records (ADRs)**:
```bash
# Find all ADRs
ls -la docs/adr/
# Search ADR content
rg "decision" docs/adr/
```

**Wiki entries**:
```bash
# Browse wiki structure
ls -la wiki/wiki/entities/
ls -la wiki/wiki/concepts/
# Search wiki content
rg "topic" wiki/wiki/ --glob "*.md"
```

**Agent skills**:
```bash
# Find skill documentation
rg "what.*does" skills/*/SKILL.md
# Find skills by category
rg "compatibility:.*auth" skills/*/SKILL.md
```

## Understanding Documentation Style

Before writing new documentation, study existing examples:

1. **Pick a reference**: Find an existing doc on a similar topic
2. **Analyze structure**: Note heading levels, code blocks, tables
3. **Check tone**: Is it formal, conversational, or technical?
4. **Match conventions**: Use the same formatting patterns

Example: If you need to write an ADR, read an existing ADR first:

```bash
fff "*adr*.md"   # Find existing ADRs
cat docs/adr/001-some-decision.md  # Read as reference
```

## Documentation Discovery Workflow

```
Before writing:
1. Search existing docs for related content
2. Check qmd for existing knowledge
3. Search ctx for past discussions
4. Read existing docs for style reference

During writing:
5. Link to relevant ADRs and decisions
6. Reference existing conventions
7. Cross-link related documentation

After writing:
8. Add to wiki or qmd knowledge base
9. Reference from relevant agent instructions
10. Update docs-update skill if patterns changed
```

## Integration with Other Skills

- **docs-update**: Use doc-search first to find what exists before updating
- **context-discovery**: Documentation search is part of context discovery
- **implementation-logger**: Extract learnings into documentation
- **qmd-knowledge**: Add new knowledge to durable storage
- **llm-wiki**: Build and maintain wiki entries from findings

## Tips

- **Search before writing**: Always check if documentation already exists
- **Follow existing patterns**: Match the style of existing docs
- **Cross-link**: Reference ADRs, wiki entries, and related docs
- **Update qmd**: After finding useful documentation, index it in qmd
- **Use `rg` over `grep`**: ripgrep is faster and respects .gitignore
- **Check wiki/ first**: The LLM wiki is designed for discoverability
