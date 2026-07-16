# Skill Evals

Before publishing a new skill, define a few evals that prove it works.

## Why this matters

A skill can sound correct in one demo and still fail on:

- near-miss prompts
- ambiguous wording
- edge cases the author did not test
- prompts that should *not* trigger the skill

If the skill is public, it should ship with a tiny eval set.

## Minimal eval set

For each skill, write at least:

- 3 happy-path prompts that should trigger the skill
- 1-2 near-miss prompts that should not trigger it
- 1 edge-case prompt that exercises a boundary or failure mode

## What to record

For each eval, capture:

- the prompt
- whether the skill should trigger
- the expected behavior in plain English
- any pass/fail notes from manual review

## Template

```markdown
# Skill evals: <skill-name>

## Goal

What capability is this skill supposed to provide?

## Happy path prompts

1. Prompt: ...
   Expected: ...

2. Prompt: ...
   Expected: ...

3. Prompt: ...
   Expected: ...

## Near-miss prompts

1. Prompt: ...
   Expected: skill should not trigger / should ask for clarification / should route elsewhere

## Edge cases

1. Prompt: ...
   Expected: ...

## Pass criteria

- The right skill triggers on the intended prompts
- The skill stays in scope on ambiguous prompts
- Failure cases are understood and documented
```

## Review checklist

- [ ] The skill has eval prompts, not just a description
- [ ] At least one negative case is included
- [ ] Expected outputs are specific enough to review manually
- [ ] The evals were run before the skill was published
- [ ] Any failures led to an update in the skill or its trigger rules
