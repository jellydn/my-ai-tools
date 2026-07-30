---
name: interview-me
description: Clarify requirements through targeted questions to uncover unknown unknowns
hint: Use when feature requirements are vague or incomplete
---

# Interview Me

Activate the `spec-interview` skill to clarify requirements through targeted questions.

## Usage

```
/interview-me
```

This command triggers an interactive interview session that:
- Uncovers unknown unknowns in your feature specification
- Focuses on questions that would change architectural decisions
- Uses `ask_user_question` for focused, one-at-a-time questioning
- Takes 5-15 minutes to complete

## When to Use

- Feature requirements are vague or incomplete
- You have a general idea but lack specifics
- Stakeholders said "you know what I mean"
- The spec has obvious gaps
- Making assumptions that could be wrong

## What Happens

The agent will:
1. Analyze the feature request to identify gaps
2. Ask targeted questions one at a time using structured question UI
3. Present 2-4 options per question with clear tradeoffs
4. Follow up on answers that reveal new unknowns
5. Summarize decisions made and suggest next steps

## See Also

- `/blindspots` - Identify unknown unknowns before starting
- Skill documentation: `skills/spec-interview/SKILL.md`
