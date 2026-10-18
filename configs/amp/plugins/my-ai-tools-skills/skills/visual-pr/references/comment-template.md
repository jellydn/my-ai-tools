# Visual PR Comment Template

Copy the skeleton, fill each placeholder, and remove optional content that does not apply.

````markdown
{Optional link line — issue, ticket, plan, or ADR. Omit when there are no relevant links.}

## Why the change

{Exactly one sentence that explains the problem and what this change makes possible.}

## Special things to note

- {List one to three reviewer-relevant warnings, migrations, constraints, deliberate omissions, or surprising
  decisions. Use "None." when there are no special considerations.}

## Change outline

{Add one short sentence before each structural view. Use only the views that explain this pull request.}

```diff
{Show a focused change to an existing data shape, file tree, component tree, call path, or control flow.}
```

```typescript
{Alternatively, show a complete new data structure or contract in its real language.}
```
````

## Rules

- Keep each view under about 15 lines and the full comment easy to scan.
- Tell the story in the clearest order; do not follow a fixed category order.
- Use real names from the pull request diff.
- Do not include a view only to fill space.
