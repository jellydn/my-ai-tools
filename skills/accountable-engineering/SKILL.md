---
name: "accountable-engineering"
description: "Guides disciplined AI-assisted engineering that avoids cognitive surrender and keeps humans accountable. Use for non-trivial implementation, architecture, security, or operational tasks."
license: "MIT"
compatibility: "cline, claude, opencode, amp, codex, gemini, cursor, pi"
hint: "Use for non-trivial AI-assisted implementation, architecture, security, or operational work"
user-invocable: true
---

# Accountable Engineering

Accountable engineering means using AI for leverage while keeping architectural, security, product, and operational
decisions understandable and human-owned. Follow this workflow for every non-trivial AI-assisted task. Apply each step
directly, loading a named companion skill only when its stated branch applies. This prevents cognitive surrender:
accepting generated decisions that nobody can independently explain.

## Workflow

### 1. Define behavior and constraints

Write the expected behavior, non-goals, security boundaries, performance expectations, and verification criteria before
editing code. Inspect repository evidence before asking questions. Ask only when different interpretations would change
behavior, scope, interfaces, security, or another material outcome.

**Complete when**: Each requested behavior has a checkable outcome, and every known constraint or non-goal is explicit.

### 2. Propose approach before implementation

Inspect the relevant code and propose the smallest approach that fits its existing boundaries. Include data flow,
integration points, failure handling, meaningful alternatives, and unanswered questions. For each significant step, name
the test, command, observable behavior, or diff property that will prove it is complete.

Load `blindspot-pass` for hidden gotchas, `spec-interview` when requirements can change the design, or
`context-discovery` when the behavior spans multiple modules or tools.

**Complete when**: The proposal accounts for every affected boundary and identifies every decision that could change
the implementation.

### 3. Review architecture and key decisions

Present material architectural, security, product, and rollout choices for review. State a recommendation and its
trade-offs for each unresolved choice.

**Complete when**: The user has approved or explicitly delegated every material choice, and the approach can be
explained without relying on generated code.

### 4. Implement in small steps

Implement the smallest independently verifiable increment, then inspect its diff and run its targeted check before
continuing. Account for every changed hunk as either required work or cleanup made necessary by that work. Remove
unrelated formatting, renaming, refactoring, and commentary changes.

Load `tdd` when behavior can be expressed as a failing test. Load `implementation-logger` when repository reality
forces a material deviation from the approved approach.

**Complete when**: Every increment is necessary for the stated behavior, reviewable in isolation, and covered by a
targeted check.

### 5. Run tests and inspect edge cases

Exercise the happy path, relevant failure paths, regressions, and operational concerns such as logs, metrics, and cost.
Record the exact commands and decisive results.

**Complete when**: Every verification criterion from step 1 has evidence, and all failures are fixed or reported as
explicit blockers.

### 6. Document what was learned

Capture material deviations, surprises, and reusable lessons. Read `~/.ai-tools/implementation-notes.md` when deciding
whether a lesson belongs in project knowledge, a handoff, or temporary session notes. Record only non-sensitive
rationale; omit secrets, credentials, customer data, and sensitive incident details.

Load `qmd-knowledge` only for a durable project lesson that future work should retrieve.

**Complete when**: Every material deviation is represented in the final explanation, and each durable lesson has one
appropriate destination.

### 7. Review the final result yourself

Read every changed file against the behavior and constraints from step 1. Resolve correctness, security, test,
documentation, and maintainability findings before declaring the task complete.

Load `slop` for AI-generated clutter, `code-review` for conventions and intent, `code-quality-review` for structural
risk, `pr-review` when review comments exist, `commit-atomic` when commits are requested, or `quiz-me` when the user
wants to verify their understanding.

**Complete when**: Every changed file is accounted for, every finding is resolved or disclosed, and verification is
current after the final edit.

### 8. Own deployment and maintenance

State the rollout owner, monitoring signals, rollback conditions, and follow-up obligations. If deployment is outside
the task, report these as remaining operational work.

Load `draft-pull-request` when the reviewed change needs a PR, while retaining deployment-specific checks and human
ownership.

**Complete when**: The responsible person can explain how the change will be released, observed, reversed, and
maintained—or those obligations are clearly handed off.

## Source

- [Addy Osmani — The Future of Software Engineering with AI](https://www.youtube.com/watch?v=2fyPnxKu8ZM)
