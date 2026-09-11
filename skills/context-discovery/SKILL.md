---
name: "context-discovery"
description: "Discover context using MCP tools — fff, sem, ctx, qmd, codebase-memory-mcp for codebase understanding"
license: "MIT"
compatibility: "cline, claude, opencode, amp, codex, gemini, cursor, pi"
hint: "Use before starting work to understand codebase context via available MCP tools"
user-invocable: true
---

# Context Discovery

## What

- Discover context using MCP tools — fff, sem, ctx, qmd, codebase-memory-mcp for codebase understanding

## Why

- This skill gives you a repeatable way to handle the task instead of improvising each time.

## How

- Follow the sections below for the concrete steps, commands, checks, and guardrails.

## When to Use

Use this skill **before and during implementation** when:
- Starting work on an unfamiliar module or feature
- The task involves multiple files or systems
- You need to understand existing patterns before coding
- Previous decisions or discussions may be relevant
- You want to avoid duplicating existing functionality

## What It Does

Leverages available MCP tools to proactively discover context about the codebase, existing patterns, decisions, and related work. Instead of relying solely on grep/read cycles, it uses purpose-built discovery tools.

## Discovery Workflow

### Step 1: File Discovery

Find the relevant files using `fff`:

```
fff auth                        # Find auth-related files
fff "*order*"                   # Find order-related files by pattern
fff config                      # Find config files
```

Scan the results to identify the module structure. `fff` returns frecency-ranked results — the files you access most appear first.

### Step 2: Pattern Discovery via `sem`

Once you know the relevant files, use `sem` to understand the code's history and structure:

```
sem blame path/to/file.ts        # See who changed each line and when
sem diff main..HEAD -- path/     # See what changed in this area
sem summary path/to/             # Get a summary of the module
```

`sem` provides entity-level diffs (function-level, not just file-level), making it easier to understand what actually changed.

### Step 3: Historical Context via `ctx`

Search past agent sessions for relevant context:

```
ctx search "auth implementation patterns"   # Past work on auth
ctx search "this module" path/to/module/    # Past discussions about this area
ctx search "decision" "why did we" path/    # Past decision-making
```

`ctx` indexes agent sessions, so you can find past discussions, decisions, and patterns the agent has already encountered.

### Step 4: Project Knowledge via `qmd`

Query durable project knowledge:

```
qmd query "What architecture decisions exist for X?"
qmd search "authentication patterns"
qmd get ADR-001        # Get a specific ADR
```

`qmd` stores project learnings, ADRs, conventions, and gotchas that persist across sessions.

### Step 5: Code Structure via `codebase-memory-mcp`

For large codebases, use the code graph to understand structure:

```
search_graph("OrderHandler")              # Find the function/class
trace_path("OrderHandler", calls)         # What does it call?
trace_path("OrderHandler", callers)       # What calls it?
get_code_snippet("package.OrderHandler")  # Read the source
get_architecture()                         # Project overview
```

### Step 6: External Context via `context7`

Look up documentation for libraries and frameworks:

```
context7 "express.js middleware API reference"
context7 "react useEffect cleanup pattern"
```

## Decision Tree

```
Where to look depends on what you need:
┌─────────────────────────────┬─────────────────┐
│ Need this                    │ Use this tool    │
├─────────────────────────────┼─────────────────┤
│ Find files by name/pattern  │ fff              │
│ Find what changed recently  │ sem diff         │
│ Find past agent discussions │ ctx search       │
│ Find ADRs / project memory  │ qmd query        │
│ Understand code structure   │ codebase-memory  │
│ Look up external docs       │ context7         │
│ Find related PRs            │ github MCP       │
└─────────────────────────────┴─────────────────┘
```

## When Not to Use Context Discovery

- **Simple tasks**: For well-known code, grep + read is faster
- **Already familiar**: If you know the codebase well, skip steps
- **External APIs**: Use `context7` or web search instead
- **Configuration-only changes**: Straightforward edits don't need deep context

## Integration with Other Skills

- Use after `/blindspots` to investigate surfaced unknowns
- Use before `implementation-logger` to establish baseline understanding
- Results from context discovery feed into implementation decisions
- Document surprising finds in implementation log

## Tips

- **Start broad, narrow fast**: Use `fff` to find candidates, then `sem`/`qmd` for depth
- **Prefer recent context**: `ctx` and `git log` give you recent work, which is most relevant
- **Limit discovery**: 2-5 minutes is usually enough
- **Document what you find**: Add significant discoveries to implementation log or qmd
