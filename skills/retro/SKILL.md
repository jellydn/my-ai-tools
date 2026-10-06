---
name: retro
description: "Review a coding session and propose environment changes that prevent repeated agent mistakes."
version: 1.0.0
author: my-ai-tools
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when reviewing the current or past coding session to improve the repository and agent workflow.
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: retrospective
  related_skills: [code-review, diagnosing-bugs, accountable-engineering]
---

# Coding Session Retrospective

Inspect a real coding session and propose improvements to the **agent's environment**, not the product code. The goal is to make the next run easier to navigate and harder to get wrong.

This is human-in-the-loop. Present findings first; do not edit steering files, standards, hooks, CI, or skills until the user chooses which findings to apply.

## When to Use

Use when:

- A coding session was unusually long, confusing, or error-prone.
- The user asks to review recent agent sessions.
- A bug or repeated mistake suggests a missing guardrail.

The default target is the current session. If the user names a count or date range, inspect that exact range. If session history is unavailable, say so and review the repository evidence only.

## Sources

Read the real sources before judging:

- Session transcript and tool output, using session search when available.
- `AGENTS.md`, `CLAUDE.md`, `GLOSSARY.md`, `GLOSSARY-MAP.md`, and repository-local steering files.
- `CODING_STANDARDS.md` or equivalent review guidance.
- Existing `package.json`, `pyproject.toml`, `Makefile`, task runner, hooks, and CI workflows.
- The final diff, test output, and any unresolved warnings.

Do not infer a recurring mistake from one suspicious line. Tie every finding to concrete evidence from the session or repository.

## Review Lens

Rank findings by severity and expected leverage. For each, record:

```text
Finding: what happened
Evidence: session message, command, file, or diff
Prevention: the smallest environment change that would stop it
Owner: repo check | agent skill | steering file | tool | documentation
Cost: maintenance and false-positive risk
```

Inspect these categories:

### Navigation

Could the agent have found the right file, command, dependency, or domain term sooner? Prefer a short navigation pointer or a `GLOSSARY.md` entry over a large instruction block.

### Automated checks

Could a deterministic test, linter, typecheck, pre-commit hook, or CI job catch the mistake? Read the existing check commands first. If a check exists but is not wired or is silently broken, fix the wiring rather than inventing another check.

Mechanical mistakes belong in automation: banned APIs, required file locations, schema shape, generated-file drift, import rules, or formatting. A sentence saying “remember to do this” is not a guardrail.

### Coding standards

Reserve `CODING_STANDARDS.md` for judgement calls that automation cannot decide: cross-file consistency, design fit, naming in context, and review expectations. Put reviewer-facing rules there, not implementation trivia.

### Steering files

Remove no-op advice and move detailed procedures into skills or docs. Keep `AGENTS.md` and equivalent files short, navigational, and high-signal. Check for stale names such as `CONTEXT.md`; this repository uses `GLOSSARY.md` when that convention applies.

### Tool economy

Look for repeated broad searches, redundant reads, missing filters, or expensive calls that a narrow command could replace. Recommend a tool or script change only when it reduces repeated cost without hiding important output.

### Information access

Identify information the agent needed but could not access: logs, service status, readonly API data, fixtures, schemas, or architecture notes. Prefer safe readonly access and concise pointers.

## Output

Present the result in this order:

1. **Keep:** practices that worked and should remain.
2. **High priority:** concrete changes with a clear prevention payoff.
3. **Medium priority:** useful but non-blocking improvements.
4. **Do not change:** ideas that are speculative, noisy, or better handled manually.
5. **Smallest next step:** one or two changes the user can approve.

For each candidate, include the exact target path and a proposed patch shape. Do not silently apply it. When the user approves, make one focused change at a time, run the relevant checks, and report the result.

## Anti-patterns

- Do not rewrite product code as a retrospective fix.
- Do not turn every one-off failure into a new rule.
- Do not add prose where a deterministic check is possible.
- Do not grow `AGENTS.md` into a procedural manual.
- Do not automate retrospectives that edit the repository without human selection.
- Do not claim a session finding without pointing to evidence.

## Verification Checklist

- [ ] Correct session or date range was inspected.
- [ ] Findings are grounded in transcript, diff, or repository evidence.
- [ ] Existing checks and steering files were read before proposing new ones.
- [ ] Mechanical violations are assigned to deterministic automation.
- [ ] Judgement calls are assigned to review standards.
- [ ] Findings are ranked by severity and leverage.
- [ ] No environment change was applied without user approval.
