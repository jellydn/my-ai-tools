# Skill Evals

Before publishing a new skill, define a few evals that prove it works.

## Why this matters

A skill can look correct in one demo and still fail on:

- near-miss prompts
- ambiguous wording
- edge cases the author did not test
- prompts that should *not* trigger the skill

If the skill is public, it should ship with a tiny eval set *and* a simple process for comparing the skill against a baseline.

## Minimal eval set

Start small. For each skill, write at least:

- 2-3 happy-path prompts that should trigger the skill
- 1-2 near-miss prompts that should not trigger it
- 1 edge-case prompt that exercises a boundary or failure mode

Vary the wording so the prompts feel like real users:

- casual vs precise
- short vs detailed
- vague vs specific
- with and without file paths or other context

## What to record

For each eval, capture:

- the prompt
- whether the skill should trigger
- the expected behavior in plain English
- any pass/fail notes from manual review

Store test cases in `evals/evals.json` inside the skill directory.

## Recommended structure

```markdown
skill-name/
├── SKILL.md
└── evals/
    └── evals.json
```

A test case should usually include:

- `prompt`: realistic user input
- `expected_output`: human-readable success criteria
- `files` (optional): input files the skill needs
- `assertions` (optional at first): concrete checks added after the first run

## Evaluation loop

A practical loop is:

1. Run the test case *with the skill*.
2. Run the same test case *without the skill* or against a previous version.
3. Compare the outputs, timing, and token cost.
4. Add assertions after you see the first round of results.
5. Review the outputs with a human.
6. Improve the skill, then rerun the evals in a new iteration.

## Assertions

Use assertions for things you can check objectively:

- output is valid JSON
- a file exists
- a chart has the expected number of bars
- a report includes a countable item

Avoid assertions that are too vague or too brittle:

- "the output is good"
- exact phrasing when wording can vary

If you need to check style, usefulness, or whether the output actually answers the user, keep that for human review.

## Human review

A human reviewer should look for things the assertions miss:

- technically correct but unhelpful outputs
- missing context
- poor organization
- flaky behavior across runs

Write feedback as something actionable, not just "looks bad".

## What to optimize

When iterating on a skill, look for three signals:

- failed assertions → missing steps or broken instructions
- consistent human complaints → weak structure or poor usefulness
- time/token outliers → unnecessary work that should be removed or bundled

If every run keeps recreating the same helper logic, consider moving it into the skill's `scripts/` directory.

## Review checklist

- [ ] The skill has eval prompts, not just a description
- [ ] At least one negative case is included
- [ ] The prompts are realistic and varied
- [ ] Expected outputs are specific enough to review manually
- [ ] The evals were run before the skill was published
- [ ] Any failures led to an update in the skill or its trigger rules
- [ ] The skill was compared against a baseline or previous version
