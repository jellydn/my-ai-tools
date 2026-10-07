---
name: plannotator-setup-goal
description: "Turn ideas into executable goal packages with guided interviews and codebase analysis"
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when turning an idea or objective into a structured goal package with facts and plan
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: planning
  source: backnotprop/plannotator@1d9fe3f10fb34af0ef3ce9eed8db1c103a0b05cc
  source_path: apps/skills/extra/plannotator-setup-goal/SKILL.md
---

# Setup Goal

Turn an idea into a goal package at `goals/<slug>/` through structured discovery, user interview, and codebase exploration.

## Phases

### 1. Rearticulate

State back what the user wants in your own words. If the conversation already has rich context, summarize it. If the goal is bare or vague, do minimal shallow exploration of the codebase to ground your understanding. Keep it to 2-3 sentences. Wait for the user to confirm or correct before continuing.

Create `goals/<slug>/` once the slug is clear. Keep working JSON files and final documents there. JSON preserves provenance and iteration state; markdown is the human-readable authoritative goal package.

**Browser session patience:** After launching an interview or facts command, wait until the user submits, dismisses, or asks you to stop. Do not close, kill, restart, refresh, or open a second session because the UI is idle. If a rerun is needed, wait for the previous session to end, update its working JSON file, and launch from that file.

For a vague goal with interdependent decisions, suggest an optional one-at-a-time grilling pass. Run it when requested, with a recommended answer for each question. Fold its resolved decisions into the bundle below; skip the bundle if grilling fully resolves scope.

### 2. Interview Bundle

Build a compact bundle of questions that can derive every outcome fact. Infer answers already clear from the request, conversation, or codebase. Only ask where the user's judgment is needed. Prefer fewer, higher-leverage questions over exhaustive confirmation.

- What the feature/change is
- Who it's for
- What problem it solves
- What behavior changes
- What success looks like
- What's in and out of scope (The most important area to determine facts)
- What edge cases to consider
- What constraints or precedent apply

**If a question can be answered by exploring the codebase, explore the codebase instead of asking.**

Write `goals/<slug>/interview.json` before showing it to the user:

```json
{
  "stage": "interview",
  "title": "Short human-readable title",
  "goalSlug": "<slug>",
  "questions": [
    {
      "id": "scope",
      "prompt": "What should be in scope?",
      "description": "Optional clarification.",
      "answerMode": "multi-custom",
      "recommendedAnswer": "Your recommended answer.",
      "recommendedOptionIds": ["ui", "server"],
      "options": [
        { "id": "ui", "label": "UI" },
        { "id": "server", "label": "Server" }
      ],
      "required": true
    }
  ]
}
```

Supported `answerMode` values: `text`, `single`, `multi`, `custom`, `single-custom`, `multi-custom`.

Run as a monitored foreground process. Save the exact submitted JSON before continuing:

```bash
plannotator setup-goal interview goals/<slug>/interview.json --json > goals/<slug>/interview-result.json
```

Check the command's exit status and read the result. If dismissed, stop and report that the session was closed. Address questions, uncertainty, or skipped-question notes in chat before proceeding. A skipped question without a note is safe to omit only when non-blocking. For revisions, update `interview.json` and rerun after the previous session ends.

### 3. Fact Sheet

A fact is a simple description of each outcome of a goal. It should be easily testable and verifiable. A fact may describe the function of a specific feature or aspect of a system. A fact may determine specific UI and UX. Again, a fact is literally anything that can be tested and verified in automated or manual testing. Keep fact language simple. In a way, a fact sheet is a design spec, but less verbose & using language the human user can easily visualize & rationalize.

Prepare `goals/<slug>/facts-review.json` from the submitted interview. When revising, start from the existing review and result files, preserve accepted facts with `"accepted": true`, and retain their verification selections.

```json
{
  "stage": "facts",
  "title": "Short human-readable title",
  "goalSlug": "<slug>",
  "facts": [
    {
      "id": "fact-1",
      "text": "The accepted fact text.",
      "accepted": false,
      "removed": false,
      "recommendedAutomatedVerification": true,
      "automatedVerification": true
    }
  ]
}
```

Run as a monitored foreground process and save the exact result:

```bash
plannotator setup-goal facts goals/<slug>/facts-review.json --json > goals/<slug>/facts-result.json
```

Check the exit status. Apply accepted, edited, and removed facts directly. If dismissed, stop. Write `facts.md` as a flat list of accepted facts, one per line. Write `facts.meta.json` preserving each accepted fact's `id`, final `text`, `comment`, `recommendedAutomatedVerification`, and `automatedVerification` value.

### 4. Plan

Explore the codebase. Discover and validate implementation paths toward each fact. Trace through code, identify files and systems involved, surface risks and unknowns. Refine until you have a confident order of operations.

Facts with `automatedVerification: true` require concrete automated checks unless a blocker is documented.

Write `goals/<slug>/plan.md`:

- Solution approach (brief)
- Ordered steps with the files/systems each touches
- Verification for each step (concrete commands or checks)
- Risks or open questions worth flagging

Gate the plan with Plannotator:

```bash
plannotator annotate goals/<slug>/plan.md --gate
```

If denied, revise from feedback and re-gate until approved.

### 5. Goal Output

Write `goals/<slug>/goal.md`:

- The articulated goal (1-3 sentences)
- Reference to `facts.md` as the shared understanding
- Reference to `plan.md` as the execution plan
- Done condition

Tell the user:

```
Done! Launch a goal with `/goal goals/<slug>/goal.md`
```
