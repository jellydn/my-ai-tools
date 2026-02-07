---
name: code-review-team
description: A team of specialized agents that work together to perform comprehensive code reviews, including quality assessment, security audit, and documentation review.
coordinator: review-coordinator
members:
  - code-quality-reviewer
  - security-auditor
  - docs-reviewer
workflow: parallel
---

# Code Review Team

This team performs comprehensive code reviews by coordinating multiple specialized agents.

## Team Members

### Review Coordinator (Main Agent)
Orchestrates the review process, distributes work to specialized agents, and synthesizes their feedback.

### Code Quality Reviewer
Focuses on:
- Code structure and organization
- Design patterns and best practices
- Performance implications
- Maintainability concerns

### Security Auditor
Focuses on:
- Security vulnerabilities
- Input validation
- Authentication/authorization
- Data exposure risks

### Documentation Reviewer
Focuses on:
- Documentation completeness
- Code comments quality
- API documentation
- README and guides

## Workflow

1. Coordinator analyzes the code changes
2. Distributes review tasks to specialized agents in parallel
3. Collects and synthesizes feedback
4. Presents comprehensive review report
