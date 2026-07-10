---
name: "spec-interview"
description: "Clarify requirements through targeted questions — uncovers unknown unknowns in specs"
license: "MIT"
compatibility: "cline, claude, opencode, amp, codex, gemini, cursor, pi"
hint: "Use when feature requirements are vague or incomplete"
user-invocable: true
---

# Spec Interview

## When to Use

Use this skill when:
- Feature requirements are vague or incomplete
- You have a general idea but lack specifics
- Stakeholders said "you know what I mean"
- The spec has obvious gaps
- Making assumptions that could be wrong

## What It Does

The agent interviews you to **uncover unknown unknowns** in your feature specification, focusing on questions that would change architectural decisions.

## How to Execute

### Step 1: Review Initial Spec

Analyze what the user provided:
- Explicit requirements (what they said)
- Implicit requirements (what they assumed)
- Missing details
- Ambiguous areas

### Step 2: Categorize Gaps

Identify question categories:

**Scope & Boundaries**:
- What's in scope vs out of scope?
- Edge cases to handle?
- MVP vs future iterations?

**User Experience**:
- What happens when...?
- Error states and recovery?
- Loading and async states?

**Technical Decisions**:
- Performance requirements?
- Data consistency needs?
- Integration points?
- Security considerations?

**Architecture Impact**:
- Does this change existing patterns?
- New abstractions needed?
- Migration strategy for existing data?

### Step 3: Prioritize Questions

Sort by impact on implementation:

1. **Architecture-changing**: Would change core approach
2. **High-impact**: Significant implementation difference
3. **Medium-impact**: Affects specific modules
4. **Low-impact**: Nice to clarify but not blocking

### Step 4: Conduct Interview (One Question at a Time)

Use the `ask_user_question` tool for each question. Ask **one question at a time** — present it, wait for the answer, then proceed to the next. This keeps the interview focused and lets the user's answer to one question influence follow-ups.

**Guidelines for using `ask_user_question`:**
- Set `header` to a short category label (max 16 chars), e.g. `"Architecture"`, `"Scope"`, `"UX"`, `"Edge Cases"`
- Write a clear `question` string with context about why you're asking
- Provide 2-4 concrete `options` with concise `label` (1-5 words) and descriptive `description` explaining trade-offs
- After the user answers, acknowledge the choice and explain how it impacts the implementation before asking the next question
- Architecture-changing questions first, then high-impact, then medium-impact

**Example — single question call:**

```
ask_user_question(questions: [{
  header: "Architecture",
  question: "Where should the export process run? Large exports could time out or block the web process.",
  options: [
    {
      label: "Synchronous HTTP",
      description: "Simple, returns CSV directly in response — but risky for large datasets that could timeout"
    },
    {
      label: "Background job + email",
      description: "More robust: process asynchronously, email link when done — requires job queue and storage"
    },
    {
      label: "Streaming download",
      description: "Immediate start, handles large data, no queuing needed — but more complex to implement"
    }
  ]
}])
```

**When to use open-ended instead of multiple choice:**
- Exploring unknown design space where you can't enumerate options
- After multiple-choice answers that surface unexpected direction
- For rank/priority questions ("Which features are most important?")
- Set `options` with 2-4 broader paths, or use ask_user_question's single-select custom answer ("Type something") for truly open exploration

### Step 5: Process Answers

After each answer:
- Acknowledge the choice and its implications
- Update your mental model
- Decide if follow-up questions are needed (you can dig deeper before moving on)
- Identify decisions that need documentation

### Step 6: Summarize

After all questions are answered:
- Summarize the key architectural decisions made
- Flag decisions the user deferred ("decide for me" or "skip")
- Outline next steps with confidence level

## Question Patterns

These show how to translate each pattern into an `ask_user_question` call.

### Architecture-Changing

```
// One question at a time
ask_user_question(questions: [{
  header: "Architecture",
  question: "How should we handle authentication for this feature? This determines whether we modify the current auth flow or build a new one.",
  options: [
    {
      label: "Extend existing auth",
      description: "Adds to current flow — simpler but may create coupling"
    },
    {
      label: "New auth abstraction",
      description: "Clean separation — more upfront work, more flexible long-term"
    },
    {
      label: "External auth service",
      description: "Offload entirely — fastest to build, adds third-party dependency"
    }
  ]
}])
```

### Scope Clarification

```
ask_user_question(questions: [{
  header: "Scope",
  question: "Should this feature support multiple organizations from the start?",
  options: [
    {
      label: "Yes, initial release",
      description: "Adds 2-3 more integration points and multi-tenant data isolation now"
    },
    {
      label: "Later if needed",
      description: "Simpler initial build, but may require data migration later"
    },
    {
      label: "Not needed at all",
      description: "Single-tenant only — keeps everything simple"
    }
  ]
}])
```

### Edge Case Discovery

```
ask_user_question(questions: [{
  header: "Edge Cases",
  question: "What should happen when the external API is down during export? The codebase has no retry logic for this service yet.",
  options: [
    {
      label: "Graceful degradation",
      description: "Show partial results with a warning banner — best UX when service is degraded"
    },
    {
      label: "Hard error to user",
      description: "Show clear error message asking them to retry — simplest implementation"
    },
    {
      label: "Auto-retry with queue",
      description: "Queue the request and retry — most robust but requires background job infrastructure"
    }
  ]
}])
```

## Interview Flow: Best Practices

1. **One question per call**: Use `ask_user_question` with a single-question array each time. This keeps the interaction focused and lets answers inform the next question.
2. **Provide context**: Always explain why you're asking and how the answer affects implementation.
3. **Show trade-offs**: Each option's description should explain the trade-off, not just restate the label.
4. **Lead with impact**: Architecture-changing questions first, then high-impact, then medium-impact.
5. **Allow deferral**: The "Chat about this" option and custom answer ("Type something") let users skip or elaborate. Honour "skip" gracefully.
6. **Limit to 4-7 questions**: Too many overwhelms. You can always follow up if needed. With one-at-a-time asking, the user stays engaged.
7. **Acknowledge each answer**: Before asking the next question, briefly restate what was decided and its implications.

## Answer Processing

After each answer via `ask_user_question`:
1. **Acknowledge**: "Thanks — going with [option] means we'll [impact]. That makes sense because [reason]."
2. **Update plan**: Adjust your mental model of the implementation.
3. **Decide follow-up**: Did the answer reveal a new unknown? Ask a follow-up question now, or note it for later.
4. **Move on**: Ask the next prioritized question or summarise if done.

After all questions:
- Present a summary of decisions made
- Flag any decisions deferred
- Suggest next steps

## Integration with Other Skills

- **Before Interview**: Run blind-spot-pass to inform questions
- **After Interview**: Document decisions in ADR or implementation notes
- **Follow-up**: Run quiz-me after implementation to verify understanding

## Success Criteria

A good spec interview:
- Uncovers at least 2-3 assumptions user didn't state
- Changes the implementation approach in at least one significant way
- Uses `ask_user_question` for focused, one-at-a-time questioning
- Takes 5-15 minutes to complete
- Provides clear direction for next steps
- Avoids unnecessary questions (don't ask if you can infer)
