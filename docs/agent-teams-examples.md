# Agent Teams Usage Examples

This guide provides practical examples of using Claude Code Agent Teams for common development workflows.

## Example 1: Feature Development with Team Coordination

When building a new feature, use the `feature-team-coordinator` to orchestrate the entire workflow:

```markdown
@feature-team-coordinator

Implement a new user authentication endpoint:
- POST /api/auth/login
- Accept email and password
- Return JWT token
- Include proper error handling

Requirements:
- Validate inputs
- Hash password comparison
- Rate limiting
- Comprehensive tests
- API documentation
```

The coordinator will:
1. Implement the endpoint
2. Delegate to `code-reviewer` for security review
3. Delegate to `test-generator` for test coverage
4. Delegate to `documentation-writer` for API docs
5. Use `ai-slop-remover` for final polish

## Example 2: Code Review Only

For quick code reviews without full feature development:

```markdown
@code-reviewer

Review the authentication middleware in:
- src/middleware/auth.ts
- src/utils/jwt.ts

Focus on:
- Security vulnerabilities
- Error handling completeness
- Token validation logic
```

## Example 3: Test Generation

Generate tests for existing code:

```markdown
@test-generator

Create comprehensive tests for the UserService class in src/services/UserService.ts

Include:
- Unit tests for all public methods
- Edge cases (null/undefined inputs)
- Error scenarios
- Integration tests with database

Match the existing test patterns in tests/services/
```

## Example 4: Documentation Writing

Create or update documentation:

```markdown
@documentation-writer

Document the new payment processing API:
- POST /api/payments/process
- GET /api/payments/:id
- POST /api/payments/refund

Include:
- Request/response examples
- Error responses
- Authentication requirements
- Rate limiting info
```

## Example 5: Clean Up AI Patterns

After making changes, clean up AI-generated patterns:

```markdown
@ai-slop-remover

Review all changes in the current branch and remove:
- Unnecessary comments
- Excessive defensive checks
- Over-engineered abstractions

Focus on making code match the existing codebase style.
```

## Example 6: Sequential Workflow

Chain agents for a complete workflow:

```markdown
Step 1: Implement feature
[Make your code changes]

Step 2: Generate tests
@test-generator
Create tests for the new feature in src/features/export.ts

Step 3: Review code
@code-reviewer
Review src/features/export.ts for quality and security

Step 4: Clean up
@ai-slop-remover
Clean up the export feature code

Step 5: Document
@documentation-writer
Document the export feature API
```

## Example 7: Parallel Review

Get multiple perspectives simultaneously:

```markdown
I've implemented a new caching layer. I need parallel reviews:

@code-reviewer
Review src/cache/RedisCache.ts for:
- Performance implications
- Error handling
- Resource cleanup

@test-generator
Create tests for src/cache/RedisCache.ts covering:
- Cache hits/misses
- Connection failures
- TTL expiration

@documentation-writer
Document the caching API in docs/caching.md
```

## Tips for Effective Team Usage

### Be Specific
❌ "Review this code"
✅ "Review auth.ts focusing on security vulnerabilities and session management"

### Provide Context
Include:
- Which files to examine
- Specific concerns or requirements
- Related code locations
- Expected patterns or conventions

### Use Appropriate Agent
- Security review → `code-reviewer`
- Test creation → `test-generator`
- API docs → `documentation-writer`
- Style cleanup → `ai-slop-remover`
- Full feature → `feature-team-coordinator`

### Iterate When Needed
If results aren't satisfactory:
1. Provide more specific feedback
2. Reference existing examples
3. Clarify expectations
4. Re-delegate with refined instructions

## Advanced Patterns

### Custom Workflow
Create your own orchestration:

```markdown
Phase 1: Implementation
[Your code changes]

Phase 2: Quality Gates
Parallel execution:
- @code-reviewer: Security and quality
- @test-generator: Test coverage

Phase 3: Address Feedback
[Fix issues from reviews]

Phase 4: Polish
- @ai-slop-remover: Style cleanup
- @documentation-writer: Documentation

Phase 5: Final Verification
Run tests and verify all checks pass
```

### Specialized Focus
Target specific aspects:

```markdown
@code-reviewer

Quick security audit only:
- SQL injection risks
- XSS vulnerabilities
- Authentication bypass potential

Skip style and minor issues - focus on critical security only.
```

## Common Workflows

### Bug Fix
```markdown
1. Identify and fix bug
2. @test-generator: Add regression test
3. @code-reviewer: Quick review of fix
```

### Refactoring
```markdown
1. Refactor code
2. @code-reviewer: Verify logic preservation
3. @test-generator: Ensure test coverage
4. @ai-slop-remover: Clean up patterns
```

### New API Endpoint
```markdown
1. @feature-team-coordinator: Implement complete endpoint
   - Code implementation
   - Tests
   - Documentation
   - Security review
```

### Documentation Update
```markdown
@documentation-writer

Update docs for the new webhook system:
- Architecture changes
- API modifications
- Migration guide
```

## Troubleshooting

### Agent Not Responding
- Verify agent file exists in `configs/claude/agents/`
- Check YAML frontmatter is valid
- Ensure `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` is set

### Unexpected Results
- Provide more context and examples
- Reference specific files and line numbers
- Clarify expected output format
- Show examples of desired patterns

### Agent Conflicts
- Prioritize critical feedback
- Consider trade-offs
- Document decisions
- Iterate with refined instructions

## Resources

- [Agent Teams Documentation](claude-code-teams.md)
- [Agent Definitions](../configs/claude/agents/)
- [Settings Configuration](../configs/claude/settings.json)
