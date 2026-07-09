---
name: code-review
description: "Review the diff since a fixed point along two axes — Conventions (does the code follow this repo's coding standards and Tidy First practices?) and Intent (does the change do what it claims to do?). Runs both reviews in parallel sub-agents and reports them side by side. Use when you want to review a branch, a PR, work-in-progress changes, or ask to \"review since X\"."
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when reviewing a branch, PR, or work-in-progress changes against a fixed point — runs parallel Conventions (coding standards + clean code smells) and Intent sub-agents
user-invocable: true
metadata:
  audience: all
  workflow: code-quality
---

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Conventions** — does the code follow this repo's documented coding standards and Tidy First practices?
- **Intent** — does the change faithfully do what it claims to do?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

## Where This Fits

This skill owns **micro / local quality** — conventions, clarity, correctness of individual changes. It answers: "Is this change well-crafted and does it do what it says?"

For **macro / structural quality** (architecture, code judo, 1k-line limits, abstraction quality), use `code-quality-review`. That skill asks: "Is there a dramatically simpler structure hiding inside this implementation?"

| Concern | code-review (this skill) | code-quality-review |
|---|---|---|
| Clean code & naming | ✅ Primary owner | — |
| Tidy First practices | ✅ Primary owner | — |
| Behavior matches commits | ✅ Primary owner | — |
| Guard clauses, helper vars | ✅ Primary owner | — |
| File under 1k lines | Flag if crossed | Enforce strictly |
| Structural simplification | Note opportunities | Demand code judo |
| Abstraction quality | Flag thin wrappers | Delete unnecessary layers |

### Companion Skills

A complete quality pipeline, in order:

| Phase | Skills | Purpose |
|-------|--------|---------|
| 1. Discovery | `blindspot-pass`<br>`context-discovery` | Find unknown unknowns and gather project context before starting |
| 2. During implementation | `implementation-logger` | Track deviations from plan as you go |
| 3. Pre-review cleanup | `slop` | Remove AI-generated clutter so the review focuses on substance |
| 4. **Review** | **`code-review`** (this skill) | Conventions + Intent, side by side |
| 5. Structural audit | `code-quality-review` | Code judo, 1k-line limits, abstraction quality |
| 6. Fix & wrap | `pr-review` → `commit-atomic` → `quiz-me` | Apply fixes, group into logical commits, verify understanding |

Phases 1–4 are the core loop. Phase 5 is recommended when the change touches architecture or crosses file-size boundaries. Phase 6 depends on what the review finds.

## Process

### 1. Pin the fixed point

The user supplies a fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If they don't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside the sub-agents.

### 2. Gather context

**Conventions sources** — discover the repo's coding standards. Look for any of these common patterns:
- `CONVENTIONS.md`, `.planning/codebase/CONVENTIONS.md`, `STYLE_GUIDE.md` — language-specific idioms and patterns
- `CONTRIBUTING.md`, `best-practices.md`, `CODING_STANDARDS.md` — general development philosophy, guard clauses, helper expectations
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` — project-specific instructions for AI coding assistants
- Any file the repo advertises as its source of truth for code style — search `README.md` or `docs/` for mentions
- If the repo documents nothing, the clean code smell baseline below still applies

**Intent sources** — understand what the change claims to do:
- Read the commit messages from `git log <fixed-point>..HEAD --oneline`
- Read the PR description if one exists (from `gh pr view` or branch context)
- Check for an `.implementation-log.md` file that records conscious deviations from the plan — the review should **not** penalize a valid pivot
- If nothing is found, the Intent axis works from the commit messages alone

### 3. Spawn both sub-agents in parallel

Send a single message with two `Agent` tool calls. Use the `general-purpose` subagent for both.

**Conventions sub-agent prompt** — include:
- The full diff command and commit list.
- The list of conventions-source files you found in step 2, **plus the clean code smell baseline below** pasted in full — the sub-agent has no other access to it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented convention: cite the convention (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-convention breaches can be hard, but baseline smells are always judgement calls. A documented repo convention overrides the baseline. Skip anything tooling (linters, formatters, pre-commit hooks) already enforces. Under 400 words."

**Intent sub-agent prompt** — include:
- The diff command and commit list.
- The commit messages and any PR description or implementation log found.
- The brief: "Report: (a) claims in the commits/PR that are missing or partial in the diff; (b) behaviour in the diff that wasn't claimed (scope creep); (c) claimed behaviour that looks incorrectly implemented. Quote the commit message or PR line for each finding. If an `.implementation-log.md` records a conscious deviation, note it but don't flag it as a problem. Under 400 words."

### 4. Aggregate

Present the two reports under `## Conventions` and `## Intent` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the two axes are deliberately separate.

End with a one-line summary: total findings per axis, and the worst issue *within each axis* (if any). Don't pick a single winner across axes.

### 5. Suggest next steps

Based on findings, suggest which companion skill to run next:
- Structural concerns → `code-quality-review` (phase 5)
- AI-generated clutter → `slop`, then re-review (phase 3 — clean first, then re-review)
- Fixes needed → `pr-review` (phase 6)
- Commit hygiene → `commit-atomic` (phase 6)

## Clean Code Smell Baseline

These 10 smells apply on top of whatever the repo documents. Two rules bind them:
- **The repo overrides.** A documented convention always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic, never a hard violation — and skip anything tooling (linters, formatters, pre-commit hooks) already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

---

**1. Mysterious Name** — a function, variable, class, or type whose name doesn't reveal what it does or holds. If no honest short name comes, the design itself is murky.
→ Rename to something descriptive. Names are the first line of documentation — prefer clarity over brevity.

**2. Duplicated Code** — the same logic shape, conditional chain, or data transformation appears in more than one hunk or file in the change.
→ Extract the shared shape into a function, helper, or shared module. Call it from both places.

**3. Long Function** — a function or method that does too many things. The reader must hold multiple concerns in their head at once.
→ Extract logical sections into well-named helper functions. A function should do one thing and do it at a single level of abstraction.

**4. Deep Nesting** — code indented 3+ levels deep. Arrow code that forces the reader to track multiple branching paths simultaneously. The happy path is buried under validation.
→ Invert conditions and bail out early at the top: `if invalid → return`. The main logic stays at the outermost level.

**5. Magic Values** — unexplained literals, hardcoded numbers, strings, or paths that carry implicit meaning. The reader can't tell if `7` means days, retries, or something else.
→ Extract into a well-named constant or configuration value: `MAX_RETRY_ATTEMPTS = 7`.

**6. Speculative Generality** — abstraction, parameter, hook, or config added for a future need the spec doesn't have. "We might need this later" code.
→ Delete it and inline back to the simplest thing that works. Add the abstraction when the second caller arrives.

**7. Dead Code** — unused variables, functions, imports, or commented-out blocks left behind. These mislead readers and add maintenance cost.
→ Delete it. Version control remembers the history; the codebase should only carry what's active.

**8. Mutable Global State** — shared variables or singletons that any part of the program can change, making behavior order-dependent and hard to reason about.
→ Pass state explicitly via parameters, return values, or dependency injection. Restrict mutation to clear, documented boundaries.

**9. Wrong Layer** — logic that belongs in one module/package leaks into a different one. Feature code in a shared utility, or domain logic in an HTTP handler.
→ Move the code to the module that already owns that concept. The reader should find logic where they'd first look for it.

**10. Unclear Intent** — code that produces correct output but leaves the reader guessing *why* it works. The algorithm is visible but the reasoning is hidden.
→ Add a brief comment explaining *why* (not *what*) for non-obvious logic. Better yet, extract into a named function whose name carries the intent.

---

## Why Two Axes

A change can pass one axis and fail the other:

- Code that follows every convention but implements the wrong thing → **Conventions pass, Intent fail.**
- Code that does exactly what the commits claim but breaks clean code conventions → **Intent pass, Conventions fail.**

Reporting them separately stops one axis from masking the other. A diff full of well-structured code that doesn't actually deliver what the commit message promised is still a failing change.

## Output Format

```markdown
## Conventions

[Conventions sub-agent report — per file/hunk, citing the convention source]

## Intent

[Intent sub-agent report — per commit/PR claim, citing the source line]

---

**Summary**: N conventions findings (worst: <brief>), M intent findings (worst: <brief>)
**Suggested**: <next companion skill to run>
```

## Tone

Use positive, discovery-first guidance. Explain *why* a convention exists rather than just stating it was violated. This project follows the Fable Field Guide principle: context over constraints.

Instead of "Don't use global state":
→ "Passing state via parameters makes the data flow visible and the function easier to test in isolation."

Instead of "Variable name is unclear":
→ "A name like `userWithActiveSubscription` tells the reader what this holds without needing to trace its origin."

Prioritize high-impact logic and safety findings over low-value stylistic nits.
