---
name: pr
description: "Write a fast-to-review pull request body with a visual summary, before/after evidence, and merge-risk analysis."
version: 1.0.0
author: my-ai-tools
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when preparing or updating a pull request for human review.
metadata:
  audience: all
  workflow: git
  related_skills: [draft-pull-request, code-review, commit-atomic]
---

# Reviewable Pull Request

Prepare a pull request body that lets a human understand the change quickly, verify that it works, and spend review time where risk is highest. This skill improves the review narrative; it does not replace code review or validation.

## When to Use

Use when:

- A branch has a meaningful diff and needs a new or updated PR body.
- The reviewer needs the shape of a refactor, flow, or integration explained.
- The change has evidence and rollback implications worth making explicit.

Load `draft-pull-request` for repository preflight, branch handling, and `gh` publication rules. Reuse an existing PR instead of opening a duplicate.

## Required Inputs

Before writing, gather:

- The authoritative spec, issue, plan, or ticket graph.
- The complete diff against the PR base.
- The actual commands run and their output.
- Any screenshots, logs, or before/after behavior available.
- The current PR template and existing reviewer notes.

Never claim a test, screenshot, or manual check that was not actually run.

## Body Template

Use these sections unless the repository's template requires equivalent headings:

```markdown
## Summary

<the smallest visual that explains the change>

## Evidence

- **Before:** <failing test, old output, old screenshot, or baseline behavior>
- **After:** <passing test, new output, new screenshot, or verified behavior>

## Merge Danger

**Door:** <two-way or one-way>

**Blast Radius:** <one-word scope>

<what can break, what rollback restores, and where careful review matters>
```

### Summary: show the shape

Choose one small visual, not a prose dump:

- **Call tree** for runtime control flow.
- **Component tree** for UI changes.
- **File tree** for ownership or layout changes.
- **Diff sketch** for a focused behavior change.
- **Mermaid sequence or flow** for cross-component data movement.
- **Pseudocode** for an algorithm or state transition.

Example:

```text
implement-spec
  read spec + ticket graph
  frontier -> isolated workers
    ticket implementation + tests
  merge verified commits
  code-review integration branch
```

Keep only the files, calls, states, and boundaries needed to understand the change. Use the domain terms from `GLOSSARY.md` when the repository has one.

### Evidence: before and after

Evidence should be execution-based whenever possible:

```markdown
- **Before:** `pytest tests/test_export.py::test_csv` — failed: endpoint missing
- **After:** `pytest tests/test_export.py::test_csv` — passed
- **Full check:** `pytest -q` — 142 passed
```

For visual work, prefer screenshots. For bug fixes, show the original reproduction and the regression check. If there is no meaningful before state, say so and provide the strongest available verification instead of manufacturing one.

### Merge Danger: risk, not drama

Classify the door:

- **Two-way:** reverting the commit restores the prior state without external cleanup.
- **One-way:** it changes external state, data, contracts, migrations, messages, or other effects that a revert cannot fully undo.

Name the blast radius plainly: `single-command`, `one-service`, `shared-library`, `data`, `all-users`, or another accurate scope. Mention rollback steps, migration order, compatibility concerns, and the most important review seam.

## Publication

After writing and checking the body:

1. Use the `draft-pull-request` workflow to create or update the PR with `--body-file`.
2. Verify the returned PR URL, title, base, head, and draft state.
3. Report the exact validation results and any environment-only blockers.

## Common Pitfalls

1. Writing a paragraph where a small diagram would make the change obvious.
2. Listing tests without showing the relevant before/after result.
3. Saying “low risk” without identifying reversibility or blast radius.
4. Treating a revert as complete rollback for a migration or external side effect.
5. Describing intended behavior instead of the behavior actually verified.
6. Replacing repository-specific PR headings or checked items without reading its template.
7. Opening a second PR for a branch that already has one.

## Verification Checklist

- [ ] Spec, issue, or ticket source was read.
- [ ] Diff was reviewed against the correct base.
- [ ] Summary contains one useful visual or diff sketch.
- [ ] Evidence includes real before/after results, or the limitation is explicit.
- [ ] Door type and blast radius are named.
- [ ] Rollback and compatibility concerns are documented.
- [ ] Repository PR template and existing reviewer notes were preserved.
- [ ] PR metadata and URL were verified after publication.
