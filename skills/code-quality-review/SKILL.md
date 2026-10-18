---
name: code-quality-review
description: "Audit a diff for structural maintainability and unnecessary complexity."
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use for a deep review of maintainability, abstraction quality, and avoidable complexity
user-invocable: true
disable-model-invocation: true
metadata:
---

# Code Quality Review

Review the current branch diff for structural quality. Preserve behavior, but actively look for a simpler design that
deletes concepts, branches, wrappers, or layers instead of moving complexity around.

## Review Boundaries

- Review only the changed code and the surrounding code needed to judge it.
- Treat repository conventions and existing canonical helpers as the source of truth.
- Skip formatter and linter findings that automation already reports.
- Prefer a small set of high-confidence structural findings over cosmetic notes.
- Do not propose a large refactor unless its benefit is clear and it stays within the change's ownership boundary.

## Review Criteria

Check each meaningful change for:

1. **Simpler structure** — Can a different model or ownership boundary remove branches, modes, helpers, or layers?
2. **Cohesive control flow** — Flag scattered special cases, repeated conditions, deep nesting, and mixed responsibilities.
3. **Useful abstractions** — Flag thin wrappers, generic magic, speculative extension points, and duplicate helpers.
4. **Clean boundaries** — Keep feature logic in its canonical module and make types and invariants explicit.
5. **Reasonable file size** — Treat a change that pushes a file above 1,000 lines as a decomposition signal unless the
   file has a clear structural reason to stay whole.
6. **Sound orchestration** — Flag unnecessarily sequential independent work and updates that can leave related state
   partially applied when a clearer atomic design exists.
7. **Legibility** — Prefer direct, boring code with clear names and comments that explain only non-obvious reasons.

## Finding Bar

Report a finding only when you can name:

- the file and relevant hunk;
- the concrete maintenance cost or failure mode;
- the smallest practical remedy; and
- why the remedy is better than the current design.

Treat these as blockers unless the implementation has a clear justification:

- a structural regression or avoidable boundary leak;
- a file newly crossing 1,000 lines without useful decomposition;
- ad hoc branching added to an already busy flow;
- duplicated logic where a canonical helper exists;
- an abstraction, cast, or optional contract that adds indirection without clarity; or
- a clear simplification that removes substantial incidental complexity.

Do not block on personal style, hypothetical future needs, or a rewrite that is only differently complex.

## Output

Order findings by impact:

1. Structural regressions and simpler designs
2. Control-flow, boundary, abstraction, and type problems
3. File-size, modularity, and legibility concerns

For each finding, use:

```text
[severity] file:line — finding
Impact: concrete cost or risk
Fix: smallest practical remedy
```

End with `APPROVE` when no blocking finding remains, or `CHANGES REQUESTED` with the blocker count. Be direct and
respectful.
