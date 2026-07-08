# /interview-me - Clarify Spec Gaps

## Usage

```
/interview-me [feature description]
```

Generates targeted questions to fill specification gaps, focusing on decisions that would change the implementation approach.

## What It Does

1. Analyzes the feature description
2. Identifies ambiguous requirements
3. Generates prioritized questions
4. Groups by impact (architecture → scope → details)
5. Provides context for why each question matters

## Examples

### Example 1: Basic Interview

```
/interview-me Add export user data feature
```

**Agent Response**:
```
Spec Interview: User Data Export

I'll ask questions prioritized by implementation impact.

## Architecture-Changing Questions

**1. Where should the export process run?**

Context: Large exports could time out or block the web process.

Options:
a) Synchronous HTTP response (simple, but risky for large datasets)
b) Background job + email link when ready (more robust)
c) Streaming download (immediate start, handles large data)

Impact: Options B or C require job queue infrastructure and storage.

---

**2. What user data should be included?**

Context: User data exists across 5 tables (users, profiles, settings,
activity_logs, preferences).

Options:
a) Just core profile data (users + profiles)
b) Everything except activity logs
c) Everything including full history

Impact: Option C means 10-100x more data and potential performance issues.

---

## High-Impact Questions

**3. Who can trigger exports?**

Options:
a) Only the user themselves (for GDPR requests)
b) Admins can export any user
c) Both, with audit logging

Impact: Options B/C need admin UI + permissions + audit trail.

---

**4. How long should exports be available?**

Options:
a) One-time download, then delete
b) Available for 7 days
c) Stored indefinitely

Impact: Options B/C need cleanup jobs + storage management.

---

## Medium-Impact Questions

**5. What format should we use?**

Options:
a) Single CSV (simple but loses relations)
b) Multiple CSVs in ZIP (preserves structure)
c) JSON (most complete, less user-friendly)

---

**6. Should exports include deleted/archived data?**

---

Take your time. Answer the architecture questions (1-2) first as they
affect everything else. Say "skip" for any you want to defer.
```

### Example 2: Interview with Context

```
/interview-me Add real-time collaboration to document editor

Context: We already have documents, users, and basic editing.
Looking to add Google Docs-style real-time collaboration.
```

**Agent Response**:
```
Spec Interview: Real-time Collaboration

## Architecture-Changing Questions

**1. What's the collaboration model?**

Context: This fundamentally changes data architecture.

Options:
a) Operational Transform (OT) - complex but proven (Google Docs)
b) Conflict-free Replicated Data Types (CRDT) - simpler, eventual consistency
c) Last-write-wins with locking - simple but poor UX

Impact: Option A requires OT library + server coordination.
Option B needs CRDT-compatible data structures.
Option C is simplest but frustrates users.

Recommendation: Start with C for MVP, plan migration to B?

---

**2. How many concurrent editors?**

Context: Affects infrastructure and algorithm complexity.

Options:
a) 2-5 users (small team collaboration)
b) 5-20 users (larger team meetings)
c) 20+ users (classroom/webinar style)

Impact: Higher concurrency needs better algorithms + infrastructure.

---

**3. Real-time transport?**

Context: How do clients communicate changes?

Options:
a) WebSockets (bidirectional, best for real-time)
b) Server-Sent Events (simpler, server to client only)
c) Polling (simplest, highest latency)

Impact: WebSocket requires WebSocket server + load balancing changes.

---

## High-Impact Questions

**4. What happens to offline edits?**

When user loses connection and keeps editing:
a) Discard on reconnect (data loss risk)
b) Merge on reconnect (needs conflict resolution)
c) Prevent editing while offline

Impact: Option B requires sophisticated merge logic.

---

**5. Should we show cursor positions?**

Options:
a) Just presence (who's here)
b) Cursor position + selection
c) Full presence awareness (cursor + active element + viewport)

Impact: More granular presence = more network traffic.

---

**6. What granularity of operations?**

Options:
a) Character-level (a, b, c typed separately)
b) Word-level (batched local edits)
c) Sentence-level (batch until Enter)

Impact: Finer granularity = more real-time, more network usage.

---

## Medium-Impact Questions

**7. Version history integration?**

Should collaborative edits:
a) Create version on each edit (verbose history)
b) Snapshot periodically (every 5min)
c) Manual save only

---

**8. Conflict UI?**

When conflicts occur, show:
a) Automatic resolution (silent)
b) Notification of conflict + resolution
c) Interactive conflict resolution UI

---

## Collaboration Features

**9. Which features?** (Check all that apply)

- [ ] User cursors
- [ ] User selections
- [ ] Comments/annotations
- [ ] Chat sidebar
- [ ] Presence indicators
- [ ] Edit attribution (who changed what)
- [ ] Access control (who can edit)
- [ ] Follow mode (view what collaborator sees)

Impact: Each adds complexity; prioritize for MVP?

---

Start with questions 1-3 (architecture) as they determine the
foundation. Questions 4-9 can be decided during implementation.

Which questions would you like to tackle first?
```

### Example 3: Follow-up Interview

```
User previously answered some questions, agent asks follow-ups:

/interview-me [continuing from previous discussion]

Follow-Up Questions: Real-time Collaboration

Based on your answers (WebSocket transport, 5-20 users, CRDT model):

**1. CRDT Library Choice?**

Context: You chose CRDT. Multiple libraries available:

Options:
a) Yjs (most mature, large bundle ~100KB)
b) Automerge (elegant, smaller, newer)
c) Roll our own (learning curve, maintenance)

Impact: Affects bundle size, learning curve, community support.

---

**2. Persistence Strategy?**

Context: CRDTs generate many small updates.

Options:
a) Store every CRDT update (complete history, large storage)
b) Snapshot periodically + recent updates (balance)
c) Compact CRDT state on save (lossy, smallest)

Impact: Affects storage costs and history fidelity.

---

[Continue with technical details now that architecture is clear]
```

## When to Use

- Feature request is vague or high-level
- Before starting complex implementation
- When assumptions need validation
- To uncover hidden requirements
- After blind spot analysis reveals unknowns

## Question Priority

### Architecture-Changing (Must answer first)
- Fundamentally different approaches
- Infrastructure requirements
- Data model changes

### High-Impact (Answer early)
- Significant implementation differences
- Scope decisions
- User-facing behavior

### Medium-Impact (Can decide during work)
- Specific module choices
- UI details
- Nice-to-have features

### Low-Impact (Can defer)
- Minor UX polish
- Non-functional preferences
- Future considerations

## Response Format

```markdown
## [Priority Level] Questions

**N. [Question]**

Context: [Why this matters]

Options:
a) [Option with tradeoffs]
b) [Option with tradeoffs]
c) [Option with tradeoffs]

Impact: [What this changes in implementation]

[Hint or recommendation if helpful]
```

## Integration

Works well with:
- `/blindspots` - Use interview to clarify unknowns found
- `/map-from` - Provide example after getting requirements
- Implementation logging - Document answers as decisions
- `/quiz-me` - Verify understanding of decisions later

## Advanced: Embedded HTML Interview

For Fable model, generates interactive HTML questionnaire:

```html
<form id="spec-interview" class="spec-interview">
  <fieldset>
    <legend>Architecture-Changing Questions</legend>
    <div class="question">
      <h3>1. Where should the export process run?</h3>
      <p class="context">Large exports could time out</p>
      <label><input type="radio" name="q1" value="sync"> Synchronous
        <span class="impact">Simple, risky for large data</span>
      </label>
      <label><input type="radio" name="q1" value="async"> Background job
        <span class="impact">Requires job queue</span>
      </label>
    </div>
  </fieldset>
  <button type="submit">Submit Answers</button>
</form>
```

## Tips

1. **Start broad**: Architecture first, details later
2. **Show options**: Concrete choices better than open-ended
3. **Explain impact**: Why the answer matters
4. **Allow deferral**: "Skip" or "decide for me" options
5. **Limit questions**: 5-8 per session, can follow up
6. **Provide context**: Why you're asking

## Related Commands

- `/blindspots` - Find unknowns before interview
- `/plan` - Create plan after requirements clear
- `/map-from` - Learn from example implementation
