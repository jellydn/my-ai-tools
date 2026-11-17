---
name: implement-spec
description: "Implement a complete spec from its ticket graph, using isolated workers and one integration branch."
version: 1.0.0
author: my-ai-tools
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when a spec and dependency-aware tickets are ready for implementation.
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: implementation
  related_skills: [tdd, code-review, diagnosing-bugs, commit-atomic]
---

# Implement Spec

Build a complete specification from its dependency-aware ticket graph. The goal is a verified **integration branch**, not a collection of disconnected worker branches.

## When to Use

Use when:

- A reviewed spec exists.
- Tickets describe acceptance criteria and blocking relationships.
- The user wants the whole spec implemented rather than one ticket.

Do not use when the spec is still ambiguous, tickets are missing dependencies, or the user only wants one isolated ticket. Resolve those inputs first with the relevant planning skills.

## Contract

Before changing code, identify:

- The spec path or authoritative issue/plan.
- The ticket source and ticket status format.
- The dependency field used to define blocking relationships.
- The repository's test, lint, typecheck, and build commands.
- The base branch and the requested integration branch name.

If any of these cannot be found, stop and report the missing input instead of inventing a task graph.

## Workflow

### 1. Read the graph once

Read the full spec and all tickets. Extract a compact work map:

```text
Ticket       Blocks on       Files/area       Acceptance check       Status
TICKET-1     none            parser           unit test                ready
TICKET-2     TICKET-1        API              integration test          blocked
```

A ticket is on the **frontier** when every blocker is complete. Tickets are not a serial to-do list: independent frontier tickets may run concurrently.

### 2. Explore before parallel work

Use one exploration pass, or a dedicated exploration worker, to locate existing patterns, ownership boundaries, relevant tests, and external documentation. Save substantial findings in a temporary notes directory accessible to later workers. Do not make every implementer rediscover the repository.

### 3. Create the integration branch

Start from the latest remote base and create one integration branch. Keep it separate from the default branch. Do not open a PR unless the user asks, the issue tracker requires it to close tickets, or the workflow explicitly says to do so.

Check before proceeding:

```bash
git fetch origin <base>
git status --short --branch
git switch -c <integration-branch> origin/<base>
```

Preserve unrelated dirty work. Never reset or stash unfamiliar user changes implicitly.

### 4. Implement frontier tickets in isolated worktrees

For each ready ticket, dispatch one implementer in its own worktree and branch. Give it the complete ticket text, acceptance criteria, relevant context pointers, and exact verification commands. It must:

1. Confirm its worktree is based on the current integration branch.
2. Load and follow `tdd` for behavior changes.
3. Make the smallest change that satisfies the ticket.
4. Run focused tests, then the relevant broader checks.
5. Commit with a conventional message.
6. Return the commit SHA, files changed, and real command output.

A timeout, partial result, or claim without a commit SHA is not completion. Inspect the worktree and either recover it deliberately or discard it.

### 5. Merge completed work deliberately

Use a merger worker or the controller to merge one verified ticket at a time into the integration branch. Resolve conflicts using the spec and domain terminology, not by choosing whichever side is shorter. After every merge:

- Run focused checks for the merged ticket.
- Update the graph status.
- Recompute the frontier.
- Start newly unblocked tickets.

Do not merge two workers that modify the same contract without reviewing their combined diff first.

### 6. Full integration review

When every ticket is complete, load `code-review` and review the full integration branch against the original spec, not only the individual ticket descriptions. Fix findings in a focused worker, rerun the affected checks, and repeat the review until there are no unresolved critical or important findings.

For changes to agent skills or workflow instructions, include a learning check before declaring the ticket complete:

1. Preserve a representative input and the old output.
2. Record any human correction and the decision behind it.
3. Update the skill with a bounded decision rule rather than a slogan.
4. Rerun the same input and compare the new output with the correction.
5. Add a deterministic check when the lesson is mechanical.

### 7. Finish cleanly

Run the repository's complete validation suite. Confirm:

- Every ticket has a commit and a resolved status.
- The integration branch contains only intended changes.
- No worker worktrees remain.
- Generated files and temporary notes are not accidentally committed.
- The final branch and commit SHA are reported.

## Communication Rules

Keep worker prompts sparse. Prefer pointers to the spec, ticket, notes, and previous commits over copying large context into every prompt. The controller owns the graph and merge order; workers own their ticket implementation.

## Common Pitfalls

1. Treating tickets as a simple list and missing blockers.
2. Letting two workers silently redefine the same field, API, or file contract.
3. Reporting a timed-out worker as done.
4. Opening a PR before the integration branch has passed full review.
5. Running only unit tests and missing integration, type, or build failures.
6. Resetting a dirty worktree and destroying unrelated user work.
7. Asking workers to explore the whole repository instead of giving them focused pointers.

## Verification Checklist

- [ ] Spec and ticket graph were read and mapped.
- [ ] Base branch was refreshed and unrelated changes preserved.
- [ ] Each ticket ran in an isolated worktree.
- [ ] Each completed ticket has a verified commit SHA.
- [ ] Merges were checked as an integrated change.
- [ ] `code-review` passed on the complete branch.
- [ ] Skill/workflow changes were rerun against a stable input, when applicable.
- [ ] Mechanical lessons became deterministic checks where practical.
- [ ] Full repository validation passed, or blockers are reported exactly.
- [ ] Worker worktrees and temporary artifacts were cleaned up.
