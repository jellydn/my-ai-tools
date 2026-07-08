---
name: "capability-experiments"
description: "Experiment with model capabilities — HTML reports, embedded questionnaires, proactive research, multi-step reasoning"
license: "MIT"
compatibility: "claude, opencode, codex, gemini, cursor, pi"
hint: "Use for rich outputs, interactive forms, or exploring what next-gen models can do"
user-invocable: true
---

# Capability Experiments

## When to Use

Use this skill when:
- You need to present complex analysis in a readable format
- Interactive questionnaires would improve user interaction
- Exploring what's possible with next-generation model capabilities
- Multi-step reasoning is needed for architectural decisions
- You want to generate rich outputs (HTML, tables, interactive elements)
- Standard text output isn't sufficient for the task

## What It Does

Teaches techniques for leveraging advanced model capabilities — HTML generation, embedded interactive elements, proactive research, and multi-step reasoning. These patterns showcase what's newly possible with next-generation models and should be used freely.

## HTML Report Generation

Advanced models can generate rich, self-contained HTML. This is useful for:

### Analysis Reports

Generate structured HTML reports for complex findings:

```html
<!DOCTYPE html>
<html>
<head><style>
  body { font-family: system-ui; max-width: 800px; margin: 2rem auto; }
  .finding { border-left: 4px solid #e74c3c; padding: 1rem; margin: 1rem 0; }
  .finding.fixed { border-color: #2ecc71; }
  .severity { font-weight: 600; font-size: 0.85rem; }
</style></head>
<body>
  <h1>Code Review: PR #288</h1>
  <div class="finding">
    <span class="severity">🔴 Critical</span>
    <p>Hardcoded path in config...</p>
  </div>
  ...
</body></html>
```

Use HTML reports when:
- Comparing multiple options or decisions
- Presenting structured analysis with severity levels
- Creating interactive documentation
- Showing progress or status dashboards

### Embedded Questionnaires

Generate HTML questionnaires for spec interviews and quizzes:

```html
<form id="quiz">
  <div class="question">
    <p>1. Why did we choose GitHub App Installation flow?</p>
    <label><input type="radio" name="q1" value="a"> OAuth is deprecated</label>
    <label><input type="radio" name="q1" value="b"> Org-level access ✓</label>
  </div>
  <button type="button" onclick="checkAnswers()">Check</button>
</form>
<script>
function checkAnswers() {
  const correct = { q1: 'b', q2: 'c' };
  // ... scoring logic
}
</script>
```

These work well with Fable's ability to render and execute embedded HTML in responses.

### Decision Trees and Flowcharts

Use HTML/CSS to visualize decision processes:

```html
<div class="decision-tree">
  <div class="node root">Feature Change</div>
  <div class="branch">
    <div class="node">Familiar code?</div>
    <div class="yes">→ Standard pattern</div>
    <div class="no">→ /blindspots first</div>
  </div>
</div>
<style>
  .decision-tree { font-family: monospace; }
  .node { background: #f0f0f0; padding: 8px; margin: 4px; }
  .yes { color: #2ecc71; }
  .no { color: #e74c3c; }
</style>
```

## Proactive Research

Let the agent self-direct exploration rather than waiting for instructions:

### Pattern: "Investigate and Report"

Instead of asking the user what to look at, proactively scan the codebase:

```
1. Scan recent changes with `fff` and `git log`
2. Identify areas of concern or interest
3. Analyze patterns and potential issues
4. Report findings with actionable recommendations
```

### Pattern: "Unknown Unknowns Scan"

Before starting work, proactively look for gotchas:

```
1. Search git history for past bugs in related areas
2. Check qmd for relevant learnings
3. Search ctx for past agent discussions
4. Review existing ADRs for architectural context
5. Report findings before proposing implementation
```

### Pattern: "Capability Probe"

When faced with a complex task, probe what's possible:

```
1. Generate multiple approaches (not just the obvious one)
2. For each approach, assess feasibility
3. Consider approaches that were hard with older models
4. Recommend the best approach with rationale
```

## Multi-Step Reasoning

Break complex decisions into structured analysis:

### Step 1: Decompose the Problem

```markdown
## Analysis: Authentication Strategy

### Dimensions to Consider
1. Security requirements (OAuth 2.0, org-level access)
2. User experience (login flow, token management)
3. Maintenance (token refresh, error handling)
4. Scalability (multiple orgs, rate limits)

### Trade-offs
| Approach | Security | UX | Maintenance | Scalability |
|----------|----------|----|-------------|-------------|
| OAuth App | Medium | High | Low | Low |
| GitHub App | High | Medium | Medium | High |
| PAT | Low | Low | High | Medium |
```

### Step 2: Research and Validate

For each promising approach, gather evidence:

```markdown
## Research: GitHub App Installation

### Findings
- ✓ Org-level repo access (required)
- ✓ Webhook-based events
- ✓ Token caching supported
- ✗ More complex setup
- ✗ Requires webhook endpoint

### Past Context
- Previous PR #123 attempted similar approach
- ADR-005 discusses webhook infrastructure
- qmd has learnings about token caching
```

### Step 3: Recommend with Evidence

```markdown
## Recommendation

**Approach**: GitHub App Installation Flow

**Rationale**:
1. Required for org-level access (blocker for OAuth App)
2. Token caching addresses UX concerns
3. Existing webhook infrastructure from PR #123
4. ADR-005 confirms architectural fit

**Risks**:
- Webhook endpoint needs high availability
- Token refresh handling adds complexity
```

## Embedded Questionnaires

Interactive questionnaires improve spec interviews and knowledge verification:

### For Spec Interviews

Generate structured questions with HTML forms:

```html
<h3>Architecture Questions</h3>
<div class="question">
  <p><strong>Q1:</strong> Should we use a single shared database or per-tenant databases?</p>
  <details>
    <summary>Context</summary>
    <p>Current system uses shared DB. Per-tenant improves isolation but adds operational complexity.</p>
  </details>
  <textarea rows="2" placeholder="Your thinking..."></textarea>
</div>
```

### For Quizzes

Generate self-assessment quizzes:

```html
<h3>Implementation Quiz</h3>
<form id="quiz">
  <div class="q">
    <p>1. What caching strategy did we use for installation tokens?</p>
    <label><input type="radio" name="q1" value="r"> Redis with TTL</label>
    <label><input type="radio" name="q1" value="w"> In-memory cache</label>
  </div>
  <button type="button" onclick="grade()">Check Understanding</button>
</form>
```

## Proactive Patterns Summary

```
When to Use Each Pattern:

┌──────────────────────────────┬──────────────────────────┐
│ Situation                     │ Use Pattern              │
├──────────────────────────────┼──────────────────────────┤
│ Complex analysis to present  │ HTML report              │
│ Spec is vague                │ Embedded questionnaire   │
│ Large, unfamiliar codebase   │ Proactive research scan  │
│ Hard architectural decision  │ Multi-step reasoning     │
│ After implementation         │ Embedded quiz            │
│ Exploring options            │ Capability probe         │
└──────────────────────────────┴──────────────────────────┘
```

## Integration with Other Skills

- **spec-interview**: Use embedded questionnaires for richer interviews
- **quiz-me**: Generate HTML quizzes instead of plaintext
- **blindspot-pass**: Present findings as structured HTML reports
- **implementation-logger**: Generate HTML reports from logs
- **doc-search**: Search for past HTML report patterns

## Tips

- **Use HTML for structure, not flash**: Clean, readable HTML is better than complex designs
- **Self-contained is key**: Include styles inline so reports render anywhere
- **Interactive when useful**: Forms and buttons engage the user; plain text is fine for simple cases
- **Probe before committing**: Try one capability at a time, verify it works
- **Fall back gracefully**: If HTML doesn't render well, plaintext always works
- **Document what works**: New capabilities discovered should be added to this skill
