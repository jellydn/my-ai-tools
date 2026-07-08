# Blind Spot Pass

## When to Use

Use this skill **before starting implementation** when:
- Working on an unfamiliar part of the codebase
- Integrating with systems you don't fully understand
- The task has high stakes or complexity
- You sense there might be hidden gotchas

## What It Does

A blind spot pass helps identify **unknown unknowns** that could derail implementation or lead to poor architectural decisions.

## How to Execute

### Step 1: Define Scope

Clearly state what you're about to work on:
- Feature or change description
- Affected modules/systems
- Current understanding level

### Step 2: Search for Context

Look in multiple places for relevant history:

```bash
# Recent changes to related files
git log --oneline --all -20 -- path/to/module/

# Search commit messages for keywords
git log --all --grep="auth\|oauth\|provider" --oneline

# Find related discussions in code comments
rg -i "TODO|FIXME|HACK|XXX" path/to/module/

# Search for error handling patterns
rg "catch|throw|error" path/to/module/ -A 3
```

### Step 3: Identify Gotchas

Document findings in categories:

**Technical Gotchas**:
- Edge cases in existing code
- Performance considerations
- Error handling patterns
- Testing requirements

**Architectural Gotchas**:
- Existing abstractions to follow
- Integration points
- Data flow patterns
- State management approaches

**Business Gotchas**:
- Implicit requirements from past discussions
- Feature flags or phased rollouts
- Backward compatibility needs
- Security or compliance requirements

### Step 4: Surface Questions

Generate questions that would change the approach:

- "I see error handling uses X pattern; should I follow it?"
- "There's a feature flag system; does this need one?"
- "Previous auth work had Y consideration; does that apply here?"

### Step 5: Present Findings

Format as a structured report:

```markdown
## Blind Spot Analysis: [Task Name]

### Context Sources Checked
- [x] Git history (last 3 months, 45 commits in auth/)
- [x] Code comments and TODOs (found 3 relevant)
- [x] Error handling patterns (uses Result type)
- [x] Test coverage (integration tests in /tests/auth/)

### Key Findings

**Architectural Patterns**:
- All auth providers extend BaseOAuthProvider
- Must implement 3 lifecycle hooks: init, authenticate, refresh
- Config validation happens at provider registration

**Known Gotchas**:
- GitHub OAuth requires app installation per org (not per user)
- Refresh tokens expire after 6 months of inactivity
- Rate limiting uses Redis; need to handle connection failures

**Testing Requirements**:
- Mock responses in tests/fixtures/oauth/
- Integration tests use test credentials from .env.test
- Must test token refresh flow explicitly

### Questions Before Proceeding

1. Should GitHub provider support org-level installation?
2. How should we handle rate limit failures? (retry? user error?)
3. Is there a preferred library for GitHub OAuth, or implement from scratch?

### Recommended Approach

[Brief recommendation based on findings]
```

## Example Usage

```
User: "I need to add Stripe payment integration to our checkout flow"

Agent: "Let me do a blind spot pass first to identify unknowns."

[Agent searches codebase, git history, finds existing payment integrations]

Agent: "Blind Spot Analysis: Stripe Integration

Context Sources Checked:
- Git history: Found previous PayPal integration (6 months ago)
- Existing code: Braintree integration in /payments/providers/
- Tests: Payment integration tests use VCR for API mocking

Key Findings:

Architectural Patterns:
- All payment providers implement PaymentProvider interface
- Webhook handling is centralized in /webhooks/payment-events
- PCI compliance: Never store card numbers, only Stripe tokens

Known Gotchas:
- Must implement idempotency keys for all charge operations
- Webhook signature verification required (security requirement)
- Stripe test mode uses different API keys from .env.stripe.test
- Currency handling: Store amounts as integers (cents) not floats

Testing Requirements:
- Use Stripe test fixtures (don't call real API in tests)
- Must test webhook verification with valid and invalid signatures
- Cover 3 main flows: successful charge, declined card, network error

Questions Before Proceeding:

1. Should we support Stripe Connect (for marketplaces) or just direct charges?
2. Do we need recurring billing support, or one-time payments only?
3. Should failed charges retry automatically, or require user action?
4. What currency/currencies do we need to support?

Recommended Approach:
Based on the PayPal integration pattern, implement as a plugin in
/payments/providers/stripe/ with webhook handler in /webhooks/stripe/.
Follow idempotency pattern from Braintree integration.
"
```

## Best Practices

1. **Search broadly first**: Git history, code, comments, tests, documentation
2. **Look for patterns**: What did previous similar work do?
3. **Find the gotchas**: Search for error handling, TODOs, FIXMEs
4. **Generate good questions**: Focus on architecture-changing decisions
5. **Provide recommendations**: Synthesize findings into an approach

## Integration with Other Skills

- **Before**: Define task scope
- **After Blind Spot Pass**: Run interview skill if major unknowns remain
- **During Implementation**: Use implementation-logger to track deviations
- **After Implementation**: Use quiz-me to verify understanding

## Common Pitfalls

- **Too narrow**: Only checking files you'll edit (check dependencies too)
- **Too shallow**: Only reading current code (check git history for context)
- **No questions**: Findings without questions don't guide next steps
- **No synthesis**: Raw data dump instead of actionable recommendations

## Success Criteria

A good blind spot pass:
- Identifies at least 2-3 gotchas you didn't know about
- Generates questions that would change your approach
- References concrete evidence (commits, code, comments)
- Provides clear recommendation for how to proceed
- Takes 5-15 minutes (not hours)
