# PR Body Template

Copy the skeleton, fill each placeholder, and delete every optional part that does not apply. Do not add sections
beyond this template unless the repository's own PR template requires them.

````markdown
{Optional link line — issue, ticket, plan, or ADR. Example: Closes #123 · [Plan](url). Omit when there are none.}

## What

{1-3 sentences or bullets: what this PR adds, changes, or removes, and where.}

## Why

{1-2 sentences: the concrete problem or need, and what becomes possible after merge.}

## How

{2-5 bullets: the approach, key decisions, and trade-offs.}

{Optional change outline: 1-3 small views from change-outline.md, each after one short sentence. Omit when the bullets
already make the shape clear.}

## Reviewer notes

- {Optional, 1-3 bullets: risks, migrations, breaking changes, deliberate omissions, or surprising decisions. Delete
  the whole section when there are none.}

## Validation

- `{command}` — {result}
- Manual: {what you checked} — {result}
````

## Rules

- **What** and **Why** are required and stay short. Put detail in **How**, not in **Why**.
- **What** names the surface area: components, commands, APIs, or configs that changed.
- **Why** states the concrete problem. Avoid vague phrases like "to improve things".
- **How** is about decisions and structure. Do not write a file-by-file changelog; the diff already shows that.
- **Reviewer notes** is for things a reviewer could miss or must act on. Do not repeat **How**.
- **Validation** lists only checks that you ran, with their result. If you ran none, write `- Not run.` and say why.
  Do not tick checklist items (yours or the repository's) for work you did not do.
- Keep the body short enough to read in about one minute. Link to plans or ADRs instead of copying them.
