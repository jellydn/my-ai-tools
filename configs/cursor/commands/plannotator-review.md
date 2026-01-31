---
name: plannotator-review
description: Interactive code review using Plannotator for collaborative feedback
---

Perform an interactive code review that can be annotated and discussed using Plannotator.

## Review Process

1. **Analyze the changes**:
   - Run `git diff main` to see what changed
   - Understand the context and purpose
   - Identify key areas requiring review

2. **Review systematically**:
   - Check correctness and logic
   - Verify error handling
   - Assess test coverage
   - Review performance implications
   - Check security considerations
   - Evaluate maintainability

3. **Provide structured feedback**:
   - Group related feedback together
   - Prioritize issues (critical, important, nice-to-have)
   - Be specific about locations and concerns
   - Suggest concrete improvements
   - Highlight positive aspects

4. **Generate review output**:
   - Create a markdown document with:
     - Summary of changes
     - Critical issues (must fix)
     - Important issues (should fix)
     - Suggestions (nice to have)
     - Positive feedback
   - Include file paths and line numbers
   - Provide code examples for suggestions

## Review Focus

### Must Review
- Correctness of the implementation
- Security vulnerabilities
- Error handling
- Test coverage

### Should Review
- Code clarity and maintainability
- Performance considerations
- Edge cases
- Documentation

### Nice to Review
- Code style
- Potential optimizations
- Alternative approaches

## Output Format

```markdown
# Code Review

## Summary
[Brief overview of changes and overall assessment]

## Critical Issues (Must Fix Before Merge)
1. **[Issue Title]** - `file.ts:123`
   - Problem: [description]
   - Impact: [why it matters]
   - Solution: [how to fix]

## Important Issues (Should Fix Before Merge)
[Same format]

## Suggestions (Nice to Have)
[Same format]

## Positive Feedback
- [What was done well]
```

This review can be shared via Plannotator for collaborative discussion and annotation.
