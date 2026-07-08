# Agent Memory — Implementation Notes Workflow

This file tells AI agents how to capture implementation notes while working in this repo.

## Goal

After any meaningful implementation, record the useful parts of the work so the next agent can pick up faster and avoid repeating mistakes.

This is for:

- what was learned
- issues or blockers encountered
- weird behavior or gotchas
- workaround decisions
- verification results

## When to write notes

Write notes when you:

- finish a feature or bug fix
- discover a project-specific behavior
- hit a blocker that took time to resolve
- find a workaround that is not obvious
- notice a gotcha that could waste time later
- change a contract, assumption, or convention

## What to capture

Keep it short and factual. Focus on the parts that matter later:

- **What changed**
- **What I learned**
- **Blockers / issues**
- **Weird stuff / gotchas**
- **Verification performed**
- **Next time / follow-up**

## Decision rule

Choose the right place for the note:

- **Durable project knowledge** that will matter later → record it in `qmd`
- **Temporary blocker or hint for the current session** → use `agentmemory`
- **Need to continue the same work later** → write a `/handoffs` plan, not a memory note
- **Nothing durable and nothing actionable** → do not record it

## Suggested note template

```md
# Implementation Notes: <feature-or-fix>

## What changed
- ...

## What I learned
- ...

## Blockers / issues
- ...

## Weird stuff / gotchas
- ...

## Verification
- ...

## Next time
- ...
```

## Style rules

- Be concise
- Prefer bullet points over long prose
- Record facts, not speculation
- Do not store secrets or sensitive data
- If the same issue looks repeatable, write it down as a durable note

## Good examples

- "The env var only works when passed as `\"$NAME\"`, not a literal string."
- "Vitest failed until dependencies were installed with `npm ci`."
- "This API needs a changeset before merge."
- "Browser verification is required for UI changes."

## Bad examples

- "Worked on stuff today"
- "There was some weird behavior"
- "Fixed a bunch of things"
- "Maybe the issue was X"

## Practical rule for agents

Before finishing a task, ask:

> What did I learn that would help the next person who touches this code?

If the answer is non-empty, write the note.
