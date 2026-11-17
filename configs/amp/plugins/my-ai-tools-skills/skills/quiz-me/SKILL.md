---
name: "quiz-me"
description: "Verify understanding after implementation with targeted quizzes"
license: "MIT"
compatibility: "cline, claude, opencode, amp, codex, gemini, cursor, pi"
hint: "Use after completing complex work to verify understanding"
user-invocable: true
---

# Quiz Me

## When to Use

Use this skill **after implementation** when:
- You've completed a complex feature
- Need to write a PR description
- Want to verify understanding of changes
- About to present work to team
- Ensuring you stay "in the loop" with agent work

## What It Does

The agent generates a quiz about the implementation to verify your understanding. This helps you:
- Identify gaps in your knowledge
- Prepare for code review discussions
- Write better PR descriptions
- Stay engaged with increasingly capable agents

## How to Execute

### Step 1: Scope the Quiz

Determine what to test:
- Core architectural decisions
- Key implementation details
- Edge cases and error handling
- Integration points
- Trade-offs made

### Step 2: Generate Questions

Create questions across difficulty levels:

**Level 1 - Recall** (What):
- What did we implement?
- What files were changed?
- What are the main components?

**Level 2 - Understanding** (Why):
- Why did we choose this approach?
- Why not use [alternative]?
- What problem does this solve?

**Level 3 - Application** (How):
- How would you explain this to a reviewer?
- How does this integrate with existing code?
- How would you debug an issue here?

**Level 4 - Analysis** (Implications):
- What are the trade-offs?
- What could go wrong?
- What would you change if requirements changed?

### Step 3: Conduct Quiz (One Question at a Time)

Use the `ask_user_question` tool for each quiz question. Ask **one question at a time** — present it, wait for the answer, provide feedback, then move to the next. This makes the quiz feel like a conversation, not a test.

**Flow for each question:**

1. **Ask** using `ask_user_question` with the question and options
2. **Read the answer** the user selected or typed
3. **Provide feedback**: tell them the correct answer, explain why, link to code
4. **Track correctness** mentally (or note it)
5. **Proceed** to the next question

**Guidelines for using `ask_user_question`:**
- Set `header` to a short label (max 16 chars) like `"Architecture"`, `"Trade-offs"`, `"Edge Cases"`
- Write a clear `question` with context and any hint references
- Provide 2-4 concrete `options` — concise `label` (1-5 words) with descriptive `description`
- After the user answers, give the correct answer with explanation and code references

### Step 4: Review Answers

After each question response:
- **If correct**: Confirm and reinforce with additional context
- **If incorrect**: Gently correct, explain why, point to the relevant code/commit
- **If open-ended**: Evaluate against expected key points, fill in gaps

### Step 5: Summarise Results

After all questions are answered:
- Report overall understanding level
- Highlight strong areas
- Flag areas to review with code references
- Extract PR description material

## Question Templates (Mapped to ask_user_question)

### Multiple Choice — Architectural Decision

```
// Ask one at a time
ask_user_question(questions: [{
  header: "Architecture",
  question: "Why did we use GitHub App Installation flow instead of OAuth for this integration? (Hint: check auth/github/installation.ts for the decision)",
  options: [
    {
      label: "OAuth is deprecated",
      description: "GitHub still supports OAuth, so this isn't the reason"
    },
    {
      label: "Org-level access",
      description: "Installation flow provides org-level access — OAuth Apps can't access org repos"
    },
    {
      label: "Easier to implement",
      description: "Installation flow is actually more complex to set up than basic OAuth"
    }
  ]
}])

// After answer — provide feedback:
// "Correct! OAuth Apps can't access organization repositories, which is a GitHub limitation.
// Installation tokens authenticate as the app installation, giving org-level scope.
// See: auth/github/installation.ts:42-58"
```

### Fill in the Blank (using open-ended)

```
ask_user_question(questions: [{
  header: "Implementation",
  question: "What are the token lifespans in our GitHub auth? Fill in:\n- User OAuth tokens last: ______\n- Installation tokens last: ______\n- We cache installation tokens for: ______\n(Hint: check auth/github/token-cache.ts)",
  options: [
    {
      label: "6mo / 1hr / 55min",
      description: "User OAuth=6 months, Installation tokens=1 hour, Cache TTL=55 minutes (5 min buffer)"
    },
    {
      label: "1yr / 8hr / 7hr",
      description: "Incorrect — installation tokens only last 1 hour, we need a 5-minute buffer before expiry"
    },
    {
      label: "Permanent / 24hr / 23hr",
      description: "Incorrect — GitHub installation tokens have a 1-hour expiry, not 24 hours"
    }
  ]
}])
```

### Trade-off Analysis

```
ask_user_question(questions: [{
  header: "Trade-offs",
  question: "What's the main trade-off of our token caching strategy? We cache installation tokens with a 55-minute TTL.",
  options: [
    {
      label: "Speed vs staleness",
      description: "Correct — caching avoids rate limits (5000/hr) but a token could be stale for up to 5 minutes before natural expiry"
    },
    {
      label: "Memory vs latency",
      description: "The token cache is small (Redis, key pattern github:install:{id}:token) — memory isn't the constraint here"
    },
    {
      label: "Security vs simplicity",
      description: "Tokens are encrypted in Redis — security wasn't the trade-off driver for the TTL decision"
    }
  ]
}])
```

### Edge Case Question

```
ask_user_question(questions: [{
  header: "Edge Cases",
  question: "What happens when a user uninstalls the GitHub App? How does our system respond?",
  options: [
    {
      label: "Hard delete record",
      description: "We soft delete instead to preserve audit trail and cascading session cleanup"
    },
    {
      label: "Soft delete + audit",
      description: "Correct — we soft delete the installation record and cascade to invalidate all user sessions, preserving the audit trail"
    },
    {
      label: "Nothing, tokens work",
      description: "Incorrect — when uninstalled, tokens immediately stop working. We must clean up sessions"
    }
  ]
}])
```

### Code Reading Question

```
ask_user_question(questions: [{
  header: "Code Reading",
  question: "In the token refresh logic, why do we compare the cached token's expiry against a 55-minute threshold instead of the full 60 minutes?",
  options: [
    {
      label: "5-min safety buffer",
      description: "Correct! The 5-minute buffer prevents edge-case race conditions where a token expires between the cache check and the API call"
    },
    {
      label: "Rate limit overhead",
      description: "Rate limits are 5000/hr — the buffer isn't about rate limits, it's about preventing stale token usage"
    },
    {
      label: "Clock drift compensation",
      description: "While clock drift is a real concern, the primary reason is preventing token expiry during the request window"
    }
  ]
}])
```

## Complete Quiz Interaction Flow

For a typical 4-6 question quiz, the flow looks like:

```
1. Agent: "Let me quiz you on the GitHub OAuth implementation.
   I'll ask one question at a time and give feedback after each."

2. ask_user_question → Q1 (Architecture question)
   User answers
   Agent feedback: "Correct! ... See auth/github/installation.ts:42"

3. ask_user_question → Q2 (Implementation question)
   User answers
   Agent feedback: "Almost — the cache TTL is 55 minutes, not 50..."

4. ask_user_question → Q3 (Edge case question)
   User answers
   Agent feedback: "Right!..."

5. ask_user_question → Q4 (Trade-off question)
   User answers
   Agent feedback: "Good analysis..."

6. Agent: "Here's your summary:
   - Strong on architecture decisions
   - Review token caching details (auth/github/token-cache.ts)
   - PR description material from Q1 and Q4..."
```

## Best Practices

1. **One question per call**: Always use `ask_user_question` with a single-question array. Never batch questions.
2. **Give feedback immediately**: After each answer, confirm or correct with code references.
3. **Match complexity**: Quiz difficulty should match implementation complexity.
4. **Test reasoning**: Don't just ask "what", ask "why" and "how".
5. **Include context**: Reference specific code/commits for verification.
6. **Provide hints**: Include hints in the question text (not as tool hints, just inline).
7. **Wrong-answer options are educational**: Each incorrect option's description should explain why it's wrong.
8. **Limit to 4-7 questions**: Too many exhausts. Quality over quantity.

## Integration with Other Skills

- **After Implementation**: Always follow complex work with quiz
- **Before PR**: Use quiz results to write description
- **With Implementation Log**: Quiz questions based on logged decisions
- **For Documentation**: Questions reveal what needs better docs

## Success Criteria

A good quiz:
- Tests understanding at multiple levels (recall → analysis)
- Uses `ask_user_question` for focused, one-at-a-time questioning
- Provides immediate feedback with code references after each answer
- Reveals gaps in knowledge
- Helps you articulate decisions
- Prepares you for code review
- Takes 5-15 minutes to complete
- Results in better PR description
- Identifies documentation needs

## Common Pitfalls

- **Too easy**: Only testing recall ("what did we do?")
- **Too hard**: Testing minutiae not worth remembering
- **No feedback**: User doesn't learn from wrong answers
- **No context**: Questions without code references
- **Too long**: Exhausting instead of enlightening
- **Batching questions**: Asking multiple questions at once defeats the one-at-a-time flow

## Output Format

### Summary After Quiz

```markdown
# Quiz Results: [Feature Name]

## Strong Areas
- [Area 1]: Solid understanding of X
- [Area 2]: Clear grasp of Y

## Areas to Review
- [Area 1]: Unclear on Z, review [file.ts:123]
- [Area 2]: Missing context on W, see [commit abc123]

## Recommended Actions
- [ ] Review [specific code section]
- [ ] Read [specific documentation]
- [ ] Discuss [specific decision] with team

## PR Description Material
Based on your answers, include in PR:
- [Key point 1 from quiz]
- [Key point 2 from quiz]
- [Trade-off explanation from Qx]
```

The quiz becomes your PR description outline.
