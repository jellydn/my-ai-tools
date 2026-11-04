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

### Boundary and state checks

Apply these checks only where the diff touches the relevant contract:

- **Input and domain model** — Validate external data at entry and carry that validated contract internally. Prefer
  existing types that exclude invalid combinations over repeated guards or casts that hide a broken model. Do not
  remove checks at a separate trust boundary or require a type-system redesign for clear, local code.
- **Retries and partial failure** — For operations that can be retried, check the outcome after a second run and after
  interruption between side effects. Flag duplicate effects or incomplete recovery against the operation's contract;
  do not assume that every operation must be idempotent.
- **Mutable ownership** — Before proposing locks or serialized execution, check whether independent actors can own
  separate state. When state must be shared, identify the writer and the mechanism that enforces safe updates. Preserve
  a correct existing transaction or synchronization model rather than forcing a single-writer rewrite.

Use existing complexity and duplication reports as evidence when available, not universal pass/fail thresholds.
Recommend a split or shared helper only when it improves cohesion or gives one business decision one owner; similar
syntax alone is not enough. Do not require Crapper, Dryer, or new tooling to complete a review.

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

## Attribution

Boundary and state checks and metric limits are adapted from Robert C. Martin's
[`ub-mode` — Architecture, Laziness Protocol, Crapper, and Dryer](https://github.com/unclebob/ub-mode/blob/3da62bf3fcfd2034de41f30d920d2739e566171f/SKILL.md).
These are scoped review checks, not a new implementation workflow or mandatory quality-tool suite. The upstream
notice is included here so it stays with this skill:

```text
MIT License

Copyright (c) 2026 Robert C. Martin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
