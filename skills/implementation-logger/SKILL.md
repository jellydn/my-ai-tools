# Implementation Logger

## When to Use

Use this skill **during implementation** when:
- Working on complex or uncertain changes
- The implementation approach isn't fully defined
- You want to track decisions for documentation
- Building knowledge about unknowns for future work
- Need to explain reasoning in PR descriptions

## What It Does

Tracks **deviations from the original plan** and **decision rationale** during implementation. Helps identify where your mental model (map) differed from reality (territory).

## How to Execute

### Step 1: Set Up Logging

At the start of implementation, create a log file:

```bash
# Create implementation log
echo "# Implementation Log: [Feature Name]" > .implementation-log.md
echo "" >> .implementation-log.md
echo "Started: $(date)" >> .implementation-log.md
echo "" >> .implementation-log.md
echo "## Original Plan" >> .implementation-log.md
echo "[Brief summary of approach]" >> .implementation-log.md
echo "" >> .implementation-log.md
echo "## Deviations & Decisions" >> .implementation-log.md
```

### Step 2: Log During Implementation

Whenever reality differs from plan, log it:

```markdown
### [Timestamp] - [Decision Point Title]

**Context**: What I encountered that wasn't in the plan

**Original Assumption**: What I thought would work

**Reality**: What I actually found

**Decision**: What I decided to do instead

**Rationale**: Why this approach is better/necessary

**Impact**: What else this might affect
```

### Step 3: Log Categories

Track different types of deviations:

**Architectural Discoveries**:
- Found existing abstraction that changes approach
- Realized need for new pattern
- Dependency constraints

**Unknown Unknowns**:
- Edge cases not in spec
- Integration points discovered
- Performance considerations

**Technical Constraints**:
- Library limitations
- Type system issues
- Test infrastructure gaps

**Spec Gaps**:
- Ambiguous requirements
- Missing error handling specs
- Unclear business logic

### Step 4: Review & Extract

After implementation:
1. Review log for patterns
2. Extract key learnings for documentation
3. Identify knowledge to preserve
4. Update relevant docs/ADRs

## Log Template

```markdown
# Implementation Log: [Feature Name]

**Date**: [Date]
**Developer**: [Name or Agent ID]
**Original Plan**: [Link to spec/plan]

## Summary
[One paragraph: what we built and key decisions]

## Original Approach
[What we planned to do]

## Deviations & Decisions

### Decision 1: [Title]
**When**: [Timestamp/phase]
**Context**: [What prompted this decision]
**Original Plan**: [What we thought we'd do]
**Reality**: [What we actually found]
**Decision**: [What we decided]
**Rationale**: [Why this is better]
**Impact**: [Side effects or dependencies]
**Code**: [Link to relevant commit/files]

### Decision 2: [Title]
...

## Unknowns Discovered

### Unknown: [Title]
**Category**: [Architecture/Spec/Technical/Business]
**Impact**: [High/Medium/Low]
**Description**: [What we didn't know]
**Resolution**: [How we resolved it]
**Future Consideration**: [Should this inform future work?]

## Learnings

### What Worked Well
- [Learning 1]
- [Learning 2]

### What Was Surprising
- [Surprise 1]
- [Surprise 2]

### What to Do Differently Next Time
- [Improvement 1]
- [Improvement 2]

## Documentation Updates Needed
- [ ] Update ADR on [topic]
- [ ] Add to MEMORY.md: [learning]
- [ ] Update [skill/guide]: [improvement]

## Follow-up Questions
1. [Question that arose during implementation]
2. [Question for stakeholder/team]
```

## Example Usage

```markdown
# Implementation Log: GitHub OAuth Integration

**Date**: 2026-07-08
**Original Plan**: docs/specs/github-oauth.md

## Summary
Implemented GitHub OAuth provider following existing OAuth pattern.
Key deviation: Used App Installation flow instead of user OAuth due to
org-level permission requirements. Added webhook endpoint for
installation events.

## Original Approach
- Implement standard OAuth 2.0 flow via library
- Use Personal Access Token (PAT) flow for initial testing

## Deviations & Decisions

### Decision 1: Use GitHub App Installation Flow

**When**: During initial auth flow implementation

**Context**: Testing revealed that org-level repo access requires GitHub
App installation, not user OAuth. Our target users need org repo access.

**Original Plan**: Standard OAuth with PAT

**Reality**: GitHub deprecated PAT for org access. Apps must use
Installation flow which requires:
- App installation per organization
- Installation webhook handling
- Installation-specific tokens

**Decision**: Implement GitHub App Installation flow instead

**Rationale**:
- Only way to get org-level repo access
- More secure (granular permissions)
- Better aligned with GitHub's current best practices
- Matches what users expect (seen in other tools)

**Impact**:
- Added webhook endpoint: /webhooks/github/installation
- New database table: github_installations
- Installation token refresh logic (expires after 1hr vs 6mo)
- More complex setup docs (users must create GitHub App)

**Code**: commit abc123, files: auth/github/installation.ts

### Decision 2: Cache Installation Tokens

**When**: During token refresh implementation

**Context**: Installation tokens expire after 1 hour. Naive approach would
request new token for every API call.

**Original Plan**: Request new token on each API call

**Reality**: GitHub rate limits token requests to 5000/hour per app.
With multiple users in same org, we'd hit limit quickly.

**Decision**: Cache installation tokens in Redis with 55min TTL

**Rationale**:
- Prevents rate limit issues
- Reduces latency (no token request per API call)
- 55min TTL provides 5min safety buffer before expiry
- Existing Redis used for other caching

**Impact**:
- Added Redis key pattern: github:install:{id}:token
- Token refresh logic checks cache first
- Cache invalidation on installation webhook events

**Code**: commit def456, files: auth/github/token-cache.ts

### Decision 3: Handle Installation Deletion

**When**: Writing webhook handler

**Context**: Users can uninstall the GitHub App from their org

**Original Plan**: Not explicitly considered

**Reality**: Installation deletion is common (users test, revoke, etc).
Must handle gracefully.

**Decision**: Soft-delete installations, preserve audit log

**Rationale**:
- Maintain audit trail of access history
- Prevent orphaned references in user sessions
- Allow re-installation without data loss
- Compliance requirement (track who had access when)

**Impact**:
- Added `deleted_at` column to github_installations
- Webhook handler for installation.deleted event
- Session middleware checks installation.deleted_at
- User sees clear error: "GitHub integration removed"

**Code**: commit ghi789, files: webhooks/github.ts

## Unknowns Discovered

### Unknown: GitHub App vs OAuth App
**Category**: Architecture
**Impact**: High
**Description**: Didn't realize GitHub has two different app types with
different capabilities. OAuth Apps can't get org-level repo access.
**Resolution**: Used GitHub App with Installation flow
**Future Consideration**: Document this in our OAuth integration guide.
Other providers may have similar dual-model systems.

### Unknown: Installation Token Lifespan
**Category**: Technical
**Impact**: Medium
**Description**: Installation tokens expire after 1 hour, not 6 months
like user tokens. This wasn't in our initial spec.
**Resolution**: Implemented caching strategy
**Future Consideration**: Standard pattern for short-lived tokens?

### Unknown: Rate Limit on Token Requests
**Category**: Technical
**Impact**: Medium
**Description**: Token endpoint has its own rate limit separate from API
**Resolution**: Cache tokens in Redis
**Future Consideration**: Consider for other OAuth providers too

## Learnings

### What Worked Well
- Blind spot pass identified existing OAuth pattern to follow
- Webhook infrastructure was already in place
- Redis caching pattern from other auth providers was reusable

### What Was Surprising
- GitHub's dual app model (wasn't in initial research)
- How common installation deletion is (users test a lot)
- Token request rate limiting (separate from API limits)

### What to Do Differently Next Time
- Research provider-specific gotchas more deeply upfront
- Ask explicitly about token lifespan in spec interview
- Consider short-lived tokens in architecture discussions

## Documentation Updates Needed
- [x] Add to skills/blindspot-pass examples: Check for dual auth models
- [ ] Update MEMORY.md: GitHub Apps vs OAuth Apps distinction
- [ ] Create ADR: Short-lived token caching strategy
- [ ] Update OAuth integration guide with GitHub App specifics

## Follow-up Questions
1. Should we implement GitHub App for user-level access too (consistency)?
2. Do other OAuth providers have similar dual models to document?
3. Should Redis cache TTL be configurable per provider?
```

## Best Practices

1. **Log as you go**: Don't wait until end of implementation
2. **Be specific**: Include timestamps, commit SHAs, file paths
3. **Explain reasoning**: Not just what changed, but why
4. **Note impact**: What else does this affect?
5. **Extract learnings**: Turn log into documentation
6. **Keep it concise**: Each entry should be 1-2 paragraphs max

## Integration with Other Skills

- **Before Implementation**: Blind spot pass + spec interview reduce unknowns
- **During Implementation**: Use this skill to track deviations
- **After Implementation**: Extract for PR description, ADRs, MEMORY.md
- **Follow-up**: Quiz-me to verify you understand the logged decisions

## Output Locations

### Where to Store Logs

**Temporary logs** (during work):
```text
.implementation-log.md  # Git ignored, working file
```

**Permanent documentation** (after completion):
```text
docs/adr/NNN-[decision].md          # Architecture decisions
MEMORY.md                            # Gotchas and learnings
wiki/[topic]/[entry].md              # Knowledge base entries
.github/pull_requests/[PR].md        # PR description
```

### Git Ignore

Add to `.gitignore`:
```text
.implementation-log.md
.dev-notes.md
```

These are working files, not committed artifacts.

## Success Criteria

A good implementation log:
- Records at least 2-3 deviations from original plan
- Explains rationale for each decision
- Identifies unknowns discovered
- Provides material for PR description
- Takes minimal time to maintain (1-2 min per entry)
- Results in better documentation

## Common Pitfalls

- **Too detailed**: Don't log every line of code, focus on decisions
- **Too late**: Logging after the fact loses context and rationale
- **No extraction**: Log sits unused instead of feeding documentation
- **No patterns**: Missing the forest for the trees; look for themes
- **Defensiveness**: Log is for learning, not justifying; be honest

## Advanced: Auto-logging

For advanced workflows, automatically log key events:

```bash
# Git commit hook to prompt for log entries
# .git/hooks/post-commit

#!/bin/bash
if [ -f .implementation-log.md ]; then
  echo "📝 Implementation log detected. Add entry for this commit? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    echo "" >> .implementation-log.md
    echo "### $(date) - $(git log -1 --pretty=%B)" >> .implementation-log.md
    echo "**Commit**: $(git rev-parse --short HEAD)" >> .implementation-log.md
    echo "**Decision**: [TODO: Fill in]" >> .implementation-log.md
    echo "" >> .implementation-log.md
    echo "Log entry template added. Edit .implementation-log.md"
  fi
fi
```

This reminds you to log after each commit.
