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

### Step 4: Generate Interview

Create structured questions with:
- Context for why you're asking
- Multiple choice options when appropriate
- Ability to defer decisions

### Step 5: Process Answers

After receiving answers:
- Update mental model
- Flag decisions that need documentation
- Identify remaining unknowns

## Question Patterns

### Architecture-Changing Questions

```text
"How should we handle [X]?"
Options:
a) [Approach that extends existing pattern]
b) [Approach that creates new abstraction]
c) [Approach that uses external service]

Impact: This determines whether we modify current auth flow or build new one.
```markdown

### Scope Clarification

```text
"Should [feature] support [variation]?"
Options:
a) Yes, in initial release
b) No, add later if needed
c) Not needed

Impact: Option A adds 2-3 more integration points to implement now.
```markdown

### Edge Case Discovery

```text
"What happens when [edge case]?"
Context: I found [situation] in the codebase that could trigger this.
Options:
a) [Graceful degradation]
b) [Hard error]
c) [Async recovery]
```markdown

## Example Usage

```text
User: "Add ability to export user data to CSV"

Agent: "Let me interview you about the requirements. I'll prioritize
questions that could change the implementation approach.

## Architecture-Changing Questions

**1. Where does the export process run?**

Context: Large exports could time out or block the web process.

Options:
a) Synchronous HTTP response (simple, but risky for large datasets)
b) Background job + email link when ready (more robust)
c) Streaming download (allows immediate start, handles large data)

Impact: Option B or C requires job queue infrastructure and S3/storage.


**2. What user data should be included?**

Context: User data exists across 5 tables (users, profiles, settings,
activity_logs, preferences).

Options:
a) Just core profile data (users + profiles tables)
b) Everything except activity logs (PII + preferences)
c) Everything including full activity history

Impact: Option C means 10-100x more data and potential performance issues.


## High-Impact Questions

**3. Who can trigger exports?**

Options:
a) Only the user themselves (for GDPR requests)
b) Admins can export any user
c) Users + admins with audit logging

Impact: Options B/C need admin UI + permission checks + audit trail.


**4. How long should exports be available?**

Context: We need to manage storage costs and data retention.

Options:
a) One-time download, then delete
b) Available for 7 days
c) Stored indefinitely

Impact: Options B/C need cleanup jobs + S3 lifecycle policies.


## Medium-Impact Questions

**5. Should exports include deleted/archived data?**

Options:
a) Active data only
b) Include deleted items marked as [Deleted]
c) Option to include or exclude

Impact: Changes query complexity and data volume.


**6. What CSV format?**

Options:
a) Simple flat structure (may lose relational data)
b) Multiple CSV files zipped together (preserves relations)
c) Single CSV with denormalized data (duplicates but simpler)

---

Take your time answering. Say 'skip' for any you want to defer.
Start with the architecture questions (1-2) as they impact everything else."
```markdown

## Interview Formats

### Multiple Choice
Best for: Clear options, technical decisions
```text
**Question**: [Clear question]
Options:
a) [Option with tradeoffs]
b) [Option with tradeoffs]
c) [Option with tradeoffs]

Impact: [What this changes]
```markdown

### Open-Ended
Best for: Design exploration, unknown constraints
```text
**Question**: [Open question about requirements]
Context: [Why this matters]
Things to consider: [Relevant factors]
```markdown

### Ranked Priority
Best for: Scope decisions
```text
**Question**: Rank these features by priority (1=must have, 5=nice to have)
- [ ] Feature A (impacts architecture)
- [ ] Feature B (can add later)
- [ ] Feature C (independent)
```markdown

## Best Practices

1. **Ask why you're asking**: Provide context for each question
2. **Show the impact**: Explain how answer changes implementation
3. **Offer options**: Give concrete choices, not open-ended "what do you think?"
4. **Prioritize ruthlessly**: Lead with architecture-changing questions
5. **Allow deferral**: Let user say "decide for me" or "skip for now"
6. **Limit to 5-8 questions**: Too many overwhelms; can always follow up
7. **Group by category**: Architecture, then scope, then details

## Integration with Other Skills

- **Before Interview**: Run blind-spot-pass to inform questions
- **During Interview**: Use embedded HTML questionnaires (Fable capability)
- **After Interview**: Document decisions in ADR or implementation notes
- **Follow-up**: Run quiz-me after implementation to verify understanding

## Success Criteria

A good spec interview:
- Uncovers at least 2-3 assumptions user didn't state
- Changes the implementation approach in at least one significant way
- Takes 5-15 minutes to complete
- Provides clear direction for next steps
- Avoids unnecessary questions (don't ask if you can infer)

## Advanced: Embedded HTML Interview

For Fable/advanced models, generate interactive questionnaires:

```html
<form id="spec-interview">
  <fieldset>
    <legend>Architecture-Changing Questions</legend>

    <div class="question">
      <h3>1. Where should the export process run?</h3>
      <p class="context">Large exports could time out or block web process.</p>

      <label>
        <input type="radio" name="q1" value="sync">
        Synchronous HTTP response
        <span class="impact">Simple, but risky for large datasets</span>
      </label>

      <label>
        <input type="radio" name="q1" value="async">
        Background job + email link
        <span class="impact">Requires job queue + storage</span>
      </label>

      <label>
        <input type="radio" name="q1" value="stream">
        Streaming download
        <span class="impact">Immediate start, handles large data</span>
      </label>
    </div>
  </fieldset>

  <button type="submit">Submit Answers</button>
</form>
```markdown

This allows rich, interactive spec gathering with better UX than plain text.
