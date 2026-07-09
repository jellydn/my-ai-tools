---
name: "quiz-me"
description: "Verify understanding after implementation with targeted quizzes"
license: "MIT"
compatibility: "claude, opencode, codex, gemini, cursor, pi"
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

### Step 3: Format Quiz

Present questions with:
- Clear question text
- Multiple choice options (when appropriate)
- Space for open-ended answers
- Reference to code for verification

### Step 4: Review Answers

After user responds:
- Validate answers
- Provide corrections if needed
- Link to specific code/commits
- Suggest areas for deeper review

## Question Templates

### Architectural Decision Questions

```
**Q1: Why did we use [Pattern/Approach]?**

Context: In [file/module], we implemented [feature] using [approach].

Options:
a) [Reason 1]
b) [Reason 2]
c) [Reason 3]

Hint: Look at the implementation log at [timestamp]
```

### Trade-off Questions

```
**Q2: What are the trade-offs of [Decision]?**

We chose to [decision]. What are the benefits and costs?

Benefits:
- [Your answer]

Costs:
- [Your answer]

Alternative we didn't choose: [Alternative]
Why we rejected it: [Your answer]
```

### Integration Questions

```
**Q3: How does [Component] integrate with [Existing System]?**

Describe the data flow and interaction points.

[Your answer]

Hint: Trace through [file.ts] starting at [function]
```

### Edge Case Questions

```
**Q4: What happens when [Edge Case]?**

We handle [edge case] in [location]. Describe:
1. How we detect it
2. How we handle it
3. What the user experiences

[Your answer]
```

### Debugging Questions

```
**Q5: If [Error] occurs, how would you debug it?**

Error: [Description]

Your debugging approach:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Where would you start looking? [Your answer]
```

## Example Usage

````
Agent: "Implementation complete! Let me quiz you to verify understanding.
This will help you write the PR description and prepare for review.

# Quiz: GitHub OAuth Integration

## Section 1: Core Decisions (Understanding)

**Q1: Why did we use GitHub App Installation flow instead of OAuth?**

Options:
a) OAuth is deprecated
b) Installation flow provides org-level access
c) Installation flow is easier to implement
d) Requirement from product spec

<details>
<summary>Hint</summary>
Check the implementation log decision #1
</details>

---

**Q2: What are the main differences in token lifespan?**

Fill in the blanks:
- User OAuth tokens last: ______
- Installation tokens last: ______
- We cache installation tokens for: ______

---

## Section 2: Implementation Details (Application)

**Q3: Describe the token caching strategy**

In your own words, explain:
1. Why we cache tokens
2. Where they're cached
3. What the TTL is and why
4. When cache is invalidated

---

**Q4: Draw the installation flow**

Sketch the sequence when a user installs the GitHub App:

User → GitHub → [Your answer] → [Your answer] → Database

Include: webhook call, token request, database update

---

## Section 3: Edge Cases (Analysis)

**Q5: What happens when a user uninstalls the GitHub App?**

a) Nothing, tokens keep working
b) Hard delete installation record
c) Soft delete, preserve audit trail
d) Cascade delete all user sessions

Explain why we chose this approach: [Your answer]

---

**Q6: What could go wrong with token caching?**

List 3 potential failure modes:
1. [Your answer]
2. [Your answer]
3. [Your answer]

How do we handle each? [Your answer]

---

## Section 4: Review Preparation (Application)

**Q7: How would you explain this PR to a reviewer?**

Write a 2-3 sentence summary:

[Your answer]

---

**Q8: What questions might a reviewer ask?**

List 3 questions a thorough reviewer would ask:
1. [Your answer]
2. [Your answer]
3. [Your answer]

Your answers:
1. [Your answer]
2. [Your answer]
3. [Your answer]

---

## Section 5: Trade-offs (Analysis)

**Q9: Installation Flow vs User OAuth - Trade-off Analysis**

Complete the table:

| Factor | Installation Flow | User OAuth |
|--------|------------------|------------|
| Org access | ✅ [Why?] | ❌ [Why?] |
| Setup complexity | [Your answer] | [Your answer] |
| Token lifespan | [Your answer] | [Your answer] |
| Rate limits | [Your answer] | [Your answer] |

Given our use case, why is Installation Flow better? [Your answer]

---

## Section 6: Future Considerations (Analysis)

**Q10: If we needed to support GitLab tomorrow, what would we reuse?**

Reusable patterns:
- [Your answer]

What would be different:
- [Your answer]

Where would you start: [Your answer]

---

# Answer Key

<details>
<summary>Expand to check your answers</summary>

**Q1**: b) Installation flow provides org-level access
- OAuth Apps can't access org repos (GitHub limitation)
- See: auth/github/installation.ts

**Q2**:
- User OAuth: 6 months
- Installation tokens: 1 hour
- Cache TTL: 55 minutes
- See: auth/github/token-cache.ts

**Q3**: Should mention:
- Why: Avoid rate limits (5000/hr token requests)
- Where: Redis with key pattern github:install:{id}:token
- TTL: 55 minutes (5min buffer before 1hr expiry)
- Invalidation: On installation deletion webhook
- See: Implementation log decision #2

[Continue for all questions...]
</details>

---

Take your time. You can check hints and code. The goal is understanding,
not memorization. Let me know when you're done!"
````

## Best Practices

1. **Match complexity**: Quiz difficulty should match implementation complexity
2. **Test reasoning**: Don't just ask "what", ask "why" and "how"
3. **Include context**: Reference specific code/commits for verification
4. **Provide hints**: Help without giving answers
5. **Review together**: Go through answers and fill gaps
6. **Extract value**: Use quiz prep to write PR description

## Integration with Other Skills

- **After Implementation**: Always follow complex work with quiz
- **Before PR**: Use quiz results to write description
- **With Implementation Log**: Quiz questions based on logged decisions
- **For Documentation**: Questions reveal what needs better docs

## Quiz Formats

### Multiple Choice
```
**Q: [Question]**

a) [Option A]
b) [Option B]
c) [Option C]
d) [Option D]

Explain your choice: [Answer]
```

### Fill in Blank
```
**Q: [Question]**

[Statement with _______] because [______].

Hint: [Hint if needed]
```

### Open-Ended
```
**Q: [Question]**

Your answer (3-4 sentences):

[Answer]
```

### Diagram/Sketch
```
**Q: Draw the data flow for [Feature]**

[Your diagram/pseudocode]

Key components to include: A, B, C
```

### Code Reading
```
**Q: What does this code do and why?**

```typescript
[Code snippet]
```

Explanation: [Your answer]

Alternative approach: [Your answer]

Why didn't we use alternative: [Your answer]
```

## Success Criteria

A good quiz:
- Tests understanding at multiple levels (recall → analysis)
- Reveals gaps in knowledge
- Helps you articulate decisions
- Prepares you for code review
- Takes 10-20 minutes to complete
- Results in better PR description
- Identifies documentation needs

## Common Pitfalls

- **Too easy**: Only testing recall ("what did we do?")
- **Too hard**: Testing minutiae not worth remembering
- **No answers**: User can't verify their understanding
- **No context**: Questions without code references
- **Too long**: Exhausting instead of enlightening

## Output Format

### During Quiz

```markdown
# Quiz: [Feature Name]

[Instructions and context]

## Section 1: [Category]
[Questions 1-3]

## Section 2: [Category]
[Questions 4-6]

...

# Answer Key
[Spoiler-protected answers with explanations]
```

### After Quiz - Knowledge Gaps

```markdown
# Quiz Results: [Feature Name]

**Score**: X/Y correct (understanding level: Good/Needs Review)

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
- [Trade-off explanation from Q5]
```

## Advanced: Embedded HTML Quiz

For Fable/advanced models, generate interactive quiz:

```html
<form id="implementation-quiz">
  <fieldset>
    <legend>Section 1: Core Decisions</legend>

    <div class="question">
      <h3>Q1: Why did we use GitHub App Installation flow?</h3>

      <label>
        <input type="radio" name="q1" value="a">
        OAuth is deprecated
      </label>

      <label>
        <input type="radio" name="q1" value="b">
        Installation flow provides org-level access
      </label>

      <label>
        <input type="radio" name="q1" value="c">
        Installation flow is easier
      </label>

      <details class="hint">
        <summary>Hint</summary>
        Check implementation log decision #1
      </details>
    </div>

    <div class="question">
      <h3>Q2: Token Lifespan</h3>
      <p>Fill in the blanks:</p>

      <label>
        User OAuth tokens last:
        <input type="text" name="q2a" placeholder="Duration">
      </label>

      <label>
        Installation tokens last:
        <input type="text" name="q2b" placeholder="Duration">
      </label>

      <label>
        We cache for:
        <input type="text" name="q2c" placeholder="Duration">
      </label>
    </div>
  </fieldset>

  <button type="submit">Check Answers</button>
</form>

<script>
  // Auto-grade and provide feedback
  document.getElementById('implementation-quiz').addEventListener('submit', (e) => {
    e.preventDefault();
    const answers = {
      q1: 'b',
      q2a: '6 months',
      q2b: '1 hour',
      q2c: '55 minutes'
    };
    // Grade and show feedback...
  });
</script>
```

This provides immediate feedback and better UX than plain text quizzes.

## Integration with PR Workflow

```bash
# After implementation
quiz-me [feature]

# Use results to write PR
# Include: key decisions, trade-offs, edge cases from quiz

# Example PR description structure from quiz:
# - Summary (from Q7)
# - Key Decisions (from Q1, Q9)
# - Trade-offs (from Q9)
# - Testing (from Q6)
# - Review Notes (from Q8)
```

The quiz becomes your PR description outline.
